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
