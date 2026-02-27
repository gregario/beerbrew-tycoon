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
	var malt := Ingredient.new()
	malt.ingredient_id = "pale_malt"
	malt.ingredient_name = "Pale Malt"
	malt.category = 0
	malt.style_compatibility = {style_id: 0.5}

	var hop := Ingredient.new()
	hop.ingredient_id = "centennial"
	hop.ingredient_name = "Centennial"
	hop.category = 1
	hop.style_compatibility = {style_id: 0.5}

	var yeast := Ingredient.new()
	yeast.ingredient_id = "ale_yeast"
	yeast.ingredient_name = "Ale Yeast"
	yeast.category = 2
	yeast.style_compatibility = {style_id: 0.5}

	return {"malt": malt, "hop": hop, "yeast": yeast}

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
	var expected := initial - GameState.INGREDIENT_COST + revenue
	assert_almost_eq(GameState.balance, expected, 0.01,
		"Balance should equal initial - ingredient_cost + revenue")

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
	var expected := balance_before - GameState.INGREDIENT_COST + revenue - GameState.RENT_AMOUNT
	assert_almost_eq(GameState.balance, expected, 0.01,
		"Balance on rent turn must include RENT_AMOUNT deduction")

func test_run_survives_two_rent_cycles():
	# With base_price=200, quality=50 → revenue ≈ 250, net ≈ +200/turn, +50 on rent turns.
	# Starting at 500, 8 turns of this should keep balance well above ingredient cost.
	for _i in range(GameState.RENT_INTERVAL * 2):
		GameState.deduct_ingredient_cost()
		_brew_and_advance(50.0)
	assert_false(_lost, "A healthy run should survive two full rent cycles")
	assert_gt(GameState.balance, GameState.INGREDIENT_COST,
		"Balance should remain above ingredient threshold after two rent cycles")
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
	# balance = 51 → deduct ingredient (50) → balance = 1 (< INGREDIENT_COST).
	# No revenue added → advance_state should detect loss.
	GameState.balance = GameState.INGREDIENT_COST + 1.0
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
	GameState.balance = GameState.INGREDIENT_COST + 1.0
	GameState.turn_counter = GameState.RENT_INTERVAL - 1
	GameState.deduct_ingredient_cost()
	# Do NOT add revenue
	GameState.current_state = GameState.State.RESULTS
	GameState.advance_state()
	assert_true(_lost, "game_lost should emit when rent wipes balance below 0")
	assert_eq(GameState.current_state, GameState.State.GAME_OVER)
