extends GutTest

var modifier_mgr: Node
var meta_mgr: Node

func before_each() -> void:
	meta_mgr = preload("res://autoloads/MetaProgressionManager.gd").new()
	add_child_autofree(meta_mgr)
	modifier_mgr = preload("res://autoloads/RunModifierManager.gd").new()
	add_child_autofree(modifier_mgr)

# --- Perk effects ---

func test_starting_cash_bonus_default() -> void:
	assert_almost_eq(modifier_mgr.get_starting_cash_multiplier(meta_mgr), 1.0, 0.01)

func test_starting_cash_bonus_with_nest_egg() -> void:
	meta_mgr.set_active_perks(["nest_egg"] as Array[String])
	assert_almost_eq(modifier_mgr.get_starting_cash_multiplier(meta_mgr), 1.05, 0.01)

func test_rp_bonus_default() -> void:
	assert_eq(modifier_mgr.get_rp_bonus(meta_mgr), 0)

func test_rp_bonus_with_quick_study() -> void:
	meta_mgr.set_active_perks(["quick_study"] as Array[String])
	assert_eq(modifier_mgr.get_rp_bonus(meta_mgr), 1)

func test_rent_multiplier_default() -> void:
	assert_almost_eq(modifier_mgr.get_rent_multiplier(meta_mgr), 1.0, 0.01)

func test_rent_multiplier_with_landlords_friend() -> void:
	meta_mgr.set_active_perks(["landlords_friend"] as Array[String])
	assert_almost_eq(modifier_mgr.get_rent_multiplier(meta_mgr), 0.9, 0.01)

func test_quality_bonus_default() -> void:
	assert_almost_eq(modifier_mgr.get_quality_bonus(meta_mgr), 0.0, 0.01)

func test_quality_bonus_with_style_specialist() -> void:
	meta_mgr.set_active_perks(["style_specialist"] as Array[String])
	assert_almost_eq(modifier_mgr.get_quality_bonus(meta_mgr), 5.0, 0.01)

# --- Modifier effects ---

func test_demand_multiplier_default() -> void:
	assert_almost_eq(modifier_mgr.get_demand_modifier(meta_mgr), 1.0, 0.01)

func test_demand_multiplier_tough_market() -> void:
	meta_mgr.set_active_modifiers(["tough_market"] as Array[String])
	assert_almost_eq(modifier_mgr.get_demand_modifier(meta_mgr), 0.8, 0.01)

func test_demand_multiplier_generous_market() -> void:
	meta_mgr.set_active_modifiers(["generous_market"] as Array[String])
	assert_almost_eq(modifier_mgr.get_demand_modifier(meta_mgr), 1.2, 0.01)

func test_starting_cash_budget_brewery() -> void:
	meta_mgr.set_active_modifiers(["budget_brewery"] as Array[String])
	assert_almost_eq(modifier_mgr.get_starting_cash_multiplier(meta_mgr), 0.5, 0.01)

func test_starting_cash_budget_brewery_plus_nest_egg() -> void:
	meta_mgr.set_active_perks(["nest_egg"] as Array[String])
	meta_mgr.set_active_modifiers(["budget_brewery"] as Array[String])
	assert_almost_eq(modifier_mgr.get_starting_cash_multiplier(meta_mgr), 0.525, 0.01)

func test_quality_bonus_master_brewer() -> void:
	meta_mgr.set_active_modifiers(["master_brewer"] as Array[String])
	assert_almost_eq(modifier_mgr.get_quality_bonus(meta_mgr), 10.0, 0.01)

func test_quality_bonus_master_brewer_plus_style_specialist() -> void:
	meta_mgr.set_active_perks(["style_specialist"] as Array[String])
	meta_mgr.set_active_modifiers(["master_brewer"] as Array[String])
	assert_almost_eq(modifier_mgr.get_quality_bonus(meta_mgr), 15.0, 0.01)

func test_infection_immunity_default() -> void:
	assert_eq(modifier_mgr.get_infection_immune_brews(meta_mgr), 0)

func test_infection_immunity_lucky_break() -> void:
	meta_mgr.set_active_modifiers(["lucky_break"] as Array[String])
	assert_eq(modifier_mgr.get_infection_immune_brews(meta_mgr), 5)

func test_ingredient_availability_default() -> void:
	assert_almost_eq(modifier_mgr.get_ingredient_availability(meta_mgr), 1.0, 0.01)

func test_ingredient_availability_shortage() -> void:
	meta_mgr.set_active_modifiers(["ingredient_shortage"] as Array[String])
	assert_almost_eq(modifier_mgr.get_ingredient_availability(meta_mgr), 0.6, 0.01)
