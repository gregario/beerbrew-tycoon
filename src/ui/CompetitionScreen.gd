extends CanvasLayer

## CompetitionScreen — full-screen overlay showing competition details,
## prizes, entry option, and medal cabinet.

signal closed()

func _ready() -> void:
	layer = 10
	visible = false

func show_screen() -> void:
	_build_ui()
	visible = true

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	if not is_instance_valid(CompetitionManager):
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
	panel_style.border_color = Color("#FFC857") if CompetitionManager.current_competition != null else Color("#8A9BB1")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(4)
	panel_style.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 12)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(header)
	var title := Label.new()
	title.text = "BEER COMPETITION"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.add_theme_font_size_override("font_size", 20)
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color(Color("#FF7B7B"), 0.2)
	close_style.set_corner_radius_all(4)
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.pressed.connect(_on_close)
	header.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	if CompetitionManager.current_competition != null:
		_build_active_competition(vbox)
	else:
		_build_no_competition(vbox)

	# Medal cabinet
	vbox.add_child(HSeparator.new())
	_build_medal_cabinet(vbox)

func _build_active_competition(parent: VBoxContainer) -> void:
	var comp: Dictionary = CompetitionManager.current_competition

	# Competition name
	var name_label := Label.new()
	name_label.text = comp["name"]
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color("#FFC857"))
	parent.add_child(name_label)

	# Details row
	var details := HBoxContainer.new()
	details.mouse_filter = Control.MOUSE_FILTER_PASS
	details.add_theme_constant_override("separation", 24)
	parent.add_child(details)

	var cat_text: String = comp["category"].capitalize() if comp["category"] != "open" else "Open (Any Style)"
	var cat_label := Label.new()
	cat_label.text = "Category: %s" % cat_text
	cat_label.add_theme_font_size_override("font_size", 20)
	cat_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	details.add_child(cat_label)

	var fee_label := Label.new()
	fee_label.text = "Entry Fee: $%d" % comp["entry_fee"]
	fee_label.add_theme_font_size_override("font_size", 20)
	fee_label.add_theme_color_override("font_color", Color("#FF7B7B"))
	details.add_child(fee_label)

	var deadline_label := Label.new()
	deadline_label.text = "Deadline: %d turns remaining" % comp["turns_remaining"]
	deadline_label.add_theme_font_size_override("font_size", 20)
	var deadline_color: Color = Color("#FF7B7B") if comp["turns_remaining"] <= 1 else Color("#FFB347")
	deadline_label.add_theme_color_override("font_color", deadline_color)
	parent.add_child(deadline_label)

	# Prizes
	var prizes_label := Label.new()
	prizes_label.text = "PRIZES"
	prizes_label.add_theme_font_size_override("font_size", 20)
	prizes_label.add_theme_color_override("font_color", Color.WHITE)
	parent.add_child(prizes_label)

	var prizes_row := HBoxContainer.new()
	prizes_row.mouse_filter = Control.MOUSE_FILTER_PASS
	prizes_row.add_theme_constant_override("separation", 16)
	parent.add_child(prizes_row)

	_add_prize_card(prizes_row, "GOLD", comp["prizes"]["gold"], Color("#FFD700"))
	_add_prize_card(prizes_row, "SILVER", comp["prizes"]["silver"], Color("#C0C0C0"))
	_add_prize_card(prizes_row, "BRONZE", comp["prizes"]["bronze"], Color("#CD7F32"))

	parent.add_child(HSeparator.new())

	# Entry section
	var entry_label := Label.new()
	entry_label.text = "SELECT ENTRY"
	entry_label.add_theme_font_size_override("font_size", 20)
	entry_label.add_theme_color_override("font_color", Color.WHITE)
	parent.add_child(entry_label)

	if CompetitionManager.player_entry != null:
		var submitted := Label.new()
		submitted.text = "Entry submitted! Quality: %.0f — Results after deadline" % CompetitionManager.player_entry["quality"]
		submitted.add_theme_font_size_override("font_size", 20)
		submitted.add_theme_color_override("font_color", Color("#5EE8A4"))
		parent.add_child(submitted)
	elif GameState.last_brew_result.is_empty():
		var no_brew := Label.new()
		no_brew.text = "No recent brew. Brew a beer first to compete!"
		no_brew.add_theme_font_size_override("font_size", 16)
		no_brew.add_theme_color_override("font_color", Color("#8A9BB1"))
		parent.add_child(no_brew)
	else:
		var brew_style_id: String = GameState.current_style.style_id if GameState.current_style else ""
		var brew_quality: float = GameState.last_brew_result.get("final_score", 0.0)
		var brew_style_name: String = GameState.current_style.style_name if GameState.current_style else "Unknown"
		var category: String = comp["category"]
		var matches: bool = category == "open" or category == brew_style_id

		var entry_card := PanelContainer.new()
		entry_card.mouse_filter = Control.MOUSE_FILTER_PASS
		var entry_style := StyleBoxFlat.new()
		entry_style.bg_color = Color("#0B1220")
		entry_style.border_color = Color("#5AA9FF") if matches else Color("#8A9BB1")
		entry_style.set_border_width_all(2)
		entry_style.set_corner_radius_all(4)
		entry_style.set_content_margin_all(12)
		entry_card.add_theme_stylebox_override("panel", entry_style)
		parent.add_child(entry_card)

		var entry_vbox := VBoxContainer.new()
		entry_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
		entry_vbox.add_theme_constant_override("separation", 8)
		entry_card.add_child(entry_vbox)

		var brew_label := Label.new()
		brew_label.text = "Your most recent brew:"
		brew_label.add_theme_font_size_override("font_size", 16)
		brew_label.add_theme_color_override("font_color", Color("#8A9BB1"))
		entry_vbox.add_child(brew_label)

		var brew_info := Label.new()
		var match_text: String = " (Matches!)" if matches else " (Wrong style)"
		brew_info.text = "Style: %s    Quality: %.0f%s" % [brew_style_name, brew_quality, match_text]
		brew_info.add_theme_font_size_override("font_size", 20)
		brew_info.add_theme_color_override("font_color", Color("#5EE8A4") if matches else Color("#FF7B7B"))
		entry_vbox.add_child(brew_info)

		if matches:
			var enter_btn := Button.new()
			enter_btn.text = "Enter Competition"
			enter_btn.custom_minimum_size = Vector2(200, 48)
			enter_btn.add_theme_font_size_override("font_size", 20)
			var btn_style := StyleBoxFlat.new()
			btn_style.bg_color = Color("#FFC857")
			btn_style.set_corner_radius_all(4)
			btn_style.set_content_margin_all(8)
			enter_btn.add_theme_stylebox_override("normal", btn_style)
			enter_btn.add_theme_color_override("font_color", Color("#0F1724"))
			enter_btn.pressed.connect(func(): _on_enter(brew_style_id, brew_quality))
			entry_vbox.add_child(enter_btn)
		else:
			var hint := Label.new()
			hint.text = "Brew a %s to compete!" % cat_text
			hint.add_theme_font_size_override("font_size", 16)
			hint.add_theme_color_override("font_color", Color("#8A9BB1"))
			entry_vbox.add_child(hint)

func _build_no_competition(parent: VBoxContainer) -> void:
	var no_comp := Label.new()
	no_comp.text = "No competition currently active."
	no_comp.add_theme_font_size_override("font_size", 20)
	no_comp.add_theme_color_override("font_color", Color("#8A9BB1"))
	parent.add_child(no_comp)

	var next_label := Label.new()
	next_label.text = "Next competition in: ~%d turns" % CompetitionManager.turns_until_next
	next_label.add_theme_font_size_override("font_size", 20)
	next_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	parent.add_child(next_label)

func _build_medal_cabinet(parent: VBoxContainer) -> void:
	var cabinet_label := Label.new()
	cabinet_label.text = "MEDAL CABINET"
	cabinet_label.add_theme_font_size_override("font_size", 20)
	cabinet_label.add_theme_color_override("font_color", Color.WHITE)
	parent.add_child(cabinet_label)

	var medals_row := HBoxContainer.new()
	medals_row.mouse_filter = Control.MOUSE_FILTER_PASS
	medals_row.add_theme_constant_override("separation", 24)
	parent.add_child(medals_row)

	_add_medal_count(medals_row, "Gold", CompetitionManager.medals["gold"], Color("#FFD700"))
	_add_medal_count(medals_row, "Silver", CompetitionManager.medals["silver"], Color("#C0C0C0"))
	_add_medal_count(medals_row, "Bronze", CompetitionManager.medals["bronze"], Color("#CD7F32"))

func _add_prize_card(parent: HBoxContainer, tier: String, amount: int, color: Color) -> void:
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.custom_minimum_size = Vector2(150, 80)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0B1220")
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)

	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_PASS
	vb.add_theme_constant_override("separation", 4)
	card.add_child(vb)

	var tier_label := Label.new()
	tier_label.text = tier
	tier_label.add_theme_font_size_override("font_size", 20)
	tier_label.add_theme_color_override("font_color", color)
	vb.add_child(tier_label)

	var amount_label := Label.new()
	amount_label.text = "$%d" % amount
	amount_label.add_theme_font_size_override("font_size", 24)
	amount_label.add_theme_color_override("font_color", Color("#5EE8A4"))
	vb.add_child(amount_label)

func _add_medal_count(parent: HBoxContainer, medal_name: String, count: int, color: Color) -> void:
	var label := Label.new()
	label.text = "%s: %d" % [medal_name, count]
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)

func _on_enter(style_id: String, quality: float) -> void:
	var success: bool = CompetitionManager.enter(style_id, quality)
	if success and is_instance_valid(ToastManager):
		ToastManager.show_toast("Competition entry submitted! Quality: %.0f" % quality)
	_build_ui()

func _on_close() -> void:
	visible = false
	closed.emit()
