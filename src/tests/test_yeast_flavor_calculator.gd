extends GutTest

func _make_yeast_with_profile(profile: Dictionary) -> Yeast:
	var y := Yeast.new()
	y.ingredient_id = "test_yeast"
	y.yeast_flavor_profile = profile
	return y

# --- Temperature range matching ---

func test_wheat_yeast_cool_favors_clove():
	var y = load("res://data/ingredients/yeast/wb06_wheat.tres") as Yeast
	var flavors := BrewingScience.calc_yeast_flavors(16.0, y)
	assert_gt(flavors.get("phenol_clove", 0.0), flavors.get("ester_banana", 0.0),
		"Cool wheat yeast should favor clove over banana")

func test_wheat_yeast_warm_favors_banana():
	var y = load("res://data/ingredients/yeast/wb06_wheat.tres") as Yeast
	var flavors := BrewingScience.calc_yeast_flavors(24.0, y)
	assert_gt(flavors.get("ester_banana", 0.0), flavors.get("phenol_clove", 0.0),
		"Warm wheat yeast should favor banana over clove")

func test_saison_high_temp_no_fusel():
	var y = load("res://data/ingredients/yeast/belle_saison.tres") as Yeast
	var flavors := BrewingScience.calc_yeast_flavors(30.0, y)
	assert_eq(flavors.get("fusel", 0.0), 0.0,
		"Saison at high temp should NOT produce fusel")
	assert_gt(flavors.get("phenol_pepper", 0.0), 0.5,
		"Saison at high temp should produce strong pepper")

func test_lager_warm_produces_fusel():
	var y = load("res://data/ingredients/yeast/w3470_lager.tres") as Yeast
	var flavors := BrewingScience.calc_yeast_flavors(18.0, y)
	assert_gt(flavors.get("fusel", 0.0), 0.0,
		"Lager yeast above 14C should produce fusel")

func test_lager_cold_is_clean():
	var y = load("res://data/ingredients/yeast/w3470_lager.tres") as Yeast
	var flavors := BrewingScience.calc_yeast_flavors(10.0, y)
	assert_gt(flavors.get("clean", 0.0), 0.9,
		"Lager yeast at 10C should be very clean")

func test_us05_forgiving_range():
	var y = load("res://data/ingredients/yeast/us05_clean_ale.tres") as Yeast
	var flavors_16 := BrewingScience.calc_yeast_flavors(18.0, y)
	var flavors_20 := BrewingScience.calc_yeast_flavors(20.0, y)
	assert_gt(flavors_16.get("clean", 0.0), 0.8,
		"US-05 at 18C should be clean")
	assert_gt(flavors_20.get("clean", 0.0), 0.8,
		"US-05 at 20C should be clean")

func test_empty_profile_returns_clean():
	var y := _make_yeast_with_profile({})
	var flavors := BrewingScience.calc_yeast_flavors(20.0, y)
	assert_eq(flavors.get("clean", 0.0), 1.0,
		"Empty profile should default to clean")

func test_range_matching_below():
	assert_true(BrewingScience._temp_matches_range(15.0, "below_18"))
	assert_false(BrewingScience._temp_matches_range(18.0, "below_18"))
	assert_false(BrewingScience._temp_matches_range(20.0, "below_18"))

func test_range_matching_above():
	assert_true(BrewingScience._temp_matches_range(25.0, "above_22"))
	assert_true(BrewingScience._temp_matches_range(22.0, "above_22"))
	assert_false(BrewingScience._temp_matches_range(20.0, "above_22"))

func test_range_matching_between():
	assert_true(BrewingScience._temp_matches_range(20.0, "18_to_22"))
	assert_true(BrewingScience._temp_matches_range(18.0, "18_to_22"))
	assert_false(BrewingScience._temp_matches_range(22.0, "18_to_22"))
	assert_false(BrewingScience._temp_matches_range(17.0, "18_to_22"))
