extends "res://scripts/paths/BreweryPath.gd"

## MassMarketPath — volume-focused brewery path.
## 2x batch size, 20% ingredient discount.
## Win condition: $50K total revenue AND all 4 distribution channels.

func get_path_name() -> String:
	return "Mass-Market Brewery"

func get_path_type() -> String:
	return "mass_market"

func get_batch_multiplier() -> float:
	return 2.0

func get_ingredient_discount() -> float:
	return 0.8

func check_win_condition(game_state) -> bool:
	if not is_instance_valid(MarketManager):
		return false
	var total_revenue: float = game_state.total_revenue if game_state else 0.0
	var channels: int = MarketManager.get_unlocked_channels().size()
	return total_revenue >= 50000.0 and channels >= 4

func get_win_description() -> String:
	return "Earn $50,000 total revenue and unlock all 4 distribution channels"
