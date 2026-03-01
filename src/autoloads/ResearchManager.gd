extends Node

## ResearchManager — manages the research tree: unlocking nodes, applying effects,
## and tracking research points.

signal research_unlocked(node_id: String)
signal rp_changed(new_amount: int)

var research_points: int = 0
var unlocked_nodes: Array[String] = []
var bonuses: Dictionary = {}
var unlocked_equipment_tier: int = 2

var _catalog: Dictionary = {}  # node_id -> ResearchNode

const ROOT_NODE_IDS: Array[String] = [
	"mash_basics", "hop_timing", "homebrew_upgrades", "ale_fundamentals"
]

const LOCKED_INGREDIENT_IDS: Array[String] = [
	"crystal_60", "chocolate_malt", "roasted_barley",
	"cascade", "centennial", "citra", "simcoe",
	"belle_saison", "wb06_wheat", "kveik_voss",
	"brewing_sugar", "flaked_oats", "irish_moss", "lactose"
]

const LOCKED_STYLE_IDS: Array[String] = [
	"lager", "wheat_beer", "stout"
]

const INGREDIENT_DIRS: Array[String] = [
	"res://data/ingredients/malts/",
	"res://data/ingredients/hops/",
	"res://data/ingredients/yeast/",
	"res://data/ingredients/adjuncts/",
]

const STYLE_DIR: String = "res://data/styles/"

const RESEARCH_PATHS: Array[String] = [
	"res://data/research/techniques/mash_basics.tres",
	"res://data/research/techniques/advanced_mashing.tres",
	"res://data/research/techniques/decoction_technique.tres",
	"res://data/research/techniques/hop_timing.tres",
	"res://data/research/techniques/dry_hopping.tres",
	"res://data/research/techniques/water_chemistry.tres",
	"res://data/research/ingredients/specialty_malts.tres",
	"res://data/research/ingredients/american_hops.tres",
	"res://data/research/ingredients/premium_hops.tres",
	"res://data/research/ingredients/specialist_yeast.tres",
	"res://data/research/equipment/homebrew_upgrades.tres",
	"res://data/research/equipment/semi_pro_equipment.tres",
	"res://data/research/equipment/pro_equipment.tres",
	"res://data/research/equipment/adjunct_brewing.tres",
	"res://data/research/styles/ale_fundamentals.tres",
	"res://data/research/styles/lager_brewing.tres",
	"res://data/research/styles/wheat_traditions.tres",
	"res://data/research/styles/dark_styles.tres",
	"res://data/research/styles/ipa_mastery.tres",
	"res://data/research/styles/belgian_arts.tres",
]


func _ready() -> void:
	_load_catalog()


func _load_catalog() -> void:
	for path in RESEARCH_PATHS:
		var node_res = load(path) as ResearchNode
		if node_res:
			_catalog[node_res.node_id] = node_res


func get_catalog_size() -> int:
	return _catalog.size()


func get_node_by_id(node_id: String) -> ResearchNode:
	return _catalog.get(node_id, null)


func is_unlocked(node_id: String) -> bool:
	return node_id in unlocked_nodes


func can_unlock(node_id: String) -> bool:
	if is_unlocked(node_id):
		return false
	var node_res: ResearchNode = get_node_by_id(node_id)
	if node_res == null:
		return false
	if research_points < node_res.rp_cost:
		return false
	for prereq in node_res.prerequisites:
		if not is_unlocked(prereq):
			return false
	return true


func unlock(node_id: String) -> bool:
	if not can_unlock(node_id):
		return false
	var node_res: ResearchNode = get_node_by_id(node_id)
	research_points -= node_res.rp_cost
	unlocked_nodes.append(node_id)
	_apply_effect(node_res.unlock_effect)
	research_unlocked.emit(node_id)
	rp_changed.emit(research_points)
	return true


func add_rp(amount: int) -> void:
	research_points += amount
	rp_changed.emit(research_points)


func get_available_nodes() -> Array:
	var result: Array = []
	for node_res in _catalog.values():
		if is_unlocked(node_res.node_id):
			continue
		var prereqs_met := true
		for prereq in node_res.prerequisites:
			if not is_unlocked(prereq):
				prereqs_met = false
				break
		if prereqs_met:
			result.append(node_res)
	return result


func get_nodes_by_category(category: ResearchNode.Category) -> Array:
	var result: Array = []
	for node_res in _catalog.values():
		if node_res.category == category:
			result.append(node_res)
	return result


func save_state() -> Dictionary:
	return {
		"research_points": research_points,
		"unlocked_nodes": unlocked_nodes.duplicate(),
	}


func load_state(data: Dictionary) -> void:
	research_points = data.get("research_points", 0)
	var saved_nodes: Array = data.get("unlocked_nodes", [])
	unlocked_nodes = []
	bonuses = {}
	unlocked_equipment_tier = 2
	# Re-lock all ingredients and styles first
	_reset_ingredient_locks()
	_reset_style_locks()
	# Re-apply all unlocked nodes
	for node_id in saved_nodes:
		unlocked_nodes.append(node_id)
		var node_res: ResearchNode = get_node_by_id(node_id)
		if node_res:
			_apply_effect(node_res.unlock_effect)


func reset() -> void:
	research_points = 0
	unlocked_nodes = []
	bonuses = {}
	unlocked_equipment_tier = 2
	_reset_ingredient_locks()
	_reset_style_locks()
	# Auto-unlock root nodes
	for node_id in ROOT_NODE_IDS:
		if node_id in _catalog:
			unlocked_nodes.append(node_id)


# ---------------------------------------------------------------------------
# Effect application
# ---------------------------------------------------------------------------
func _apply_effect(effect: Dictionary) -> void:
	if effect.is_empty():
		return
	var effect_type: String = effect.get("type", "")
	match effect_type:
		"unlock_ingredients":
			_unlock_ingredients(effect.get("ids", []))
		"unlock_style":
			_unlock_styles(effect.get("ids", []))
		"unlock_equipment_tier":
			var tier: int = effect.get("tier", 2)
			if tier > unlocked_equipment_tier:
				unlocked_equipment_tier = tier
		"brewing_bonus":
			var bonus_dict: Dictionary = effect.get("bonuses", {})
			for key in bonus_dict:
				bonuses[key] = bonuses.get(key, 0.0) + bonus_dict[key]


func _unlock_ingredients(ids: Array) -> void:
	for ingredient_id in ids:
		for dir_path in INGREDIENT_DIRS:
			var file_path: String = dir_path + str(ingredient_id) + ".tres"
			if ResourceLoader.exists(file_path):
				var res = load(file_path)
				if res and "unlocked" in res:
					res.unlocked = true


func _unlock_styles(ids: Array) -> void:
	for style_id in ids:
		var file_path: String = STYLE_DIR + str(style_id) + ".tres"
		if ResourceLoader.exists(file_path):
			var res = load(file_path)
			if res and "unlocked" in res:
				res.unlocked = true


func _reset_ingredient_locks() -> void:
	for ingredient_id in LOCKED_INGREDIENT_IDS:
		for dir_path in INGREDIENT_DIRS:
			var file_path: String = dir_path + str(ingredient_id) + ".tres"
			if ResourceLoader.exists(file_path):
				var res = load(file_path)
				if res and "unlocked" in res:
					res.unlocked = false


func _reset_style_locks() -> void:
	for style_id in LOCKED_STYLE_IDS:
		var file_path: String = STYLE_DIR + str(style_id) + ".tres"
		if ResourceLoader.exists(file_path):
			var res = load(file_path)
			if res and "unlocked" in res:
				res.unlocked = false
