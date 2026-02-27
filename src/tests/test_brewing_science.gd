## Tests for Brewing Science system.
extends GutTest

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
