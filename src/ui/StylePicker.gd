extends Control

## StylePicker — lets the player select a beer style and shows market demand.

signal style_selected(style: Resource)

const STYLE_PATHS := [
	"res://data/styles/lager.tres",
	"res://data/styles/pale_ale.tres",
	"res://data/styles/wheat_beer.tres",
	"res://data/styles/stout.tres",
]

@onready var style_buttons_container: VBoxContainer = $CardPanel/MarginContainer/VBox/StyleButtons
@onready var next_button: Button = $CardPanel/MarginContainer/VBox/FooterRow/NextButton
@onready var title_label: Label = $CardPanel/MarginContainer/VBox/HeaderRow/Title
@onready var balance_label: Label = $CardPanel/MarginContainer/VBox/HeaderRow/BalanceLabel

var _styles: Array = []
var _selected_style: Resource = null
var _style_buttons: Array[Button] = []

func _ready() -> void:
	_load_styles()
	_build_ui()
	next_button.disabled = true
	next_button.pressed.connect(_on_next_pressed)
	GameState.balance_changed.connect(_on_balance_changed)
	_refresh_balance()

func _load_styles() -> void:
	_styles.clear()
	for path in STYLE_PATHS:
		var res := load(path) as BeerStyle
		if res:
			_styles.append(res)

func _build_ui() -> void:
	# Clear old buttons
	for child in style_buttons_container.get_children():
		child.queue_free()
	_style_buttons.clear()

	for style in _styles:
		var demand := MarketSystem.get_demand_weight(style.style_id)
		var demand_label := "High Demand" if demand > 1.0 else "Normal"
		var btn := Button.new()
		btn.text = "%s  [%s]" % [style.style_name, demand_label]
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size.y = 60
		btn.pressed.connect(_on_style_button_pressed.bind(style, btn))
		style_buttons_container.add_child(btn)
		_style_buttons.append(btn)

func _on_style_button_pressed(style: BeerStyle, btn: Button) -> void:
	_selected_style = style
	GameState.set_style(style)
	# Highlight selected
	for b in _style_buttons:
		b.button_pressed = false
	btn.button_pressed = true
	next_button.disabled = false

func _on_next_pressed() -> void:
	if _selected_style != null:
		style_selected.emit(_selected_style)
		GameState.advance_state()

func _refresh_balance() -> void:
	if balance_label:
		balance_label.text = "Balance: $%.0f" % GameState.balance

func _on_balance_changed(_new_balance: float) -> void:
	_refresh_balance()

func _exit_tree() -> void:
	if GameState.balance_changed.is_connected(_on_balance_changed):
		GameState.balance_changed.disconnect(_on_balance_changed)

## Called when this overlay becomes visible — refresh demand indicators.
func refresh() -> void:
	_selected_style = null
	next_button.disabled = true
	_build_ui()
	_refresh_balance()
