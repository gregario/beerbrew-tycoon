extends Control

## RecipeDesigner — multi-select ingredient picker (malts, hops, yeast, adjuncts).

signal recipe_confirmed(recipe: Dictionary)

const MALT_PATHS := [
	"res://data/ingredients/malts/pilsner_malt.tres",
	"res://data/ingredients/malts/pale_malt.tres",
	"res://data/ingredients/malts/maris_otter.tres",
	"res://data/ingredients/malts/munich_malt.tres",
	"res://data/ingredients/malts/wheat_malt.tres",
	"res://data/ingredients/malts/crystal_60.tres",
	"res://data/ingredients/malts/chocolate_malt.tres",
	"res://data/ingredients/malts/roasted_barley.tres",
]
const HOP_PATHS := [
	"res://data/ingredients/hops/saaz.tres",
	"res://data/ingredients/hops/hallertau.tres",
	"res://data/ingredients/hops/east_kent_goldings.tres",
	"res://data/ingredients/hops/fuggle.tres",
	"res://data/ingredients/hops/cascade.tres",
	"res://data/ingredients/hops/centennial.tres",
	"res://data/ingredients/hops/citra.tres",
	"res://data/ingredients/hops/simcoe.tres",
]
const YEAST_PATHS := [
	"res://data/ingredients/yeast/us05_clean_ale.tres",
	"res://data/ingredients/yeast/s04_english_ale.tres",
	"res://data/ingredients/yeast/w3470_lager.tres",
	"res://data/ingredients/yeast/wb06_wheat.tres",
	"res://data/ingredients/yeast/belle_saison.tres",
	"res://data/ingredients/yeast/kveik_voss.tres",
]
const ADJUNCT_PATHS := [
	"res://data/ingredients/adjuncts/lactose.tres",
	"res://data/ingredients/adjuncts/brewing_sugar.tres",
	"res://data/ingredients/adjuncts/irish_moss.tres",
	"res://data/ingredients/adjuncts/flaked_oats.tres",
]

const SELECTION_LIMITS := {"malts": 3, "hops": 2, "adjuncts": 2}
const FLAVOR_AXES := ["bitterness", "sweetness", "roastiness", "fruitiness", "funkiness"]

@onready var malt_container: VBoxContainer = $CardPanel/MarginContainer/VBox/HBox/MaltPanel/VBox
@onready var hop_container: VBoxContainer = $CardPanel/MarginContainer/VBox/HBox/HopPanel/VBox
@onready var yeast_container: VBoxContainer = $CardPanel/MarginContainer/VBox/HBox/YeastPanel/VBox
@onready var adjunct_container: VBoxContainer = $CardPanel/MarginContainer/VBox/HBox/AdjunctPanel/VBox

@onready var malt_title: Label = $CardPanel/MarginContainer/VBox/HBox/MaltPanel/MaltTitle
@onready var hop_title: Label = $CardPanel/MarginContainer/VBox/HBox/HopPanel/HopTitle
@onready var yeast_title: Label = $CardPanel/MarginContainer/VBox/HBox/YeastPanel/YeastTitle
@onready var adjunct_title: Label = $CardPanel/MarginContainer/VBox/HBox/AdjunctPanel/AdjunctTitle

@onready var flavor_bars: HBoxContainer = $CardPanel/MarginContainer/VBox/SummaryPanel/SummaryVBox/FlavorBars
@onready var cost_label: Label = $CardPanel/MarginContainer/VBox/SummaryPanel/SummaryVBox/CostLabel
@onready var warning_label: Label = $CardPanel/MarginContainer/VBox/SummaryPanel/SummaryVBox/WarningLabel
@onready var brew_button: Button = $CardPanel/MarginContainer/VBox/FooterRow/BrewButton

var _selected := {"malts": [], "hops": [], "yeast": null, "adjuncts": []}
var _ingredients := {"malts": [], "hops": [], "yeast": [], "adjuncts": []}

func _ready() -> void:
	_load_ingredients()
	_build_panels()
	brew_button.disabled = true
	brew_button.pressed.connect(_on_brew_pressed)
	_update_summary()

func _load_ingredients() -> void:
	for path in MALT_PATHS:
		var ing = load(path)
		if ing: _ingredients["malts"].append(ing)
	for path in HOP_PATHS:
		var ing = load(path)
		if ing: _ingredients["hops"].append(ing)
	for path in YEAST_PATHS:
		var ing = load(path)
		if ing: _ingredients["yeast"].append(ing)
	for path in ADJUNCT_PATHS:
		var ing = load(path)
		if ing: _ingredients["adjuncts"].append(ing)

func _build_panels() -> void:
	_build_category(malt_container, "malts", _ingredients["malts"])
	_build_category(hop_container, "hops", _ingredients["hops"])
	_build_category(yeast_container, "yeast", _ingredients["yeast"])
	_build_category(adjunct_container, "adjuncts", _ingredients["adjuncts"])
	_update_counter_badges()

func _build_category(container: VBoxContainer, slot: String, ingredients: Array) -> void:
	for child in container.get_children():
		if child is Button:
			child.queue_free()
	for ing in ingredients:
		var btn := Button.new()
		if ing.unlocked:
			btn.text = "%s  $%d" % [ing.ingredient_name, ing.cost]
		else:
			btn.text = "%s  (Locked)" % ing.ingredient_name
			btn.disabled = true
			btn.modulate.a = 0.5
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.custom_minimum_size.y = 36
		btn.toggle_mode = true
		btn.button_pressed = false
		btn.pressed.connect(_on_ingredient_pressed.bind(slot, ing, btn))
		container.add_child(btn)

func _on_ingredient_pressed(slot: String, ing: Resource, btn: Button) -> void:
	if not ing.unlocked:
		return
	if slot == "yeast":
		# Radio-style for yeast (exactly 1)
		_selected["yeast"] = ing
		_deselect_siblings(btn)
		btn.button_pressed = true
	else:
		# Toggle for multi-select categories
		if ing in _selected[slot]:
			_selected[slot].erase(ing)
			btn.button_pressed = false
		elif _selected[slot].size() < SELECTION_LIMITS[slot]:
			_selected[slot].append(ing)
			btn.button_pressed = true
		else:
			# At limit — reject the toggle
			btn.button_pressed = false
	_update_counter_badges()
	_update_summary()
	_check_brew_enabled()

func _deselect_siblings(btn: Button) -> void:
	var parent := btn.get_parent()
	for child in parent.get_children():
		if child is Button and child != btn:
			child.button_pressed = false

func _update_counter_badges() -> void:
	malt_title.text = "MALTS (%d/%d)" % [_selected["malts"].size(), SELECTION_LIMITS["malts"]]
	hop_title.text = "HOPS (%d/%d)" % [_selected["hops"].size(), SELECTION_LIMITS["hops"]]
	var yeast_count := 1 if _selected["yeast"] != null else 0
	yeast_title.text = "YEAST (%d/1)" % yeast_count
	adjunct_title.text = "ADJUNCTS (%d/%d)" % [_selected["adjuncts"].size(), SELECTION_LIMITS["adjuncts"]]

func _check_brew_enabled() -> void:
	var has_base_malt := false
	for m in _selected["malts"]:
		if m is Malt and m.is_base_malt:
			has_base_malt = true
			break
	brew_button.disabled = not (has_base_malt and
		_selected["hops"].size() >= 1 and
		_selected["yeast"] != null)
	# Show warning if malts selected but no base malt
	if _selected["malts"].size() > 0 and not has_base_malt:
		warning_label.text = "Recipe requires at least one base malt"
		warning_label.visible = true
	else:
		warning_label.visible = false

func _update_summary() -> void:
	if cost_label == null:
		return
	# Build a temporary recipe dict to compute cost and flavor
	var recipe := _build_recipe_dict()
	var total_cost := GameState.get_recipe_cost(recipe)
	cost_label.text = "Total: $%d" % total_cost

	# Update flavor bars
	var combined := _combine_flavor_profiles(recipe)
	var bars := flavor_bars.get_children()
	for i in range(FLAVOR_AXES.size()):
		if i < bars.size() and bars[i] is ProgressBar:
			var bar: ProgressBar = bars[i] as ProgressBar
			bar.value = combined.get(FLAVOR_AXES[i], 0.0) * 100.0
			bar.tooltip_text = "%s: %d%%" % [FLAVOR_AXES[i].capitalize(), int(bar.value)]

func _build_recipe_dict() -> Dictionary:
	return {
		"malts": _selected["malts"].duplicate(),
		"hops": _selected["hops"].duplicate(),
		"yeast": _selected["yeast"],
		"adjuncts": _selected["adjuncts"].duplicate(),
	}

## Average all ingredients' flavor_profile dictionaries across 5 axes.
func _combine_flavor_profiles(recipe: Dictionary) -> Dictionary:
	var totals := {}
	for axis in FLAVOR_AXES:
		totals[axis] = 0.0
	var count := 0
	for malt in recipe.get("malts", []):
		for axis in FLAVOR_AXES:
			totals[axis] += malt.flavor_profile.get(axis, 0.0)
		count += 1
	for hop in recipe.get("hops", []):
		for axis in FLAVOR_AXES:
			totals[axis] += hop.flavor_profile.get(axis, 0.0)
		count += 1
	var yeast_res: Resource = recipe.get("yeast", null)
	if yeast_res:
		for axis in FLAVOR_AXES:
			totals[axis] += yeast_res.flavor_profile.get(axis, 0.0)
		count += 1
	for adj in recipe.get("adjuncts", []):
		for axis in FLAVOR_AXES:
			totals[axis] += adj.flavor_profile.get(axis, 0.0)
		count += 1
	if count > 0:
		for axis in FLAVOR_AXES:
			totals[axis] /= float(count)
	return totals

func _on_brew_pressed() -> void:
	var recipe := _build_recipe_dict()
	GameState.set_recipe(recipe)
	recipe_confirmed.emit(recipe)
	GameState.advance_state()

## Reset selection state when panel reopens.
func refresh() -> void:
	_selected = {"malts": [], "hops": [], "yeast": null, "adjuncts": []}
	_build_panels()
	brew_button.disabled = true
	_update_summary()
