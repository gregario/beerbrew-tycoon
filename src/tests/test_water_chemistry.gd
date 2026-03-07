extends GutTest

## Tests for water chemistry integration: GameState water profile, QualityCalculator scoring.

# --- Helper: minimal BeerStyle ---
func _make_style(id: String = "pale_ale") -> BeerStyle:
	var s := BeerStyle.new()
	s.style_id = id
	s.style_name = id.capitalize()
	s.ideal_flavor_ratio = 0.5
	s.base_price = 100.0
	s.ideal_flavor_profile = {
		"bitterness": 0.5, "sweetness": 0.3,
		"roastiness": 0.1, "fruitiness": 0.3, "funkiness": 0.0
	}
	return s

# --- GameState tests ---

func test_gamestate_water_profile_defaults_to_null():
	assert_null(GameState.current_water_profile, "Water profile should default to null")

func test_gamestate_set_water_profile_persists():
	var wp := WaterProfile.new()
	wp.profile_id = "test"
	wp.display_name = "Test Water"
	GameState.set_water_profile(wp)
	assert_eq(GameState.current_water_profile, wp, "Water profile should persist after set")
	# Cleanup
	GameState.current_water_profile = null

func test_gamestate_reset_clears_water_profile():
	var wp := WaterProfile.new()
	wp.profile_id = "test"
	GameState.set_water_profile(wp)
	assert_not_null(GameState.current_water_profile)
	GameState.reset()
	assert_null(GameState.current_water_profile, "reset() should clear water profile to null")

# --- QualityCalculator water scoring tests ---

func test_water_score_default_tap_water_is_60():
	var style := _make_style("pale_ale")
	var score: float = QualityCalculator._compute_water_score(style, null)
	assert_eq(score, 60.0, "Null water profile (tap water) should score 60")

func test_water_score_with_matching_profile():
	var style := _make_style("pale_ale")
	var wp := WaterProfile.new()
	wp.profile_id = "hoppy"
	wp.style_affinities = {"pale_ale": 0.95}
	var score: float = QualityCalculator._compute_water_score(style, wp)
	assert_eq(score, 95.0, "Hoppy water for pale ale should score 95")

func test_water_score_with_poor_match():
	var style := _make_style("stout")
	var wp := WaterProfile.new()
	wp.profile_id = "soft"
	wp.style_affinities = {"stout": 0.4}
	var score: float = QualityCalculator._compute_water_score(style, wp)
	assert_eq(score, 40.0, "Soft water for stout should score 40")

func test_water_score_unknown_style_defaults_to_60():
	var style := _make_style("unknown_style_xyz")
	var wp := WaterProfile.new()
	wp.profile_id = "balanced"
	wp.style_affinities = {"pale_ale": 0.8}
	var score: float = QualityCalculator._compute_water_score(style, wp)
	assert_eq(score, 60.0, "Unknown style should fall back to 0.6 affinity (60 score)")

func test_perfect_water_scores_higher_than_wrong_water():
	var style := _make_style("ipa")
	var good_wp := WaterProfile.new()
	good_wp.profile_id = "hoppy"
	good_wp.style_affinities = {"ipa": 0.95}
	var bad_wp := WaterProfile.new()
	bad_wp.profile_id = "malty"
	bad_wp.style_affinities = {"ipa": 0.35}
	var good_score: float = QualityCalculator._compute_water_score(style, good_wp)
	var bad_score: float = QualityCalculator._compute_water_score(style, bad_wp)
	assert_gt(good_score, bad_score, "Perfect water match should score higher than wrong water")

func test_water_profile_affects_final_quality():
	var style := _make_style("pale_ale")
	var recipe := {"malts": [], "hops": [], "yeast": null, "adjuncts": []}
	var sliders := {"mashing": 65.0, "boiling": 60.0, "fermenting": 20.0}
	# With no water profile (tap = 60)
	var result_tap: Dictionary = QualityCalculator.calculate_quality(style, recipe, sliders, [], null)
	# With good water profile
	var wp := WaterProfile.new()
	wp.profile_id = "hoppy"
	wp.style_affinities = {"pale_ale": 0.95}
	var result_good: Dictionary = QualityCalculator.calculate_quality(style, recipe, sliders, [], wp)
	assert_gt(result_good["water_score"], result_tap["water_score"],
		"Good water profile should produce higher water_score than tap")
	# Final score should also differ (water is 10% weight)
	assert_gt(result_good["final_score"], result_tap["final_score"],
		"Good water should boost final score vs tap water")

func test_loaded_water_profile_scoring():
	var soft = load("res://data/water/soft.tres") as WaterProfile
	assert_not_null(soft)
	var style := _make_style("lager")
	# Soft water has lager affinity of 0.9
	var score: float = QualityCalculator._compute_water_score(style, soft)
	assert_eq(score, 90.0, "Soft water should score 90 for lager (affinity 0.9)")
