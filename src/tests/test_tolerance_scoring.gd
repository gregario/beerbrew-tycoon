extends GutTest

# ---------------------------------------------------------------------------
# Mash score tests — ±2°C flat zone
# ---------------------------------------------------------------------------

func test_mash_score_within_ideal_range():
	var style := BeerStyle.new()
	style.ideal_mash_temp_min = 64.0
	style.ideal_mash_temp_max = 66.0
	assert_eq(BrewingScience.calc_mash_score(65.0, style), 1.0)

func test_mash_score_within_flat_zone():
	var style := BeerStyle.new()
	style.ideal_mash_temp_min = 64.0
	style.ideal_mash_temp_max = 66.0
	# 62°C is ideal_min - 2 = within flat zone
	assert_eq(BrewingScience.calc_mash_score(62.0, style), 1.0, "2C below ideal min should be in flat zone")
	# 68°C is ideal_max + 2 = within flat zone
	assert_eq(BrewingScience.calc_mash_score(68.0, style), 1.0, "2C above ideal max should be in flat zone")

func test_mash_score_just_outside_flat_zone():
	var style := BeerStyle.new()
	style.ideal_mash_temp_min = 64.0
	style.ideal_mash_temp_max = 66.0
	# 61°C is 1°C beyond flat zone edge (62°C)
	var score := BrewingScience.calc_mash_score(61.0, style)
	assert_lt(score, 1.0, "1C beyond flat zone should be penalized")
	assert_gt(score, 0.5, "1C beyond flat zone should not be heavily penalized")

func test_mash_score_extreme_deviation():
	var style := BeerStyle.new()
	style.ideal_mash_temp_min = 64.0
	style.ideal_mash_temp_max = 66.0
	# 55°C is 7°C beyond flat zone edge — should be heavily penalized
	var score := BrewingScience.calc_mash_score(55.0, style)
	assert_lt(score, 0.2, "7C beyond flat zone should be severely penalized")

func test_mash_score_never_negative():
	var style := BeerStyle.new()
	style.ideal_mash_temp_min = 64.0
	style.ideal_mash_temp_max = 66.0
	assert_gte(BrewingScience.calc_mash_score(50.0, style), 0.0)

# ---------------------------------------------------------------------------
# Boil score tests — 45-90 min flat zone with DMS awareness
# ---------------------------------------------------------------------------

func test_boil_score_within_style_range():
	var style := BeerStyle.new()
	style.ideal_boil_min = 60.0
	style.ideal_boil_max = 90.0
	assert_eq(BrewingScience.calc_boil_score(75.0, style), 1.0)

func test_boil_score_flat_zone_non_pilsner():
	var style := BeerStyle.new()
	style.ideal_boil_min = 60.0
	style.ideal_boil_max = 90.0
	# 45 min is within flat zone for non-pilsner
	assert_eq(BrewingScience.calc_boil_score(45.0, style, false), 1.0, "45min should be in flat zone for non-pilsner")
	# 50 min also in flat zone
	assert_eq(BrewingScience.calc_boil_score(50.0, style, false), 1.0, "50min should be in flat zone")

func test_boil_score_short_boil_non_pilsner():
	var style := BeerStyle.new()
	style.ideal_boil_min = 60.0
	style.ideal_boil_max = 90.0
	# 30 min is 15 min below flat zone for non-pilsner
	var score := BrewingScience.calc_boil_score(30.0, style, false)
	assert_lt(score, 1.0, "30min should be penalized even for non-pilsner")
	assert_gt(score, 0.5, "30min should not be heavily penalized for non-pilsner")

func test_boil_score_pilsner_no_flat_zone():
	var style := BeerStyle.new()
	style.ideal_boil_min = 75.0
	style.ideal_boil_max = 90.0
	# 50 min — for pilsner, no flat zone, so 25 min below ideal_min
	var score := BrewingScience.calc_boil_score(50.0, style, true)
	assert_lt(score, 1.0, "Short boil with pilsner malt should be penalized")

func test_boil_score_pilsner_within_range():
	var style := BeerStyle.new()
	style.ideal_boil_min = 75.0
	style.ideal_boil_max = 90.0
	assert_eq(BrewingScience.calc_boil_score(80.0, style, true), 1.0, "In-range boil for pilsner should score 1.0")

func test_boil_score_never_negative():
	var style := BeerStyle.new()
	style.ideal_boil_min = 60.0
	style.ideal_boil_max = 90.0
	assert_gte(BrewingScience.calc_boil_score(0.0, style), 0.0)
