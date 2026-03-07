extends GutTest

# --- Task 1: Default specialty field values ---

func test_default_is_specialty_is_false() -> void:
	var style = BeerStyle.new()
	assert_false(style.is_specialty)

func test_default_fermentation_turns_is_one() -> void:
	var style = BeerStyle.new()
	assert_eq(style.fermentation_turns, 1)

func test_default_variance_modifier_is_one() -> void:
	var style = BeerStyle.new()
	assert_eq(style.variance_modifier, 1.0)

func test_default_specialty_category_is_empty() -> void:
	var style = BeerStyle.new()
	assert_eq(style.specialty_category, "")

func test_specialty_fields_can_be_set() -> void:
	var style = BeerStyle.new()
	style.is_specialty = true
	style.fermentation_turns = 5
	style.variance_modifier = 1.5
	style.specialty_category = "sour_wild"
	assert_true(style.is_specialty)
	assert_eq(style.fermentation_turns, 5)
	assert_eq(style.variance_modifier, 1.5)
	assert_eq(style.specialty_category, "sour_wild")

# --- Task 2: Specialty .tres files ---

func test_berliner_weisse_loads() -> void:
	var style: BeerStyle = load("res://data/styles/berliner_weisse.tres")
	assert_not_null(style)
	assert_eq(style.style_id, "berliner_weisse")
	assert_eq(style.style_name, "Berliner Weisse")
	assert_true(style.is_specialty)
	assert_eq(style.fermentation_turns, 3)
	assert_eq(style.specialty_category, "sour_wild")
	assert_false(style.unlocked)
	assert_eq(style.base_price, 250.0)
	assert_eq(style.ideal_flavor_ratio, 0.6)
	assert_gt(style.ideal_flavor_profile.get("funkiness", 0.0), 0.5)

func test_lambic_loads() -> void:
	var style: BeerStyle = load("res://data/styles/lambic.tres")
	assert_not_null(style)
	assert_eq(style.style_id, "lambic")
	assert_eq(style.style_name, "Lambic")
	assert_true(style.is_specialty)
	assert_eq(style.fermentation_turns, 5)
	assert_eq(style.specialty_category, "sour_wild")
	assert_false(style.unlocked)
	assert_eq(style.base_price, 350.0)
	assert_eq(style.ideal_flavor_ratio, 0.65)
	assert_gt(style.ideal_flavor_profile.get("funkiness", 0.0), 0.7)

func test_experimental_brew_loads() -> void:
	var style: BeerStyle = load("res://data/styles/experimental_brew.tres")
	assert_not_null(style)
	assert_eq(style.style_id, "experimental_brew")
	assert_eq(style.style_name, "Experimental Brew")
	assert_true(style.is_specialty)
	assert_eq(style.fermentation_turns, 1)
	assert_eq(style.specialty_category, "experimental")
	assert_false(style.unlocked)
	assert_eq(style.base_price, 200.0)
	assert_eq(style.ideal_flavor_ratio, 0.5)
