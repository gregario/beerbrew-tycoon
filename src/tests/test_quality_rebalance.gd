## Tests for QualityCalculator 7-component rebalance.
extends GutTest

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

var _default_fp := {"bitterness": 0.0, "sweetness": 0.0, "roastiness": 0.0, "fruitiness": 0.0, "funkiness": 0.0}

func _make_style(style_id: String, ideal_flavor_ratio: float, preferred: Dictionary = {}, ideal_fp: Dictionary = {"bitterness": 0.0, "sweetness": 0.0, "roastiness": 0.0, "fruitiness": 0.0, "funkiness": 0.0}) -> BeerStyle:
	var s := BeerStyle.new()
	s.style_id = style_id
	s.style_name = style_id
	s.ideal_flavor_ratio = ideal_flavor_ratio
	s.base_price = 200.0
	s.preferred_ingredients = preferred
	s.ideal_flavor_profile = ideal_fp
	return s

func _make_malt(id: String, flavor_profile: Dictionary) -> Malt:
	var m := Malt.new()
	m.ingredient_id = id
	m.ingredient_name = id
	m.category = Ingredient.Category.MALT
	m.cost = 20
	m.flavor_profile = flavor_profile
	m.is_base_malt = true
	return m

func _make_hop(id: String, flavor_profile: Dictionary) -> Hop:
	var h := Hop.new()
	h.ingredient_id = id
	h.ingredient_name = id
	h.category = Ingredient.Category.HOP
	h.cost = 25
	h.flavor_profile = flavor_profile
	return h

func _make_yeast(id: String, fp: Dictionary = {}, temp_min: float = 18.0, temp_max: float = 22.0) -> Yeast:
	var y := Yeast.new()
	y.ingredient_id = id
	y.ingredient_name = id
	y.category = Ingredient.Category.YEAST
	y.cost = 15
	y.flavor_profile = fp if not fp.is_empty() else _default_fp
	y.ideal_temp_min_c = temp_min
	y.ideal_temp_max_c = temp_max
	return y

func _make_neutral_recipe() -> Dictionary:
	return {
		"malts": [_make_malt("pale_malt", _default_fp)],
		"hops": [_make_hop("centennial", _default_fp)],
		"yeast": _make_yeast("ale_yeast"),
		"adjuncts": [],
	}

func _mid_sliders() -> Dictionary:
	return {"mashing": 65.5, "boiling": 60.0, "fermenting": 20.0}

# ---------------------------------------------------------------------------
# Tests: weight constants
# ---------------------------------------------------------------------------

func test_weights_sum_to_one():
	var total: float = (
		QualityCalculator.WEIGHT_STYLE +
		QualityCalculator.WEIGHT_FERMENTATION +
		QualityCalculator.WEIGHT_SCIENCE +
		QualityCalculator.WEIGHT_WATER +
		QualityCalculator.WEIGHT_HOP_SCHEDULE +
		QualityCalculator.WEIGHT_NOVELTY +
		QualityCalculator.WEIGHT_CONDITIONING
	)
	assert_almost_eq(total, 1.0, 0.001, "7 component weights must sum to 1.0")

# ---------------------------------------------------------------------------
# Tests: fermentation component
# ---------------------------------------------------------------------------

func test_perfect_ferment_scores_high():
	var style := _make_style("test", 0.5)
	var yeast := _make_yeast("ale", _default_fp, 18.0, 22.0)
	var recipe := _make_neutral_recipe()
	recipe["yeast"] = yeast
	# 20°C is perfectly in range for yeast (18-22)
	var sliders := {"mashing": 65.5, "boiling": 60.0, "fermenting": 20.0}
	var result := QualityCalculator.calculate_quality(style, recipe, sliders, [])
	# accuracy=1.0, desirability=0.7 (default, no yeast_temp_flavors), stability=0.6
	# = (1.0*0.4 + 0.7*0.4 + 0.6*0.2) * 100 = (0.4+0.28+0.12)*100 = 80
	assert_gte(result["fermentation_score"], 75.0, "Perfect ferment should score >= 75")

func test_bad_ferment_scores_low():
	var style := _make_style("test", 0.5)
	var yeast := _make_yeast("ale", _default_fp, 18.0, 22.0)
	var recipe := _make_neutral_recipe()
	recipe["yeast"] = yeast
	# 28°C is way outside range (18-22), distance=6 -> quality_bonus=0.6
	var sliders := {"mashing": 65.5, "boiling": 60.0, "fermenting": 28.0}
	var result := QualityCalculator.calculate_quality(style, recipe, sliders, [])
	# accuracy=0.6, desirability=0.7 (default), stability=0.6
	# = (0.6*0.4 + 0.7*0.4 + 0.6*0.2) * 100 = (0.24+0.28+0.12)*100 = 64
	assert_lt(result["fermentation_score"], result["fermentation_score"] + 1.0)
	# Compare: bad ferment should score lower than perfect
	var good_sliders := {"mashing": 65.5, "boiling": 60.0, "fermenting": 20.0}
	var good_result := QualityCalculator.calculate_quality(style, recipe, good_sliders, [])
	assert_lt(result["fermentation_score"], good_result["fermentation_score"],
		"Bad ferment temp should score lower than perfect")

# ---------------------------------------------------------------------------
# Tests: flavor compound scoring
# ---------------------------------------------------------------------------

func test_flavor_compounds_matching_scores_high():
	var style := _make_style("hefeweizen", 0.6)
	style.yeast_temp_flavors = {"ester_banana": 0.8, "phenol_clove": 0.5}
	# When compounds match desired intensities, score should be near 1.0
	var score: float = QualityCalculator._score_flavor_compounds(
		{"ester_banana": 0.8, "phenol_clove": 0.5},
		style
	)
	assert_almost_eq(score, 1.0, 0.01, "Matching compounds should score ~1.0")

func test_flavor_compounds_mismatched_scores_lower():
	var style := _make_style("hefeweizen", 0.6)
	style.yeast_temp_flavors = {"ester_banana": 0.8, "phenol_clove": 0.5}
	var good_score: float = QualityCalculator._score_flavor_compounds(
		{"ester_banana": 0.8, "phenol_clove": 0.5},
		style
	)
	var bad_score: float = QualityCalculator._score_flavor_compounds(
		{"ester_banana": 0.0, "phenol_clove": 0.0},
		style
	)
	assert_gt(good_score, bad_score, "Matching compounds should score higher than mismatched")

func test_flavor_compounds_empty_style_returns_default():
	var style := _make_style("test", 0.5)
	# style.yeast_temp_flavors is empty by default
	var score: float = QualityCalculator._score_flavor_compounds(
		{"clean": 1.0},
		style
	)
	assert_almost_eq(score, 0.7, 0.01, "Empty style expectations should return 0.7 default")

# ---------------------------------------------------------------------------
# Tests: water component
# ---------------------------------------------------------------------------

func test_water_default_returns_60():
	var style := _make_style("test", 0.5)
	var result := QualityCalculator.calculate_quality(style, _make_neutral_recipe(), _mid_sliders(), [])
	assert_almost_eq(result["water_score"], 60.0, 0.1, "Default water (null) should be 60")

func test_water_with_profile_uses_affinity():
	var style := _make_style("ipa", 0.5)
	var wp := WaterProfile.new()
	wp.profile_id = "hoppy"
	wp.style_affinities = {"ipa": 0.9}
	var result := QualityCalculator.calculate_quality(
		style, _make_neutral_recipe(), _mid_sliders(), [], wp
	)
	assert_almost_eq(result["water_score"], 90.0, 0.1, "Hoppy water for IPA should score 90")

func test_water_profile_unknown_style_returns_default():
	var style := _make_style("unknown_style", 0.5)
	var wp := WaterProfile.new()
	wp.profile_id = "soft"
	wp.style_affinities = {"pilsner": 0.95}
	var result := QualityCalculator.calculate_quality(
		style, _make_neutral_recipe(), _mid_sliders(), [], wp
	)
	# WaterProfile.get_affinity defaults to 0.6 for unknown styles
	assert_almost_eq(result["water_score"], 60.0, 0.1, "Unknown style affinity should default to 60")

# ---------------------------------------------------------------------------
# Tests: hop schedule component
# ---------------------------------------------------------------------------

func test_hop_schedule_empty_returns_50():
	var style := _make_style("test", 0.5)
	var result := QualityCalculator.calculate_quality(style, _make_neutral_recipe(), _mid_sliders(), [])
	assert_almost_eq(result["hop_schedule_score"], 50.0, 0.1, "Empty allocations should score 50")

func test_hop_schedule_matching_scores_higher():
	var style := _make_style("ipa", 0.5)
	style.hop_schedule_expectations = {"bittering": 0.3, "aroma": 0.5, "dry_hop": 0.2}
	var hop_alloc := {"cascade": "aroma", "centennial": "bittering"}
	var result := QualityCalculator.calculate_quality(
		style, _make_neutral_recipe(), _mid_sliders(), [], null, hop_alloc
	)
	# 2 hops, both match expected slots -> 100
	assert_almost_eq(result["hop_schedule_score"], 100.0, 0.1,
		"All matching slots should score 100")

func test_hop_schedule_no_style_expectations_returns_70():
	var style := _make_style("test", 0.5)
	# style.hop_schedule_expectations is empty by default
	var hop_alloc := {"cascade": "aroma"}
	var result := QualityCalculator.calculate_quality(
		style, _make_neutral_recipe(), _mid_sliders(), [], null, hop_alloc
	)
	assert_almost_eq(result["hop_schedule_score"], 70.0, 0.1,
		"No style expectations with allocations should score 70")

# ---------------------------------------------------------------------------
# Tests: conditioning component
# ---------------------------------------------------------------------------

func test_conditioning_zero_weeks():
	var style := _make_style("test", 0.5)
	var result := QualityCalculator.calculate_quality(style, _make_neutral_recipe(), _mid_sliders(), [])
	assert_almost_eq(result["conditioning_score"], 0.0, 0.1, "0 weeks conditioning should score 0")

func test_conditioning_scales_per_week():
	var style := _make_style("test", 0.5)
	var r1 := QualityCalculator.calculate_quality(style, _make_neutral_recipe(), _mid_sliders(), [], null, {}, 1)
	var r2 := QualityCalculator.calculate_quality(style, _make_neutral_recipe(), _mid_sliders(), [], null, {}, 2)
	var r4 := QualityCalculator.calculate_quality(style, _make_neutral_recipe(), _mid_sliders(), [], null, {}, 4)
	assert_almost_eq(r1["conditioning_score"], 25.0, 0.1, "1 week = 25")
	assert_almost_eq(r2["conditioning_score"], 50.0, 0.1, "2 weeks = 50")
	assert_almost_eq(r4["conditioning_score"], 100.0, 0.1, "4 weeks = 100 (max)")

func test_conditioning_capped_at_100():
	var style := _make_style("test", 0.5)
	var result := QualityCalculator.calculate_quality(
		style, _make_neutral_recipe(), _mid_sliders(), [], null, {}, 10
	)
	assert_almost_eq(result["conditioning_score"], 100.0, 0.1, "Conditioning should cap at 100")

# ---------------------------------------------------------------------------
# Tests: backward compatibility
# ---------------------------------------------------------------------------

func test_backward_compat_old_signature_works():
	var style := _make_style("test", 0.5)
	var recipe := _make_neutral_recipe()
	var sliders := _mid_sliders()
	# Call with only the original 4 params — should work fine
	var result := QualityCalculator.calculate_quality(style, recipe, sliders, [])
	assert_gte(result["final_score"], 0.0)
	assert_lte(result["final_score"], 100.0)
	assert_has(result, "ratio_score")
	assert_has(result, "ingredient_score")
	assert_has(result, "base_score")

func test_backward_compat_base_score_still_present():
	var style := _make_style("test", 0.5)
	var result := QualityCalculator.calculate_quality(style, _make_neutral_recipe(), _mid_sliders(), [])
	assert_has(result, "base_score")
	assert_gte(result["base_score"], 0.0)
	assert_lte(result["base_score"], 100.0)

# ---------------------------------------------------------------------------
# Tests: style match combines ratio and ingredients
# ---------------------------------------------------------------------------

func test_style_match_combines_ratio_and_ingredients():
	var style := _make_style("test", 0.5)
	var recipe := _make_neutral_recipe()
	var sliders := _mid_sliders()
	var result := QualityCalculator.calculate_quality(style, recipe, sliders, [])
	var expected: float = result["ratio_score"] * 0.5 + result["ingredient_score"] * 0.5
	assert_almost_eq(result["style_match"], expected, 0.01,
		"style_match should be ratio*0.5 + ingredient*0.5")

# ---------------------------------------------------------------------------
# Tests: all expected keys present
# ---------------------------------------------------------------------------

func test_all_expected_keys_present():
	var style := _make_style("test", 0.5)
	var recipe := _make_neutral_recipe()
	var result := QualityCalculator.calculate_quality(style, recipe, _mid_sliders(), [])
	var expected_keys := [
		"final_score", "style_match", "ratio_score", "ingredient_score",
		"fermentation_score", "science_score", "water_score", "hop_schedule_score",
		"novelty_score", "conditioning_score", "base_score",
		"total_flavor_points", "total_technique_points", "novelty_modifier",
		"brew_attributes",
	]
	for key in expected_keys:
		assert_has(result, key, "Result should contain key: %s" % key)

# ---------------------------------------------------------------------------
# Tests: science score now focuses on mash + boil only
# ---------------------------------------------------------------------------

func test_science_score_mash_boil_only():
	var style := _make_style("test", 0.5)
	style.ideal_mash_temp_min = 64.0
	style.ideal_mash_temp_max = 66.0
	style.ideal_boil_min = 50.0
	style.ideal_boil_max = 70.0
	var recipe := _make_neutral_recipe()
	# Perfect mash (65.0 in 64-66+2 tolerance) and perfect boil (60.0 in 45-90 flat zone)
	var sliders := {"mashing": 65.0, "boiling": 60.0, "fermenting": 20.0}
	var result := QualityCalculator.calculate_quality(style, recipe, sliders, [])
	# mash=1.0*50 + boil=1.0*50 = 100
	assert_gte(result["science_score"], 95.0,
		"Perfect mash and boil should give high science score")

func test_science_score_unaffected_by_ferment_temp():
	var style := _make_style("test", 0.5)
	style.ideal_mash_temp_min = 64.0
	style.ideal_mash_temp_max = 66.0
	var recipe := _make_neutral_recipe()
	# Same mash/boil, different ferment temps
	var good_ferment := {"mashing": 65.0, "boiling": 60.0, "fermenting": 20.0}
	var bad_ferment := {"mashing": 65.0, "boiling": 60.0, "fermenting": 28.0}
	var r1 := QualityCalculator.calculate_quality(style, recipe, good_ferment, [])
	var r2 := QualityCalculator.calculate_quality(style, recipe, bad_ferment, [])
	assert_almost_eq(r1["science_score"], r2["science_score"], 0.01,
		"Science score should not depend on fermentation temperature")
