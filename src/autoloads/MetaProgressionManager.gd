extends Node

## MetaProgressionManager — persistent cross-run progression.
## Owns unlock points, unlocked items, achievements, run history.
## Persists to user://meta.json (separate from run saves).

signal points_changed(available: int, lifetime: int)
signal item_unlocked(category: String, item_id: String)
signal achievement_completed(achievement_id: String)

# --- Persistent state ---
var available_points: int = 0
var lifetime_points: int = 0
var total_runs: int = 0

var unlocked_styles: Array[String] = []
var unlocked_blueprints: Array[String] = []
var unlocked_ingredients: Array[String] = []
var unlocked_perks: Array[String] = []

var achievements: Dictionary = {
	"first_victory": false,
	"budget_master": false,
	"perfect_brew": false,
	"survivor": false,
	"diversified": false,
	"scarcity_brewer": false,
}

var achievement_progress: Dictionary = {
	"best_quality": 0.0,
	"best_turns": 0,
	"min_equipment_spend": 999999,
	"max_channels": 0,
	"min_unique_ingredients": 999,
}

var run_history: Array[Dictionary] = []

# Active selections for current/next run
var active_perks: Array[String] = []
var active_modifiers: Array[String] = []

const MAX_PERKS: int = 3
const MAX_MODIFIERS: int = 2
const MAX_HISTORY: int = 10
const META_SAVE_PATH: String = "user://meta.json"


func _ready() -> void:
	load_from_disk()


const ACHIEVEMENT_MODIFIER_MAP: Dictionary = {
	"first_victory": "tough_market",
	"budget_master": "budget_brewery",
	"perfect_brew": "master_brewer",
	"survivor": "lucky_break",
	"diversified": "generous_market",
	"scarcity_brewer": "ingredient_shortage",
}

const UNLOCK_CATALOG: Dictionary = {
	"styles": [
		{"id": "lager", "name": "Lager", "description": "Crisp, clean, light-bodied", "cost": 5},
		{"id": "wheat_beer", "name": "Wheat Beer", "description": "Hazy, fruity esters", "cost": 5},
		{"id": "stout", "name": "Stout", "description": "Roasted, coffee, dark", "cost": 8},
		{"id": "berliner_weisse", "name": "Berliner Weisse", "description": "Sour, tart, refreshing", "cost": 10},
		{"id": "lambic", "name": "Lambic", "description": "Wild fermented, complex", "cost": 10},
	],
	"blueprints": [
		{"id": "mash_tun", "name": "Mash Tun", "description": "50% off research cost", "cost": 5},
		{"id": "temp_chamber", "name": "Temperature Chamber", "description": "50% off research cost", "cost": 5},
		{"id": "kegging_kit", "name": "Kegging Kit", "description": "50% off research cost", "cost": 5},
		{"id": "three_vessel", "name": "Three-Vessel System", "description": "50% off research cost", "cost": 8},
		{"id": "ss_conical", "name": "SS Conical Fermenter", "description": "50% off research cost", "cost": 8},
	],
	"ingredients": [
		{"id": "crystal_60", "name": "Crystal 60", "description": "Caramel, toffee malt", "cost": 3},
		{"id": "chocolate_malt", "name": "Chocolate Malt", "description": "Dark, rich flavor", "cost": 3},
		{"id": "cascade", "name": "Cascade Hops", "description": "Floral, citrus American hop", "cost": 4},
		{"id": "citra", "name": "Citra Hops", "description": "Tropical, grapefruit hop", "cost": 6},
		{"id": "belle_saison", "name": "Belle Saison Yeast", "description": "Spicy, fruity esters", "cost": 5},
		{"id": "kveik_voss", "name": "Kveik (Voss)", "description": "Fast, tropical fermentation", "cost": 5},
	],
	"perks": [
		{"id": "nest_egg", "name": "Nest Egg", "description": "+5% starting cash ($525)", "cost": 8},
		{"id": "quick_study", "name": "Quick Study", "description": "+1 base RP per brew", "cost": 10},
		{"id": "landlords_friend", "name": "Landlord's Friend", "description": "-10% rent costs", "cost": 8},
		{"id": "style_specialist", "name": "Style Specialist", "description": "+5% quality for one style family", "cost": 12},
	],
}

# --- Points ---

func add_points(amount: int) -> void:
	available_points += amount
	lifetime_points += amount
	points_changed.emit(available_points, lifetime_points)

func spend_points(amount: int) -> bool:
	if amount > available_points:
		return false
	available_points -= amount
	points_changed.emit(available_points, lifetime_points)
	return true

# --- Unlocks ---

func unlock_style(style_id: String, cost: int) -> bool:
	if style_id in unlocked_styles:
		return false
	if not spend_points(cost):
		return false
	unlocked_styles.append(style_id)
	item_unlocked.emit("styles", style_id)
	return true

func unlock_blueprint(equipment_id: String, cost: int) -> bool:
	if equipment_id in unlocked_blueprints:
		return false
	if not spend_points(cost):
		return false
	unlocked_blueprints.append(equipment_id)
	item_unlocked.emit("blueprints", equipment_id)
	return true

func unlock_ingredient(ingredient_id: String, cost: int) -> bool:
	if ingredient_id in unlocked_ingredients:
		return false
	if not spend_points(cost):
		return false
	unlocked_ingredients.append(ingredient_id)
	item_unlocked.emit("ingredients", ingredient_id)
	return true

func unlock_perk(perk_id: String, cost: int) -> bool:
	if perk_id in unlocked_perks:
		return false
	if not spend_points(cost):
		return false
	unlocked_perks.append(perk_id)
	item_unlocked.emit("perks", perk_id)
	return true

func is_unlocked(category: String, item_id: String) -> bool:
	match category:
		"styles": return item_id in unlocked_styles
		"blueprints": return item_id in unlocked_blueprints
		"ingredients": return item_id in unlocked_ingredients
		"perks": return item_id in unlocked_perks
	return false

# --- Achievements ---

func get_achievements() -> Dictionary:
	return achievements.duplicate()

func complete_achievement(achievement_id: String) -> void:
	if achievements.has(achievement_id) and not achievements[achievement_id]:
		achievements[achievement_id] = true
		achievement_completed.emit(achievement_id)

func is_achievement_completed(achievement_id: String) -> bool:
	return achievements.get(achievement_id, false)

func get_achievement_progress() -> Dictionary:
	return achievement_progress.duplicate()

# --- Perk/modifier selection ---

func set_active_perks(perks: Array[String]) -> void:
	active_perks = perks.slice(0, MAX_PERKS)

func set_active_modifiers(modifiers: Array[String]) -> void:
	active_modifiers = modifiers.slice(0, MAX_MODIFIERS)

func has_active_perk(perk_id: String) -> bool:
	return perk_id in active_perks

func has_active_modifier(modifier_id: String) -> bool:
	return modifier_id in active_modifiers

func has_challenge_modifier() -> bool:
	var challenge_ids: Array[String] = ["tough_market", "budget_brewery", "ingredient_shortage"]
	for mod_id in active_modifiers:
		if mod_id in challenge_ids:
			return true
	return false

# --- Run points & end_run ---

func calculate_run_points(metrics: Dictionary) -> int:
	var turns: int = mini(int(metrics.get("turns", 0)) / 5, 5)
	var revenue: int = mini(int(float(metrics.get("revenue", 0.0)) / 2000.0), 5)
	var quality: int = mini(int(float(metrics.get("best_quality", 0.0)) / 20.0), 5)
	var medals: int = mini(int(metrics.get("medals", 0)), 5)
	var win: int = 5 if metrics.get("won", false) else 0
	var base: int = mini(turns + revenue + quality + medals + win, 25)
	if has_challenge_modifier():
		return mini(int(float(base) * 1.5), 25)
	return base

func end_run(metrics: Dictionary) -> int:
	var points: int = calculate_run_points(metrics)
	add_points(points)
	update_achievement_progress(metrics)
	check_achievements()
	record_run({"points": points, "metrics": metrics})
	return points

# --- Achievement system ---

func get_achievement_modifier_map() -> Dictionary:
	return ACHIEVEMENT_MODIFIER_MAP.duplicate()

func is_modifier_unlocked(modifier_id: String) -> bool:
	for achievement_id in ACHIEVEMENT_MODIFIER_MAP:
		if ACHIEVEMENT_MODIFIER_MAP[achievement_id] == modifier_id:
			return is_achievement_completed(achievement_id)
	return false

func update_achievement_progress(metrics: Dictionary) -> void:
	var q: float = float(metrics.get("best_quality", 0.0))
	if q > float(achievement_progress["best_quality"]):
		achievement_progress["best_quality"] = q
	var t: int = int(metrics.get("turns", 0))
	if t > int(achievement_progress["best_turns"]):
		achievement_progress["best_turns"] = t
	var es: int = int(metrics.get("equipment_spend", 999999))
	if es < int(achievement_progress["min_equipment_spend"]):
		achievement_progress["min_equipment_spend"] = es
	var ch: int = int(metrics.get("channels_unlocked", 0))
	if ch > int(achievement_progress["max_channels"]):
		achievement_progress["max_channels"] = ch
	var ui: int = int(metrics.get("unique_ingredients", 999))
	if ui < int(achievement_progress["min_unique_ingredients"]):
		achievement_progress["min_unique_ingredients"] = ui
	# Track win state for conditional achievements
	if metrics.get("won", false):
		achievement_progress["has_won"] = true
		achievement_progress["won_equipment_spend"] = es
		achievement_progress["won_unique_ingredients"] = ui

func check_achievements() -> void:
	var has_won: bool = achievement_progress.get("has_won", false)
	if has_won and not achievements["first_victory"]:
		complete_achievement("first_victory")
	if has_won and int(achievement_progress.get("won_equipment_spend", 999999)) < 1000 and not achievements["budget_master"]:
		complete_achievement("budget_master")
	if float(achievement_progress["best_quality"]) >= 95.0 and not achievements["perfect_brew"]:
		complete_achievement("perfect_brew")
	if int(achievement_progress["best_turns"]) >= 20 and not achievements["survivor"]:
		complete_achievement("survivor")
	if int(achievement_progress["max_channels"]) >= 4 and not achievements["diversified"]:
		complete_achievement("diversified")
	if has_won and int(achievement_progress.get("won_unique_ingredients", 999)) <= 10 and not achievements["scarcity_brewer"]:
		complete_achievement("scarcity_brewer")

# --- Unlock catalog ---

func get_unlock_catalog() -> Dictionary:
	return UNLOCK_CATALOG

func has_blueprint_discount(equipment_id: String) -> bool:
	return equipment_id in unlocked_blueprints

# --- Run history ---

func record_run(run_data: Dictionary) -> void:
	total_runs += 1
	run_history.append(run_data)
	if run_history.size() > MAX_HISTORY:
		run_history.pop_front()

# --- Persistence ---

func save_state() -> Dictionary:
	return {
		"version": 1,
		"available_points": available_points,
		"lifetime_points": lifetime_points,
		"total_runs": total_runs,
		"unlocked_styles": unlocked_styles.duplicate(),
		"unlocked_blueprints": unlocked_blueprints.duplicate(),
		"unlocked_ingredients": unlocked_ingredients.duplicate(),
		"unlocked_perks": unlocked_perks.duplicate(),
		"achievements": achievements.duplicate(),
		"achievement_progress": achievement_progress.duplicate(),
		"run_history": run_history.duplicate(true),
		"active_perks": active_perks.duplicate(),
		"active_modifiers": active_modifiers.duplicate(),
	}

func load_state(data: Dictionary) -> void:
	available_points = data.get("available_points", 0)
	lifetime_points = data.get("lifetime_points", 0)
	total_runs = data.get("total_runs", 0)
	unlocked_styles.assign(data.get("unlocked_styles", []))
	unlocked_blueprints.assign(data.get("unlocked_blueprints", []))
	unlocked_ingredients.assign(data.get("unlocked_ingredients", []))
	unlocked_perks.assign(data.get("unlocked_perks", []))
	var loaded_achievements: Dictionary = data.get("achievements", {})
	for key in achievements:
		achievements[key] = loaded_achievements.get(key, false)
	var loaded_progress: Dictionary = data.get("achievement_progress", {})
	for key in achievement_progress:
		achievement_progress[key] = loaded_progress.get(key, achievement_progress[key])
	run_history.assign(data.get("run_history", []))
	active_perks.assign(data.get("active_perks", []))
	active_modifiers.assign(data.get("active_modifiers", []))

func save_to_disk() -> void:
	var data: Dictionary = save_state()
	var json_string: String = JSON.stringify(data, "\t")
	var file: FileAccess = FileAccess.open(META_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)

func load_from_disk() -> void:
	if not FileAccess.file_exists(META_SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(META_SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json_string: String = file.get_as_text()
	var json: JSON = JSON.new()
	var err: int = json.parse(json_string)
	if err == OK:
		load_state(json.data)

func reset_meta() -> void:
	available_points = 0
	lifetime_points = 0
	total_runs = 0
	unlocked_styles.clear()
	unlocked_blueprints.clear()
	unlocked_ingredients.clear()
	unlocked_perks.clear()
	for key in achievements:
		achievements[key] = false
	for key in achievement_progress:
		match key:
			"min_equipment_spend": achievement_progress[key] = 999999
			"min_unique_ingredients": achievement_progress[key] = 999
			_: achievement_progress[key] = 0
	run_history.clear()
	active_perks.clear()
	active_modifiers.clear()
