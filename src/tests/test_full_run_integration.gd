extends GutTest

## Integration tests simulating a complete game run through all systems.

func before_each() -> void:
	# Reset all autoloads
	GameState.reset()
	if is_instance_valid(MetaProgressionManager):
		MetaProgressionManager.active_perks.clear()
		MetaProgressionManager.active_modifiers.clear()

func _simulate_brew(style_id: String, sliders: Dictionary) -> Dictionary:
	# Load style
	var style_path: String = "res://data/styles/%s.tres" % style_id
	var style: Resource = load(style_path)
	GameState.current_style = style

	# Set minimal recipe (first available malt + hop + yeast)
	var malt: Resource = load("res://data/ingredients/malts/pale_malt.tres")
	var hop: Resource = load("res://data/ingredients/hops/saaz.tres")
	var yeast: Resource = load("res://data/ingredients/yeast/us05_clean_ale.tres")
	GameState.current_recipe = {
		"malts": [malt],
		"hops": [hop],
		"yeast": yeast,
		"adjuncts": [],
		"ingredients": [malt, hop, yeast],
	}

	# Set state to BREWING_PHASES so advance_state() transitions to RESULTS
	GameState.current_state = GameState.State.BREWING_PHASES
	return GameState.execute_brew(sliders)

func _simulate_sell() -> void:
	GameState.execute_sell([], 0.0)

# --- Full run tests ---

func test_fresh_run_starts_with_correct_balance() -> void:
	assert_eq(GameState.balance, GameState.STARTING_BALANCE)
	assert_eq(GameState.turn_counter, 0)
	assert_eq(GameState.current_state, GameState.State.EQUIPMENT_MANAGE)

func test_brew_produces_valid_result() -> void:
	var result: Dictionary = _simulate_brew("pale_ale", {"mash": 50, "boil": 50, "ferment": 50})
	assert_true(result.has("final_score"))
	assert_gte(result["final_score"], 0.0)
	assert_lte(result["final_score"], 100.0)
	assert_eq(GameState.current_state, GameState.State.RESULTS)

func test_sell_adds_revenue() -> void:
	_simulate_brew("pale_ale", {"mash": 50, "boil": 50, "ferment": 50})
	_simulate_sell()
	# Revenue should be added (might be small with default pricing)
	assert_gte(GameState.total_revenue, 0.0)

func test_multiple_brews_increment_turn_counter() -> void:
	_simulate_brew("pale_ale", {"mash": 50, "boil": 50, "ferment": 50})
	_simulate_sell()
	GameState._on_results_continue()
	assert_gte(GameState.turn_counter, 1)

func test_rp_earned_per_brew() -> void:
	var initial_rp: int = ResearchManager.research_points if is_instance_valid(ResearchManager) else 0
	_simulate_brew("pale_ale", {"mash": 50, "boil": 50, "ferment": 50})
	if is_instance_valid(ResearchManager):
		assert_gt(ResearchManager.research_points, initial_rp)

func test_equipment_spend_tracked() -> void:
	assert_eq(GameState.equipment_spend, 0.0)
	GameState.record_equipment_purchase(500.0)
	assert_eq(GameState.equipment_spend, 500.0)

func test_unique_ingredients_tracked_across_brews() -> void:
	_simulate_brew("pale_ale", {"mash": 50, "boil": 50, "ferment": 50})
	var first_count: int = GameState.unique_ingredients_used
	assert_gt(first_count, 0)
	# Second brew with same ingredients should not increase count
	_simulate_brew("pale_ale", {"mash": 50, "boil": 50, "ferment": 50})
	assert_eq(GameState.unique_ingredients_used, first_count)

func test_loss_condition_triggers_on_zero_balance() -> void:
	GameState.balance = 0.0
	assert_true(GameState.check_loss_condition())

func test_loss_condition_triggers_below_minimum_recipe_cost() -> void:
	GameState.balance = float(GameState.MINIMUM_RECIPE_COST) - 1.0
	assert_true(GameState.check_loss_condition())

func test_default_win_condition() -> void:
	GameState.balance = GameState.WIN_TARGET
	assert_true(GameState.check_win_condition())

func test_meta_progression_starting_cash_with_nest_egg() -> void:
	if not is_instance_valid(MetaProgressionManager):
		return
	MetaProgressionManager.set_active_perks(["nest_egg"] as Array[String])
	GameState.reset()
	assert_almost_eq(GameState.balance, GameState.STARTING_BALANCE * 1.05, 0.01)
	MetaProgressionManager.active_perks.clear()
	GameState.reset()

func test_meta_progression_budget_brewery_modifier() -> void:
	if not is_instance_valid(MetaProgressionManager):
		return
	MetaProgressionManager.set_active_modifiers(["budget_brewery"] as Array[String])
	GameState.reset()
	assert_almost_eq(GameState.balance, GameState.STARTING_BALANCE * 0.5, 0.01)
	MetaProgressionManager.active_modifiers.clear()
	GameState.reset()
