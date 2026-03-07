extends Node

## PathManager — orchestrates brewery path selection and delegates
## all path-specific queries to the active BreweryPath strategy.

const FORK_BALANCE_THRESHOLD: float = 15000.0
const FORK_BEERS_THRESHOLD: int = 25

signal path_chosen(path_type: String)

var current_path = null  # BreweryPath or null

func has_chosen_path() -> bool:
	return current_path != null

func can_choose_path() -> bool:
	if has_chosen_path():
		return false
	if not is_instance_valid(BreweryExpansion):
		return false
	if BreweryExpansion.current_stage != BreweryExpansion.Stage.MICROBREWERY:
		return false
	if not is_instance_valid(GameState):
		return false
	return (GameState.balance >= FORK_BALANCE_THRESHOLD
		and BreweryExpansion.beers_brewed >= FORK_BEERS_THRESHOLD)

func choose_path(path_type: String) -> void:
	if has_chosen_path():
		return
	match path_type:
		"artisan":
			current_path = preload("res://scripts/paths/ArtisanPath.gd").new()
		"mass_market":
			current_path = preload("res://scripts/paths/MassMarketPath.gd").new()
		_:
			push_warning("Unknown path type: %s" % path_type)
			return
	path_chosen.emit(path_type)

# --- Delegated getters ---

func get_path_name() -> String:
	if current_path == null:
		return ""
	return current_path.get_path_name()

func get_path_type() -> String:
	if current_path == null:
		return ""
	return current_path.get_path_type()

func get_quality_bonus() -> float:
	if current_path == null:
		return 1.0
	return current_path.get_quality_bonus()

func get_batch_multiplier() -> float:
	if current_path == null:
		return 1.0
	return current_path.get_batch_multiplier()

func get_ingredient_discount() -> float:
	if current_path == null:
		return 1.0
	return current_path.get_ingredient_discount()

func get_competition_discount() -> float:
	if current_path == null:
		return 1.0
	return current_path.get_competition_discount()

func check_win_condition() -> bool:
	if current_path == null:
		return false
	return current_path.check_win_condition(GameState)

# --- Reputation (artisan-specific, safe to call on any path) ---

func get_reputation() -> int:
	if current_path != null and current_path.has_method("add_reputation"):
		return current_path.reputation
	return 0

func add_reputation(amount: int) -> void:
	if current_path != null and current_path.has_method("add_reputation"):
		current_path.add_reputation(amount)

# --- Persistence ---

func save_state() -> Dictionary:
	if current_path == null:
		return {"path_type": ""}
	return current_path.serialize()

func load_state(data: Dictionary) -> void:
	var path_type: String = data.get("path_type", "")
	if path_type == "":
		current_path = null
		return
	current_path = null
	choose_path(path_type)
	if current_path != null:
		current_path.deserialize(data)

func reset() -> void:
	current_path = null
