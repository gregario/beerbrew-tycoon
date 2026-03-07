extends Control

## StylePicker — lets the player select a beer style and shows market demand.

signal style_selected(style: Resource)

const STYLE_PATHS := [
	"res://data/styles/lager.tres",
	"res://data/styles/pale_ale.tres",
	"res://data/styles/wheat_beer.tres",
	"res://data/styles/stout.tres",
]

const SPECIALTY_STYLE_PATHS := [
	"res://data/styles/lambic.tres",
	"res://data/styles/berliner_weisse.tres",
	"res://data/styles/experimental_brew.tres",
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
		var demand := MarketManager.get_demand_weight(style.style_id)
		var demand_label := "High Demand" if demand > 1.0 else "Normal"
		var btn := Button.new()
		if style.unlocked:
			btn.text = "%s  [%s]" % [style.style_name, demand_label]
		else:
			btn.text = "%s  (Research Required)" % style.style_name
			btn.disabled = true
			btn.modulate.a = 0.5
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size.y = 60
		btn.pressed.connect(_on_style_button_pressed.bind(style, btn))
		style_buttons_container.add_child(btn)
		_style_buttons.append(btn)

	# Specialty styles section (artisan + wild_fermentation research)
	if _should_show_specialty():
		_build_specialty_section()

func _on_style_button_pressed(style: BeerStyle, btn: Button) -> void:
	if not style.unlocked:
		return
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

# ---------------------------------------------------------------------------
# Specialty Styles Section
# ---------------------------------------------------------------------------

func _should_show_specialty() -> bool:
	if not is_instance_valid(PathManager):
		return false
	if PathManager.get_path_type() != "artisan":
		return false
	if not is_instance_valid(ResearchManager):
		return false
	return ResearchManager.is_unlocked("wild_fermentation")

func _build_specialty_section() -> void:
	# Section header separator
	var sep := HSeparator.new()
	sep.add_theme_constant_override("separation", 8)
	style_buttons_container.add_child(sep)

	var header := Label.new()
	header.text = "SPECIALTY STYLES"
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color("#FFC857"))
	style_buttons_container.add_child(header)

	var specialty_styles: Array = []
	for path in SPECIALTY_STYLE_PATHS:
		var res = load(path) as BeerStyle
		if res:
			specialty_styles.append(res)

	for style in specialty_styles:
		var btn := Button.new()
		var info_parts: Array[String] = [style.style_name]
		if style.specialty_category != "":
			info_parts.append("[%s]" % style.specialty_category.capitalize().replace("_", " "))
		if style.fermentation_turns > 1:
			info_parts.append("Ages: %d turns" % style.fermentation_turns)
		btn.text = " | ".join(info_parts)
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size.y = 60

		# Accent border style for specialty cards
		var btn_style := StyleBoxFlat.new()
		btn_style.bg_color = Color("#0B1220", 0.8)
		btn_style.border_color = Color("#FFC857", 0.5)
		btn_style.set_border_width_all(2)
		btn_style.set_corner_radius_all(6)
		btn_style.content_margin_left = 12
		btn_style.content_margin_right = 12
		btn_style.content_margin_top = 8
		btn_style.content_margin_bottom = 8
		btn.add_theme_stylebox_override("normal", btn_style)
		btn.add_theme_color_override("font_color", Color("#FFC857"))

		btn.pressed.connect(_on_style_button_pressed.bind(style, btn))
		style_buttons_container.add_child(btn)
		_style_buttons.append(btn)
