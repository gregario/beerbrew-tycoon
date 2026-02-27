## Tests for QualityCalculator autoload.
## Run with GUT: Tools -> GUT -> Run All
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

func _make_malt(id: String, flavor_profile: Dictionary, compat_unused := {}) -> Malt:
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

func _make_yeast_res(id: String, flavor_profile: Dictionary) -> Yeast:
	var y := Yeast.new()
	y.ingredient_id = id
	y.ingredient_name = id
	y.category = Ingredient.Category.YEAST
	y.cost = 15
	y.flavor_profile = flavor_profile
	return y

func _make_neutral_recipe(style_id: String) -> Dictionary:
	return {
		"malts": [_make_malt("pale_malt", _default_fp)],
		"hops": [_make_hop("centennial", _default_fp)],
		"yeast": _make_yeast_res("ale_yeast", _default_fp),
		"adjuncts": [],
	}

func _ideal_sliders_for(style: BeerStyle) -> Dictionary:
	# Approximation: solve for slider values that produce the style's ideal_flavor_ratio.
	# At equal sliders (50/50/50) the ratio = 0.5.
	# Lager needs ratio ~0.35 -> increase technique (mashing up, fermenting down).
	# This helper just returns midpoint sliders and lets tests check the logic.
	return {"mashing": 50.0, "boiling": 50.0, "fermenting": 50.0}

# ---------------------------------------------------------------------------
# Tests: ratio scoring
# ---------------------------------------------------------------------------

func test_perfect_ratio_scores_high():
	# Style with ideal_flavor_ratio = 0.5 (balanced).
	# At 50/50/50 sliders, total flavor = 75, total technique = 75 -> ratio = 0.5. Perfect.
	var style := _make_style("balanced", 0.5)
	var recipe := _make_neutral_recipe("balanced")
	var sliders := {"mashing": 50.0, "boiling": 50.0, "fermenting": 50.0}
	var result := QualityCalculator.calculate_quality(style, recipe, sliders, [])
	assert_gte(result["ratio_score"], 90.0, "Perfect ratio should score >= 90")

func test_poor_ratio_scores_low():
	# Style with ideal = 0.35 (technique-heavy), but player pushes all flavor (fermenting=100).
	var style := _make_style("lager_test", 0.35)
	var recipe := _make_neutral_recipe("lager_test")
	# All flavor: mashing=0, boiling=0, fermenting=100 -> flavor=70, technique=30 -> ratio=0.7
	# Deviation from ideal = |0.7 - 0.35| = 0.35 -> exactly at RATIO_TOLERANCE -> score = 0
	var sliders := {"mashing": 0.0, "boiling": 0.0, "fermenting": 100.0}
	var result := QualityCalculator.calculate_quality(style, recipe, sliders, [])
	assert_lte(result["ratio_score"], 10.0, "Poor ratio should score <= 10")

func test_four_styles_have_different_optimal_positions():
	# Each style's ideal ratio is distinct; confirm that scores at 50/50/50 differ.
	var styles := [
		_make_style("lager", 0.35),
		_make_style("pale_ale", 0.55),
		_make_style("wheat_beer", 0.65),
		_make_style("stout", 0.45),
	]
	var sliders := {"mashing": 50.0, "boiling": 50.0, "fermenting": 50.0}
	var scores := []
	for s in styles:
		var result := QualityCalculator.calculate_quality(s, _make_neutral_recipe(s.style_id), sliders, [])
		scores.append(result["ratio_score"])
	# They should not all be equal (except coincidentally near 0.5)
	# wheat_beer (0.65) at ratio 0.5 has higher deviation than pale_ale (0.55)
	assert_gt(scores[1], scores[0], "Pale Ale (0.55) closer to 0.5 than Lager (0.35)")
	assert_gt(scores[1], scores[2], "Pale Ale (0.55) closer to 0.5 than Wheat Beer (0.65)")

# ---------------------------------------------------------------------------
# Tests: ingredient compatibility
# ---------------------------------------------------------------------------

func test_high_compatibility_improves_score():
	# Good recipe: ingredients are in preferred_ingredients with high compat + matching flavor
	var preferred := {"good_malt": 0.9, "good_hop": 0.9, "good_yeast": 0.9,
		"bad_malt": 0.1, "bad_hop": 0.1, "bad_yeast": 0.1}
	var style := _make_style("test_style", 0.5, preferred)
	var sliders := {"mashing": 50.0, "boiling": 50.0, "fermenting": 50.0}

	var good_recipe := {
		"malts": [_make_malt("good_malt", _default_fp)],
		"hops": [_make_hop("good_hop", _default_fp)],
		"yeast": _make_yeast_res("good_yeast", _default_fp),
		"adjuncts": [],
	}
	var bad_recipe := {
		"malts": [_make_malt("bad_malt", _default_fp)],
		"hops": [_make_hop("bad_hop", _default_fp)],
		"yeast": _make_yeast_res("bad_yeast", _default_fp),
		"adjuncts": [],
	}

	var good_result := QualityCalculator.calculate_quality(style, good_recipe, sliders, [])
	var bad_result := QualityCalculator.calculate_quality(style, bad_recipe, sliders, [])

	assert_gt(good_result["ingredient_score"], bad_result["ingredient_score"],
		"Good ingredients should score higher than bad ones")

# ---------------------------------------------------------------------------
# Tests: novelty modifier
# ---------------------------------------------------------------------------

func test_first_brew_has_full_novelty():
	var style := _make_style("lager", 0.35)
	var recipe := _make_neutral_recipe("lager")
	var sliders := {"mashing": 50.0, "boiling": 50.0, "fermenting": 50.0}
	var result := QualityCalculator.calculate_quality(style, recipe, sliders, [])
	assert_eq(result["novelty_modifier"], 1.0, "First brew of a recipe should have 1.0 novelty")

func test_repeated_recipe_incurs_penalty():
	var style := _make_style("lager", 0.35)
	var recipe := _make_neutral_recipe("lager")
	var sliders := {"mashing": 50.0, "boiling": 50.0, "fermenting": 50.0}
	var history := [
		{"style_id": "lager", "malt_ids": ["pale_malt"], "hop_ids": ["centennial"], "yeast_id": "ale_yeast", "adjunct_ids": []},
		{"style_id": "lager", "malt_ids": ["pale_malt"], "hop_ids": ["centennial"], "yeast_id": "ale_yeast", "adjunct_ids": []},
	]
	var result := QualityCalculator.calculate_quality(style, recipe, sliders, history)
	# 2 prior repeats -> modifier = 1.0 - (2 * 0.15) = 0.70
	assert_eq(result["novelty_modifier"], 0.7,
		"After 2 repeats modifier should be 0.70")

func test_novelty_modifier_is_floored():
	var style := _make_style("lager", 0.35)
	var recipe := _make_neutral_recipe("lager")
	var sliders := {"mashing": 50.0, "boiling": 50.0, "fermenting": 50.0}
	# 10 repeats -> would be 1.0 - 1.5 = -0.5, but floored at 0.4
	var history := []
	for i in range(10):
		history.append({"style_id": "lager", "malt_ids": ["pale_malt"],
			"hop_ids": ["centennial"], "yeast_id": "ale_yeast", "adjunct_ids": []})
	var result := QualityCalculator.calculate_quality(style, recipe, sliders, history)
	assert_eq(result["novelty_modifier"], 0.4,
		"Novelty modifier should be floored at 0.4")

func test_different_ingredient_gets_no_penalty():
	var style := _make_style("lager", 0.35)
	var sliders := {"mashing": 50.0, "boiling": 50.0, "fermenting": 50.0}
	# History has lager + pale_malt + cascade + ale_yeast
	var history := [
		{"style_id": "lager", "malt_ids": ["pale_malt"], "hop_ids": ["cascade"], "yeast_id": "ale_yeast", "adjunct_ids": []},
	]
	# New recipe uses hallertau instead of cascade
	var recipe := {
		"malts": [_make_malt("pale_malt", _default_fp)],
		"hops": [_make_hop("hallertau", _default_fp)],
		"yeast": _make_yeast_res("ale_yeast", _default_fp),
		"adjuncts": [],
	}
	var result := QualityCalculator.calculate_quality(style, recipe, sliders, history)
	assert_eq(result["novelty_modifier"], 1.0,
		"Changed ingredient should not count as repeat")

# ---------------------------------------------------------------------------
# Tests: score breakdown
# ---------------------------------------------------------------------------

func test_result_has_all_expected_keys():
	var style := _make_style("test", 0.5)
	var recipe := _make_neutral_recipe("test")
	var sliders := {"mashing": 50.0, "boiling": 50.0, "fermenting": 50.0}
	var result := QualityCalculator.calculate_quality(style, recipe, sliders, [])
	assert_has(result, "final_score")
	assert_has(result, "ratio_score")
	assert_has(result, "ingredient_score")
	assert_has(result, "novelty_score")
	assert_has(result, "base_score")
	assert_has(result, "total_flavor_points")
	assert_has(result, "total_technique_points")
	assert_has(result, "novelty_modifier")

func test_final_score_within_valid_range():
	var style := _make_style("test", 0.5)
	var recipe := _make_neutral_recipe("test")
	var sliders := {"mashing": 50.0, "boiling": 50.0, "fermenting": 50.0}
	var result := QualityCalculator.calculate_quality(style, recipe, sliders, [])
	assert_gte(result["final_score"], 0.0, "Score must be >= 0")
	assert_lte(result["final_score"], 100.0, "Score must be <= 100")

# ---------------------------------------------------------------------------
# Tests: preferred ingredients and flavor profile matching
# ---------------------------------------------------------------------------

func test_preferred_ingredient_scores_higher():
	var style := _make_style("stout", 0.45,
		{"roasted_barley": 0.95, "pale_malt": 0.6},
		{"bitterness": 0.4, "sweetness": 0.3, "roastiness": 0.8, "fruitiness": 0.1, "funkiness": 0.0})
	var fp_roasty := {"bitterness": 0.3, "sweetness": 0.1, "roastiness": 0.9, "fruitiness": 0.0, "funkiness": 0.0}
	var good_recipe := {
		"malts": [_make_malt("roasted_barley", fp_roasty)],
		"hops": [_make_hop("ekg", _default_fp)],
		"yeast": _make_yeast_res("s04", _default_fp),
		"adjuncts": [],
	}
	var bad_recipe := {
		"malts": [_make_malt("unknown_malt", _default_fp)],
		"hops": [_make_hop("unknown_hop", _default_fp)],
		"yeast": _make_yeast_res("unknown_yeast", _default_fp),
		"adjuncts": [],
	}
	var sliders := {"mashing": 50.0, "boiling": 50.0, "fermenting": 50.0}
	var good_result := QualityCalculator.calculate_quality(style, good_recipe, sliders, [])
	var bad_result := QualityCalculator.calculate_quality(style, bad_recipe, sliders, [])
	assert_gt(good_result["ingredient_score"], bad_result["ingredient_score"],
		"Preferred ingredients should score higher")

func test_flavor_profile_match_scores_higher():
	var ideal_fp := {"bitterness": 0.4, "sweetness": 0.3, "roastiness": 0.8, "fruitiness": 0.1, "funkiness": 0.0}
	var style := _make_style("stout", 0.45, {}, ideal_fp)
	var matching_fp := {"bitterness": 0.4, "sweetness": 0.3, "roastiness": 0.8, "fruitiness": 0.1, "funkiness": 0.0}
	var mismatched_fp := {"bitterness": 0.0, "sweetness": 0.0, "roastiness": 0.0, "fruitiness": 0.9, "funkiness": 0.8}
	var good_recipe := {
		"malts": [_make_malt("m1", matching_fp)],
		"hops": [_make_hop("h1", matching_fp)],
		"yeast": _make_yeast_res("y1", matching_fp),
		"adjuncts": [],
	}
	var bad_recipe := {
		"malts": [_make_malt("m2", mismatched_fp)],
		"hops": [_make_hop("h2", mismatched_fp)],
		"yeast": _make_yeast_res("y2", mismatched_fp),
		"adjuncts": [],
	}
	var sliders := {"mashing": 50.0, "boiling": 50.0, "fermenting": 50.0}
	var good_result := QualityCalculator.calculate_quality(style, good_recipe, sliders, [])
	var bad_result := QualityCalculator.calculate_quality(style, bad_recipe, sliders, [])
	assert_gt(good_result["ingredient_score"], bad_result["ingredient_score"],
		"Matching flavor profile should score higher")
