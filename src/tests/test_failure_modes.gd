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
