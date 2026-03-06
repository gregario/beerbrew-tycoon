extends CanvasLayer

## MarketForecast — tabbed overlay (Forecast / Channels / Research).
## Built entirely in code (no .tscn needed).
## Follows the same pattern as ContractBoard.gd / CompetitionScreen.gd.

signal closed()

var _active_tab: int = 0  # 0=Forecast, 1=Channels, 2=Research

const TAB_NAMES: Array[String] = ["Forecast", "Channels", "Research"]

const CHANNEL_DESCRIPTIONS: Dictionary = {
	"taproom": "Rewards quality & variety",
	"local_bars": "Prefers popular styles",
	"retail": "Prefers recognizable brands",
	"events": "Rewards specialty beers",
}

const UNLOCK_HINTS: Dictionary = {
	"always": "Available",
	"brewery_stage": "Unlock: Microbrewery",
	"research": "Unlock: Research",
	"events": "Unlock: Win a medal",
}


func _ready() -> void:
	layer = 10
	visible = false


## Open the market forecast and rebuild the display.
func show_screen() -> void:
	_build_ui()
	visible = true


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	if not is_instance_valid(MarketManager):
		return

	# Dim background
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# Center panel 900x550
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
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
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(header)
	var title := Label.new()
	title.text = "MARKET FORECAST"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var season_label := Label.new()
	season_label.text = "%s (turn %d/%d)" % [MarketManager.get_season_name(), MarketManager.season_turn + 1, MarketManager.TURNS_PER_SEASON]
	season_label.add_theme_font_size_override("font_size", 20)
	season_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	header.add_child(season_label)
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

	# Tab bar
	var tab_bar := HBoxContainer.new()
	tab_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	tab_bar.add_theme_constant_override("separation", 4)
	vbox.add_child(tab_bar)
	for i in range(TAB_NAMES.size()):
		var tab_btn := Button.new()
		tab_btn.text = TAB_NAMES[i]
		tab_btn.custom_minimum_size = Vector2(120, 36)
		tab_btn.add_theme_font_size_override("font_size", 20)
		var tab_style := StyleBoxFlat.new()
		if i == _active_tab:
			tab_style.bg_color = Color("#5AA9FF", 0.3)
			tab_btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			tab_style.bg_color = Color("#0B1220")
			tab_btn.add_theme_color_override("font_color", Color("#8A9BB1"))
		tab_style.set_corner_radius_all(4)
		tab_style.set_content_margin_all(4)
		tab_btn.add_theme_stylebox_override("normal", tab_style)
		var idx := i
		tab_btn.pressed.connect(func(): _switch_tab(idx))
		tab_bar.add_child(tab_btn)

	vbox.add_child(HSeparator.new())

	# Tab content area (ScrollContainer for overflow)
	var scroll := ScrollContainer.new()
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	vbox.add_child(scroll)

	var content := VBoxContainer.new()
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	content.add_theme_constant_override("separation", 12)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	match _active_tab:
		0: _build_forecast_tab(content)
		1: _build_channels_tab(content)
		2: _build_research_tab(content)


func _switch_tab(idx: int) -> void:
	_active_tab = idx
	_build_ui()


# ---------------------------------------------------------------------------
# FORECAST TAB
# ---------------------------------------------------------------------------

func _build_forecast_tab(parent: VBoxContainer) -> void:
	# Trend info
	var trend_row := HBoxContainer.new()
	trend_row.mouse_filter = Control.MOUSE_FILTER_PASS
	trend_row.add_theme_constant_override("separation", 24)
	parent.add_child(trend_row)

	var seasonal_title := Label.new()
	seasonal_title.text = "SEASONAL DEMAND"
	seasonal_title.add_theme_font_size_override("font_size", 20)
	seasonal_title.add_theme_color_override("font_color", Color("#FFC857"))
	seasonal_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trend_row.add_child(seasonal_title)

	if MarketManager.active_trend_style != "":
		var trend_label := Label.new()
		trend_label.text = "TRENDING: %s (+%.1f) %d turns" % [
			MarketManager.active_trend_style.capitalize(),
			MarketManager.TREND_BONUS,
			MarketManager.trend_remaining_turns
		]
		trend_label.add_theme_font_size_override("font_size", 18)
		trend_label.add_theme_color_override("font_color", Color("#5EE8A4"))
		trend_row.add_child(trend_label)

	# Seasonal modifier table
	_build_seasonal_table(parent)

	parent.add_child(HSeparator.new())

	# Saturation section
	var sat_title := Label.new()
	sat_title.text = "SATURATION"
	sat_title.add_theme_font_size_override("font_size", 20)
	sat_title.add_theme_color_override("font_color", Color("#FFC857"))
	parent.add_child(sat_title)

	var style_ids: Array = MarketManager.get_all_demand_weights().keys()
	var has_saturation := false
	for sid in style_ids:
		var penalty: float = MarketManager.get_saturation_penalty(sid)
		if penalty > 0.0:
			has_saturation = true
			_build_saturation_row(parent, sid, penalty)

	if not has_saturation:
		var none_label := Label.new()
		none_label.text = "No saturation — all styles are fresh"
		none_label.add_theme_font_size_override("font_size", 16)
		none_label.add_theme_color_override("font_color", Color("#8A9BB1"))
		parent.add_child(none_label)

	parent.add_child(HSeparator.new())

	# Combined demand section
	var demand_title := Label.new()
	demand_title.text = "COMBINED DEMAND (current)"
	demand_title.add_theme_font_size_override("font_size", 20)
	demand_title.add_theme_color_override("font_color", Color("#FFC857"))
	parent.add_child(demand_title)

	for sid in style_ids:
		_build_demand_row(parent, sid)


func _build_seasonal_table(parent: VBoxContainer) -> void:
	var style_ids: Array = MarketManager.get_all_demand_weights().keys()
	# Grid: columns = Style + 4 seasons = 5
	var grid := GridContainer.new()
	grid.columns = 5
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 4)
	parent.add_child(grid)

	# Header row
	_add_grid_cell(grid, "Style", Color("#8A9BB1"), 18, true)
	for s in range(4):
		var is_current: bool = (s == MarketManager.current_season)
		var col: Color = Color("#5AA9FF") if is_current else Color("#8A9BB1")
		var label_text: String = MarketManager.SEASON_NAMES[s]
		if is_current:
			label_text += "*"
		_add_grid_cell(grid, label_text, col, 18, true)

	# Data rows
	for sid in style_ids:
		_add_grid_cell(grid, sid.capitalize(), Color.WHITE, 16, false)
		var mods: Array = MarketManager.SEASONAL_MODIFIERS.get(sid, [0.0, 0.0, 0.0, 0.0])
		for s in range(4):
			var val: float = mods[s] if s < mods.size() else 0.0
			var is_current: bool = (s == MarketManager.current_season)
			var text: String = "%+.1f" % val
			var col: Color
			if val > 0.0:
				col = Color("#5EE8A4")
			elif val < 0.0:
				col = Color("#FF7B7B")
			else:
				col = Color("#8A9BB1")
			if is_current:
				# Wrap in a subtle highlight panel
				var cell_panel := PanelContainer.new()
				cell_panel.mouse_filter = Control.MOUSE_FILTER_PASS
				var cell_style := StyleBoxFlat.new()
				cell_style.bg_color = Color("#5AA9FF", 0.15)
				cell_style.set_corner_radius_all(2)
				cell_style.set_content_margin_all(2)
				cell_panel.add_theme_stylebox_override("panel", cell_style)
				cell_panel.custom_minimum_size = Vector2(80, 0)
				grid.add_child(cell_panel)
				var lbl := Label.new()
				lbl.text = text
				lbl.add_theme_font_size_override("font_size", 16)
				lbl.add_theme_color_override("font_color", col)
				lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				cell_panel.add_child(lbl)
			else:
				_add_grid_cell(grid, text, col, 16, false)


func _add_grid_cell(parent: GridContainer, text: String, color: Color, font_size: int, bold: bool) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.custom_minimum_size = Vector2(80, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if not bold else HORIZONTAL_ALIGNMENT_LEFT
	parent.add_child(label)


func _build_saturation_row(parent: VBoxContainer, style_id: String, penalty: float) -> void:
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	var name_label := Label.new()
	name_label.text = style_id.capitalize()
	name_label.custom_minimum_size = Vector2(120, 0)
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	row.add_child(name_label)

	# Progress bar
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = MarketManager.SATURATION_MAX_PENALTY
	bar.value = penalty
	bar.custom_minimum_size = Vector2(200, 20)
	bar.show_percentage = false
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color("#0F1724")
	bar_bg.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bar_bg)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color("#FFB347")
	bar_fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", bar_fill)
	row.add_child(bar)

	var penalty_label := Label.new()
	var recovering_text: String = " (recovering)" if penalty > 0.0 else ""
	penalty_label.text = "%.1f penalty%s" % [penalty, recovering_text]
	penalty_label.add_theme_font_size_override("font_size", 16)
	penalty_label.add_theme_color_override("font_color", Color("#FFB347"))
	row.add_child(penalty_label)


func _build_demand_row(parent: VBoxContainer, style_id: String) -> void:
	var seasonal: float = MarketManager.get_seasonal_modifier(style_id)
	var trend: float = MarketManager.get_trend_bonus(style_id)
	var saturation: float = MarketManager.get_saturation_penalty(style_id)
	var total: float = MarketManager.get_demand_multiplier(style_id)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_PASS
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var name_label := Label.new()
	name_label.text = "%s:" % style_id.capitalize()
	name_label.custom_minimum_size = Vector2(120, 0)
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	row.add_child(name_label)

	# Formula breakdown
	var formula_parts: Array[String] = ["1.0"]
	if seasonal != 0.0:
		formula_parts.append("%+.1f" % seasonal)
	if trend != 0.0:
		formula_parts.append("%+.1f" % trend)
	if saturation != 0.0:
		formula_parts.append("-%0.1f" % saturation)

	var formula_label := Label.new()
	formula_label.text = "%s = %.1fx" % [" ".join(formula_parts), total]
	formula_label.add_theme_font_size_override("font_size", 16)
	formula_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	row.add_child(formula_label)

	# Arrow indicator
	var arrow_label := Label.new()
	if total >= 1.5:
		arrow_label.text = "^^"
		arrow_label.add_theme_color_override("font_color", Color("#5EE8A4"))
	elif total > 1.0:
		arrow_label.text = "^"
		arrow_label.add_theme_color_override("font_color", Color("#5EE8A4"))
	elif total < 0.7:
		arrow_label.text = "vv"
		arrow_label.add_theme_color_override("font_color", Color("#FF7B7B"))
	elif total < 1.0:
		arrow_label.text = "v"
		arrow_label.add_theme_color_override("font_color", Color("#FFB347"))
	else:
		arrow_label.text = "-"
		arrow_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	arrow_label.add_theme_font_size_override("font_size", 16)
	row.add_child(arrow_label)


# ---------------------------------------------------------------------------
# CHANNELS TAB
# ---------------------------------------------------------------------------

func _build_channels_tab(parent: VBoxContainer) -> void:
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	parent.add_child(grid)

	for ch in MarketManager.CHANNELS:
		_build_channel_card(grid, ch)


func _build_channel_card(parent: GridContainer, channel: Dictionary) -> void:
	var unlocked: bool = MarketManager.is_channel_unlocked(channel.id)

	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.custom_minimum_size = Vector2(380, 160)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0B1220")
	style.border_color = Color("#5EE8A4") if unlocked else Color("#8A9BB1", 0.4)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(16)
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)

	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_PASS
	vb.add_theme_constant_override("separation", 6)
	card.add_child(vb)

	var name_label := Label.new()
	name_label.text = channel.name.to_upper()
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color.WHITE if unlocked else Color("#8A9BB1"))
	vb.add_child(name_label)

	_add_channel_detail(vb, "Margin: %.1fx" % channel.margin, Color("#FFC857") if unlocked else Color("#8A9BB1", 0.6))
	_add_channel_detail(vb, "Volume: %d%%" % int(channel.volume_pct * 100), Color("#5AA9FF") if unlocked else Color("#8A9BB1", 0.6))

	if unlocked:
		_add_channel_detail(vb, "Status: Available", Color("#5EE8A4"))
	else:
		_add_channel_detail(vb, "Status: Locked", Color("#FF7B7B"))
		_add_channel_detail(vb, UNLOCK_HINTS.get(channel.unlock_type, ""), Color("#8A9BB1"))

	var desc: String = CHANNEL_DESCRIPTIONS.get(channel.id, "")
	if desc != "":
		_add_channel_detail(vb, desc, Color("#8A9BB1"))


func _add_channel_detail(parent: VBoxContainer, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)


# ---------------------------------------------------------------------------
# RESEARCH TAB
# ---------------------------------------------------------------------------

func _build_research_tab(parent: VBoxContainer) -> void:
	var title := Label.new()
	title.text = "MARKET RESEARCH — $%d" % MarketManager.RESEARCH_COST
	title.add_theme_font_size_override("font_size", 22)
	title.add_theme_color_override("font_color", Color("#FFC857"))
	parent.add_child(title)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	parent.add_child(spacer)

	if MarketManager.research_purchased:
		_build_research_results(parent)
	else:
		_build_research_purchase(parent)


func _build_research_purchase(parent: VBoxContainer) -> void:
	var desc := Label.new()
	desc.text = "Purchase a research report to reveal upcoming market trends\nand seasonal forecasts."
	desc.add_theme_font_size_override("font_size", 18)
	desc.add_theme_color_override("font_color", Color("#8A9BB1"))
	parent.add_child(desc)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	parent.add_child(spacer)

	var buy_btn := Button.new()
	buy_btn.text = "Buy Research Report"
	buy_btn.custom_minimum_size = Vector2(240, 48)
	buy_btn.add_theme_font_size_override("font_size", 20)
	buy_btn.add_theme_color_override("font_color", Color("#0F1724"))

	# Disable if can't afford
	var can_afford: bool = is_instance_valid(GameState) and GameState.balance >= MarketManager.RESEARCH_COST
	buy_btn.disabled = not can_afford

	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color("#5AA9FF") if can_afford else Color("#8A9BB1", 0.4)
	btn_style.set_corner_radius_all(8)
	btn_style.content_margin_left = 24
	btn_style.content_margin_right = 24
	btn_style.content_margin_top = 8
	btn_style.content_margin_bottom = 8
	buy_btn.add_theme_stylebox_override("normal", btn_style)

	buy_btn.pressed.connect(_on_buy_research)
	parent.add_child(buy_btn)

	if not can_afford:
		var cost_label := Label.new()
		cost_label.text = "Insufficient funds (need $%d)" % MarketManager.RESEARCH_COST
		cost_label.add_theme_font_size_override("font_size", 16)
		cost_label.add_theme_color_override("font_color", Color("#FF7B7B"))
		parent.add_child(cost_label)


func _build_research_results(parent: VBoxContainer) -> void:
	var bought_label := Label.new()
	bought_label.text = "Research Report Purchased"
	bought_label.add_theme_font_size_override("font_size", 20)
	bought_label.add_theme_color_override("font_color", Color("#5EE8A4"))
	parent.add_child(bought_label)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 8)
	parent.add_child(spacer)

	var forecast: Dictionary = MarketManager.get_trend_forecast()

	# Next season info
	var next_season_name: String = MarketManager.SEASON_NAMES[forecast["next_season"]]
	var turns_left: int = forecast["turns_until_next_season"]
	_add_research_line(parent, "Next season: %s in %d turns" % [next_season_name, turns_left], Color.WHITE)

	# Trend forecast
	if forecast.has("active_trend"):
		_add_research_line(parent,
			"Trend forecast: %s trending for %d more turns" % [
				forecast["active_trend"].capitalize(),
				forecast["trend_remaining"]
			],
			Color("#5EE8A4")
		)
	else:
		var next_trend: int = forecast.get("next_trend_in", 0)
		_add_research_line(parent,
			"No active trend. Next trend in ~%d turns" % next_trend,
			Color("#8A9BB1")
		)


func _add_research_line(parent: VBoxContainer, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)


func _on_buy_research() -> void:
	if not is_instance_valid(MarketManager) or not is_instance_valid(GameState):
		return
	var success: bool = MarketManager.buy_research()
	if success:
		GameState.balance -= MarketManager.RESEARCH_COST
		if GameState.has_signal("balance_changed"):
			GameState.emit_signal("balance_changed")
		if is_instance_valid(ToastManager):
			ToastManager.show_toast("Market research report purchased — $%d" % MarketManager.RESEARCH_COST)
		_build_ui()


func _on_close() -> void:
	visible = false
	closed.emit()
