## Tests for the conditioning system (Group 8).
extends GutTest


# ---------------------------------------------------------------------------
# State machine
# ---------------------------------------------------------------------------

func test_conditioning_enum_exists() -> void:
	var state: GameState.State = GameState.State.CONDITIONING
	assert_not_null(state, "CONDITIONING should exist in GameState.State enum")

func test_advance_state_results_to_conditioning() -> void:
	GameState.reset()
	GameState.current_state = GameState.State.RESULTS
	GameState.advance_state()
	assert_eq(GameState.current_state, GameState.State.CONDITIONING,
		"RESULTS should advance to CONDITIONING")

func test_advance_state_conditioning_to_sell() -> void:
	GameState.reset()
	GameState.current_state = GameState.State.CONDITIONING
	GameState.advance_state()
	assert_eq(GameState.current_state, GameState.State.SELL,
		"CONDITIONING should advance to SELL")

func test_full_state_flow_results_conditioning_sell() -> void:
	GameState.reset()
	GameState.current_state = GameState.State.RESULTS
	GameState.advance_state()  # RESULTS -> CONDITIONING
	assert_eq(GameState.current_state, GameState.State.CONDITIONING)
	GameState.advance_state()  # CONDITIONING -> SELL
	assert_eq(GameState.current_state, GameState.State.SELL)

# ---------------------------------------------------------------------------
# Conditioning weeks
# ---------------------------------------------------------------------------

func test_conditioning_weeks_defaults_to_zero() -> void:
	GameState.reset()
	assert_eq(GameState.conditioning_weeks, 0,
		"conditioning_weeks should default to 0")

func test_set_conditioning_weeks() -> void:
	GameState.reset()
	GameState.set_conditioning_weeks(3)
	assert_eq(GameState.conditioning_weeks, 3)

func test_set_conditioning_weeks_clamps_max() -> void:
	GameState.reset()
	GameState.set_conditioning_weeks(10)
	assert_eq(GameState.conditioning_weeks, 4,
		"conditioning_weeks should be clamped to 4")

func test_set_conditioning_weeks_clamps_min() -> void:
	GameState.reset()
	GameState.set_conditioning_weeks(-5)
	assert_eq(GameState.conditioning_weeks, 0,
		"conditioning_weeks should be clamped to 0")

func test_conditioning_weeks_resets_to_zero() -> void:
	GameState.conditioning_weeks = 3
	GameState.reset()
	assert_eq(GameState.conditioning_weeks, 0,
		"conditioning_weeks should reset to 0")

# ---------------------------------------------------------------------------
# Off-flavor decay math
# ---------------------------------------------------------------------------

func test_diacetyl_decay_3_weeks() -> void:
	var intensities: Dictionary = {"diacetyl": 0.8}
	var decayed: Dictionary = FailureSystem.apply_conditioning_decay(intensities, 3)
	assert_almost_eq(decayed["diacetyl"], 0.05, 0.001,
		"Diacetyl 0.8 after 3 weeks (0.25/week) should be 0.05")

func test_acetaldehyde_decay_2_weeks() -> void:
	var intensities: Dictionary = {"acetaldehyde": 0.5}
	var decayed: Dictionary = FailureSystem.apply_conditioning_decay(intensities, 2)
	assert_almost_eq(decayed["acetaldehyde"], 0.2, 0.001,
		"Acetaldehyde 0.5 after 2 weeks (0.15/week) should be 0.2")

func test_oxidation_does_not_decay() -> void:
	var intensities: Dictionary = {"oxidation": 0.6}
	var decayed: Dictionary = FailureSystem.apply_conditioning_decay(intensities, 4)
	assert_almost_eq(decayed["oxidation"], 0.6, 0.001,
		"Oxidation should not decay (rate = 0.0)")

func test_decay_does_not_go_negative() -> void:
	var intensities: Dictionary = {"diacetyl": 0.1}
	var decayed: Dictionary = FailureSystem.apply_conditioning_decay(intensities, 4)
	assert_almost_eq(decayed["diacetyl"], 0.0, 0.001,
		"Decay should floor at 0.0, not go negative")

func test_esters_decay() -> void:
	var intensities: Dictionary = {"esters": 0.5}
	var decayed: Dictionary = FailureSystem.apply_conditioning_decay(intensities, 2)
	assert_almost_eq(decayed["esters"], 0.4, 0.001,
		"Esters 0.5 after 2 weeks (0.05/week) should be 0.4")

func test_fusel_alcohols_decay() -> void:
	var intensities: Dictionary = {"fusel_alcohols": 0.6}
	var decayed: Dictionary = FailureSystem.apply_conditioning_decay(intensities, 3)
	assert_almost_eq(decayed["fusel_alcohols"], 0.3, 0.001,
		"Fusel alcohols 0.6 after 3 weeks (0.1/week) should be 0.3")

func test_multiple_off_flavors_decay_independently() -> void:
	var intensities: Dictionary = {
		"diacetyl": 0.8,
		"oxidation": 0.5,
		"esters": 0.3,
	}
	var decayed: Dictionary = FailureSystem.apply_conditioning_decay(intensities, 2)
	assert_almost_eq(decayed["diacetyl"], 0.3, 0.001)
	assert_almost_eq(decayed["oxidation"], 0.5, 0.001)
	assert_almost_eq(decayed["esters"], 0.2, 0.001)

func test_zero_weeks_returns_original_intensities() -> void:
	var intensities: Dictionary = {"diacetyl": 0.8, "esters": 0.5}
	var decayed: Dictionary = FailureSystem.apply_conditioning_decay(intensities, 0)
	assert_almost_eq(decayed["diacetyl"], 0.8, 0.001)
	assert_almost_eq(decayed["esters"], 0.5, 0.001)

# ---------------------------------------------------------------------------
# Conditioning cost
# ---------------------------------------------------------------------------

func test_conditioning_cost_zero_weeks() -> void:
	GameState.reset()
	GameState.last_brew_result = {"final_score": 50.0}
	var result: Dictionary = GameState.execute_conditioning(0)
	assert_eq(result["cost"], 0.0, "0 weeks should cost 0")

func test_conditioning_cost_calculation() -> void:
	GameState.reset()
	GameState.last_brew_result = {"final_score": 50.0}
	var rent: float = BreweryExpansion.get_rent_amount()
	var expected_cost: float = 2.0 * (rent / 4.0)
	var balance_before: float = GameState.balance
	var result: Dictionary = GameState.execute_conditioning(2)
	assert_almost_eq(result["cost"], expected_cost, 0.01,
		"Cost should be weeks * rent/4")
	assert_almost_eq(GameState.balance, balance_before - expected_cost, 0.01,
		"Balance should be deducted by cost")

func test_conditioning_cost_4_weeks() -> void:
	GameState.reset()
	GameState.last_brew_result = {"final_score": 50.0}
	var rent: float = BreweryExpansion.get_rent_amount()
	var expected_cost: float = 4.0 * (rent / 4.0)
	var result: Dictionary = GameState.execute_conditioning(4)
	assert_almost_eq(result["cost"], expected_cost, 0.01)

# ---------------------------------------------------------------------------
# Execute conditioning integration
# ---------------------------------------------------------------------------

func test_execute_conditioning_applies_quality_bonus() -> void:
	GameState.reset()
	GameState.last_brew_result = {"final_score": 60.0}
	GameState.execute_conditioning(3)
	assert_almost_eq(GameState.last_brew_result["final_score"], 63.0, 0.01,
		"Quality bonus should be +1% per week (flat)")

func test_execute_conditioning_quality_caps_at_100() -> void:
	GameState.reset()
	GameState.last_brew_result = {"final_score": 99.0}
	GameState.execute_conditioning(4)
	assert_almost_eq(GameState.last_brew_result["final_score"], 100.0, 0.01,
		"Quality should not exceed 100")

func test_execute_conditioning_applies_decay() -> void:
	GameState.reset()
	GameState.last_brew_result = {
		"final_score": 50.0,
		"off_flavor_intensities": {"diacetyl": 0.8, "oxidation": 0.4},
	}
	GameState.execute_conditioning(2)
	var intensities: Dictionary = GameState.last_brew_result["off_flavor_intensities"]
	assert_almost_eq(intensities["diacetyl"], 0.3, 0.001,
		"Diacetyl should decay after conditioning")
	assert_almost_eq(intensities["oxidation"], 0.4, 0.001,
		"Oxidation should not decay")

func test_execute_conditioning_deducts_cost() -> void:
	GameState.reset()
	GameState.last_brew_result = {"final_score": 50.0}
	var balance_before: float = GameState.balance
	var rent: float = BreweryExpansion.get_rent_amount()
	GameState.execute_conditioning(2)
	var expected_cost: float = 2.0 * (rent / 4.0)
	assert_almost_eq(GameState.balance, balance_before - expected_cost, 0.01)

func test_execute_conditioning_returns_empty_without_brew() -> void:
	GameState.reset()
	var result: Dictionary = GameState.execute_conditioning(2)
	assert_true(result.is_empty(),
		"execute_conditioning should return {} if no last_brew_result")

func test_execute_conditioning_stores_weeks_in_result() -> void:
	GameState.reset()
	GameState.last_brew_result = {"final_score": 50.0}
	GameState.execute_conditioning(3)
	assert_eq(GameState.last_brew_result.get("conditioning_weeks", 0), 3)

func test_execute_conditioning_stores_cost_in_result() -> void:
	GameState.reset()
	GameState.last_brew_result = {"final_score": 50.0}
	var rent: float = BreweryExpansion.get_rent_amount()
	GameState.execute_conditioning(2)
	var expected_cost: float = 2.0 * (rent / 4.0)
	assert_almost_eq(GameState.last_brew_result.get("conditioning_cost", 0.0), expected_cost, 0.01)
