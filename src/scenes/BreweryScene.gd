extends Node2D

## BreweryScene — isometric garage brewery view.
## Uses placeholder ColorRects until pixel art sprites are ready.
## Equipment mode overlays slot buttons on top of stations.

signal slot_clicked(slot_index: int)
signal start_brewing_pressed()
signal research_requested()

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
var _equipment_ui: CanvasLayer = null

const SLOT_NAMES: Array[String] = ["Kettle", "Fermenter", "Bottler"]
const SLOT_POSITIONS: Array[Vector2] = [
	Vector2(240, 312),  # Above Kettle
	Vector2(520, 296),  # Above Fermenter
	Vector2(840, 328),  # Above Bottler
]

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
	for i in range(_slot_buttons.size()):
		var btn := _slot_buttons[i]
		var slot_id: String = EquipmentManager.station_slots[i]
		if slot_id == "":
			btn.text = "%s\n[Empty Slot]" % SLOT_NAMES[i]
			btn.add_theme_color_override("font_color", Color("#8A9BB1"))
		else:
			var equip: Equipment = EquipmentManager.get_equipment(slot_id)
			var name_text: String = equip.equipment_name if equip else slot_id
			btn.text = "%s\n%s" % [SLOT_NAMES[i], name_text]
			btn.add_theme_color_override("font_color", Color("#5EE8A4"))
	# Update balance
	if _balance_label:
		_balance_label.text = "Balance: $%.0f" % GameState.balance

# ---------------------------------------------------------------------------
# Build equipment UI programmatically
# ---------------------------------------------------------------------------

func _build_equipment_ui() -> void:
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

	# Title label
	var title := Label.new()
	title.text = "EQUIPMENT MANAGEMENT"
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#8A9BB1"))
	title.position = Vector2(32, 50)
	_equipment_ui.add_child(title)

	# Station slot buttons
	for i in range(3):
		var btn := Button.new()
		btn.name = "SlotButton_%d" % i
		btn.custom_minimum_size = Vector2(160, 60)
		btn.position = SLOT_POSITIONS[i]
		btn.text = "%s\n[Empty Slot]" % SLOT_NAMES[i]
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
