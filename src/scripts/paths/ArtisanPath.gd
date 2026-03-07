extends "res://scripts/paths/BreweryPath.gd"

## ArtisanPath — quality-focused brewery path.
## +20% quality bonus, 50% competition fee discount, reputation tracking.
## Win condition: 5+ medals AND reputation >= 100.

var reputation: int = 0

func get_path_name() -> String:
	return "Artisan Brewery"

func get_path_type() -> String:
	return "artisan"

func get_quality_bonus() -> float:
	return 1.2

func get_competition_discount() -> float:
	return 0.5

func add_reputation(amount: int) -> void:
	reputation += amount

func check_win_condition(game_state) -> bool:
	if not is_instance_valid(CompetitionManager):
		return false
	var total_medals: int = (CompetitionManager.medals["gold"]
		+ CompetitionManager.medals["silver"]
		+ CompetitionManager.medals["bronze"])
	return total_medals >= 5 and reputation >= 100

func get_win_description() -> String:
	return "Earn 5 competition medals and reach 100 reputation"

func serialize() -> Dictionary:
	var data: Dictionary = super.serialize()
	data["reputation"] = reputation
	return data

func deserialize(data: Dictionary) -> void:
	reputation = data.get("reputation", 0)
