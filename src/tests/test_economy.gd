## Tests for GameState economy logic.
extends GutTest

func before_each():
	MarketSystem.register_styles(["lager", "pale_ale", "wheat_beer", "stout"])
	GameState.reset()

# ---------------------------------------------------------------------------
# Tests: revenue formula
# ---------------------------------------------------------------------------

func test_quality_multiplier_at_score_0():
	var mult := GameState.quality_to_multiplier(0.0)
	assert_eq(mult, 0.5, "Score 0 → 0.5x multiplier")

func test_quality_multiplier_at_score_50():
	var mult := GameState.quality_to_multiplier(50.0)
	assert_eq(mult, 1.25, "Score 50 → 1.25x multiplier (lerp 0.5..2.0 at 0.5)")

func test_quality_multiplier_at_score_100():
	var mult := GameState.quality_to_multiplier(100.0)
	assert_eq(mult, 2.0, "Score 100 → 2.0x multiplier")

func test_revenue_at_neutral_conditions():
	# Set up a style and neutral demand
	var style := BeerStyle.new()
	style.style_id = "test_style"
	style.base_price = 200.0
	GameState.set_style(style)
	# Manually set demand to normal (1.0)
	MarketSystem.register_styles(["test_style"])
	MarketSystem.initialize_demand()
	# Force normal demand
	MarketSystem._demand_weights["test_style"] = MarketSystem.DEMAND_NORMAL

	var revenue := GameState.calculate_revenue(50.0)
	# 200 * lerp(0.5, 2.0, 0.5) * 1.0 = 200 * 1.25 * 1.0 = 250.0
	assert_eq(revenue, 250.0, "Revenue at score 50, demand 1.0, base 200 should be 250")

func test_high_quality_earns_more_than_low():
	var style := BeerStyle.new()
	style.style_id = "test_style2"
	style.base_price = 200.0
	GameState.set_style(style)
	MarketSystem.register_styles(["test_style2"])
	MarketSystem._demand_weights["test_style2"] = MarketSystem.DEMAND_NORMAL

	var high_revenue := GameState.calculate_revenue(80.0)
	var low_revenue  := GameState.calculate_revenue(40.0)
	assert_gt(high_revenue, low_revenue,
		"Score 80 should earn more than score 40")

# ---------------------------------------------------------------------------
# Tests: balance operations
# ---------------------------------------------------------------------------

func test_starting_balance():
	assert_eq(GameState.balance, GameState.STARTING_BALANCE,
		"Balance should start at STARTING_BALANCE after reset")

func test_deduct_recipe_cost_sums_ingredients():
	GameState.balance = 500.0
	var m := Malt.new()
	m.cost = 20
	m.is_base_malt = true
	var h := Hop.new()
	h.cost = 25
	var y := Yeast.new()
	y.cost = 15
	var recipe := {"malts": [m], "hops": [h], "yeast": y, "adjuncts": []}
	GameState.set_recipe(recipe)
	var ok := GameState.deduct_ingredient_cost()
	assert_true(ok)
	assert_eq(GameState.balance, 440.0)  # 500 - (20+25+15)

func test_deduct_recipe_cost_with_multiple_malts():
	GameState.balance = 500.0
	var m1 := Malt.new()
	m1.cost = 20
	m1.is_base_malt = true
	var m2 := Malt.new()
	m2.cost = 25
	var h := Hop.new()
	h.cost = 25
	var y := Yeast.new()
	y.cost = 15
	var recipe := {"malts": [m1, m2], "hops": [h], "yeast": y, "adjuncts": []}
	GameState.set_recipe(recipe)
	var ok := GameState.deduct_ingredient_cost()
	assert_true(ok)
	assert_eq(GameState.balance, 415.0)  # 500 - (20+25+25+15)

func test_deduct_recipe_cost_fails_insufficient_balance():
	GameState.balance = 30.0
	var m := Malt.new()
	m.cost = 20
	m.is_base_malt = true
	var h := Hop.new()
	h.cost = 25
	var y := Yeast.new()
	y.cost = 15
	var recipe := {"malts": [m], "hops": [h], "yeast": y, "adjuncts": []}
	GameState.set_recipe(recipe)
	var ok := GameState.deduct_ingredient_cost()
	assert_false(ok)
	assert_eq(GameState.balance, 30.0)  # unchanged

func test_get_recipe_cost():
	var m := Malt.new()
	m.cost = 20
	var h := Hop.new()
	h.cost = 25
	var y := Yeast.new()
	y.cost = 15
	var a := Adjunct.new()
	a.cost = 10
	var recipe := {"malts": [m], "hops": [h], "yeast": y, "adjuncts": [a]}
	assert_eq(GameState.get_recipe_cost(recipe), 70)

func test_add_revenue_increases_balance():
	var initial := GameState.balance
	GameState.add_revenue(300.0)
	assert_eq(GameState.balance, initial + 300.0)

# ---------------------------------------------------------------------------
# Tests: rent
# ---------------------------------------------------------------------------

func test_check_rent_due_at_interval():
	GameState.turn_counter = GameState.RENT_INTERVAL
	assert_true(GameState.check_rent_due(), "Rent should be due at RENT_INTERVAL")

func test_check_rent_not_due_before_interval():
	GameState.turn_counter = GameState.RENT_INTERVAL - 1
	assert_false(GameState.check_rent_due(), "Rent should not be due before interval")

func test_check_rent_not_due_at_turn_zero():
	GameState.turn_counter = 0
	assert_false(GameState.check_rent_due(), "Rent should not be due at turn 0")

func test_deduct_rent():
	var initial := GameState.balance
	GameState.deduct_rent()
	assert_eq(GameState.balance, initial - GameState.RENT_AMOUNT)

# ---------------------------------------------------------------------------
# Tests: win / loss conditions
# ---------------------------------------------------------------------------

func test_win_condition_at_target():
	GameState.balance = GameState.WIN_TARGET
	assert_true(GameState.check_win_condition(), "Should win when balance ≥ WIN_TARGET")

func test_win_condition_not_met_below_target():
	GameState.balance = GameState.WIN_TARGET - 1.0
	assert_false(GameState.check_win_condition())

func test_loss_condition_at_zero():
	GameState.balance = 0.0
	assert_true(GameState.check_loss_condition(), "Loss when balance is 0")

func test_loss_condition_uses_minimum_recipe_cost():
	GameState.balance = 40.0
	assert_true(GameState.check_loss_condition())

func test_loss_condition_not_met_with_sufficient_balance():
	GameState.balance = GameState.MINIMUM_RECIPE_COST + 10.0
	assert_false(GameState.check_loss_condition())

# ---------------------------------------------------------------------------
# Tests: reset
# ---------------------------------------------------------------------------

func test_reset_clears_state():
	GameState.balance = 99999.0
	GameState.turn_counter = 50
	GameState.recipe_history = [{"style_id": "lager"}]
	GameState.best_quality = 95.0
	GameState.reset()
	assert_eq(GameState.balance, GameState.STARTING_BALANCE)
	assert_eq(GameState.turn_counter, 0)
	assert_eq(GameState.recipe_history.size(), 0)
	assert_eq(GameState.best_quality, 0.0)
