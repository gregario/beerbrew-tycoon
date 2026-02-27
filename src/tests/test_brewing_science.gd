## Tests for Brewing Science system.
extends GutTest

# ---------------------------------------------------------------------------
# BeerStyle fields (from Task 1)
# ---------------------------------------------------------------------------

func test_beer_style_has_ideal_mash_temp_range():
	var style: BeerStyle = BeerStyle.new()
	style.ideal_mash_temp_min = 62.0
	style.ideal_mash_temp_max = 64.0
	assert_eq(style.ideal_mash_temp_min, 62.0)
	assert_eq(style.ideal_mash_temp_max, 64.0)

func test_beer_style_has_ideal_boil_range():
	var style: BeerStyle = BeerStyle.new()
	style.ideal_boil_min = 60.0
	style.ideal_boil_max = 90.0
	assert_eq(style.ideal_boil_min, 60.0)
	assert_eq(style.ideal_boil_max, 90.0)

# ---------------------------------------------------------------------------
# Fermentability curve
# ---------------------------------------------------------------------------

func test_low_mash_temp_gives_high_fermentability():
	var result: float = BrewingScience.calc_fermentability(62.0)
	assert_almost_eq(result, 0.82, 0.01, "62°C should give ~0.82 fermentability")

func test_high_mash_temp_gives_low_fermentability():
	var result: float = BrewingScience.calc_fermentability(69.0)
	assert_almost_eq(result, 0.57, 0.01, "69°C should give ~0.57 fermentability")

func test_mid_mash_temp_gives_mid_fermentability():
	var result: float = BrewingScience.calc_fermentability(65.0)
	var expected: float = 0.82 - ((65.0 - 62.0) / 7.0 * 0.25)
	assert_almost_eq(result, expected, 0.01)

# ---------------------------------------------------------------------------
# Hop utilization
# ---------------------------------------------------------------------------

func test_long_boil_gives_high_bittering():
	var result: Dictionary = BrewingScience.calc_hop_utilization(90.0, 6.0)
	assert_gt(result["bittering"], result["aroma"], "90 min boil should favor bittering")

func test_short_boil_gives_high_aroma():
	var result: Dictionary = BrewingScience.calc_hop_utilization(30.0, 6.0)
	assert_gt(result["aroma"], result["bittering"], "30 min boil should favor aroma")

func test_hop_util_scales_with_alpha_acid():
	var low_aa: Dictionary = BrewingScience.calc_hop_utilization(60.0, 4.0)
	var high_aa: Dictionary = BrewingScience.calc_hop_utilization(60.0, 10.0)
	assert_gt(high_aa["bittering"], low_aa["bittering"], "Higher alpha acid = more bittering")

# ---------------------------------------------------------------------------
# Yeast accuracy
# ---------------------------------------------------------------------------

func _make_test_yeast(temp_min: float, temp_max: float) -> Yeast:
	var y := Yeast.new()
	y.ingredient_id = "test_yeast"
	y.ideal_temp_min_c = temp_min
	y.ideal_temp_max_c = temp_max
	return y

func test_ferment_temp_in_ideal_range_gives_full_bonus():
	var yeast := _make_test_yeast(18.0, 22.0)
	var result: Dictionary = BrewingScience.calc_yeast_accuracy(20.0, yeast)
	assert_eq(result["quality_bonus"], 1.0, "In-range temp should give 1.0 bonus")
	assert_eq(result["off_flavors"].size(), 0, "No off-flavors in ideal range")

func test_ferment_temp_slightly_outside_gives_mild_penalty():
	var yeast := _make_test_yeast(18.0, 22.0)
	var result: Dictionary = BrewingScience.calc_yeast_accuracy(24.0, yeast)
	assert_almost_eq(result["quality_bonus"], 0.85, 0.01, "1-2°C outside should give 0.85")

func test_ferment_temp_far_above_gives_heavy_penalty():
	var yeast := _make_test_yeast(18.0, 22.0)
	var result: Dictionary = BrewingScience.calc_yeast_accuracy(25.0, yeast)
	assert_almost_eq(result["quality_bonus"], 0.6, 0.01, "3°C+ above should give 0.6")
	assert_true(result["off_flavors"].has("fruity_esters") or result["off_flavors"].has("fusel_alcohols"),
		"Should have ester or fusel off-flavors")

func test_ferment_temp_far_below_gives_heavy_penalty():
	var yeast := _make_test_yeast(18.0, 22.0)
	var result: Dictionary = BrewingScience.calc_yeast_accuracy(15.0, yeast)
	assert_almost_eq(result["quality_bonus"], 0.6, 0.01, "3°C+ below should give 0.6")
	assert_true(result["off_flavors"].has("stalled_ferment"),
		"Should have stalling off-flavor")

# ---------------------------------------------------------------------------
# Equipment noise
# ---------------------------------------------------------------------------

func test_garage_equipment_adds_drift():
	var drift: float = BrewingScience.calc_temp_drift(50)
	assert_almost_eq(absf(drift), 0.0, 2.01, "Garage drift should be within ±2°C")

func test_perfect_equipment_no_drift():
	var drift: float = BrewingScience.calc_temp_drift(100)
	assert_eq(drift, 0.0, "Perfect equipment should have no drift")

# ---------------------------------------------------------------------------
# Stochastic noise
# ---------------------------------------------------------------------------

func test_stochastic_noise_within_bounds():
	for i in range(20):
		var noised: float = BrewingScience.apply_noise(1.0, i)
		assert_gte(noised, 0.95, "Noised value should be >= 0.95")
		assert_lte(noised, 1.05, "Noised value should be <= 1.05")

func test_same_seed_gives_same_noise():
	var a: float = BrewingScience.apply_noise(1.0, 42)
	var b: float = BrewingScience.apply_noise(1.0, 42)
	assert_eq(a, b, "Same seed should produce same noise")

# ---------------------------------------------------------------------------
# Mash temp scoring
# ---------------------------------------------------------------------------

func test_mash_score_perfect_temp():
	var style := BeerStyle.new()
	style.ideal_mash_temp_min = 66.0
	style.ideal_mash_temp_max = 68.0
	var score: float = BrewingScience.calc_mash_score(67.0, style)
	assert_almost_eq(score, 1.0, 0.01, "Temp in ideal range should score 1.0")

func test_mash_score_outside_range():
	var style := BeerStyle.new()
	style.ideal_mash_temp_min = 66.0
	style.ideal_mash_temp_max = 68.0
	var score: float = BrewingScience.calc_mash_score(62.0, style)
	assert_lt(score, 0.6, "Temp far outside ideal should score low")

# ---------------------------------------------------------------------------
# Boil duration scoring
# ---------------------------------------------------------------------------

func test_boil_score_perfect_duration():
	var style := BeerStyle.new()
	style.ideal_boil_min = 60.0
	style.ideal_boil_max = 90.0
	var score: float = BrewingScience.calc_boil_score(70.0, style)
	assert_almost_eq(score, 1.0, 0.01, "Duration in ideal range should score 1.0")

func test_boil_score_outside_range():
	var style := BeerStyle.new()
	style.ideal_boil_min = 60.0
	style.ideal_boil_max = 90.0
	var score: float = BrewingScience.calc_boil_score(30.0, style)
	assert_lt(score, 0.6, "Duration far outside ideal should score low")

# ---------------------------------------------------------------------------
# Integration: full brew flow with brewing science
# ---------------------------------------------------------------------------

func _make_full_style() -> BeerStyle:
	var s := BeerStyle.new()
	s.style_id = "test_ipa"
	s.style_name = "IPA"
	s.ideal_flavor_ratio = 0.55
	s.base_price = 200.0
	s.preferred_ingredients = {"pale_malt": 0.9, "cascade": 0.95, "us05_clean_ale": 0.9}
	s.ideal_flavor_profile = {"bitterness": 0.6, "sweetness": 0.2, "roastiness": 0.1, "fruitiness": 0.5, "funkiness": 0.0}
	s.ideal_mash_temp_min = 63.0
	s.ideal_mash_temp_max = 66.0
	s.ideal_boil_min = 60.0
	s.ideal_boil_max = 90.0
	return s

func _make_full_recipe() -> Dictionary:
	var malt := Malt.new()
	malt.ingredient_id = "pale_malt"
	malt.ingredient_name = "Pale Malt"
	malt.category = Ingredient.Category.MALT
	malt.cost = 20
	malt.flavor_profile = {"bitterness": 0.1, "sweetness": 0.2, "roastiness": 0.1, "fruitiness": 0.1, "funkiness": 0.0}
	malt.is_base_malt = true

	var hop := Hop.new()
	hop.ingredient_id = "cascade"
	hop.ingredient_name = "Cascade"
	hop.category = Ingredient.Category.HOP
	hop.cost = 25
	hop.alpha_acid_pct = 6.0
	hop.aroma_intensity = 0.8
	hop.variety_family = "american"
	hop.flavor_profile = {"bitterness": 0.4, "sweetness": 0.0, "roastiness": 0.0, "fruitiness": 0.6, "funkiness": 0.0}

	var yeast := Yeast.new()
	yeast.ingredient_id = "us05_clean_ale"
	yeast.ingredient_name = "US-05"
	yeast.category = Ingredient.Category.YEAST
	yeast.cost = 15
	yeast.ideal_temp_min_c = 15.0
	yeast.ideal_temp_max_c = 24.0
	yeast.flavor_profile = {"bitterness": 0.0, "sweetness": 0.1, "roastiness": 0.0, "fruitiness": 0.05, "funkiness": 0.0}

	return {"malts": [malt], "hops": [hop], "yeast": yeast, "adjuncts": []}

func test_brew_attributes_detected_for_ipa():
	var yeast := Yeast.new()
	yeast.ideal_temp_min_c = 15.0
	yeast.ideal_temp_max_c = 24.0
	var hop := Hop.new()
	hop.variety_family = "american"
	var attrs: Array[String] = BrewingScience.detect_brew_attributes(63.0, 40.0, 20.0, yeast, [hop])
	assert_has(attrs, "dry_body", "63C should produce dry body")
	assert_has(attrs, "citrus_aroma", "Short boil + american hop = citrus aroma")
	assert_has(attrs, "clean_ferment", "20C in range 15-24 = clean")

func test_quality_includes_science_and_attributes():
	var style := _make_full_style()
	var recipe := _make_full_recipe()
	var sliders := {"mashing": 65.0, "boiling": 70.0, "fermenting": 20.0}
	var result: Dictionary = QualityCalculator.calculate_quality(style, recipe, sliders, [])
	assert_has(result, "science_score", "Result should include science score")
	assert_has(result, "brew_attributes", "Result should include brew attributes")
	assert_gt(result["science_score"], 0.0, "Science score should be positive")
	assert_gt(result["brew_attributes"].size(), 0, "Should detect some attributes")

func test_full_brew_flow_produces_tasting_notes():
	GameState.reset()
	GameState.general_taste = 3
	var style := _make_full_style()
	var recipe := _make_full_recipe()
	var sliders := {"mashing": 65.0, "boiling": 70.0, "fermenting": 20.0}
	var result: Dictionary = QualityCalculator.calculate_quality(style, recipe, sliders, [])
	var brew_attrs: Array[String] = []
	var raw_attrs: Array = result.get("brew_attributes", [])
	for attr in raw_attrs:
		brew_attrs.append(str(attr))
	var notes: String = TasteSystem.generate_tasting_notes(
		brew_attrs, "IPA", sliders
	)
	assert_true(notes.length() > 0, "Should generate tasting notes")
