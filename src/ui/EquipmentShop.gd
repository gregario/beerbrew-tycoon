extends Control

## EquipmentShop — full catalog card overlay for browsing and purchasing equipment.
## Built entirely in code (no .tscn needed).

signal closed()

const CATEGORY_LABELS: Array[String] = ["All", "Brewing", "Fermentation", "Packaging", "Utility"]
const CATEGORY_MAP: Dictionary = {
	0: -1,  # All
	1: Equipment.Category.BREWING,
	2: Equipment.Category.FERMENTATION,
	3: Equipment.Category.PACKAGING,
	4: Equipment.Category.UTILITY,
}

var _selected_category: int = 0  # Index into CATEGORY_LABELS

# UI references
var _dim_bg: ColorRect = null
var _panel: PanelContainer = null
var _balance_label: Label = null
var _tab_container: HBoxContainer = null
var _tab_buttons: Array[Button] = []
var _item_scroll: ScrollContainer = null
var _item_list: VBoxContainer = null
var _close_button: Button = null

func _ready() -> void:
	_build_ui()
	visible = false

## Open the shop and refresh the catalog.
func show_shop() -> void:
	_selected_category = 0
	_refresh_tabs()
	_refresh_items()
	visible = true

# ---------------------------------------------------------------------------
# Build UI
# ---------------------------------------------------------------------------

func _build_ui() -> void:
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
	_panel.custom_minimum_size = Vector2(900, 550)
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

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 16)
	_panel.add_child(main_vbox)

	# Header: title, balance, close
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)

	var title := Label.new()
	title.text = "EQUIPMENT SHOP"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#5AA9FF"))
	header.add_child(title)

	_balance_label = Label.new()
	_balance_label.add_theme_font_size_override("font_size", 22)
	_balance_label.add_theme_color_override("font_color", Color("#FFC857"))
	header.add_child(_balance_label)

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

	main_vbox.add_child(header)

	# Category tabs
	_tab_container = HBoxContainer.new()
	_tab_container.add_theme_constant_override("separation", 8)
	for i in range(CATEGORY_LABELS.size()):
		var tab_btn := Button.new()
		tab_btn.text = CATEGORY_LABELS[i]
		tab_btn.custom_minimum_size = Vector2(100, 36)
		tab_btn.add_theme_font_size_override("font_size", 16)
		var idx := i
		tab_btn.pressed.connect(func(): _on_tab_selected(idx))
		_tab_container.add_child(tab_btn)
		_tab_buttons.append(tab_btn)
	main_vbox.add_child(_tab_container)

	# Scrollable item list
	_item_scroll = ScrollContainer.new()
	_item_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_item_scroll.custom_minimum_size = Vector2(0, 350)

	_item_list = VBoxContainer.new()
	_item_list.add_theme_constant_override("separation", 8)
	_item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_item_scroll.add_child(_item_list)

	main_vbox.add_child(_item_scroll)

# ---------------------------------------------------------------------------
# Tab handling
# ---------------------------------------------------------------------------

func _on_tab_selected(index: int) -> void:
	_selected_category = index
	_refresh_tabs()
	_refresh_items()

func _refresh_tabs() -> void:
	for i in range(_tab_buttons.size()):
		var btn := _tab_buttons[i]
		var is_active := (i == _selected_category)
		var style := StyleBoxFlat.new()
		if is_active:
			style.bg_color = Color("#5AA9FF", 0.3)
			style.border_color = Color("#5AA9FF", 0.8)
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			style.bg_color = Color("#0F1724", 0.5)
			style.border_color = Color("#8A9BB1", 0.3)
			btn.add_theme_color_override("font_color", Color("#8A9BB1"))
		style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		btn.add_theme_stylebox_override("normal", style)

# ---------------------------------------------------------------------------
# Refresh item list
# ---------------------------------------------------------------------------

func _refresh_items() -> void:
	# Clear existing items
	for child in _item_list.get_children():
		child.queue_free()

	# Update balance
	_balance_label.text = "Balance: $%.0f" % GameState.balance

	if not is_instance_valid(EquipmentManager):
		return

	# Get filtered equipment list
	var items: Array = []
	var cat_value: int = CATEGORY_MAP[_selected_category]
	if cat_value == -1:
		items = EquipmentManager.get_all_equipment()
	else:
		items = EquipmentManager.get_equipment_by_category(cat_value as Equipment.Category)

	# Sort by tier then name
	items.sort_custom(func(a, b):
		if a.tier != b.tier:
			return a.tier < b.tier
		return a.equipment_name < b.equipment_name
	)

	# Build rows after frame to allow queue_free to complete
	await get_tree().process_frame
	_build_item_rows(items)

func _build_item_rows(items: Array) -> void:
	for equip in items:
		if not equip is Equipment:
			continue
		var row := _create_shop_row(equip)
		_item_list.add_child(row)

func _create_shop_row(equip: Equipment) -> PanelContainer:
	var row_panel := PanelContainer.new()
	var row_style := StyleBoxFlat.new()
	var is_owned: bool = equip.equipment_id in EquipmentManager.owned_equipment
	row_style.bg_color = Color("#0F1724", 0.6)
	row_style.border_color = Color("#5EE8A4", 0.3) if is_owned else Color("#8A9BB1", 0.2)
	row_style.set_border_width_all(1)
	row_style.set_corner_radius_all(8)
	row_style.content_margin_left = 16
	row_style.content_margin_right = 16
	row_style.content_margin_top = 12
	row_style.content_margin_bottom = 12
	row_panel.add_theme_stylebox_override("panel", row_style)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 16)

	# Name + tier badge column
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)

	# Owned checkmark
	if is_owned:
		var check := Label.new()
		check.text = "OK"
		check.add_theme_font_size_override("font_size", 14)
		check.add_theme_color_override("font_color", Color("#5EE8A4"))
		name_row.add_child(check)

	var name_label := Label.new()
	name_label.text = equip.equipment_name
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color.WHITE if not is_owned else Color("#5EE8A4"))
	name_row.add_child(name_label)

	# Tier badge
	var tier_label := Label.new()
	tier_label.text = "T%d" % equip.tier
	tier_label.add_theme_font_size_override("font_size", 14)
	tier_label.add_theme_color_override("font_color", Color("#FFC857"))
	name_row.add_child(tier_label)

	info.add_child(name_row)

	# Stat bonuses line
	var bonus_text := _get_bonus_text(equip)
	if bonus_text != "":
		var bonus_label := Label.new()
		bonus_label.text = bonus_text
		bonus_label.add_theme_font_size_override("font_size", 14)
		bonus_label.add_theme_color_override("font_color", Color("#8A9BB1"))
		info.add_child(bonus_label)

	hbox.add_child(info)

	# Action button column
	if is_owned:
		# Show upgrade button if upgrade path exists and target not owned
		if equip.upgrades_to != "" and equip.upgrades_to not in EquipmentManager.owned_equipment:
			var can_afford: bool = GameState.balance >= equip.upgrade_cost
			var upg_btn := Button.new()
			upg_btn.text = "Upgrade $%d" % equip.upgrade_cost
			upg_btn.custom_minimum_size = Vector2(140, 36)
			upg_btn.disabled = not can_afford
			upg_btn.add_theme_font_size_override("font_size", 16)
			var upg_style := StyleBoxFlat.new()
			upg_style.bg_color = Color("#5EE8A4", 0.2) if can_afford else Color("#8A9BB1", 0.1)
			upg_style.border_color = Color("#5EE8A4", 0.5) if can_afford else Color("#8A9BB1", 0.3)
			upg_style.set_border_width_all(1)
			upg_style.set_corner_radius_all(6)
			upg_style.content_margin_left = 8
			upg_style.content_margin_right = 8
			upg_style.content_margin_top = 4
			upg_style.content_margin_bottom = 4
			upg_btn.add_theme_stylebox_override("normal", upg_style)
			upg_btn.add_theme_color_override("font_color", Color("#5EE8A4") if can_afford else Color("#8A9BB1"))
			var eid := equip.equipment_id
			upg_btn.pressed.connect(func(): _on_upgrade_pressed(eid))
			hbox.add_child(upg_btn)
		else:
			var owned_label := Label.new()
			owned_label.text = "Owned"
			owned_label.add_theme_font_size_override("font_size", 16)
			owned_label.add_theme_color_override("font_color", Color("#5EE8A4"))
			hbox.add_child(owned_label)
	else:
		var can_afford: bool = GameState.balance >= equip.cost
		var buy_btn := Button.new()
		buy_btn.text = "Buy $%d" % equip.cost
		buy_btn.custom_minimum_size = Vector2(120, 36)
		buy_btn.disabled = not can_afford
		buy_btn.add_theme_font_size_override("font_size", 16)
		var buy_style := StyleBoxFlat.new()
		buy_style.bg_color = Color("#FFC857", 0.2) if can_afford else Color("#8A9BB1", 0.1)
		buy_style.border_color = Color("#FFC857", 0.5) if can_afford else Color("#8A9BB1", 0.3)
		buy_style.set_border_width_all(1)
		buy_style.set_corner_radius_all(6)
		buy_style.content_margin_left = 8
		buy_style.content_margin_right = 8
		buy_style.content_margin_top = 4
		buy_style.content_margin_bottom = 4
		buy_btn.add_theme_stylebox_override("normal", buy_style)
		buy_btn.add_theme_color_override("font_color", Color("#FFC857") if can_afford else Color("#8A9BB1"))
		var eid := equip.equipment_id
		buy_btn.pressed.connect(func(): _on_buy_pressed(eid))
		hbox.add_child(buy_btn)

	row_panel.add_child(hbox)
	return row_panel

# ---------------------------------------------------------------------------
# Actions
# ---------------------------------------------------------------------------

func _on_buy_pressed(equipment_id: String) -> void:
	var success := EquipmentManager.purchase(equipment_id)
	if success:
		_refresh_items()

func _on_upgrade_pressed(equipment_id: String) -> void:
	var success := EquipmentManager.upgrade(equipment_id)
	if success:
		_refresh_items()

# ---------------------------------------------------------------------------
# Helpers
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

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		closed.emit()
