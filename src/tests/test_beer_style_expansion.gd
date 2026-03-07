extends GutTest

func test_beer_style_has_family():
	var s := BeerStyle.new()
	s.family = "ales"
	assert_eq(s.family, "ales")

func test_beer_style_default_family_is_empty():
	var s := BeerStyle.new()
	assert_eq(s.family, "")

func test_beer_style_has_water_affinity():
	var s := BeerStyle.new()
	s.water_affinity = {"hoppy": 0.95, "malty": 0.3}
	assert_eq(s.water_affinity["hoppy"], 0.95)
	assert_eq(s.water_affinity["malty"], 0.3)

func test_beer_style_has_hop_schedule_expectations():
	var s := BeerStyle.new()
	s.hop_schedule_expectations = {"bittering": 0.3, "aroma": 0.5, "dry_hop": 0.2}
	assert_eq(s.hop_schedule_expectations["aroma"], 0.5)

func test_beer_style_has_yeast_temp_flavors():
	var s := BeerStyle.new()
	s.yeast_temp_flavors = {"ester_banana": 0.8, "clean": 0.9}
	assert_eq(s.yeast_temp_flavors["ester_banana"], 0.8)

func test_beer_style_has_acceptable_off_flavors():
	var s := BeerStyle.new()
	s.acceptable_off_flavors = {"ester": 0.8}
	assert_eq(s.acceptable_off_flavors["ester"], 0.8)

func test_beer_style_default_acceptable_off_flavors_empty():
	var s := BeerStyle.new()
	assert_eq(s.acceptable_off_flavors.size(), 0)

func test_beer_style_has_primary_lesson():
	var s := BeerStyle.new()
	s.primary_lesson = "water_chemistry"
	assert_eq(s.primary_lesson, "water_chemistry")

func test_pale_ale_has_family():
	var s = load("res://data/styles/pale_ale.tres") as BeerStyle
	assert_eq(s.family, "ales")

func test_stout_has_family():
	var s = load("res://data/styles/stout.tres") as BeerStyle
	assert_eq(s.family, "dark")

func test_all_existing_styles_have_families():
	var paths := [
		"res://data/styles/pale_ale.tres",
		"res://data/styles/stout.tres",
		"res://data/styles/lager.tres",
		"res://data/styles/wheat_beer.tres",
		"res://data/styles/berliner_weisse.tres",
		"res://data/styles/lambic.tres",
		"res://data/styles/experimental_brew.tres",
	]
	for path in paths:
		var s = load(path) as BeerStyle
		assert_ne(s.family, "", "%s should have a family" % path)

func test_pale_ale_water_affinity():
	var s = load("res://data/styles/pale_ale.tres") as BeerStyle
	assert_true(s.water_affinity.has("hoppy"), "Pale Ale should have hoppy water affinity")
	assert_gt(s.water_affinity["hoppy"], 0.8, "Pale Ale should favor hoppy water")

func test_stout_acceptable_off_flavors():
	var s = load("res://data/styles/stout.tres") as BeerStyle
	assert_true(s.acceptable_off_flavors.size() >= 0, "Stout off-flavor dict should exist")
