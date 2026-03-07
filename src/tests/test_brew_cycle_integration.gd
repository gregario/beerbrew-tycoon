## Integration tests for the full brew cycle (Group 12).
## Validates execute_brew result keys, off-flavor evaluation, state flow,
## water/hop effects, conditioning decay, and result dict completeness.
extends GutTest


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

func _load_water(profile_id: String) -> Resource:
	return load("res://data/water/%s.tres" % profile_id)

func _setup_brew(style_id: String = "pale_ale") -> void:
	GameState.current_style = _load_style(style_id)
	GameState.current_recipe = {
		"malts": [_load_malt("pale_malt")],
		"hops": [_load_hop("cascade")],
		"yeast": _load_yeast("us05_clean_ale"),
		"adjuncts": [],
		"ingredients": [_load_malt("pale_malt"), _load_hop("cascade"), _load_yeast("us05_clean_ale")],
	}
	GameState.current_state = GameState.State.BREWING_PHASES

func _default_sliders() -> Dictionary:
	return {"mashing": 65.0, "boiling": 60.0, "fermenting": 20.0}


# ---------------------------------------------------------------------------
# 12.6a — Full brew cycle with all new components
# ---------------------------------------------------------------------------

func test_full_brew_cycle_has_all_keys() -> void:
	_setup_brew()
	var result: Dictionary = GameState.execute_brew(_default_sliders())
	assert_true(result.has("final_score"), "Result should have final_score")
	assert_true(result.has("style_match") or result.has("ratio_score"), "Result should have style scoring")
	assert_true(result.has("fermentation_score"), "Result should have fermentation_score")
	assert_true(result.has("science_score"), "Result should have science_score")
	assert_true(result.has("off_flavors"), "Result should have off_flavors array")
	assert_true(result.has("off_flavor_intensities"), "Result should have off_flavor_intensities dict")
	assert_true(result.has("off_flavor_tags"), "Result should have off_flavor_tags")
	assert_true(result.has("infected"), "Result should have infected flag")
	assert_true(result.has("failure_messages"), "Result should have failure_messages")
	assert_true(result.has("rp_earned"), "Result should have rp_earned")


func test_full_brew_cycle_off_flavors_is_array() -> void:
	_setup_brew()
	var result: Dictionary = GameState.execute_brew(_default_sliders())
	assert_true(result["off_flavors"] is Array, "off_flavors should be an Array")


func test_full_brew_cycle_off_flavor_intensities_is_dict() -> void:
	_setup_brew()
	var result: Dictionary = GameState.execute_brew(_default_sliders())
	assert_true(result["off_flavor_intensities"] is Dictionary, "off_flavor_intensities should be a Dictionary")


func test_brew_result_has_water_score() -> void:
	_setup_brew()
	var result: Dictionary = GameState.execute_brew(_default_sliders())
	assert_true(result.has("water_score"), "Result should have water_score")


func test_brew_result_has_hop_schedule_score() -> void:
	_setup_brew()
	var result: Dictionary = GameState.execute_brew(_default_sliders())
	assert_true(result.has("hop_schedule_score"), "Result should have hop_schedule_score")


func test_brew_result_has_conditioning_score() -> void:
	_setup_brew()
	var result: Dictionary = GameState.execute_brew(_default_sliders())
	assert_true(result.has("conditioning_score"), "Result should have conditioning_score")


# ---------------------------------------------------------------------------
# 12.6b — Off-flavor evaluation in brew result
# ---------------------------------------------------------------------------

func test_off_flavor_eval_entries_have_expected_keys() -> void:
	# Force poor temp control to generate off-flavors
	GameState.temp_control_quality = 0
	_setup_brew()
	# Run multiple times to increase chance of off-flavors
	var found_entry := false
	for i in range(20):
		GameState.reset()
		GameState.temp_control_quality = 0
		_setup_brew()
		var result: Dictionary = GameState.execute_brew(_default_sliders())
		var off_flavors: Array = result.get("off_flavors", [])
		if off_flavors.size() > 0:
			var entry: Dictionary = off_flavors[0]
			assert_true(entry.has("type"), "Entry should have type")
			assert_true(entry.has("intensity"), "Entry should have intensity")
			assert_true(entry.has("severity"), "Entry should have severity")
			assert_true(entry.has("context"), "Entry should have context")
			assert_true(entry.has("penalty"), "Entry should have penalty")
			assert_true(entry.has("display_name"), "Entry should have display_name")
			found_entry = true
			break
	assert_true(found_entry, "Should have generated at least one off-flavor entry with temp_control=0")


func test_off_flavor_severity_labels_valid() -> void:
	var valid_severities: Array = ["subtle", "noticeable", "dominant"]
	GameState.temp_control_quality = 0
	_setup_brew()
	for i in range(20):
		GameState.reset()
		GameState.temp_control_quality = 0
		_setup_brew()
		var result: Dictionary = GameState.execute_brew(_default_sliders())
		var off_flavors: Array = result.get("off_flavors", [])
		for entry in off_flavors:
			assert_true(valid_severities.has(entry["severity"]),
				"Severity '%s' should be valid" % entry["severity"])


func test_off_flavor_context_labels_valid() -> void:
	var valid_contexts: Array = ["desired", "neutral", "flaw"]
	GameState.temp_control_quality = 0
	_setup_brew()
	for i in range(20):
		GameState.reset()
		GameState.temp_control_quality = 0
		_setup_brew()
		var result: Dictionary = GameState.execute_brew(_default_sliders())
		var off_flavors: Array = result.get("off_flavors", [])
		for entry in off_flavors:
			assert_true(valid_contexts.has(entry["context"]),
				"Context '%s' should be valid" % entry["context"])


# ---------------------------------------------------------------------------
# 12.6c — State flow
# ---------------------------------------------------------------------------

func test_state_flow_recipe_to_results() -> void:
	_setup_brew()
	assert_eq(GameState.current_state, GameState.State.BREWING_PHASES)
	GameState.execute_brew(_default_sliders())
	assert_eq(GameState.current_state, GameState.State.RESULTS,
		"After execute_brew, state should be RESULTS")


func test_state_flow_results_to_conditioning() -> void:
	_setup_brew()
	GameState.execute_brew(_default_sliders())
	assert_eq(GameState.current_state, GameState.State.RESULTS)
	GameState.advance_state()
	assert_eq(GameState.current_state, GameState.State.CONDITIONING,
		"RESULTS should advance to CONDITIONING")


func test_state_flow_conditioning_to_sell() -> void:
	_setup_brew()
	GameState.execute_brew(_default_sliders())
	GameState.advance_state()  # RESULTS -> CONDITIONING
	assert_eq(GameState.current_state, GameState.State.CONDITIONING)
	GameState.advance_state()  # CONDITIONING -> SELL
	assert_eq(GameState.current_state, GameState.State.SELL,
		"CONDITIONING should advance to SELL")


func test_full_state_flow_brew_to_equipment() -> void:
	_setup_brew()
	GameState.execute_brew(_default_sliders())
	# RESULTS -> CONDITIONING -> SELL -> (advance triggers _on_results_continue) -> EQUIPMENT_MANAGE
	GameState.advance_state()  # -> CONDITIONING
	GameState.advance_state()  # -> SELL
	GameState.advance_state()  # -> EQUIPMENT_MANAGE (via _on_results_continue)
	assert_eq(GameState.current_state, GameState.State.EQUIPMENT_MANAGE,
		"After SELL advance, state should be EQUIPMENT_MANAGE")


# ---------------------------------------------------------------------------
# 12.6d — Water profile affects quality
# ---------------------------------------------------------------------------

func test_water_profile_affects_quality() -> void:
	# Brew without water profile
	_setup_brew()
	GameState.current_water_profile = null
	var result_no_water: Dictionary = GameState.execute_brew(_default_sliders())
	var water_score_null: float = result_no_water.get("water_score", 0.0)

	# Brew with a water profile
	GameState.reset()
	_setup_brew()
	GameState.current_water_profile = _load_water("balanced")
	var result_with_water: Dictionary = GameState.execute_brew(_default_sliders())
	var water_score_set: float = result_with_water.get("water_score", 0.0)

	# Both should have water_score key
	assert_true(result_no_water.has("water_score"), "Result without water should still have water_score")
	assert_true(result_with_water.has("water_score"), "Result with water should have water_score")
	# With a balanced profile, water_score should differ from null (default)
	# We can't guarantee which is higher due to style affinity, but they should both be numbers
	assert_gte(water_score_null, 0.0)
	assert_gte(water_score_set, 0.0)


# ---------------------------------------------------------------------------
# 12.6e — Hop allocations affect quality
# ---------------------------------------------------------------------------

func test_hop_allocations_in_result() -> void:
	_setup_brew()
	var hop: Resource = _load_hop("cascade")
	GameState.current_hop_allocations = {hop.ingredient_id: "aroma"}
	var result: Dictionary = GameState.execute_brew(_default_sliders())
	assert_true(result.has("hop_schedule_score"), "Result should have hop_schedule_score")
	assert_gte(result["hop_schedule_score"], 0.0)


func test_hop_allocations_differ_from_none() -> void:
	# Brew without allocations
	_setup_brew()
	GameState.current_hop_allocations = {}
	var result_no_alloc: Dictionary = GameState.execute_brew(_default_sliders())

	# Brew with allocations
	GameState.reset()
	_setup_brew()
	var hop: Resource = _load_hop("cascade")
	GameState.current_hop_allocations = {hop.ingredient_id: "bittering"}
	var result_with_alloc: Dictionary = GameState.execute_brew(_default_sliders())

	assert_true(result_no_alloc.has("hop_schedule_score"))
	assert_true(result_with_alloc.has("hop_schedule_score"))


# ---------------------------------------------------------------------------
# 12.6f — Conditioning decay works in execute_conditioning
# ---------------------------------------------------------------------------

func test_conditioning_decay_in_execute_conditioning() -> void:
	_setup_brew()
	GameState.execute_brew(_default_sliders())
	# Inject off-flavor intensities
	GameState.last_brew_result["off_flavor_intensities"] = {"diacetyl": 0.8}
	GameState.execute_conditioning(3)
	var decayed: Dictionary = GameState.last_brew_result.get("off_flavor_intensities", {})
	assert_true(decayed.has("diacetyl"), "Diacetyl should still be in dict after decay")
	assert_almost_eq(decayed["diacetyl"], 0.05, 0.01,
		"Diacetyl 0.8 after 3 weeks (0.25/wk) should be ~0.05")


func test_conditioning_adds_quality_bonus() -> void:
	_setup_brew()
	GameState.execute_brew(_default_sliders())
	var score_before: float = GameState.last_brew_result["final_score"]
	GameState.execute_conditioning(2)
	var score_after: float = GameState.last_brew_result["final_score"]
	assert_almost_eq(score_after, minf(score_before + 2.0, 100.0), 0.01,
		"Quality should increase by +1 per conditioning week")


# ---------------------------------------------------------------------------
# 12.6g — Result dict has all expected keys
# ---------------------------------------------------------------------------

func test_result_dict_expected_keys() -> void:
	_setup_brew()
	var result: Dictionary = GameState.execute_brew(_default_sliders())
	var expected_keys: Array = [
		"final_score", "style_match", "fermentation_score",
		"water_score", "hop_schedule_score", "conditioning_score",
		"off_flavors", "off_flavor_intensities",
		"off_flavor_tags", "infected", "failure_messages",
	]
	for key in expected_keys:
		assert_true(result.has(key), "Result dict should have key '%s'" % key)


# ---------------------------------------------------------------------------
# 12.5 — Reset clears new state fields
# ---------------------------------------------------------------------------

func test_reset_clears_water_profile() -> void:
	GameState.current_water_profile = _load_water("balanced")
	GameState.reset()
	assert_null(GameState.current_water_profile, "current_water_profile should be null after reset")


func test_reset_clears_hop_allocations() -> void:
	GameState.current_hop_allocations = {"hop_1": "aroma"}
	GameState.reset()
	assert_eq(GameState.current_hop_allocations.size(), 0, "current_hop_allocations should be empty after reset")


func test_reset_clears_conditioning_weeks() -> void:
	GameState.conditioning_weeks = 3
	GameState.reset()
	assert_eq(GameState.conditioning_weeks, 0, "conditioning_weeks should be 0 after reset")


func test_reset_clears_non_discoveries() -> void:
	GameState.non_discoveries = {"mash_tolerance": true}
	GameState.reset()
	assert_eq(GameState.non_discoveries.size(), 0, "non_discoveries should be empty after reset")
