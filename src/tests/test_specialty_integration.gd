extends GutTest

## Integration tests for specialty beer aging in GameState.

func _make_specialty_style() -> BeerStyle:
	var s := BeerStyle.new()
	s.style_id = "lambic"
	s.style_name = "Lambic"
	s.ideal_flavor_ratio = 0.5
	s.base_price = 200.0
	s.base_demand_weight = 1.0
	s.preferred_ingredients = {"pale_malt": 0.7, "centennial": 0.5, "us05_clean_ale": 0.5}
	s.ideal_flavor_profile = {"bitterness": 0.4, "sweetness": 0.2, "roastiness": 0.0, "fruitiness": 0.1, "funkiness": 0.0}
	s.is_specialty = true
	s.fermentation_turns = 3
	return s

func _make_normal_style() -> BeerStyle:
	var s := BeerStyle.new()
	s.style_id = "lager"
	s.style_name = "Lager"
	s.ideal_flavor_ratio = 0.5
	s.base_price = 200.0
	s.base_demand_weight = 1.0
	s.preferred_ingredients = {"pale_malt": 0.7, "centennial": 0.5, "us05_clean_ale": 0.5}
	s.ideal_flavor_profile = {"bitterness": 0.4, "sweetness": 0.2, "roastiness": 0.0, "fruitiness": 0.1, "funkiness": 0.0}
	return s

func _make_recipe() -> Dictionary:
	var malt := Malt.new()
	malt.ingredient_id = "pale_malt"
	malt.ingredient_name = "Pale Malt"
	malt.category = 0
	malt.cost = 20
	malt.is_base_malt = true
	malt.flavor_profile = {"bitterness": 0.0, "sweetness": 0.3, "roastiness": 0.05, "fruitiness": 0.0, "funkiness": 0.0}

	var hop := Hop.new()
	hop.ingredient_id = "centennial"
	hop.ingredient_name = "Centennial"
	hop.category = 1
	hop.cost = 25
	hop.flavor_profile = {"bitterness": 0.6, "sweetness": 0.0, "roastiness": 0.0, "fruitiness": 0.4, "funkiness": 0.0}

	var yeast := Yeast.new()
	yeast.ingredient_id = "us05_clean_ale"
	yeast.ingredient_name = "US-05 (Clean Ale)"
	yeast.category = 2
	yeast.cost = 15
	yeast.flavor_profile = {"bitterness": 0.0, "sweetness": 0.1, "roastiness": 0.0, "fruitiness": 0.05, "funkiness": 0.0}

	return {"malts": [malt], "hops": [hop], "yeast": yeast, "adjuncts": []}

func before_each() -> void:
	MarketManager.register_styles(["lambic", "lager", "pale_ale", "wheat_beer", "stout"])
	GameState.reset()

# --- Specialty beer queuing ---

func test_execute_brew_queues_specialty_beer() -> void:
	GameState.set_style(_make_specialty_style())
	GameState.set_recipe(_make_recipe())
	GameState.current_state = GameState.State.BREWING_PHASES
	var sliders: Dictionary = {"mashing": 50.0, "boiling": 50.0, "fermenting": 50.0}
	var result: Dictionary = GameState.execute_brew(sliders)
	assert_true(result.get("is_aging", false), "Specialty brew should have is_aging = true")
	assert_eq(result.get("aging_turns", 0), 3, "Specialty brew should have aging_turns = 3")
	assert_eq(SpecialtyBeerManager.get_aging_queue().size(), 1, "Beer should be in aging queue")

func test_execute_brew_normal_beer_not_queued() -> void:
	GameState.set_style(_make_normal_style())
	GameState.set_recipe(_make_recipe())
	GameState.current_state = GameState.State.BREWING_PHASES
	var sliders: Dictionary = {"mashing": 50.0, "boiling": 50.0, "fermenting": 50.0}
	var result: Dictionary = GameState.execute_brew(sliders)
	assert_false(result.get("is_aging", false), "Normal brew should not have is_aging")
	assert_eq(SpecialtyBeerManager.get_aging_queue().size(), 0, "No beer should be in aging queue")

# --- Aging tick in _on_results_continue ---

func test_aging_ticks_on_results_continue() -> void:
	# Manually queue a beer with 2 turns remaining
	SpecialtyBeerManager.queue_beer({
		"style_id": "lambic",
		"style_name": "Lambic",
		"recipe": {},
		"quality_base": 60.0,
		"turns_remaining": 2,
		"variance_seed": 42,
	})
	# Simulate a normal brew and advance through to trigger _on_results_continue
	GameState.set_style(_make_normal_style())
	GameState.set_recipe(_make_recipe())
	GameState.current_state = GameState.State.RESULTS
	GameState.advance_state()  # RESULTS -> SELL
	GameState.advance_state()  # SELL -> _on_results_continue
	# Beer should have been ticked: 2 -> 1
	assert_eq(SpecialtyBeerManager.get_aging_queue().size(), 1)
	assert_eq(SpecialtyBeerManager.get_aging_queue()[0]["turns_remaining"], 1)

func test_completed_aged_beer_adds_revenue() -> void:
	# Queue a beer with 1 turn remaining — it will complete on tick
	SpecialtyBeerManager.queue_beer({
		"style_id": "lambic",
		"style_name": "Lambic",
		"recipe": {},
		"quality_base": 60.0,
		"turns_remaining": 1,
		"variance_seed": 42,
	})
	var balance_before: float = GameState.balance
	GameState.set_style(_make_normal_style())
	GameState.set_recipe(_make_recipe())
	GameState.current_state = GameState.State.RESULTS
	GameState.advance_state()  # RESULTS -> SELL
	GameState.advance_state()  # SELL -> _on_results_continue
	# Balance should have increased from aged beer revenue
	assert_gt(GameState.balance, balance_before, "Balance should increase from aged beer revenue")

func test_completed_aged_beers_stored_in_last_brew_result() -> void:
	SpecialtyBeerManager.queue_beer({
		"style_id": "lambic",
		"style_name": "Lambic",
		"recipe": {},
		"quality_base": 60.0,
		"turns_remaining": 1,
		"variance_seed": 42,
	})
	GameState.set_style(_make_normal_style())
	GameState.set_recipe(_make_recipe())
	GameState.current_state = GameState.State.RESULTS
	GameState.advance_state()  # RESULTS -> SELL
	GameState.advance_state()  # SELL -> _on_results_continue
	var completed: Variant = GameState.last_brew_result.get("completed_aged_beers", null)
	assert_not_null(completed, "last_brew_result should have completed_aged_beers")
	if completed != null:
		assert_eq(completed.size(), 1, "Should have 1 completed aged beer")

# --- Reset ---

func test_reset_clears_specialty_beer_manager() -> void:
	SpecialtyBeerManager.queue_beer({
		"style_id": "lambic",
		"style_name": "Lambic",
		"recipe": {},
		"quality_base": 60.0,
		"turns_remaining": 3,
		"variance_seed": 42,
	})
	GameState.reset()
	assert_eq(SpecialtyBeerManager.get_aging_queue().size(), 0, "Reset should clear aging queue")
