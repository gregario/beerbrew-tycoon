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

const WATER_PROFILE_PATHS := [
	"res://data/water/soft.tres",
	"res://data/water/balanced.tres",
	"res://data/water/malty.tres",
	"res://data/water/hoppy.tres",
	"res://data/water/juicy.tres",
]

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
var _water_profiles: Array = []
var _selected_water_profile = null  # WaterProfile or null (tap water)
var _water_section: VBoxContainer = null
var _hop_schedule_section: VBoxContainer = null
var _hop_allocation_buttons: Dictionary = {}  # hop_id -> {slot_name: Button}

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
	_build_water_selector()
	_build_hop_schedule_selector()

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
	# Rebuild hop schedule when hops change
	if slot == "hops":
		_build_hop_schedule_selector()

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

func _build_water_selector() -> void:
	# Remove old water section if it exists
	if _water_section != null and is_instance_valid(_water_section):
		_water_section.queue_free()
		_water_section = null
	# Only show water selector when Water Kit equipment is slotted
	if not is_instance_valid(EquipmentManager) or not EquipmentManager.is_revealed("water_selector"):
		return
	# Load water profiles
	_water_profiles.clear()
	for path in WATER_PROFILE_PATHS:
		var wp = load(path)
		if wp:
			_water_profiles.append(wp)
	if _water_profiles.is_empty():
		return
	# Build the UI section
	_water_section = VBoxContainer.new()
	_water_section.name = "WaterSection"
	var title_label := Label.new()
	title_label.text = "WATER PROFILE"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_water_section.add_child(title_label)
	var desc_label := Label.new()
	desc_label.text = "Select water chemistry (default: tap water)"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 12)
	_water_section.add_child(desc_label)
	# "Tap Water (default)" button
	var tap_btn := Button.new()
	tap_btn.text = "Tap Water (default)"
	tap_btn.toggle_mode = true
	tap_btn.button_pressed = (_selected_water_profile == null)
	tap_btn.custom_minimum_size.y = 32
	tap_btn.pressed.connect(_on_water_selected.bind(null, tap_btn))
	_water_section.add_child(tap_btn)
	# One button per water profile
	for wp in _water_profiles:
		var btn := Button.new()
		btn.text = "%s — %s" % [wp.display_name, wp.mineral_description]
		btn.toggle_mode = true
		btn.button_pressed = (_selected_water_profile == wp)
		btn.custom_minimum_size.y = 32
		btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
		btn.pressed.connect(_on_water_selected.bind(wp, btn))
		_water_section.add_child(btn)
	# Insert before FooterRow in the VBox
	var vbox: VBoxContainer = brew_button.get_parent().get_parent()
	var footer_idx: int = vbox.get_children().find(brew_button.get_parent())
	if footer_idx >= 0:
		vbox.add_child(_water_section)
		vbox.move_child(_water_section, footer_idx)

const HOP_SLOTS := ["bittering", "flavor", "aroma", "dry_hop"]

func _build_hop_schedule_selector() -> void:
	# Remove old hop schedule section if it exists
	if _hop_schedule_section != null and is_instance_valid(_hop_schedule_section):
		_hop_schedule_section.queue_free()
		_hop_schedule_section = null
	_hop_allocation_buttons.clear()
	# Only show when hop_schedule equipment is revealed AND hops are selected
	if not is_instance_valid(EquipmentManager) or not EquipmentManager.is_revealed("hop_schedule"):
		GameState.set_hop_allocations({})
		return
	var selected_hops: Array = _selected["hops"]
	if selected_hops.is_empty():
		GameState.set_hop_allocations({})
		return
	# Build the UI section
	_hop_schedule_section = VBoxContainer.new()
	_hop_schedule_section.name = "HopScheduleSection"
	var title_label := Label.new()
	title_label.text = "HOP SCHEDULE"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hop_schedule_section.add_child(title_label)
	var desc_label := Label.new()
	desc_label.text = "Assign each hop to a timing slot"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 12)
	_hop_schedule_section.add_child(desc_label)
	# For each selected hop, show a row with 4 radio buttons
	for hop in selected_hops:
		var hop_id: String = hop.ingredient_id
		var row := HBoxContainer.new()
		row.name = "HopRow_%s" % hop_id
		var hop_label := Label.new()
		hop_label.text = hop.ingredient_name + ":"
		hop_label.custom_minimum_size.x = 100
		row.add_child(hop_label)
		_hop_allocation_buttons[hop_id] = {}
		for slot in HOP_SLOTS:
			var btn := Button.new()
			btn.text = slot.capitalize().replace("_", " ")
			btn.toggle_mode = true
			btn.button_pressed = (slot == "bittering")  # Default to bittering
			btn.custom_minimum_size.y = 28
			btn.pressed.connect(_on_hop_slot_selected.bind(hop_id, slot, btn))
			row.add_child(btn)
			_hop_allocation_buttons[hop_id][slot] = btn
		_hop_schedule_section.add_child(row)
	# Insert before FooterRow in the VBox
	var vbox: VBoxContainer = brew_button.get_parent().get_parent()
	var footer_idx: int = vbox.get_children().find(brew_button.get_parent())
	if footer_idx >= 0:
		vbox.add_child(_hop_schedule_section)
		vbox.move_child(_hop_schedule_section, footer_idx)
	# Set default allocations (all bittering)
	_update_hop_allocations()

func _on_hop_slot_selected(hop_id: String, slot: String, btn: Button) -> void:
	# Radio-style: deselect other slots for this hop
	if _hop_allocation_buttons.has(hop_id):
		for s in _hop_allocation_buttons[hop_id]:
			var other_btn: Button = _hop_allocation_buttons[hop_id][s]
			if other_btn != btn:
				other_btn.button_pressed = false
	btn.button_pressed = true
	_update_hop_allocations()

func _update_hop_allocations() -> void:
	var allocations: Dictionary = {}
	for hop_id in _hop_allocation_buttons:
		for slot in _hop_allocation_buttons[hop_id]:
			var btn: Button = _hop_allocation_buttons[hop_id][slot]
			if btn.button_pressed:
				allocations[hop_id] = slot
				break
		if not allocations.has(hop_id):
			allocations[hop_id] = "bittering"  # Fallback default
	GameState.set_hop_allocations(allocations)

func _on_water_selected(profile, btn: Button) -> void:
	_selected_water_profile = profile
	GameState.set_water_profile(profile)
	# Radio-style: deselect all other water buttons
	if _water_section != null:
		for child in _water_section.get_children():
			if child is Button and child != btn:
				child.button_pressed = false
	btn.button_pressed = true

func _on_brew_pressed() -> void:
	var recipe := _build_recipe_dict()
	GameState.set_recipe(recipe)
	recipe_confirmed.emit(recipe)
	GameState.advance_state()

## Reset selection state when panel reopens.
func refresh() -> void:
	_selected = {"malts": [], "hops": [], "yeast": null, "adjuncts": []}
	_selected_water_profile = null
	GameState.set_water_profile(null)
	GameState.set_hop_allocations({})
	_build_panels()
	brew_button.disabled = true
	_update_summary()
