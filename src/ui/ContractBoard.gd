extends CanvasLayer

## ContractBoard — full-screen overlay showing available and active contracts.
## Built entirely in code (no .tscn needed).
## Follows the same pattern as StaffScreen.gd / ExpansionOverlay.gd.

signal closed()


func _ready() -> void:
	visible = false


## Open the contract board and rebuild the display.
func show_board() -> void:
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
	panel_style.border_color = Color("#8A9BB1")
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
	title.text = "CONTRACT BOARD"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var count_label := Label.new()
	count_label.text = "Active: %d/%d" % [ContractManager.active_contracts.size(), ContractManager.MAX_ACTIVE]
	count_label.add_theme_font_size_override("font_size", 20)
	count_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	header.add_child(count_label)
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

	# Active contracts section
	var active_label := Label.new()
	active_label.text = "ACTIVE CONTRACTS"
	active_label.add_theme_font_size_override("font_size", 20)
	active_label.add_theme_color_override("font_color", Color("#FFC857"))
	vbox.add_child(active_label)

	if ContractManager.active_contracts.size() == 0:
		var none_label := Label.new()
		none_label.text = "(No active contracts)"
		none_label.add_theme_font_size_override("font_size", 16)
		none_label.add_theme_color_override("font_color", Color("#8A9BB1"))
		vbox.add_child(none_label)
	else:
		for contract in ContractManager.active_contracts:
			_add_active_card(vbox, contract)

	vbox.add_child(HSeparator.new())

	# Available contracts section
	var avail_header := HBoxContainer.new()
	vbox.add_child(avail_header)
	var avail_label := Label.new()
	avail_label.text = "AVAILABLE CONTRACTS"
	avail_label.add_theme_font_size_override("font_size", 20)
	avail_label.add_theme_color_override("font_color", Color.WHITE)
	avail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	avail_header.add_child(avail_label)
	var refresh_label := Label.new()
	refresh_label.text = "Refresh: %d turns" % ContractManager.refresh_counter
	refresh_label.add_theme_font_size_override("font_size", 16)
	refresh_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	avail_header.add_child(refresh_label)

	var cards_row := HBoxContainer.new()
	cards_row.add_theme_constant_override("separation", 16)
	vbox.add_child(cards_row)

	for contract in ContractManager.available_contracts:
		_add_available_card(cards_row, contract)


func _add_active_card(parent: VBoxContainer, contract: Dictionary) -> void:
	var card := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0B1220")
	style.border_color = Color("#FFC857")
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	card.add_child(vb)

	var row1 := HBoxContainer.new()
	vb.add_child(row1)
	var client := Label.new()
	client.text = "%s — Wants: %s" % [contract["client_name"], contract["required_style"].capitalize()]
	client.add_theme_font_size_override("font_size", 20)
	client.add_theme_color_override("font_color", Color.WHITE)
	row1.add_child(client)

	var row2 := HBoxContainer.new()
	row2.add_theme_constant_override("separation", 24)
	vb.add_child(row2)
	var quality := Label.new()
	quality.text = "Min Quality: %d" % int(contract["minimum_quality"])
	quality.add_theme_font_size_override("font_size", 16)
	quality.add_theme_color_override("font_color", Color("#8A9BB1"))
	row2.add_child(quality)
	var reward := Label.new()
	reward.text = "Reward: $%d (+$%d bonus)" % [contract["reward"], contract["bonus_reward"]]
	reward.add_theme_font_size_override("font_size", 16)
	reward.add_theme_color_override("font_color", Color("#5EE8A4"))
	row2.add_child(reward)

	var row3 := HBoxContainer.new()
	row3.add_theme_constant_override("separation", 24)
	vb.add_child(row3)
	var remaining: int = contract.get("remaining_turns", 0)
	var deadline := Label.new()
	deadline.text = "Deadline: %d turns remaining" % remaining
	deadline.add_theme_font_size_override("font_size", 16)
	var deadline_color: Color = Color("#FF7B7B") if remaining <= 1 else Color("#FFB347")
	deadline.add_theme_color_override("font_color", deadline_color)
	row3.add_child(deadline)
	var penalty := Label.new()
	penalty.text = "Penalty: -$%d" % contract["reputation_penalty"]
	penalty.add_theme_font_size_override("font_size", 16)
	penalty.add_theme_color_override("font_color", Color("#FF7B7B"))
	row3.add_child(penalty)


func _add_available_card(parent: HBoxContainer, contract: Dictionary) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(250, 200)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0B1220")
	style.border_color = Color("#8A9BB1")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 6)
	card.add_child(vb)

	var name_label := Label.new()
	name_label.text = contract["client_name"]
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	vb.add_child(name_label)

	_add_detail(vb, "Style: %s" % contract["required_style"].capitalize(), Color("#FFC857"))
	_add_detail(vb, "Quality: %d+" % int(contract["minimum_quality"]), Color("#8A9BB1"))
	_add_detail(vb, "Reward: $%d" % contract["reward"], Color("#5EE8A4"))
	_add_detail(vb, "Deadline: %d turns" % contract["deadline_turns"], Color("#8A9BB1"))
	_add_detail(vb, "Penalty: -$%d" % contract["reputation_penalty"], Color("#FF7B7B"))

	var accept_btn := Button.new()
	accept_btn.text = "Accept"
	accept_btn.custom_minimum_size = Vector2(100, 36)
	accept_btn.disabled = ContractManager.active_contracts.size() >= ContractManager.MAX_ACTIVE
	var cid: String = contract["contract_id"]
	accept_btn.pressed.connect(func(): _on_accept(cid))
	var btn_style := StyleBoxFlat.new()
	btn_style.bg_color = Color("#5AA9FF")
	btn_style.set_corner_radius_all(4)
	btn_style.set_content_margin_all(4)
	accept_btn.add_theme_stylebox_override("normal", btn_style)
	accept_btn.add_theme_color_override("font_color", Color("#0F1724"))
	vb.add_child(accept_btn)


func _add_detail(parent: VBoxContainer, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)


func _on_accept(contract_id: String) -> void:
	var success: bool = ContractManager.accept(contract_id)
	if success and is_instance_valid(ToastManager):
		for c in ContractManager.active_contracts:
			if c["contract_id"] == contract_id:
				ToastManager.show_toast("Contract accepted: %s — %s" % [c["client_name"], c["required_style"].capitalize()])
				break
	_build_ui()  # Rebuild to reflect changes


func _on_close() -> void:
	visible = false
	closed.emit()
