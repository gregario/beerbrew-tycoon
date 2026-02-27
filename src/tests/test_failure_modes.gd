## Tests for failure modes and QA system.
extends GutTest

# ---------------------------------------------------------------------------
# GameState stat defaults
# ---------------------------------------------------------------------------

func test_sanitation_quality_defaults_to_50() -> void:
	GameState.reset()
	assert_eq(GameState.sanitation_quality, 50, "sanitation_quality should default to 50")

func test_temp_control_quality_defaults_to_50() -> void:
	GameState.reset()
	assert_eq(GameState.temp_control_quality, 50, "temp_control_quality should default to 50")

# ---------------------------------------------------------------------------
# Infection probability
# ---------------------------------------------------------------------------

func test_infection_chance_at_sanitation_80() -> void:
	var chance: float = FailureSystem.calc_infection_chance(80)
	assert_lte(chance, 0.10, "Sanitation 80+ should give <=10% infection chance")

func test_infection_chance_at_sanitation_100() -> void:
	var chance: float = FailureSystem.calc_infection_chance(100)
	assert_eq(chance, 0.0, "Sanitation 100 should give 0% infection chance")

func test_infection_chance_at_sanitation_30() -> void:
	var chance: float = FailureSystem.calc_infection_chance(30)
	assert_almost_eq(chance, 0.35, 0.01, "Sanitation 30 should give 35% infection chance")

func test_infection_chance_at_sanitation_50() -> void:
	var chance: float = FailureSystem.calc_infection_chance(50)
	assert_almost_eq(chance, 0.25, 0.01, "Sanitation 50 should give 25% infection chance")

func test_infection_chance_never_negative() -> void:
	var chance: float = FailureSystem.calc_infection_chance(100)
	assert_gte(chance, 0.0, "Infection chance should never be negative")

# ---------------------------------------------------------------------------
# Infection penalty
# ---------------------------------------------------------------------------

func test_apply_infection_penalty_reduces_score() -> void:
	var result: Dictionary = FailureSystem.apply_infection_penalty(80.0)
	assert_gte(result["penalized_score"], 80.0 * 0.4, "Infected score should be >= 40% of original")
	assert_lte(result["penalized_score"], 80.0 * 0.6, "Infected score should be <= 60% of original")

func test_apply_infection_penalty_flags_infected() -> void:
	var result: Dictionary = FailureSystem.apply_infection_penalty(80.0)
	assert_true(result["infected"], "Result should be flagged as infected")

func test_apply_infection_penalty_has_message() -> void:
	var result: Dictionary = FailureSystem.apply_infection_penalty(80.0)
	assert_true(result["message"].length() > 0, "Infection result should have a message")

# ---------------------------------------------------------------------------
# Off-flavor probability
# ---------------------------------------------------------------------------

func test_off_flavor_chance_at_temp_control_80() -> void:
	var chance: float = FailureSystem.calc_off_flavor_chance(80)
	assert_lte(chance, 0.10, "Temp control 80+ should give <=10% off-flavor chance")

func test_off_flavor_chance_at_temp_control_30() -> void:
	var chance: float = FailureSystem.calc_off_flavor_chance(30)
	assert_almost_eq(chance, 0.35, 0.01, "Temp control 30 should give 35% off-flavor chance")

func test_off_flavor_chance_at_temp_control_100() -> void:
	var chance: float = FailureSystem.calc_off_flavor_chance(100)
	assert_eq(chance, 0.0, "Temp control 100 should give 0% off-flavor chance")

# ---------------------------------------------------------------------------
# Off-flavor penalty
# ---------------------------------------------------------------------------

func test_off_flavor_penalty_reduces_score() -> void:
	var result: Dictionary = FailureSystem.apply_off_flavor_penalty(80.0)
	assert_gte(result["penalized_score"], 80.0 * 0.7, "Off-flavor score should be >= 70% of original")
	assert_lte(result["penalized_score"], 80.0 * 0.85, "Off-flavor score should be <= 85% of original")

func test_off_flavor_penalty_has_tag() -> void:
	var result: Dictionary = FailureSystem.apply_off_flavor_penalty(80.0)
	assert_true(result["off_flavor_tags"].size() > 0, "Off-flavor result should have tags")

func test_off_flavor_tag_is_valid_type() -> void:
	var valid_types: Array[String] = ["esters", "fusel_alcohols", "dms"]
	var result: Dictionary = FailureSystem.apply_off_flavor_penalty(80.0)
	var tag: String = result["off_flavor_tags"][0]
	assert_true(valid_types.has(tag), "Off-flavor tag should be a valid type: %s" % tag)

func test_off_flavor_penalty_has_message() -> void:
	var result: Dictionary = FailureSystem.apply_off_flavor_penalty(80.0)
	assert_true(result["message"].length() > 0, "Off-flavor result should have a message")

# ---------------------------------------------------------------------------
# Combined failure roll
# ---------------------------------------------------------------------------

func test_roll_failures_returns_expected_keys() -> void:
	var result: Dictionary = FailureSystem.roll_failures(80.0, 80, 80)
	assert_has(result, "final_score", "Result should have final_score")
	assert_has(result, "infected", "Result should have infected flag")
	assert_has(result, "off_flavor_tags", "Result should have off_flavor_tags")
	assert_has(result, "failure_messages", "Result should have failure_messages")
	assert_has(result, "infection_message", "Result should have infection_message")
	assert_has(result, "off_flavor_message", "Result should have off_flavor_message")

func test_roll_failures_perfect_stats_no_failures() -> void:
	var infected_count: int = 0
	var off_flavor_count: int = 0
	for i in range(50):
		var result: Dictionary = FailureSystem.roll_failures(80.0, 100, 100)
		if result["infected"]:
			infected_count += 1
		if result["off_flavor_tags"].size() > 0:
			off_flavor_count += 1
	assert_eq(infected_count, 0, "Perfect sanitation should never infect")
	assert_eq(off_flavor_count, 0, "Perfect temp control should never produce off-flavors")

func test_roll_failures_preserves_score_when_clean() -> void:
	var result: Dictionary = FailureSystem.roll_failures(75.0, 100, 100)
	assert_eq(result["final_score"], 75.0, "Clean brew should preserve original score")

func test_roll_failures_infection_reduces_score() -> void:
	var found_infection: bool = false
	for i in range(200):
		var result: Dictionary = FailureSystem.roll_failures(80.0, 0, 100)
		if result["infected"]:
			assert_lt(result["final_score"], 80.0, "Infected brew should have lower score")
			found_infection = true
			break
	assert_true(found_infection, "Should have found at least one infection in 200 rolls at sanitation=0")

func test_roll_failures_off_flavor_reduces_score() -> void:
	var found_off_flavor: bool = false
	for i in range(200):
		var result: Dictionary = FailureSystem.roll_failures(80.0, 100, 0)
		if result["off_flavor_tags"].size() > 0:
			assert_lt(result["final_score"], 80.0, "Off-flavor brew should have lower score")
			found_off_flavor = true
			break
	assert_true(found_off_flavor, "Should have found at least one off-flavor in 200 rolls at temp_control=0")

# ---------------------------------------------------------------------------
# Integration: execute_brew includes failure rolls
# ---------------------------------------------------------------------------

func _make_test_style() -> BeerStyle:
	var s := BeerStyle.new()
	s.style_id = "test_ipa"
	s.style_name = "IPA"
	s.ideal_flavor_ratio = 0.5
	s.base_price = 200.0
	s.preferred_ingredients = {}
	s.ideal_flavor_profile = {"bitterness": 0.8, "sweetness": 0.2, "roastiness": 0.0, "fruitiness": 0.3, "funkiness": 0.0}
	s.ideal_mash_temp_min = 64.0
	s.ideal_mash_temp_max = 66.0
	s.ideal_boil_min = 50.0
	s.ideal_boil_max = 70.0
	return s

func _make_test_malt() -> Malt:
	var m := Malt.new()
	m.ingredient_id = "pale_malt"
	m.ingredient_name = "Pale Malt"
	m.cost = 15
	m.flavor_profile = {"bitterness": 0.1, "sweetness": 0.3, "roastiness": 0.1, "fruitiness": 0.0, "funkiness": 0.0}
	return m

func _make_test_hop() -> Hop:
	var h := Hop.new()
	h.ingredient_id = "centennial"
	h.ingredient_name = "Centennial"
	h.cost = 20
	h.alpha_acid_pct = 10.0
	h.flavor_profile = {"bitterness": 0.8, "sweetness": 0.0, "roastiness": 0.0, "fruitiness": 0.3, "funkiness": 0.0}
	return h

func _make_test_yeast() -> Yeast:
	var y := Yeast.new()
	y.ingredient_id = "ale_yeast"
	y.ingredient_name = "Ale Yeast"
	y.cost = 15
	y.ideal_temp_min_c = 18.0
	y.ideal_temp_max_c = 22.0
	y.attenuation_pct = 75.0
	y.flavor_profile = {"bitterness": 0.0, "sweetness": 0.1, "roastiness": 0.0, "fruitiness": 0.2, "funkiness": 0.0}
	return y

func test_execute_brew_result_has_failure_keys() -> void:
	GameState.reset()
	GameState.balance = 5000.0
	GameState.current_style = _make_test_style()
	GameState.current_recipe = {"malts": [_make_test_malt()], "hops": [_make_test_hop()], "yeast": _make_test_yeast(), "adjuncts": []}
	var sliders: Dictionary = {"mashing": 65.0, "boiling": 60.0, "fermenting": 20.0}
	var result: Dictionary = GameState.execute_brew(sliders)
	assert_has(result, "infected", "Brew result should have infected flag")
	assert_has(result, "off_flavor_tags", "Brew result should have off_flavor_tags")
	assert_has(result, "failure_messages", "Brew result should have failure_messages")

func test_execute_brew_perfect_stats_preserves_score() -> void:
	GameState.reset()
	GameState.balance = 5000.0
	GameState.sanitation_quality = 100
	GameState.temp_control_quality = 100
	GameState.current_style = _make_test_style()
	GameState.current_recipe = {"malts": [_make_test_malt()], "hops": [_make_test_hop()], "yeast": _make_test_yeast(), "adjuncts": []}
	var sliders: Dictionary = {"mashing": 65.0, "boiling": 60.0, "fermenting": 20.0}
	var result: Dictionary = GameState.execute_brew(sliders)
	assert_false(result["infected"], "Perfect sanitation should not cause infection")
	assert_eq(result["off_flavor_tags"].size(), 0, "Perfect temp control should produce no off-flavors")
