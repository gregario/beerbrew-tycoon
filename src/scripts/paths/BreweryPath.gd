extends RefCounted

## BreweryPath — base class for brewery path strategies.
## Subclasses override bonuses, win conditions, and serialization.

func get_path_name() -> String:
	return ""

func get_path_type() -> String:
	return ""

func get_quality_bonus() -> float:
	return 1.0

func get_batch_multiplier() -> float:
	return 1.0

func get_ingredient_discount() -> float:
	return 1.0

func get_competition_discount() -> float:
	return 1.0

func check_win_condition(_game_state) -> bool:
	return false

func get_win_description() -> String:
	return ""

func serialize() -> Dictionary:
	return {"path_type": get_path_type()}

func deserialize(_data: Dictionary) -> void:
	pass
