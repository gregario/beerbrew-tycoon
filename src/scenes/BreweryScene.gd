extends Node2D

## BreweryScene — isometric garage brewery view.
## Uses placeholder ColorRects until pixel art sprites are ready.
## Equipment mode overlays slot buttons on top of stations.

signal slot_clicked(slot_index: int)
signal start_brewing_pressed()
signal research_requested()
signal staff_requested()
signal contracts_requested()

@onready var kettle_node: ColorRect = $Stations/Kettle
@onready var fermenter_node: ColorRect = $Stations/Fermenter
@onready var bottler_node: ColorRect = $Stations/Bottler
@onready var brew_animation: AnimationPlayer = $BrewAnimation
@onready var character_node: ColorRect = $Character

# Equipment mode UI elements (created in _ready)
var _slot_buttons: Array[Button] = []
var _balance_label: Label = null
var _start_button: Button = null
var _research_button: Button = null
var _staff_button: Button = null
var _contracts_button: Button = null
var _equipment_ui: CanvasLayer = null

const SLOT_NAMES: Array[String] = ["Kettle", "Fermenter", "Bottler"]
const SLOT_POSITIONS: Array[Vector2] = [
	Vector2(240, 312),  # Above Kettle
	Vector2(520, 296),  # Above Fermenter
	Vector2(840, 328),  # Above Bottler
]

const SLOT_NAMES_MICRO: Array[String] = ["Kettle", "Fermenter", "Bottler", "Station 4", "Station 5"]
const SLOT_POSITIONS_MICRO: Array[Vector2] = [
	Vector2(140, 312), Vector2(340, 296), Vector2(540, 312), Vector2(740, 296), Vector2(940, 312)
]

var _contract_board: CanvasLayer = null
var _expansion_overlay: CanvasLayer = null

func _ready() -> void:
	set_brewing(false)
	_build_equipment_ui()

## Enable or disable the "brewing in progress" visual state.
func set_brewing(active: bool) -> void:
	if brew_animation == null:
		return
	if active:
		if brew_animation.has_animation("brewing"):
			brew_animation.play("brewing")
	else:
		brew_animation.stop()
		if kettle_node:
			kettle_node.color = Color(0.3, 0.5, 0.8, 1.0)  # Rest state color

## Show or hide the equipment management UI overlay.
func set_equipment_mode(active: bool) -> void:
	if _equipment_ui:
		_equipment_ui.visible = active
	if active:
		refresh_slots()

## Update slot button labels from EquipmentManager state.
func refresh_slots() -> void:
	if not is_instance_valid(EquipmentManager):
		return
	var slot_names: Array[String] = SLOT_NAMES
	if is_instance_valid(BreweryExpansion) and BreweryExpansion.get_max_slots() > 3:
		slot_names = SLOT_NAMES_MICRO
	for i in range(_slot_buttons.size()):
		var btn := _slot_buttons[i]
		var slot_id: String = EquipmentManager.station_slots[i]
		if slot_id == "":
			btn.text = "%s\n[Empty Slot]" % slot_names[i]
			btn.add_theme_color_override("font_color", Color("#8A9BB1"))
		else:
			var equip: Equipment = EquipmentManager.get_equipment(slot_id)
			var name_text: String = equip.equipment_name if equip else slot_id
			btn.text = "%s\n%s" % [slot_names[i], name_text]
			btn.add_theme_color_override("font_color", Color("#5EE8A4"))
	# Update balance
	if _balance_label:
		_balance_label.text = "Balance: $%.0f" % GameState.balance

# ---------------------------------------------------------------------------
# Build equipment UI programmatically
# ---------------------------------------------------------------------------

func _build_equipment_ui() -> void:
	# Clean up previous UI if rebuilding (e.g., after expansion)
	if _equipment_ui != null:
		_equipment_ui.queue_free()
		_slot_buttons.clear()
	_equipment_ui = CanvasLayer.new()
	_equipment_ui.name = "EquipmentUI"
	_equipment_ui.layer = 5
	_equipment_ui.visible = false
	add_child(_equipment_ui)

	# Semi-transparent background hint
	var hint_bg := ColorRect.new()
	hint_bg.color = Color("#0F1724", 0.3)
	hint_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_equipment_ui.add_child(hint_bg)

	# Balance label at top
	_balance_label = Label.new()
	_balance_label.text = "Balance: $0"
	_balance_label.add_theme_font_size_override("font_size", 24)
	_balance_label.add_theme_color_override("font_color", Color("#FFC857"))
	_balance_label.position = Vector2(32, 16)
	_equipment_ui.add_child(_balance_label)

	# Title label (dynamic stage name)
	var stage_name: String = BreweryExpansion.get_stage_name() if is_instance_valid(BreweryExpansion) else "EQUIPMENT MANAGEMENT"
	var title := Label.new()
	title.text = stage_name
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#8A9BB1"))
	title.position = Vector2(32, 50)
	_equipment_ui.add_child(title)

	# Expansion banner (when threshold is met)
	if is_instance_valid(BreweryExpansion) and BreweryExpansion.can_expand():
		var banner := PanelContainer.new()
		var banner_style := StyleBoxFlat.new()
		banner_style.bg_color = Color("#0B1220", 0.95)
		banner_style.border_color = Color("#FFC857")
		banner_style.set_border_width_all(2)
		banner_style.set_corner_radius_all(4)
		banner_style.set_content_margin_all(12)
		banner.add_theme_stylebox_override("panel", banner_style)
		banner.position = Vector2(200, 50)
		banner.size = Vector2(880, 48)
		_equipment_ui.add_child(banner)
		var banner_hbox := HBoxContainer.new()
		banner_hbox.add_theme_constant_override("separation", 16)
		banner.add_child(banner_hbox)
		var banner_text := Label.new()
		banner_text.text = "Ready to expand! Upgrade to Microbrewery — $%d" % int(BreweryExpansion.EXPAND_COST)
		banner_text.add_theme_font_size_override("font_size", 20)
		banner_text.add_theme_color_override("font_color", Color("#FFC857"))
		banner_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		banner_hbox.add_child(banner_text)
		var details_btn := Button.new()
		details_btn.text = "View Details >"
		details_btn.custom_minimum_size = Vector2(160, 36)
		details_btn.pressed.connect(_on_expansion_details)
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color("#FFC857")
		btn_style.set_corner_radius_all(4)
		btn_style.set_content_margin_all(4)
		details_btn.add_theme_stylebox_override("normal", btn_style)
		details_btn.add_theme_color_override("font_color", Color("#0F1724"))
		banner_hbox.add_child(details_btn)

	# Station slot buttons (dynamic count based on stage)
	var slot_names: Array[String] = SLOT_NAMES
	var slot_positions: Array[Vector2] = SLOT_POSITIONS
	var max_slots: int = 3
	if is_instance_valid(BreweryExpansion):
		max_slots = BreweryExpansion.get_max_slots()
		if max_slots > 3:
			slot_names = SLOT_NAMES_MICRO
			slot_positions = SLOT_POSITIONS_MICRO

	for i in range(max_slots):
		var btn := Button.new()
		btn.name = "SlotButton_%d" % i
		btn.custom_minimum_size = Vector2(160, 60)
		btn.position = slot_positions[i]
		btn.text = "%s\n[Empty Slot]" % slot_names[i]
		btn.add_theme_font_size_override("font_size", 16)

		var style_normal := StyleBoxFlat.new()
		style_normal.bg_color = Color("#0B1220", 0.85)
		style_normal.border_color = Color("#5AA9FF", 0.6)
		style_normal.set_border_width_all(2)
		style_normal.set_corner_radius_all(6)
		style_normal.content_margin_left = 12
		style_normal.content_margin_right = 12
		style_normal.content_margin_top = 8
		style_normal.content_margin_bottom = 8
		btn.add_theme_stylebox_override("normal", style_normal)

		var style_hover := style_normal.duplicate()
		style_hover.border_color = Color("#5AA9FF", 1.0)
		style_hover.bg_color = Color("#0B1220", 0.95)
		btn.add_theme_stylebox_override("hover", style_hover)

		var style_pressed := style_normal.duplicate()
		style_pressed.bg_color = Color("#5AA9FF", 0.2)
		btn.add_theme_stylebox_override("pressed", style_pressed)

		var idx := i  # Capture for closure
		btn.pressed.connect(func(): slot_clicked.emit(idx))
		_equipment_ui.add_child(btn)
		_slot_buttons.append(btn)

	# "Start Brewing" button at bottom center
	_start_button = Button.new()
	_start_button.name = "StartBrewingButton"
	_start_button.text = "Start Brewing  >"
	_start_button.custom_minimum_size = Vector2(240, 48)
	_start_button.position = Vector2(520, 620)
	_start_button.add_theme_font_size_override("font_size", 24)
	_start_button.add_theme_color_override("font_color", Color("#0F1724"))

	var start_style := StyleBoxFlat.new()
	start_style.bg_color = Color("#FFC857")
	start_style.set_corner_radius_all(8)
	start_style.content_margin_left = 24
	start_style.content_margin_right = 24
	start_style.content_margin_top = 8
	start_style.content_margin_bottom = 8
	_start_button.add_theme_stylebox_override("normal", start_style)

	var start_hover := start_style.duplicate()
	start_hover.bg_color = Color("#FFD680")
	_start_button.add_theme_stylebox_override("hover", start_hover)

	_start_button.pressed.connect(func(): start_brewing_pressed.emit())
	_equipment_ui.add_child(_start_button)

	# "Research" button next to Start Brewing
	_research_button = Button.new()
	_research_button.name = "ResearchButton"
	_research_button.text = "Research"
	_research_button.custom_minimum_size = Vector2(160, 48)
	_research_button.position = Vector2(780, 620)
	_research_button.add_theme_font_size_override("font_size", 24)
	_research_button.add_theme_color_override("font_color", Color("#0F1724"))

	var research_style := StyleBoxFlat.new()
	research_style.bg_color = Color("#5AA9FF")
	research_style.set_corner_radius_all(8)
	research_style.content_margin_left = 24
	research_style.content_margin_right = 24
	research_style.content_margin_top = 8
	research_style.content_margin_bottom = 8
	_research_button.add_theme_stylebox_override("normal", research_style)

	var research_hover := research_style.duplicate()
	research_hover.bg_color = Color("#7BBFFF")
	_research_button.add_theme_stylebox_override("hover", research_hover)

	_research_button.pressed.connect(func(): research_requested.emit())
	_equipment_ui.add_child(_research_button)

	# "Staff" button next to Research
	_staff_button = Button.new()
	_staff_button.name = "StaffButton"
	_staff_button.text = "Staff"
	_staff_button.custom_minimum_size = Vector2(160, 48)
	_staff_button.position = Vector2(960, 620)
	_staff_button.add_theme_font_size_override("font_size", 24)
	_staff_button.add_theme_color_override("font_color", Color("#0F1724"))

	var staff_style := StyleBoxFlat.new()
	staff_style.bg_color = Color("#5AA9FF")
	staff_style.set_corner_radius_all(8)
	staff_style.content_margin_left = 24
	staff_style.content_margin_right = 24
	staff_style.content_margin_top = 8
	staff_style.content_margin_bottom = 8
	_staff_button.add_theme_stylebox_override("normal", staff_style)

	var staff_hover := staff_style.duplicate()
	staff_hover.bg_color = Color("#7BBFFF")
	_staff_button.add_theme_stylebox_override("hover", staff_hover)

	_staff_button.pressed.connect(func(): staff_requested.emit())
	_equipment_ui.add_child(_staff_button)

	# Disable staff button in garage stage
	if is_instance_valid(BreweryExpansion) and BreweryExpansion.current_stage == BreweryExpansion.Stage.GARAGE:
		_staff_button.disabled = true
		_staff_button.tooltip_text = "Upgrade to Microbrewery to hire staff"

	# "Contracts" button next to Staff
	_contracts_button = Button.new()
	_contracts_button.name = "ContractsButton"
	_contracts_button.text = "Contracts"
	# Add active count badge if contracts exist
	if is_instance_valid(ContractManager) and ContractManager.active_contracts.size() > 0:
		_contracts_button.text = "Contracts (%d)" % ContractManager.active_contracts.size()
	_contracts_button.custom_minimum_size = Vector2(160, 48)
	_contracts_button.position = Vector2(1140, 620)
	_contracts_button.add_theme_font_size_override("font_size", 24)
	_contracts_button.add_theme_color_override("font_color", Color("#0F1724"))

	var contracts_style := StyleBoxFlat.new()
	contracts_style.bg_color = Color("#5AA9FF")
	contracts_style.set_corner_radius_all(8)
	contracts_style.content_margin_left = 24
	contracts_style.content_margin_right = 24
	contracts_style.content_margin_top = 8
	contracts_style.content_margin_bottom = 8
	_contracts_button.add_theme_stylebox_override("normal", contracts_style)

	var contracts_hover := contracts_style.duplicate()
	contracts_hover.bg_color = Color("#7BBFFF")
	_contracts_button.add_theme_stylebox_override("hover", contracts_hover)

	_contracts_button.pressed.connect(func(): _on_contracts_pressed())
	_equipment_ui.add_child(_contracts_button)

func _on_contracts_pressed() -> void:
	if _contract_board == null:
		_contract_board = preload("res://ui/ContractBoard.gd").new()
		add_child(_contract_board)
		_contract_board.closed.connect(_on_contract_board_closed)
	_contract_board.show_board()

func _on_contract_board_closed() -> void:
	# Refresh the contracts button badge count
	if _contracts_button and is_instance_valid(ContractManager):
		if ContractManager.active_contracts.size() > 0:
			_contracts_button.text = "Contracts (%d)" % ContractManager.active_contracts.size()
		else:
			_contracts_button.text = "Contracts"

func _on_expansion_details() -> void:
	if _expansion_overlay == null:
		_expansion_overlay = preload("res://ui/ExpansionOverlay.gd").new()
		add_child(_expansion_overlay)
		_expansion_overlay.expansion_confirmed.connect(_on_expansion_confirmed)
	_expansion_overlay.show_overlay()

func _on_expansion_confirmed() -> void:
	_build_equipment_ui()
	refresh_slots()
