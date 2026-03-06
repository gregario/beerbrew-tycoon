extends CanvasLayer

## SellOverlay — post-brew overlay where the player allocates their batch across
## distribution channels and sets a price, then confirms the sale.
## Follows the same pattern as ContractBoard.gd / StaffScreen.gd.

signal closed()
signal sale_confirmed(allocations: Array, price_offset: float)

# Internal state set by show_overlay()
var _style_name: String = ""
var _base_price: float = 0.0
var _quality_score: float = 0.0
var _batch_size: int = 10
var _demand_mult: float = 1.0
var _price_offset: float = 0.0

# Channel allocation: {channel_id: int}
var _channel_units: Dictionary = {}

# UI references for live updates
var _price_label: Label = null
var _price_pct_label: Label = null
var _volume_label: Label = null
var _price_slider: HSlider = null
var _allocated_label: Label = null
var _projected_label: Label = null
var _waste_label: Label = null
var _channel_rows: Dictionary = {}  # {channel_id: {units_label, rev_label, plus_btn, minus_btn}}
var _confirm_btn: Button = null


func _ready() -> void:
	layer = 10
	visible = false


## Open the sell overlay and rebuild the display.
func show_overlay(style_name: String, base_price: float, quality_score: float,
		batch_size: int, demand_mult: float) -> void:
	_style_name = style_name
	_base_price = base_price
	_quality_score = quality_score
	_batch_size = batch_size
	_demand_mult = demand_mult
	_price_offset = 0.0
	_channel_units = {}

	# Initialize channel allocations to zero
	var channels: Array = MarketManager.get_unlocked_channels()
	for ch in channels:
		_channel_units[ch.id] = 0

	# Auto-default: allocate as much as possible to highest-margin channels first
	_auto_allocate(channels)

	_build_ui()
	visible = true


func _auto_allocate(channels: Array) -> void:
	# Sort channels by margin descending (taproom=1.0, events=1.5, etc.)
	var sorted_channels: Array = channels.duplicate()
	sorted_channels.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.margin > b.margin
	)

	var remaining: int = _batch_size
	for ch in sorted_channels:
		var max_units: int = MarketManager.get_max_units(ch.id, _batch_size)
		var units: int = mini(max_units, remaining)
		_channel_units[ch.id] = units
		remaining -= units
		if remaining <= 0:
			break


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	_channel_rows = {}

	# Dim background
	var dim := ColorRect.new()
	dim.color = Color("#0F1724", 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# Center panel 900x550
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 550)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#0B1220")
	panel_style.border_color = Color("#8A9BB1")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(4)
	panel_style.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	# ---- Header row ----
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title := Label.new()
	title.text = "SELL: %s" % _style_name
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var demand_label := Label.new()
	demand_label.text = "Demand: %.1fx" % _demand_mult
	demand_label.add_theme_font_size_override("font_size", 20)
	var demand_color: Color = Color("#5EE8A4") if _demand_mult >= 1.0 else Color("#FF7B7B")
	demand_label.add_theme_color_override("font_color", demand_color)
	header.add_child(demand_label)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(16, 0)
	header.add_child(spacer)
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(_on_close)
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color(Color("#FF7B7B"), 0.2)
	close_style.set_corner_radius_all(4)
	close_btn.add_theme_stylebox_override("normal", close_style)
	header.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	# ---- Pricing section ----
	var pricing_header := HBoxContainer.new()
	vbox.add_child(pricing_header)
	var pricing_title := Label.new()
	pricing_title.text = "PRICING"
	pricing_title.add_theme_font_size_override("font_size", 22)
	pricing_title.add_theme_color_override("font_color", Color("#FFC857"))
	pricing_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pricing_header.add_child(pricing_title)
	var batch_label := Label.new()
	batch_label.text = "Batch Size: %d units" % _batch_size
	batch_label.add_theme_font_size_override("font_size", 18)
	batch_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	pricing_header.add_child(batch_label)

	# Base price
	var base_row := HBoxContainer.new()
	base_row.add_theme_constant_override("separation", 8)
	vbox.add_child(base_row)
	var base_label := Label.new()
	base_label.text = "Base Price: $%.0f" % _base_price
	base_label.add_theme_font_size_override("font_size", 18)
	base_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	base_row.add_child(base_label)

	# Adjusted price + slider row
	var slider_row := HBoxContainer.new()
	slider_row.add_theme_constant_override("separation", 12)
	vbox.add_child(slider_row)

	_price_label = Label.new()
	_price_label.text = "Your Price: $%.0f" % _base_price
	_price_label.add_theme_font_size_override("font_size", 18)
	_price_label.add_theme_color_override("font_color", Color.WHITE)
	_price_label.custom_minimum_size = Vector2(160, 0)
	slider_row.add_child(_price_label)

	_price_pct_label = Label.new()
	_price_pct_label.text = "(+0%)"
	_price_pct_label.add_theme_font_size_override("font_size", 18)
	_price_pct_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	_price_pct_label.custom_minimum_size = Vector2(80, 0)
	slider_row.add_child(_price_pct_label)

	_price_slider = HSlider.new()
	_price_slider.min_value = -0.3
	_price_slider.max_value = 0.5
	_price_slider.step = 0.05
	_price_slider.value = _price_offset
	_price_slider.custom_minimum_size = Vector2(300, 24)
	_price_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_price_slider.value_changed.connect(_on_price_changed)
	slider_row.add_child(_price_slider)

	# Volume effect
	var vol_row := HBoxContainer.new()
	vbox.add_child(vol_row)
	_volume_label = Label.new()
	_volume_label.add_theme_font_size_override("font_size", 16)
	_volume_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	vol_row.add_child(_volume_label)

	vbox.add_child(HSeparator.new())

	# ---- Distribution section ----
	var dist_header := HBoxContainer.new()
	vbox.add_child(dist_header)
	var dist_title := Label.new()
	dist_title.text = "DISTRIBUTION"
	dist_title.add_theme_font_size_override("font_size", 22)
	dist_title.add_theme_color_override("font_color", Color("#FFC857"))
	dist_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dist_header.add_child(dist_title)
	_allocated_label = Label.new()
	_allocated_label.add_theme_font_size_override("font_size", 18)
	_allocated_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	dist_header.add_child(_allocated_label)

	# Channel rows (all 4 — unlocked get +/- buttons, locked show "Locked")
	var channels_container := VBoxContainer.new()
	channels_container.add_theme_constant_override("separation", 4)
	vbox.add_child(channels_container)

	for ch in MarketManager.CHANNELS:
		var unlocked: bool = MarketManager.is_channel_unlocked(ch.id)
		_add_channel_row(channels_container, ch, unlocked)

	vbox.add_child(HSeparator.new())

	# ---- Projected revenue box ----
	var proj_panel := PanelContainer.new()
	var proj_style := StyleBoxFlat.new()
	proj_style.bg_color = Color("#0B1220")
	proj_style.border_color = Color("#5EE8A4")
	proj_style.set_border_width_all(2)
	proj_style.set_corner_radius_all(4)
	proj_style.set_content_margin_all(12)
	proj_panel.add_theme_stylebox_override("panel", proj_style)
	vbox.add_child(proj_panel)

	var proj_vbox := VBoxContainer.new()
	proj_vbox.add_theme_constant_override("separation", 2)
	proj_panel.add_child(proj_vbox)

	_projected_label = Label.new()
	_projected_label.add_theme_font_size_override("font_size", 22)
	_projected_label.add_theme_color_override("font_color", Color("#5EE8A4"))
	proj_vbox.add_child(_projected_label)

	_waste_label = Label.new()
	_waste_label.add_theme_font_size_override("font_size", 16)
	_waste_label.add_theme_color_override("font_color", Color("#FF7B7B"))
	proj_vbox.add_child(_waste_label)

	# ---- Confirm button ----
	var btn_row := HBoxContainer.new()
	btn_row.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(btn_row)

	_confirm_btn = Button.new()
	_confirm_btn.text = "Confirm Sale"
	_confirm_btn.custom_minimum_size = Vector2(200, 44)
	_confirm_btn.add_theme_font_size_override("font_size", 22)
	_confirm_btn.add_theme_color_override("font_color", Color("#0F1724"))
	var confirm_style := StyleBoxFlat.new()
	confirm_style.bg_color = Color("#FFC857")
	confirm_style.set_corner_radius_all(8)
	confirm_style.set_content_margin_all(8)
	_confirm_btn.add_theme_stylebox_override("normal", confirm_style)
	var confirm_hover := confirm_style.duplicate()
	confirm_hover.bg_color = Color("#FFD680")
	_confirm_btn.add_theme_stylebox_override("hover", confirm_hover)
	_confirm_btn.pressed.connect(_on_confirm)
	btn_row.add_child(_confirm_btn)

	# Initial projection update
	_update_projections()


func _add_channel_row(parent: VBoxContainer, ch: Dictionary, unlocked: bool) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var name_label := Label.new()
	name_label.text = ch.name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.custom_minimum_size = Vector2(120, 0)
	row.add_child(name_label)

	if not unlocked:
		name_label.add_theme_color_override("font_color", Color("#8A9BB1"))
		var locked_label := Label.new()
		locked_label.text = "Locked"
		locked_label.add_theme_font_size_override("font_size", 18)
		locked_label.add_theme_color_override("font_color", Color("#8A9BB1"))
		row.add_child(locked_label)
		return

	name_label.add_theme_color_override("font_color", Color.WHITE)

	# Minus button
	var minus_btn := Button.new()
	minus_btn.text = "-"
	minus_btn.custom_minimum_size = Vector2(36, 32)
	minus_btn.add_theme_font_size_override("font_size", 18)
	var minus_style := StyleBoxFlat.new()
	minus_style.bg_color = Color("#FF7B7B", 0.3)
	minus_style.set_corner_radius_all(4)
	minus_btn.add_theme_stylebox_override("normal", minus_style)
	var cid: String = ch.id
	minus_btn.pressed.connect(func(): _on_channel_minus(cid))
	row.add_child(minus_btn)

	# Plus button
	var plus_btn := Button.new()
	plus_btn.text = "+"
	plus_btn.custom_minimum_size = Vector2(36, 32)
	plus_btn.add_theme_font_size_override("font_size", 18)
	var plus_style := StyleBoxFlat.new()
	plus_style.bg_color = Color("#5EE8A4", 0.3)
	plus_style.set_corner_radius_all(4)
	plus_btn.add_theme_stylebox_override("normal", plus_style)
	plus_btn.pressed.connect(func(): _on_channel_plus(cid))
	row.add_child(plus_btn)

	# Units label
	var units_label := Label.new()
	units_label.text = "%d units" % _channel_units.get(ch.id, 0)
	units_label.add_theme_font_size_override("font_size", 18)
	units_label.add_theme_color_override("font_color", Color.WHITE)
	units_label.custom_minimum_size = Vector2(100, 0)
	row.add_child(units_label)

	# Max label
	var max_units: int = MarketManager.get_max_units(ch.id, _batch_size)
	var max_label := Label.new()
	max_label.text = "(max %d)" % max_units
	max_label.add_theme_font_size_override("font_size", 16)
	max_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	max_label.custom_minimum_size = Vector2(80, 0)
	row.add_child(max_label)

	# Arrow
	var arrow := Label.new()
	arrow.text = "->"
	arrow.add_theme_font_size_override("font_size", 18)
	arrow.add_theme_color_override("font_color", Color("#8A9BB1"))
	row.add_child(arrow)

	# Revenue estimate label
	var rev_label := Label.new()
	rev_label.text = "$0 est."
	rev_label.add_theme_font_size_override("font_size", 18)
	rev_label.add_theme_color_override("font_color", Color("#5EE8A4"))
	rev_label.custom_minimum_size = Vector2(120, 0)
	row.add_child(rev_label)

	# Margin info
	var margin_label := Label.new()
	margin_label.text = "(%.0f%% margin)" % (ch.margin * 100.0)
	margin_label.add_theme_font_size_override("font_size", 14)
	margin_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	row.add_child(margin_label)

	_channel_rows[ch.id] = {
		"units_label": units_label,
		"rev_label": rev_label,
		"plus_btn": plus_btn,
		"minus_btn": minus_btn,
	}


func _on_price_changed(value: float) -> void:
	_price_offset = value
	_update_projections()


func _on_channel_plus(channel_id: String) -> void:
	var total_allocated: int = _get_total_allocated()
	if total_allocated >= _batch_size:
		return
	var max_units: int = MarketManager.get_max_units(channel_id, _batch_size)
	var current: int = _channel_units.get(channel_id, 0)
	if current >= max_units:
		return
	_channel_units[channel_id] = current + 1
	_update_projections()


func _on_channel_minus(channel_id: String) -> void:
	var current: int = _channel_units.get(channel_id, 0)
	if current <= 0:
		return
	_channel_units[channel_id] = current - 1
	_update_projections()


func _get_total_allocated() -> int:
	var total: int = 0
	for cid in _channel_units:
		total += _channel_units[cid]
	return total


func _update_projections() -> void:
	var adjusted_price: float = _base_price * (1.0 + _price_offset)
	var quality_mult: float = GameState.quality_to_multiplier(_quality_score)
	var volume_mod: float = MarketManager.calculate_volume_modifier(_price_offset, _quality_score)
	var total_allocated: int = 0
	var total_revenue: float = 0.0

	for channel_id in _channel_units:
		var units: int = _channel_units[channel_id]
		total_allocated += units
		var ch: Dictionary = MarketManager.get_channel(channel_id)
		var rev: float = units * adjusted_price * ch.margin * quality_mult * _demand_mult * volume_mod
		total_revenue += rev

		# Update channel row labels
		if _channel_rows.has(channel_id):
			var row: Dictionary = _channel_rows[channel_id]
			row["units_label"].text = "%d units" % units
			row["rev_label"].text = "$%.0f est." % rev

	# Update price labels
	if _price_label:
		_price_label.text = "Your Price: $%.0f" % adjusted_price
	if _price_pct_label:
		var pct: int = int(_price_offset * 100.0)
		var sign: String = "+" if pct >= 0 else ""
		_price_pct_label.text = "(%s%d%%)" % [sign, pct]
		if pct > 0:
			_price_pct_label.add_theme_color_override("font_color", Color("#5EE8A4"))
		elif pct < 0:
			_price_pct_label.add_theme_color_override("font_color", Color("#FF7B7B"))
		else:
			_price_pct_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	if _volume_label:
		_volume_label.text = "Volume Effect: %.2fx" % volume_mod
	if _allocated_label:
		_allocated_label.text = "Allocated: %d/%d" % [total_allocated, _batch_size]
	if _projected_label:
		_projected_label.text = "PROJECTED REVENUE          $%.0f" % total_revenue
	if _waste_label:
		var unsold: int = _batch_size - total_allocated
		if unsold > 0:
			_waste_label.text = "(%d unsold units wasted)" % unsold
			_waste_label.visible = true
		else:
			_waste_label.visible = false


func _on_confirm() -> void:
	var allocations: Array = []
	for channel_id in _channel_units:
		var units: int = _channel_units[channel_id]
		if units > 0:
			allocations.append({"channel_id": channel_id, "units": units})
	visible = false
	sale_confirmed.emit(allocations, _price_offset)


func _on_close() -> void:
	visible = false
	closed.emit()
