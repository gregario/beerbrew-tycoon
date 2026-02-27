extends Control

## EquipmentPopup — mini-card popup for managing a single equipment slot.
## Shown when clicking a station slot in BreweryScene.
## Built entirely in code (no .tscn needed).

signal item_assigned(slot_index: int, equipment_id: String)
signal browse_shop_requested()
signal upgrade_requested(equipment_id: String)
signal closed()

var _current_slot: int = -1

# UI references (built in _ready)
var _dim_bg: ColorRect = null
var _panel: PanelContainer = null
var _content_vbox: VBoxContainer = null
var _title_label: Label = null
var _close_button: Button = null

func _ready() -> void:
	_build_ui()
	visible = false

## Show the popup for a given station slot index.
func show_for_slot(slot_index: int) -> void:
	_current_slot = slot_index
	_refresh_content()
	visible = true

# ---------------------------------------------------------------------------
# Build UI
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	# Full-screen layout
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Dim overlay
	_dim_bg = ColorRect.new()
	_dim_bg.set_anchors_preset(PRESET_FULL_RECT)
	_dim_bg.color = Color("#0F1724", 0.6)
	_dim_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim_bg.gui_input.connect(_on_dim_input)
	add_child(_dim_bg)

	# Centered panel
	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(500, 400)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#0B1220")
	panel_style.border_color = Color("#5AA9FF", 0.4)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(12)
	panel_style.content_margin_left = 24
	panel_style.content_margin_right = 24
	panel_style.content_margin_top = 24
	panel_style.content_margin_bottom = 24
	_panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(_panel)

	_content_vbox = VBoxContainer.new()
	_content_vbox.add_theme_constant_override("separation", 16)
	_panel.add_child(_content_vbox)

# ---------------------------------------------------------------------------
# Refresh content based on current slot state
# ---------------------------------------------------------------------------

func _refresh_content() -> void:
	# Clear previous content
	for child in _content_vbox.get_children():
		child.queue_free()

	# Wait one frame for queue_free to take effect, then rebuild
	await get_tree().process_frame
	_build_content()

func _build_content() -> void:
	if not is_instance_valid(EquipmentManager):
		return

	var slot_names: Array[String] = ["Kettle", "Fermenter", "Bottler"]
	var slot_name: String = slot_names[_current_slot] if _current_slot >= 0 and _current_slot < 3 else "Slot"
	var slot_id: String = EquipmentManager.station_slots[_current_slot]

	# Header row: title + close button
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)

	_title_label = Label.new()
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_label.add_theme_font_size_override("font_size", 24)
	_title_label.add_theme_color_override("font_color", Color("#5AA9FF"))
	header.add_child(_title_label)

	_close_button = Button.new()
	_close_button.text = "X"
	_close_button.custom_minimum_size = Vector2(36, 36)
	_close_button.add_theme_font_size_override("font_size", 20)
	_close_button.pressed.connect(func(): closed.emit())
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color("#FF7B7B", 0.2)
	close_style.set_corner_radius_all(4)
	_close_button.add_theme_stylebox_override("normal", close_style)
	header.add_child(_close_button)

	_content_vbox.add_child(header)

	if slot_id == "":
		_build_empty_slot_content(slot_name)
	else:
		_build_occupied_slot_content(slot_name, slot_id)

func _build_empty_slot_content(slot_name: String) -> void:
	_title_label.text = "%s — Empty" % slot_name

	var desc := Label.new()
	desc.text = "Assign owned equipment to this station:"
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color("#8A9BB1"))
	_content_vbox.add_child(desc)

	# List unslotted owned equipment
	var unslotted: Array = EquipmentManager.get_unslotted_owned()
	if unslotted.size() == 0:
		var empty_msg := Label.new()
		empty_msg.text = "No unassigned equipment. Visit the shop!"
		empty_msg.add_theme_font_size_override("font_size", 16)
		empty_msg.add_theme_color_override("font_color", Color("#8A9BB1"))
		_content_vbox.add_child(empty_msg)
	else:
		var scroll := ScrollContainer.new()
		scroll.custom_minimum_size = Vector2(0, 200)
		scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
		var list := VBoxContainer.new()
		list.add_theme_constant_override("separation", 8)

		for equip_id in unslotted:
			var equip: Equipment = EquipmentManager.get_equipment(equip_id)
			if equip == null:
				continue
			var row := _create_equipment_row(equip, true)
			list.add_child(row)

		scroll.add_child(list)
		_content_vbox.add_child(scroll)

	# Browse Shop button
	_add_browse_shop_button()

func _build_occupied_slot_content(slot_name: String, slot_id: String) -> void:
	var equip: Equipment = EquipmentManager.get_equipment(slot_id)
	if equip == null:
		_title_label.text = "%s — %s" % [slot_name, slot_id]
		return

	_title_label.text = "%s — %s" % [slot_name, equip.equipment_name]

	# Stats panel
	var stats_panel := _create_stats_panel(equip)
	_content_vbox.add_child(stats_panel)

	# Action buttons row
	var actions := HBoxContainer.new()
	actions.add_theme_constant_override("separation", 12)

	# Swap (unassign) button
	var swap_btn := Button.new()
	swap_btn.text = "Unassign"
	swap_btn.custom_minimum_size = Vector2(120, 40)
	swap_btn.add_theme_font_size_override("font_size", 16)
	var swap_style := StyleBoxFlat.new()
	swap_style.bg_color = Color("#FFB347", 0.2)
	swap_style.border_color = Color("#FFB347", 0.5)
	swap_style.set_border_width_all(1)
	swap_style.set_corner_radius_all(6)
	swap_style.content_margin_left = 12
	swap_style.content_margin_right = 12
	swap_style.content_margin_top = 6
	swap_style.content_margin_bottom = 6
	swap_btn.add_theme_stylebox_override("normal", swap_style)
	swap_btn.add_theme_color_override("font_color", Color("#FFB347"))
	swap_btn.pressed.connect(func():
		EquipmentManager.unassign_slot(_current_slot)
		_refresh_content()
	)
	actions.add_child(swap_btn)

	# Upgrade button (if upgrade path exists)
	if equip.upgrades_to != "":
		var target: Equipment = EquipmentManager.get_equipment(equip.upgrades_to)
		var upgrade_btn := Button.new()
		var can_afford: bool = GameState.balance >= equip.upgrade_cost
		upgrade_btn.text = "Upgrade ($%d)" % equip.upgrade_cost
		upgrade_btn.custom_minimum_size = Vector2(160, 40)
		upgrade_btn.add_theme_font_size_override("font_size", 16)
		upgrade_btn.disabled = not can_afford
		var upg_style := StyleBoxFlat.new()
		upg_style.bg_color = Color("#5EE8A4", 0.2) if can_afford else Color("#8A9BB1", 0.1)
		upg_style.border_color = Color("#5EE8A4", 0.5) if can_afford else Color("#8A9BB1", 0.3)
		upg_style.set_border_width_all(1)
		upg_style.set_corner_radius_all(6)
		upg_style.content_margin_left = 12
		upg_style.content_margin_right = 12
		upg_style.content_margin_top = 6
		upg_style.content_margin_bottom = 6
		upgrade_btn.add_theme_stylebox_override("normal", upg_style)
		upgrade_btn.add_theme_color_override("font_color", Color("#5EE8A4") if can_afford else Color("#8A9BB1"))
		var eid := equip.equipment_id
		upgrade_btn.pressed.connect(func(): upgrade_requested.emit(eid))
		actions.add_child(upgrade_btn)

	_content_vbox.add_child(actions)

	# Browse shop button
	_add_browse_shop_button()

# ---------------------------------------------------------------------------
# Helper: equipment row with Assign button
# ---------------------------------------------------------------------------

func _create_equipment_row(equip: Equipment, show_assign: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.text = "%s (T%d)" % [equip.equipment_name, equip.tier]
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	info.add_child(name_label)

	var bonus_text := _get_bonus_text(equip)
	if bonus_text != "":
		var bonus_label := Label.new()
		bonus_label.text = bonus_text
		bonus_label.add_theme_font_size_override("font_size", 14)
		bonus_label.add_theme_color_override("font_color", Color("#8A9BB1"))
		info.add_child(bonus_label)

	row.add_child(info)

	if show_assign:
		var assign_btn := Button.new()
		assign_btn.text = "Assign"
		assign_btn.custom_minimum_size = Vector2(100, 36)
		assign_btn.add_theme_font_size_override("font_size", 16)
		var assign_style := StyleBoxFlat.new()
		assign_style.bg_color = Color("#5AA9FF", 0.2)
		assign_style.border_color = Color("#5AA9FF", 0.5)
		assign_style.set_border_width_all(1)
		assign_style.set_corner_radius_all(6)
		assign_style.content_margin_left = 12
		assign_style.content_margin_right = 12
		assign_style.content_margin_top = 4
		assign_style.content_margin_bottom = 4
		assign_btn.add_theme_stylebox_override("normal", assign_style)
		assign_btn.add_theme_color_override("font_color", Color("#5AA9FF"))
		var eid := equip.equipment_id
		var slot := _current_slot
		assign_btn.pressed.connect(func(): item_assigned.emit(slot, eid))
		row.add_child(assign_btn)

	return row

# ---------------------------------------------------------------------------
# Helper: stats panel
# ---------------------------------------------------------------------------

func _create_stats_panel(equip: Equipment) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0F1724", 0.8)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)

	var desc_label := Label.new()
	desc_label.text = equip.description
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)

	# Tier badge
	var tier_label := Label.new()
	tier_label.text = "Tier %d" % equip.tier
	tier_label.add_theme_font_size_override("font_size", 14)
	tier_label.add_theme_color_override("font_color", Color("#FFC857"))
	vbox.add_child(tier_label)

	# Stat bonuses
	var bonus_text := _get_bonus_text(equip)
	if bonus_text != "":
		var bonus := Label.new()
		bonus.text = bonus_text
		bonus.add_theme_font_size_override("font_size", 16)
		bonus.add_theme_color_override("font_color", Color("#5EE8A4"))
		vbox.add_child(bonus)

	panel.add_child(vbox)
	return panel

# ---------------------------------------------------------------------------
# Helper: bonus text string
# ---------------------------------------------------------------------------

func _get_bonus_text(equip: Equipment) -> String:
	var parts: Array[String] = []
	if equip.sanitation_bonus != 0:
		parts.append("San +%d" % equip.sanitation_bonus)
	if equip.temp_control_bonus != 0:
		parts.append("Temp +%d" % equip.temp_control_bonus)
	if equip.efficiency_bonus != 0.0:
		parts.append("Eff +%.0f%%" % (equip.efficiency_bonus * 100))
	if equip.batch_size_multiplier != 1.0:
		parts.append("Batch x%.1f" % equip.batch_size_multiplier)
	return " | ".join(parts)

# ---------------------------------------------------------------------------
# Helper: browse shop button
# ---------------------------------------------------------------------------

func _add_browse_shop_button() -> void:
	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_vbox.add_child(spacer)

	var shop_btn := Button.new()
	shop_btn.text = "Browse Shop"
	shop_btn.custom_minimum_size = Vector2(200, 40)
	shop_btn.add_theme_font_size_override("font_size", 18)
	var shop_style := StyleBoxFlat.new()
	shop_style.bg_color = Color("#FFC857", 0.2)
	shop_style.border_color = Color("#FFC857", 0.5)
	shop_style.set_border_width_all(1)
	shop_style.set_corner_radius_all(6)
	shop_style.content_margin_left = 16
	shop_style.content_margin_right = 16
	shop_style.content_margin_top = 8
	shop_style.content_margin_bottom = 8
	shop_btn.add_theme_stylebox_override("normal", shop_style)
	shop_btn.add_theme_color_override("font_color", Color("#FFC857"))
	shop_btn.pressed.connect(func(): browse_shop_requested.emit())
	_content_vbox.add_child(shop_btn)

# ---------------------------------------------------------------------------
# Input handling
# ---------------------------------------------------------------------------

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		closed.emit()
