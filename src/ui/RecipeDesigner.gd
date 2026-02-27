extends Control

## RecipeDesigner — ingredient selection (malt, hop, yeast) for the current recipe.

signal recipe_confirmed(recipe: Dictionary)

const MALT_PATHS := [
	"res://data/ingredients/malts/pale_malt.tres",
	"res://data/ingredients/malts/crystal_malt.tres",
	"res://data/ingredients/malts/munich_malt.tres",
	"res://data/ingredients/malts/roasted_barley.tres",
]
const HOP_PATHS := [
	"res://data/ingredients/hops/cascade.tres",
	"res://data/ingredients/hops/centennial.tres",
	"res://data/ingredients/hops/hallertau.tres",
	"res://data/ingredients/hops/east_kent_goldings.tres",
]
const YEAST_PATHS := [
	"res://data/ingredients/yeast/ale_yeast.tres",
	"res://data/ingredients/yeast/lager_yeast.tres",
	"res://data/ingredients/yeast/wheat_yeast.tres",
]

@onready var malt_container: VBoxContainer = $Panel/VBox/HBox/MaltPanel/VBox
@onready var hop_container: VBoxContainer = $Panel/VBox/HBox/HopPanel/VBox
@onready var yeast_container: VBoxContainer = $Panel/VBox/HBox/YeastPanel/VBox
@onready var summary_label: Label = $Panel/VBox/Summary
@onready var brew_button: Button = $Panel/VBox/BrewButton

var _selected := {"malt": null, "hop": null, "yeast": null}
var _ingredients := {"malt": [], "hop": [], "yeast": []}

func _ready() -> void:
	_load_ingredients()
	_build_panels()
	brew_button.disabled = true
	brew_button.pressed.connect(_on_brew_pressed)
	_update_summary()

func _load_ingredients() -> void:
	for path in MALT_PATHS:
		var ing := load(path) as Ingredient
		if ing: _ingredients["malt"].append(ing)
	for path in HOP_PATHS:
		var ing := load(path) as Ingredient
		if ing: _ingredients["hop"].append(ing)
	for path in YEAST_PATHS:
		var ing := load(path) as Ingredient
		if ing: _ingredients["yeast"].append(ing)

func _build_panels() -> void:
	_build_category(malt_container, "malt", _ingredients["malt"])
	_build_category(hop_container, "hop", _ingredients["hop"])
	_build_category(yeast_container, "yeast", _ingredients["yeast"])

func _build_category(container: VBoxContainer, slot: String, ingredients: Array) -> void:
	for child in container.get_children():
		if child is Button:
			child.queue_free()
	for ing in ingredients:
		var btn := Button.new()
		btn.text = ing.ingredient_name
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_ingredient_pressed.bind(slot, ing, btn))
		container.add_child(btn)

func _on_ingredient_pressed(slot: String, ing: Resource, btn: Button) -> void:
	_selected[slot] = ing
	# Deselect siblings
	var parent := btn.get_parent()
	for child in parent.get_children():
		if child is Button:
			child.button_pressed = false
	btn.button_pressed = true
	_update_summary()
	_check_brew_enabled()

func _check_brew_enabled() -> void:
	brew_button.disabled = not (_selected["malt"] != null and
		_selected["hop"] != null and _selected["yeast"] != null)

func _update_summary() -> void:
	if summary_label == null:
		return
	var malt_name: String = _selected["malt"].ingredient_name if _selected["malt"] else "—"
	var hop_name: String  = _selected["hop"].ingredient_name  if _selected["hop"]  else "—"
	var yeast_name: String = _selected["yeast"].ingredient_name if _selected["yeast"] else "—"
	summary_label.text = "Malt: %s  |  Hop: %s  |  Yeast: %s" % [malt_name, hop_name, yeast_name]

func _on_brew_pressed() -> void:
	if _selected["malt"] == null or _selected["hop"] == null or _selected["yeast"] == null:
		return
	var recipe := {
		"malt": _selected["malt"],
		"hop":  _selected["hop"],
		"yeast": _selected["yeast"],
	}
	GameState.set_recipe(recipe)
	recipe_confirmed.emit(recipe)
	GameState.advance_state()

## Reset selection state when panel reopens.
func refresh() -> void:
	_selected = {"malt": null, "hop": null, "yeast": null}
	_build_panels()
	brew_button.disabled = true
	_update_summary()
