## Integration tests: full run scenarios.
## Verifies balance math, turn counter, rent timing, win/loss triggers.
## Tasks 14.1 (win run) and 14.2 (loss/bankruptcy run).
extends GutTest

var _won: bool = false
var _lost: bool = false

func _on_won() -> void:
	_won = true

func _on_lost() -> void:
	_lost = true

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_style(style_id: String = "lager") -> BeerStyle:
	var s := BeerStyle.new()
	s.style_id = style_id
	s.style_name = style_id.capitalize()
	s.ideal_flavor_ratio = 0.5  # balanced: 50/50/50 sliders are perfect
	s.base_price = 200.0
	s.base_demand_weight = 1.0
	return s

func _make_recipe(style_id: String = "lager") -> Dictionary:
	var malt := Malt.new()
	malt.ingredient_id = "pale_malt"
	malt.ingredient_name = "Pale Malt"
	malt.category = 0
	malt.cost = 20
	malt.is_base_malt = true
	malt.style_compatibility = {style_id: 0.5}

	var hop := Hop.new()
	hop.ingredient_id = "centennial"
	hop.ingredient_name = "Centennial"
	hop.category = 1
	hop.cost = 25
	hop.style_compatibility = {style_id: 0.5}

	var yeast := Yeast.new()
	yeast.ingredient_id = "ale_yeast"
	yeast.ingredient_name = "Ale Yeast"
	yeast.category = 2
	yeast.cost = 15
	yeast.style_compatibility = {style_id: 0.5}

	return {"malts": [malt], "hops": [hop], "yeast": yeast, "adjuncts": []}

func before_each() -> void:
	MarketSystem.register_styles(["lager", "pale_ale", "wheat_beer", "stout"])
	GameState.reset()  # calls MarketSystem.initialize_demand() internally
	# Force deterministic demand AFTER reset to override the random initialization
	MarketSystem._demand_weights["lager"] = MarketSystem.DEMAND_NORMAL
	_won = false
	_lost = false
	if not GameState.game_won.is_connected(_on_won):
		GameState.game_won.connect(_on_won)
	if not GameState.game_lost.is_connected(_on_lost):
		GameState.game_lost.connect(_on_lost)
	GameState.set_style(_make_style())
	GameState.set_recipe(_make_recipe())

func after_each() -> void:
	if GameState.game_won.is_connected(_on_won):
		GameState.game_won.disconnect(_on_won)
	if GameState.game_lost.is_connected(_on_lost):
		GameState.game_lost.disconnect(_on_lost)

## Simulate the revenue phase of one brew, then advance through results.
## quality_score: pass 0.0–100.0; revenue is computed from this score.
## Does NOT deduct ingredient cost — call that separately.
func _brew_and_advance(quality_score: float) -> float:
	var revenue := GameState.calculate_revenue(quality_score)
	GameState.add_revenue(revenue)
	GameState.record_brew(quality_score)
	GameState.current_state = GameState.State.RESULTS
	GameState.advance_state()
	return revenue

# ---------------------------------------------------------------------------
# Tests: balance math — Task 14.1
# ---------------------------------------------------------------------------

func test_balance_after_one_turn_matches_expected_math():
	var initial := GameState.balance
	GameState.deduct_ingredient_cost()
	var revenue := GameState.calculate_revenue(50.0)
	_brew_and_advance(50.0)
	var recipe_cost := GameState.get_recipe_cost(GameState.current_recipe)
	var expected := initial - recipe_cost + revenue
	assert_almost_eq(GameState.balance, expected, 0.01,
		"Balance should equal initial - recipe_cost + revenue")

# ---------------------------------------------------------------------------
# Tests: turn counter — Task 14.1
# ---------------------------------------------------------------------------

func test_turn_counter_increments_each_turn():
	assert_eq(GameState.turn_counter, 0)
	GameState.deduct_ingredient_cost()
	_brew_and_advance(50.0)
	assert_eq(GameState.turn_counter, 1, "Counter should be 1 after first turn")
	GameState.deduct_ingredient_cost()
	_brew_and_advance(50.0)
	assert_eq(GameState.turn_counter, 2, "Counter should be 2 after second turn")

# ---------------------------------------------------------------------------
# Tests: rent timing — Task 14.1
# ---------------------------------------------------------------------------

func test_rent_not_charged_before_interval():
	watch_signals(GameState)
	for _i in range(GameState.RENT_INTERVAL - 1):
		GameState.deduct_ingredient_cost()
		_brew_and_advance(50.0)
	assert_signal_not_emitted(GameState, "rent_charged",
		"rent_charged should not fire before RENT_INTERVAL turns complete")

func test_rent_deducted_at_rent_interval():
	# Run RENT_INTERVAL-1 turns first (no rent)
	for _i in range(GameState.RENT_INTERVAL - 1):
		GameState.deduct_ingredient_cost()
		_brew_and_advance(50.0)
	# On the rent turn, capture balance before and compute expected
	var balance_before := GameState.balance
	GameState.deduct_ingredient_cost()
	var revenue := GameState.calculate_revenue(50.0)
	_brew_and_advance(50.0)
	var rent_recipe_cost := GameState.get_recipe_cost(GameState.current_recipe)
	var expected := balance_before - rent_recipe_cost + revenue - GameState.RENT_AMOUNT
	assert_almost_eq(GameState.balance, expected, 0.01,
		"Balance on rent turn must include RENT_AMOUNT deduction")

func test_run_survives_two_rent_cycles():
	# With base_price=200, quality=50 → revenue ≈ 250, net ≈ +200/turn, +50 on rent turns.
	# Starting at 500, 8 turns of this should keep balance well above ingredient cost.
	for _i in range(GameState.RENT_INTERVAL * 2):
		GameState.deduct_ingredient_cost()
		_brew_and_advance(50.0)
	assert_false(_lost, "A healthy run should survive two full rent cycles")
	assert_gt(GameState.balance, GameState.MINIMUM_RECIPE_COST,
		"Balance should remain above minimum recipe cost after two rent cycles")
	assert_eq(GameState.turn_counter, GameState.RENT_INTERVAL * 2)

# ---------------------------------------------------------------------------
# Tests: win condition — Task 14.1
# ---------------------------------------------------------------------------

func test_win_condition_triggers_when_balance_crosses_target():
	# Set balance so that even minimum revenue (score=0 → 200*0.5=100) tips past WIN_TARGET.
	# After deduct: WIN_TARGET - 1 - 50 = WIN_TARGET - 51; after revenue 100: WIN_TARGET + 49.
	GameState.balance = GameState.WIN_TARGET - 1.0
	GameState.deduct_ingredient_cost()
	_brew_and_advance(0.0)
	assert_true(_won, "game_won should emit when balance crosses WIN_TARGET")
	assert_eq(GameState.current_state, GameState.State.GAME_OVER,
		"State should be GAME_OVER after winning")
	assert_true(GameState.run_won, "run_won flag should be true")

# ---------------------------------------------------------------------------
# Tests: loss conditions — Task 14.2
# ---------------------------------------------------------------------------

func test_loss_triggers_when_cant_afford_next_brew():
	# balance = recipe_cost + 1 → deduct → balance = 1 (< MINIMUM_RECIPE_COST).
	# No revenue added → advance_state should detect loss.
	var loss_recipe_cost := GameState.get_recipe_cost(GameState.current_recipe)
	GameState.balance = loss_recipe_cost + 1.0
	GameState.deduct_ingredient_cost()
	# Do NOT add revenue — simulate zero revenue to leave balance below threshold
	GameState.current_state = GameState.State.RESULTS
	GameState.advance_state()
	assert_true(_lost, "game_lost should emit when balance falls below ingredient cost")
	assert_eq(GameState.current_state, GameState.State.GAME_OVER)
	assert_false(GameState.run_won, "run_won should be false on loss")

func test_loss_triggers_via_rent_wipe():
	# balance = 51, turn_counter = RENT_INTERVAL-1 (3).
	# After deduct: balance = 1.
	# On advance: turn becomes 4, rent is due → balance = 1 - 150 = -149 → loss.
	var rent_loss_recipe_cost := GameState.get_recipe_cost(GameState.current_recipe)
	GameState.balance = rent_loss_recipe_cost + 1.0
	GameState.turn_counter = GameState.RENT_INTERVAL - 1
	GameState.deduct_ingredient_cost()
	# Do NOT add revenue
	GameState.current_state = GameState.State.RESULTS
	GameState.advance_state()
	assert_true(_lost, "game_lost should emit when rent wipes balance below 0")
	assert_eq(GameState.current_state, GameState.State.GAME_OVER)

# ---------------------------------------------------------------------------
# Tests: execute_brew() integration — Task 5
# ---------------------------------------------------------------------------

func test_execute_brew_runs_full_cycle():
	# execute_brew() must: deduct cost, calculate quality+revenue, record brew,
	# populate last_brew_result, and advance state BREWING_PHASES → RESULTS.
	# Turn counter increments when the results screen advances (separate step).
	GameState.current_state = GameState.State.BREWING_PHASES
	var sliders := {"mashing": 50.0, "boiling": 50.0, "fermenting": 50.0}
	var initial_balance := GameState.balance
	var result := GameState.execute_brew(sliders)
	assert_false(result.is_empty(), "execute_brew should return a non-empty result")
	assert_true(result.has("final_score"), "result must contain final_score key")
	assert_true(result.has("revenue"), "result must contain revenue key")
	assert_eq(GameState.current_state, GameState.State.RESULTS,
		"state must be RESULTS after execute_brew")
	assert_false(GameState.last_brew_result.is_empty(),
		"last_brew_result must be populated after execute_brew")
	assert_eq(GameState.last_brew_result, result,
		"last_brew_result must match the returned Dictionary")
	assert_ne(GameState.balance, initial_balance,
		"balance must have changed after execute_brew")
	# Advance through results to verify the full turn lifecycle completes
	GameState.advance_state()
	assert_eq(GameState.turn_counter, 1, "turn_counter must increment after results advance")

func test_execute_brew_fails_when_balance_insufficient():
	# If balance < recipe cost, execute_brew must return {} and touch nothing.
	GameState.current_state = GameState.State.BREWING_PHASES
	var insuf_recipe_cost := GameState.get_recipe_cost(GameState.current_recipe)
	GameState.balance = insuf_recipe_cost - 1.0
	var balance_before := GameState.balance
	var sliders := {"mashing": 50.0, "boiling": 50.0, "fermenting": 50.0}
	var result := GameState.execute_brew(sliders)
	assert_true(result.is_empty(), "execute_brew must return {} when balance is insufficient")
	assert_almost_eq(GameState.balance, balance_before, 0.01,
		"balance must be unchanged on failed execute_brew")
	assert_eq(GameState.turn_counter, 0,
		"turn_counter must not increment on failed execute_brew")
	assert_true(GameState.last_brew_result.is_empty(),
		"last_brew_result must remain empty on failed execute_brew")

func test_execute_brew_win_condition():
	# execute_brew advances to RESULTS; win check fires in _on_results_continue
	# when the results screen advances. Minimum revenue: base_price=200, quality=0 → 100.
	# 9999 - 50 + 100 = 10049 >= 10000 → win on results advance.
	GameState.current_state = GameState.State.BREWING_PHASES
	GameState.balance = GameState.WIN_TARGET - 1.0
	var sliders := {"mashing": 50.0, "boiling": 50.0, "fermenting": 50.0}
	GameState.execute_brew(sliders)
	assert_eq(GameState.current_state, GameState.State.RESULTS,
		"state must be RESULTS after execute_brew with winning balance")
	assert_gte(GameState.balance, GameState.WIN_TARGET,
		"balance must be >= WIN_TARGET after execute_brew")
	# Advance through results — triggers _on_results_continue → win check → game_won
	GameState.advance_state()
	assert_true(_won, "game_won must emit after results advance when balance >= WIN_TARGET")
	assert_eq(GameState.current_state, GameState.State.GAME_OVER,
		"state must be GAME_OVER after winning")
	assert_true(GameState.run_won, "run_won must be true after a win")
