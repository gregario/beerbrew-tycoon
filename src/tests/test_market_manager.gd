# src/tests/test_market_manager.gd
extends GutTest

var manager: Node

func before_each() -> void:
	manager = load("res://autoloads/MarketManager.gd").new()
	add_child_autofree(manager)
	manager.register_styles(["pale_ale", "stout", "ipa", "wheat_beer"])

func after_each() -> void:
	manager = null

# -- Seasonal cycles --

func test_initial_season_is_spring() -> void:
	manager.initialize()
	assert_eq(manager.current_season, 0, "Should start in Spring (season 0)")

func test_season_names() -> void:
	assert_eq(manager.SEASON_NAMES, ["Spring", "Summer", "Fall", "Winter"])

func test_season_advances_after_6_turns() -> void:
	manager.initialize()
	for i in range(6):
		manager.tick()
	assert_eq(manager.current_season, 1, "Should be Summer after 6 ticks")

func test_season_wraps_after_24_turns() -> void:
	manager.initialize()
	for i in range(24):
		manager.tick()
	assert_eq(manager.current_season, 0, "Should wrap back to Spring")

func test_seasonal_modifier_returns_float() -> void:
	manager.initialize()
	var mod: float = manager.get_seasonal_modifier("stout")
	assert_typeof(mod, TYPE_FLOAT)

func test_stout_has_positive_winter_modifier() -> void:
	manager.initialize()
	for i in range(18):
		manager.tick()
	assert_eq(manager.current_season, 3, "Should be Winter")
	var mod: float = manager.get_seasonal_modifier("stout")
	assert_gt(mod, 0.0, "Stout should have positive modifier in Winter")

func test_seasonal_modifier_for_unknown_style_is_zero() -> void:
	manager.initialize()
	assert_eq(manager.get_seasonal_modifier("nonexistent"), 0.0)

func test_get_season_turn_returns_position_within_season() -> void:
	manager.initialize()
	manager.tick()
	manager.tick()
	assert_eq(manager.season_turn, 2)

func test_get_season_name() -> void:
	manager.initialize()
	assert_eq(manager.get_season_name(), "Spring")

func test_get_demand_multiplier_includes_seasonal() -> void:
	manager.initialize()
	var demand: float = manager.get_demand_multiplier("pale_ale")
	var expected: float = 1.0 + manager.get_seasonal_modifier("pale_ale")
	assert_almost_eq(demand, expected, 0.001)

func test_demand_multiplier_clamped_minimum() -> void:
	manager.initialize()
	var demand: float = manager.get_demand_multiplier("pale_ale")
	assert_gte(demand, 0.3)

func test_demand_multiplier_clamped_maximum() -> void:
	manager.initialize()
	var demand: float = manager.get_demand_multiplier("pale_ale")
	assert_lte(demand, 2.5)
