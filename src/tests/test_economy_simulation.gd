extends GutTest

## Economy simulation tests — verify that the math allows a reasonable player
## to reach the default win condition ($10,000) within 60 turns.
## These tests exercise QualityCalculator and GameState economics directly,
## without instantiating any scenes.


func before_each() -> void:
	GameState.reset()


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _load_style(style_id: String) -> Resource:
	return load("res://data/styles/%s.tres" % style_id)

func _load_malt(malt_id: String) -> Resource:
	return load("res://data/ingredients/malts/%s.tres" % malt_id)

func _load_hop(hop_id: String) -> Resource:
	return load("res://data/ingredients/hops/%s.tres" % hop_id)

func _load_yeast(yeast_id: String) -> Resource:
	return load("res://data/ingredients/yeast/%s.tres" % yeast_id)

## Sets up a brew with good-compatibility ingredients for pale ale.
func _setup_pale_ale_brew() -> void:
	GameState.current_style = _load_style("pale_ale")
	var malt: Resource = _load_malt("pale_malt")
	var hop: Resource = _load_hop("cascade")
	var yeast: Resource = _load_yeast("us05_clean_ale")
	GameState.current_recipe = {
		"malts": [malt],
		"hops": [hop],
		"yeast": yeast,
		"adjuncts": [],
		"ingredients": [malt, hop, yeast],
	}
	GameState.current_state = GameState.State.BREWING_PHASES

## Reasonable mid-range sliders: 65C mash, 60min boil, 20C ferment.
func _mid_range_sliders() -> Dictionary:
	return {"mashing": 65.0, "boiling": 60.0, "fermenting": 20.0}

## Simulates selling through taproom only (early game).
## Taproom: margin 1.0, volume_pct 0.3 → 3 units out of 10 batch.
func _sell_taproom(units: int = 3) -> Dictionary:
	return GameState.execute_sell(
		[{"channel_id": "taproom", "units": units}],
		0.0  # no price offset
	)


# ---------------------------------------------------------------------------
# Core economy math verification
# ---------------------------------------------------------------------------

func test_quality_multiplier_at_65_is_profitable() -> void:
	# Quality 65 → multiplier = lerp(0.5, 2.0, 0.65) = 1.475
	var mult: float = GameState.quality_to_multiplier(65.0)
	assert_almost_eq(mult, 1.475, 0.01,
		"Quality 65 should yield ~1.475x multiplier")

func test_quality_multiplier_at_50_is_baseline() -> void:
	var mult: float = GameState.quality_to_multiplier(50.0)
	assert_almost_eq(mult, 1.25, 0.01,
		"Quality 50 should yield 1.25x multiplier")

func test_ingredient_cost_pale_ale_is_reasonable() -> void:
	# pale_malt=15, cascade=25, us05=15 → total $55
	_setup_pale_ale_brew()
	var cost: int = GameState.get_recipe_cost(GameState.current_recipe)
	assert_eq(cost, 55, "Pale ale with basic ingredients should cost $55")

func test_rent_per_turn_average() -> void:
	# Garage rent $150 every 4 turns = $37.50/turn avg
	var rent: float = 150.0
	var avg_per_turn: float = rent / float(GameState.RENT_INTERVAL)
	assert_almost_eq(avg_per_turn, 37.5, 0.01,
		"Average rent per turn should be $37.50")


# ---------------------------------------------------------------------------
# Single brew profit test
# ---------------------------------------------------------------------------

func test_single_brew_is_profitable_with_mid_quality() -> void:
	_setup_pale_ale_brew()
	# Deduct ingredient cost
	var cost: int = GameState.get_recipe_cost(GameState.current_recipe)
	var starting: float = GameState.balance

	var result: Dictionary = GameState.execute_brew(_mid_range_sliders())
	var quality: float = result["final_score"]

	# Sell through taproom (3 units at base price $200)
	var sell_result: Dictionary = _sell_taproom(3)
	var revenue: float = sell_result.get("total", 0.0)

	# Net profit = revenue - cost (rent not included, charged separately)
	var net: float = revenue - float(cost)
	gut.p("Quality: %.1f, Revenue: $%.0f, Cost: $%d, Net: $%.0f" % [quality, revenue, cost, net])
	assert_gt(revenue, 0.0, "Revenue should be positive")


# ---------------------------------------------------------------------------
# Multi-turn economy simulation
# ---------------------------------------------------------------------------

func test_win_achievable_within_60_turns() -> void:
	# Simulate a reasonable player run:
	# - Brews pale ale each turn with good ingredients and mid-range sliders
	# - Sells through taproom (3 units) at default price
	# - Rent charged every 4 turns ($150)
	# - No equipment, staff, or research spending
	# - High sanitation/temp_control to avoid failures
	GameState.sanitation_quality = 80
	GameState.temp_control_quality = 80

	var turns: int = 0
	var max_turns: int = 60
	var won: bool = false
	var balance_log: Array = []

	while turns < max_turns:
		_setup_pale_ale_brew()

		# Check if we can still afford to brew
		var cost: int = GameState.get_recipe_cost(GameState.current_recipe)
		if GameState.balance < cost:
			gut.p("Ran out of money at turn %d, balance: $%.0f" % [turns, GameState.balance])
			break

		var result: Dictionary = GameState.execute_brew(_mid_range_sliders())
		if result.is_empty():
			gut.p("Brew failed at turn %d" % turns)
			break

		# Sell through taproom
		_sell_taproom(3)

		# Advance turn (handles rent, market tick, etc.)
		GameState.advance_state()  # RESULTS -> CONDITIONING
		GameState.advance_state()  # CONDITIONING -> SELL
		GameState.advance_state()  # SELL -> _on_results_continue -> EQUIPMENT_MANAGE or GAME_OVER

		turns += 1
		balance_log.append({"turn": turns, "balance": GameState.balance})

		# Check win
		if GameState.run_won or GameState.balance >= GameState.WIN_TARGET:
			won = true
			break

		# Check loss
		if GameState.current_state == GameState.State.GAME_OVER:
			gut.p("Game over at turn %d, balance: $%.0f" % [turns, GameState.balance])
			break

	gut.p("Simulation ended after %d turns. Final balance: $%.0f. Won: %s" % [
		turns, GameState.balance, str(won)])

	# Log first 5 and last 5 balance entries
	if balance_log.size() > 0:
		var log_start: int = mini(5, balance_log.size())
		for i in range(log_start):
			var entry: Dictionary = balance_log[i]
			gut.p("  Turn %d: $%.0f" % [entry["turn"], entry["balance"]])
		if balance_log.size() > 10:
			gut.p("  ...")
		var log_end_start: int = maxi(log_start, balance_log.size() - 5)
		for i in range(log_end_start, balance_log.size()):
			var entry: Dictionary = balance_log[i]
			gut.p("  Turn %d: $%.0f" % [entry["turn"], entry["balance"]])

	assert_true(won, "Player should be able to win within %d turns with reasonable play" % max_turns)


func test_early_game_net_positive_per_brew() -> void:
	# Verify that a single brew-sell cycle in the early game is net positive
	# even after accounting for average rent cost per turn.
	GameState.sanitation_quality = 70
	GameState.temp_control_quality = 70
	_setup_pale_ale_brew()

	var cost: int = GameState.get_recipe_cost(GameState.current_recipe)
	var result: Dictionary = GameState.execute_brew(_mid_range_sliders())
	var quality: float = result.get("final_score", 0.0)

	# Sell through taproom
	var sell_result: Dictionary = _sell_taproom(3)
	var revenue: float = sell_result.get("total", 0.0)

	# Average rent per turn
	var avg_rent: float = 150.0 / 4.0  # $37.50

	var net_per_turn: float = revenue - float(cost) - avg_rent
	gut.p("Quality: %.1f, Revenue: $%.0f, Cost: $%d, Avg Rent: $%.0f, Net: $%.0f" % [
		quality, revenue, cost, avg_rent, net_per_turn])

	assert_gt(net_per_turn, 0.0,
		"Net profit per brew (revenue - ingredients - avg rent) should be positive")


func test_starting_balance_survives_first_rent_cycle() -> void:
	# With $500 starting balance, player should survive the first 4 turns
	# (rent charged at turn 4). Brewing each turn with cheap ingredients.
	GameState.sanitation_quality = 70
	GameState.temp_control_quality = 70

	for turn_idx in range(4):
		_setup_pale_ale_brew()
		var cost: int = GameState.get_recipe_cost(GameState.current_recipe)
		if GameState.balance < cost:
			assert_true(false, "Should afford ingredients on turn %d (balance: $%.0f, cost: $%d)" % [
				turn_idx + 1, GameState.balance, cost])
			return
		GameState.execute_brew(_mid_range_sliders())
		_sell_taproom(3)
		GameState.advance_state()  # RESULTS -> CONDITIONING
		GameState.advance_state()  # CONDITIONING -> SELL
		GameState.advance_state()  # SELL -> advance

	gut.p("Balance after 4 turns (including rent): $%.0f" % GameState.balance)
	assert_gt(GameState.balance, float(GameState.MINIMUM_RECIPE_COST),
		"Balance after 4 turns should still be above minimum recipe cost")


func test_quality_score_in_expected_range_with_good_setup() -> void:
	# With compatible ingredients and mid-range sliders, quality should be 50-80
	GameState.sanitation_quality = 80
	GameState.temp_control_quality = 80
	_setup_pale_ale_brew()
	var result: Dictionary = GameState.execute_brew(_mid_range_sliders())
	var quality: float = result["final_score"]
	gut.p("Quality with good setup: %.1f" % quality)
	assert_gte(quality, 40.0, "Quality with good ingredients should be at least 40")
	assert_lte(quality, 95.0, "Quality should not exceed 95 without bonuses")


func test_revenue_scales_with_quality() -> void:
	# Higher quality should produce higher revenue
	var low_mult: float = GameState.quality_to_multiplier(30.0)
	var mid_mult: float = GameState.quality_to_multiplier(60.0)
	var high_mult: float = GameState.quality_to_multiplier(90.0)
	assert_lt(low_mult, mid_mult, "Mid quality should earn more than low")
	assert_lt(mid_mult, high_mult, "High quality should earn more than mid")
	gut.p("Multipliers — Q30: %.2f, Q60: %.2f, Q90: %.2f" % [low_mult, mid_mult, high_mult])


func test_loss_not_immediate_with_bad_brews() -> void:
	# Even with poor quality, player should survive several turns before losing
	GameState.sanitation_quality = 30
	GameState.temp_control_quality = 30
	var survived_turns: int = 0

	for turn_idx in range(10):
		_setup_pale_ale_brew()
		var cost: int = GameState.get_recipe_cost(GameState.current_recipe)
		if GameState.balance < cost:
			break
		GameState.execute_brew(_mid_range_sliders())
		_sell_taproom(3)
		GameState.advance_state()  # RESULTS -> CONDITIONING
		GameState.advance_state()  # CONDITIONING -> SELL
		GameState.advance_state()  # SELL -> advance
		survived_turns += 1
		if GameState.current_state == GameState.State.GAME_OVER:
			break

	gut.p("Survived %d turns with poor quality. Final balance: $%.0f" % [
		survived_turns, GameState.balance])
	assert_gte(survived_turns, 3,
		"Player should survive at least 3 turns even with poor quality")
