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

# -- Trending styles --

func test_no_trend_initially() -> void:
	manager.initialize()
	assert_eq(manager.active_trend_style, "", "No trend at start")

func test_trend_bonus_constant() -> void:
	assert_eq(manager.TREND_BONUS, 0.5)

func test_get_trend_bonus_zero_when_no_trend() -> void:
	manager.initialize()
	assert_eq(manager.get_trend_bonus("pale_ale"), 0.0)

func test_get_trend_bonus_when_trending() -> void:
	manager.initialize()
	manager.active_trend_style = "pale_ale"
	manager.trend_remaining_turns = 4
	assert_eq(manager.get_trend_bonus("pale_ale"), 0.5)

func test_trend_bonus_zero_for_non_trending_style() -> void:
	manager.initialize()
	manager.active_trend_style = "stout"
	manager.trend_remaining_turns = 4
	assert_eq(manager.get_trend_bonus("pale_ale"), 0.0)

func test_trend_expires_after_duration() -> void:
	manager.initialize()
	manager.active_trend_style = "pale_ale"
	manager.trend_remaining_turns = 2
	manager.tick()
	assert_eq(manager.trend_remaining_turns, 1)
	manager.tick()
	assert_eq(manager.active_trend_style, "", "Trend should expire")

func test_trend_included_in_demand_multiplier() -> void:
	manager.initialize()
	manager.active_trend_style = "pale_ale"
	manager.trend_remaining_turns = 4
	var demand: float = manager.get_demand_multiplier("pale_ale")
	var seasonal: float = manager.get_seasonal_modifier("pale_ale")
	var expected: float = clampf(1.0 + seasonal + 0.5, 0.3, 2.5)
	assert_almost_eq(demand, expected, 0.001)

func test_new_trend_starts_within_range() -> void:
	manager.initialize()
	# Force next_trend_in to 1 so a trend triggers on next tick
	manager._next_trend_in = 1
	manager.tick()
	if manager.active_trend_style != "":
		assert_true(manager._style_ids.has(manager.active_trend_style))
		assert_gte(manager.trend_remaining_turns, 4)
		assert_lte(manager.trend_remaining_turns, 6)

# -- Market saturation --

func test_initial_saturation_is_zero() -> void:
	manager.initialize()
	assert_eq(manager.get_saturation_penalty("pale_ale"), 0.0)

func test_record_brew_increases_saturation() -> void:
	manager.initialize()
	manager.record_brew("pale_ale")
	assert_almost_eq(manager.get_saturation_penalty("pale_ale"), 0.1, 0.001)

func test_multiple_brews_stack_saturation() -> void:
	manager.initialize()
	manager.record_brew("pale_ale")
	manager.record_brew("pale_ale")
	manager.record_brew("pale_ale")
	assert_almost_eq(manager.get_saturation_penalty("pale_ale"), 0.3, 0.001)

func test_saturation_capped_at_floor() -> void:
	manager.initialize()
	for i in range(10):
		manager.record_brew("pale_ale")
	assert_almost_eq(manager.get_saturation_penalty("pale_ale"), 0.5, 0.001)

func test_saturation_recovers_on_tick() -> void:
	manager.initialize()
	manager.record_brew("pale_ale")
	manager.record_brew("pale_ale")  # 0.2 saturation
	manager.tick()  # recovers 0.05 → 0.15
	assert_almost_eq(manager.get_saturation_penalty("pale_ale"), 0.15, 0.001)

func test_saturation_does_not_go_below_zero() -> void:
	manager.initialize()
	manager.record_brew("pale_ale")  # 0.1
	manager.tick()  # 0.05
	manager.tick()  # 0.0
	manager.tick()  # still 0.0
	assert_almost_eq(manager.get_saturation_penalty("pale_ale"), 0.0, 0.001)

func test_saturation_only_recovers_for_styles_not_brewed_this_turn() -> void:
	manager.initialize()
	manager.record_brew("pale_ale")
	manager.record_brew("stout")
	manager.tick()
	assert_almost_eq(manager.get_saturation_penalty("pale_ale"), 0.05, 0.001)

func test_saturation_subtracted_from_demand() -> void:
	manager.initialize()
	manager.record_brew("pale_ale")
	manager.record_brew("pale_ale")  # 0.2 saturation
	var demand: float = manager.get_demand_multiplier("pale_ale")
	var seasonal: float = manager.get_seasonal_modifier("pale_ale")
	var expected: float = clampf(1.0 + seasonal - 0.2, 0.3, 2.5)
	assert_almost_eq(demand, expected, 0.001)

func test_saturation_reset_on_initialize() -> void:
	manager.initialize()
	manager.record_brew("pale_ale")
	manager.initialize()
	assert_eq(manager.get_saturation_penalty("pale_ale"), 0.0)

# -- Distribution channels --

func test_channel_count() -> void:
	assert_eq(manager.CHANNELS.size(), 4)

func test_taproom_always_unlocked() -> void:
	manager.initialize()
	var unlocked: Array = manager.get_unlocked_channels()
	assert_true(unlocked.any(func(c): return c.id == "taproom"))

func test_channel_has_required_fields() -> void:
	var ch: Dictionary = manager.CHANNELS[0]
	assert_has(ch, "id")
	assert_has(ch, "name")
	assert_has(ch, "margin")
	assert_has(ch, "volume_pct")
	assert_has(ch, "unlock_type")

func test_taproom_margin_is_1() -> void:
	var taproom: Dictionary = manager.get_channel("taproom")
	assert_eq(taproom.margin, 1.0)

func test_local_bars_margin_is_07() -> void:
	var bars: Dictionary = manager.get_channel("local_bars")
	assert_almost_eq(bars.margin, 0.7, 0.001)

func test_retail_margin_is_05() -> void:
	var retail: Dictionary = manager.get_channel("retail")
	assert_almost_eq(retail.margin, 0.5, 0.001)

func test_events_margin_is_15() -> void:
	var events: Dictionary = manager.get_channel("events")
	assert_almost_eq(events.margin, 1.5, 0.001)

func test_is_channel_unlocked_taproom() -> void:
	manager.initialize()
	assert_true(manager.is_channel_unlocked("taproom"))

func test_local_bars_locked_in_garage() -> void:
	manager.initialize()
	# Without BreweryExpansion autoload, bars should be locked
	assert_false(manager.is_channel_unlocked("local_bars"))

func test_get_max_units_for_channel() -> void:
	manager.initialize()
	var max_units: int = manager.get_max_units("taproom", 10)
	assert_eq(max_units, 3)

func test_get_max_units_local_bars() -> void:
	var max_units: int = manager.get_max_units("local_bars", 10)
	assert_eq(max_units, 5)

func test_get_max_units_retail() -> void:
	var max_units: int = manager.get_max_units("retail", 10)
	assert_eq(max_units, 10)

func test_get_max_units_events() -> void:
	var max_units: int = manager.get_max_units("events", 10)
	assert_eq(max_units, 2)

# -- Player pricing --

func test_default_price_offset_is_zero() -> void:
	manager.initialize()
	assert_eq(manager.get_price_offset(), 0.0)

func test_set_price_offset_stores_value() -> void:
	manager.initialize()
	manager.set_price_offset(0.2)
	assert_almost_eq(manager.get_price_offset(), 0.2, 0.001)

func test_price_offset_clamped_min() -> void:
	manager.initialize()
	manager.set_price_offset(-0.5)
	assert_almost_eq(manager.get_price_offset(), -0.3, 0.001)

func test_price_offset_clamped_max() -> void:
	manager.initialize()
	manager.set_price_offset(0.8)
	assert_almost_eq(manager.get_price_offset(), 0.5, 0.001)

func test_volume_modifier_at_base_price() -> void:
	var vol: float = manager.calculate_volume_modifier(0.0, 70.0)
	assert_almost_eq(vol, 1.0, 0.001)

func test_volume_modifier_premium_pricing() -> void:
	# offset=+0.5 → base_vol = 1.0 - 0.5*0.5 = 0.75, quality_factor=0.7, penalty=0.5*0.5*(1-0.7)=0.075 → 0.675
	var vol: float = manager.calculate_volume_modifier(0.5, 70.0)
	assert_lt(vol, 1.0, "Premium pricing should reduce volume")
	assert_gt(vol, 0.3, "Should be above floor")

func test_volume_modifier_discount_pricing() -> void:
	# offset=-0.3 → base_vol = 1.0 - (-0.3)*0.5 = 1.15, no premium penalty
	var vol: float = manager.calculate_volume_modifier(-0.3, 70.0)
	assert_almost_eq(vol, 1.15, 0.001)

func test_volume_modifier_clamped_min() -> void:
	var vol: float = manager.calculate_volume_modifier(0.5, 20.0)
	assert_gte(vol, 0.3)

func test_volume_modifier_clamped_max() -> void:
	var vol: float = manager.calculate_volume_modifier(-0.3, 90.0)
	assert_lte(vol, 1.5)

func test_low_quality_harsh_premium_penalty() -> void:
	var vol_low: float = manager.calculate_volume_modifier(0.4, 40.0)
	var vol_high: float = manager.calculate_volume_modifier(0.4, 90.0)
	assert_lt(vol_low, vol_high, "Low quality should suffer more from premium pricing")

func test_price_offset_resets() -> void:
	manager.initialize()
	manager.set_price_offset(0.3)
	manager.initialize()
	assert_eq(manager.get_price_offset(), 0.0)

func test_get_adjusted_price() -> void:
	manager.initialize()
	manager.set_price_offset(0.1)
	assert_almost_eq(manager.get_adjusted_price(200.0), 220.0, 0.01)

# -- Market research --

func test_research_not_purchased_initially() -> void:
	manager.initialize()
	assert_false(manager.research_purchased)

func test_research_cost() -> void:
	assert_eq(manager.RESEARCH_COST, 100)

func test_buy_research_returns_true() -> void:
	manager.initialize()
	var result: bool = manager.buy_research()
	assert_true(result)
	assert_true(manager.research_purchased)

func test_buy_research_twice_returns_false() -> void:
	manager.initialize()
	manager.buy_research()
	assert_false(manager.buy_research(), "Can only buy once per turn")

func test_research_resets_each_turn() -> void:
	manager.initialize()
	manager.buy_research()
	manager.tick()
	assert_false(manager.research_purchased, "Research resets after tick")

func test_get_trend_forecast_without_research() -> void:
	manager.initialize()
	var forecast: Dictionary = manager.get_trend_forecast()
	assert_false(forecast.has("next_trend_in"))

func test_get_trend_forecast_with_research() -> void:
	manager.initialize()
	manager._next_trend_in = 2
	manager.buy_research()
	var forecast: Dictionary = manager.get_trend_forecast()
	assert_true(forecast.has("next_trend_in"))

# -- Save/Load --

func test_save_data_returns_dictionary() -> void:
	manager.initialize()
	var data: Dictionary = manager.save_data()
	assert_typeof(data, TYPE_DICTIONARY)

func test_save_load_preserves_season() -> void:
	manager.initialize()
	for i in range(8):
		manager.tick()
	var data: Dictionary = manager.save_data()
	manager.initialize()
	manager.load_data(data)
	assert_eq(manager.current_season, 1)
	assert_eq(manager.season_turn, 2)

func test_save_load_preserves_saturation() -> void:
	manager.initialize()
	manager.record_brew("pale_ale")
	manager.record_brew("pale_ale")
	var data: Dictionary = manager.save_data()
	manager.initialize()
	manager.load_data(data)
	assert_almost_eq(manager.get_saturation_penalty("pale_ale"), 0.2, 0.001)

func test_save_load_preserves_trend() -> void:
	manager.initialize()
	manager.active_trend_style = "stout"
	manager.trend_remaining_turns = 3
	var data: Dictionary = manager.save_data()
	manager.initialize()
	manager.load_data(data)
	assert_eq(manager.active_trend_style, "stout")
	assert_eq(manager.trend_remaining_turns, 3)
