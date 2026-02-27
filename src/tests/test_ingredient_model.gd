extends GutTest

func test_ingredient_has_base_fields():
	var ing := Ingredient.new()
	ing.ingredient_id = "test"
	ing.ingredient_name = "Test Ingredient"
	ing.description = "A test"
	ing.category = Ingredient.Category.MALT
	ing.cost = 20
	ing.flavor_tags = ["bready", "light"]
	ing.flavor_profile = {"bitterness": 0.1, "sweetness": 0.3, "roastiness": 0.0, "fruitiness": 0.0, "funkiness": 0.0}
	ing.unlocked = true
	assert_eq(ing.ingredient_id, "test")
	assert_eq(ing.cost, 20)
	assert_eq(ing.flavor_tags.size(), 2)
	assert_eq(ing.flavor_profile["sweetness"], 0.3)
	assert_true(ing.unlocked)

func test_ingredient_category_has_adjunct():
	var ing := Ingredient.new()
	ing.category = Ingredient.Category.ADJUNCT
	assert_eq(ing.category, Ingredient.Category.ADJUNCT)

func test_default_flavor_profile():
	var ing := Ingredient.new()
	assert_eq(ing.flavor_profile.size(), 5)
	assert_eq(ing.flavor_profile["bitterness"], 0.0)

func test_malt_has_typed_properties():
	var m := Malt.new()
	m.ingredient_id = "pale_malt"
	m.category = Ingredient.Category.MALT
	m.cost = 15
	m.color_srm = 4.0
	m.body_contribution = 0.4
	m.sweetness = 0.3
	m.fermentability = 0.85
	m.is_base_malt = true
	assert_eq(m.color_srm, 4.0)
	assert_eq(m.body_contribution, 0.4)
	assert_eq(m.fermentability, 0.85)
	assert_true(m.is_base_malt)
	assert_true(m is Ingredient, "Malt should extend Ingredient")

func test_malt_inherits_flavor_profile():
	var m := Malt.new()
	m.flavor_profile = {"bitterness": 0.0, "sweetness": 0.5, "roastiness": 0.0, "fruitiness": 0.0, "funkiness": 0.0}
	assert_eq(m.flavor_profile["sweetness"], 0.5)

func test_hop_has_typed_properties():
	var h := Hop.new()
	h.alpha_acid_pct = 12.0
	h.aroma_intensity = 0.95
	h.variety_family = "american"
	assert_eq(h.alpha_acid_pct, 12.0)
	assert_eq(h.aroma_intensity, 0.95)
	assert_eq(h.variety_family, "american")
	assert_true(h is Ingredient)

func test_yeast_has_typed_properties():
	var y := Yeast.new()
	y.attenuation_pct = 0.77
	y.ideal_temp_min_c = 15.0
	y.ideal_temp_max_c = 24.0
	y.flocculation = "medium"
	assert_eq(y.attenuation_pct, 0.77)
	assert_eq(y.ideal_temp_min_c, 15.0)
	assert_eq(y.ideal_temp_max_c, 24.0)
	assert_eq(y.flocculation, "medium")
	assert_true(y is Ingredient)

func test_adjunct_has_typed_properties():
	var a := Adjunct.new()
	a.fermentable = false
	a.adjunct_type = "sugar"
	a.effect_description = "Adds body without ABV"
	assert_false(a.fermentable)
	assert_eq(a.adjunct_type, "sugar")
	assert_eq(a.effect_description, "Adds body without ABV")
	assert_true(a is Ingredient)

func test_beer_style_has_preferred_ingredients():
	var s := BeerStyle.new()
	s.preferred_ingredients = {"roasted_barley": 0.9, "pale_malt": 0.7}
	assert_eq(s.preferred_ingredients["roasted_barley"], 0.9)

func test_beer_style_has_ideal_flavor_profile():
	var s := BeerStyle.new()
	s.ideal_flavor_profile = {"bitterness": 0.3, "sweetness": 0.2, "roastiness": 0.8, "fruitiness": 0.1, "funkiness": 0.0}
	assert_eq(s.ideal_flavor_profile["roastiness"], 0.8)

func test_beer_style_get_ingredient_compatibility():
	var s := BeerStyle.new()
	s.preferred_ingredients = {"roasted_barley": 0.9}
	assert_eq(s.get_ingredient_compatibility("roasted_barley"), 0.9)
	assert_eq(s.get_ingredient_compatibility("unknown_ingredient"), 0.5)
