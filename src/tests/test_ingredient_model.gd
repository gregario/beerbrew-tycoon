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
