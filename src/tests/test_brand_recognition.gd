# src/tests/test_brand_recognition.gd
extends GutTest

var manager: Node

func before_each() -> void:
	manager = load("res://autoloads/MarketManager.gd").new()
	add_child_autofree(manager)
	manager.register_styles(["pale_ale", "stout", "ipa", "wheat_beer"])
	manager.initialize()

func after_each() -> void:
	manager = null

# -- Brand recognition basics --

func test_brand_recognition_starts_at_zero() -> void:
	assert_eq(manager.get_brand_recognition("pale_ale"), 0.0)

func test_add_brand_recognition_retail() -> void:
	manager.add_brand_recognition("pale_ale", "retail")
	assert_almost_eq(manager.get_brand_recognition("pale_ale"), 7.5, 0.001)

func test_add_brand_recognition_local_bars() -> void:
	manager.add_brand_recognition("pale_ale", "local_bars")
	assert_almost_eq(manager.get_brand_recognition("pale_ale"), 5.0, 0.001)

func test_add_brand_recognition_taproom() -> void:
	manager.add_brand_recognition("pale_ale", "taproom")
	assert_almost_eq(manager.get_brand_recognition("pale_ale"), 2.5, 0.001)

func test_add_brand_recognition_events() -> void:
	manager.add_brand_recognition("pale_ale", "events")
	assert_almost_eq(manager.get_brand_recognition("pale_ale"), 1.5, 0.001)

func test_brand_recognition_capped_at_100() -> void:
	for i in range(20):
		manager.add_brand_recognition("pale_ale", "retail")
	assert_almost_eq(manager.get_brand_recognition("pale_ale"), 100.0, 0.001)

# -- Brand decay --

func test_brand_decay_for_unbrewed_style() -> void:
	manager.add_brand_recognition("pale_ale", "local_bars")  # 5.0
	manager.tick_brand_decay("stout")
	assert_almost_eq(manager.get_brand_recognition("pale_ale"), 3.0, 0.001)

func test_no_decay_for_brewed_style() -> void:
	manager.add_brand_recognition("pale_ale", "local_bars")  # 5.0
	manager.tick_brand_decay("pale_ale")
	assert_almost_eq(manager.get_brand_recognition("pale_ale"), 5.0, 0.001)

func test_decay_floors_at_zero() -> void:
	manager.add_brand_recognition("pale_ale", "events")  # 1.5
	manager.tick_brand_decay("stout")  # 1.5 - 2.0 = clamped to 0
	assert_almost_eq(manager.get_brand_recognition("pale_ale"), 0.0, 0.001)

# -- Demand multiplier --

func test_demand_multiplier_at_zero_recognition() -> void:
	var mult: float = manager.get_brand_demand_multiplier("pale_ale")
	assert_almost_eq(mult, 1.0, 0.001)

func test_demand_multiplier_at_max_recognition() -> void:
	for i in range(20):
		manager.add_brand_recognition("pale_ale", "retail")
	var mult: float = manager.get_brand_demand_multiplier("pale_ale")
	assert_almost_eq(mult, 1.5, 0.001)

func test_demand_multiplier_at_60_recognition() -> void:
	# 60 recognition: 1.0 + (60/100) * 0.5 = 1.3
	manager.brand_recognition["pale_ale"] = 60.0
	var mult: float = manager.get_brand_demand_multiplier("pale_ale")
	assert_almost_eq(mult, 1.3, 0.001)

# -- Save/Load --

func test_save_load_preserves_brand_data() -> void:
	manager.add_brand_recognition("pale_ale", "retail")  # 7.5
	manager.add_brand_recognition("stout", "local_bars")  # 5.0
	var data: Dictionary = manager.save_data()
	manager.initialize()
	assert_eq(manager.get_brand_recognition("pale_ale"), 0.0, "Should be reset after initialize")
	manager.load_data(data)
	assert_almost_eq(manager.get_brand_recognition("pale_ale"), 7.5, 0.001)
	assert_almost_eq(manager.get_brand_recognition("stout"), 5.0, 0.001)

# -- Task 12: Brand recognition integrated into get_demand_multiplier --

func test_demand_with_brand_greater_than_without() -> void:
	# Without brand
	var demand_no_brand: float = manager.get_demand_multiplier("pale_ale")
	# Add brand recognition
	for i in range(10):
		manager.add_brand_recognition("pale_ale", "retail")  # 75.0 total
	var demand_with_brand: float = manager.get_demand_multiplier("pale_ale")
	assert_gt(demand_with_brand, demand_no_brand, "Demand with brand should exceed demand without brand")
