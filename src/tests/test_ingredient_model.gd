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
