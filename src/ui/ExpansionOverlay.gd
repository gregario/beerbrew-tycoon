extends CanvasLayer

signal expansion_confirmed()
signal closed()

var _panel: PanelContainer
var _balance_after_label: Label

func _ready() -> void:
	visible = false

func show_overlay() -> void:
	_build_ui()
	visible = true

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	# Dim background
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# Center panel 900x550
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 550)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(190, 85)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#0B1220")
	panel_style.border_color = Color("#FFC857")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(4)
	panel_style.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title := Label.new()
	title.text = "EXPAND YOUR BREWERY"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.pressed.connect(_on_close)
	header.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	# Stage transition row
	var stage_row := HBoxContainer.new()
	stage_row.add_theme_constant_override("separation", 16)
	stage_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(stage_row)
	var from_label := Label.new()
	from_label.text = "GARAGE"
	from_label.add_theme_font_size_override("font_size", 24)
	from_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	stage_row.add_child(from_label)
	var arrow := Label.new()
	arrow.text = "  ───>  "
	arrow.add_theme_font_size_override("font_size", 24)
	arrow.add_theme_color_override("font_color", Color("#FFC857"))
	stage_row.add_child(arrow)
	var to_label := Label.new()
	to_label.text = "MICROBREWERY"
	to_label.add_theme_font_size_override("font_size", 24)
	to_label.add_theme_color_override("font_color", Color("#FFC857"))
	stage_row.add_child(to_label)

	# Benefits
	_add_section_label(vbox, "WHAT YOU GET:", Color("#5EE8A4"))
	var benefits := _add_info_box(vbox, Color("#5EE8A4"))
	_add_info_line(benefits, "Station Slots: 3 → 5 (+2 new slots)")
	_add_info_line(benefits, "Staff Hiring: Locked → Unlocked (max 2)")
	_add_info_line(benefits, "Equipment: T1-T2 → T1-T4 unlocked")
	_add_info_line(benefits, "Larger Space: Industrial brewery layout")

	# Costs
	_add_section_label(vbox, "COSTS:", Color("#FFB347"))
	var costs := _add_info_box(vbox, Color("#FFB347"))
	_add_info_line(costs, "Upgrade Cost: $%d (one-time)" % int(BreweryExpansion.EXPAND_COST))
	_add_info_line(costs, "Rent Increase: $150 → $400 per period")

	# Balance after
	_balance_after_label = Label.new()
	var after_amount: float = GameState.balance - BreweryExpansion.EXPAND_COST
	_balance_after_label.text = "Balance after: $%d" % int(after_amount)
	_balance_after_label.add_theme_font_size_override("font_size", 20)
	var after_color: Color = Color("#FF7B7B") if after_amount < 200 else Color("#8A9BB1")
	_balance_after_label.add_theme_color_override("font_color", after_color)
	vbox.add_child(_balance_after_label)

	# Button row
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 24)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)
	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(160, 48)
	cancel_btn.pressed.connect(_on_close)
	btn_row.add_child(cancel_btn)
	var expand_btn := Button.new()
	expand_btn.text = "Expand — $%d" % int(BreweryExpansion.EXPAND_COST)
	expand_btn.custom_minimum_size = Vector2(240, 48)
	expand_btn.disabled = not BreweryExpansion.can_afford_expansion()
	expand_btn.pressed.connect(_on_expand)
	var expand_style := StyleBoxFlat.new()
	expand_style.bg_color = Color("#FFC857")
	expand_style.set_corner_radius_all(8)
	expand_style.set_content_margin_all(8)
	expand_btn.add_theme_stylebox_override("normal", expand_style)
	expand_btn.add_theme_color_override("font_color", Color("#0F1724"))
	btn_row.add_child(expand_btn)

func _add_section_label(parent: VBoxContainer, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)

func _add_info_box(parent: VBoxContainer, border_color: Color) -> VBoxContainer:
	var pc := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0B1220")
	style.border_color = border_color
	style.border_width_left = 2
	style.set_content_margin_all(12)
	pc.add_theme_stylebox_override("panel", style)
	parent.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	pc.add_child(vb)
	return vb

func _add_info_line(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color.WHITE)
	parent.add_child(label)

func _on_expand() -> void:
	var success: bool = BreweryExpansion.expand()
	if success:
		if is_instance_valid(EquipmentManager):
			EquipmentManager.resize_slots()
		if is_instance_valid(ToastManager):
			ToastManager.show_toast("Welcome to your Microbrewery! 2 new station slots unlocked.")
			ToastManager.show_toast("Rent increased: $150 → $400 per period")
		expansion_confirmed.emit()
		visible = false

func _on_close() -> void:
	visible = false
	closed.emit()
