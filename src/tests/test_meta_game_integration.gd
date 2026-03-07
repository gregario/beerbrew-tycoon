extends GutTest

func before_each() -> void:
	GameState.reset()
	if is_instance_valid(MetaProgressionManager):
		MetaProgressionManager.active_perks.clear()
		MetaProgressionManager.active_modifiers.clear()

func test_starting_balance_default() -> void:
	GameState.reset()
	assert_eq(GameState.balance, GameState.STARTING_BALANCE)

func test_starting_balance_with_nest_egg() -> void:
	MetaProgressionManager.set_active_perks(["nest_egg"] as Array[String])
	GameState.reset()
	var expected: float = GameState.STARTING_BALANCE * 1.05
	assert_almost_eq(GameState.balance, expected, 0.01)

func test_starting_balance_with_budget_brewery() -> void:
	MetaProgressionManager.set_active_modifiers(["budget_brewery"] as Array[String])
	GameState.reset()
	var expected: float = GameState.STARTING_BALANCE * 0.5
	assert_almost_eq(GameState.balance, expected, 0.01)

func test_rp_bonus_query() -> void:
	MetaProgressionManager.set_active_perks(["quick_study"] as Array[String])
	var bonus: int = RunModifierManager.get_rp_bonus(MetaProgressionManager)
	assert_eq(bonus, 1)

func test_rent_discount_query() -> void:
	MetaProgressionManager.set_active_perks(["landlords_friend"] as Array[String])
	var mult: float = RunModifierManager.get_rent_multiplier(MetaProgressionManager)
	assert_almost_eq(mult, 0.9, 0.01)

func test_equipment_spend_starts_at_zero() -> void:
	GameState.reset()
	assert_eq(GameState.equipment_spend, 0.0)

func test_record_equipment_purchase() -> void:
	GameState.reset()
	GameState.record_equipment_purchase(500.0)
	assert_eq(GameState.equipment_spend, 500.0)
	GameState.record_equipment_purchase(300.0)
	assert_eq(GameState.equipment_spend, 800.0)

func test_unique_ingredients_starts_at_zero() -> void:
	GameState.reset()
	assert_eq(GameState.unique_ingredients_used, 0)

func test_meta_effects_cleared_after_perk_clear() -> void:
	MetaProgressionManager.set_active_perks(["nest_egg"] as Array[String])
	MetaProgressionManager.active_perks.clear()
	GameState.reset()
	assert_eq(GameState.balance, GameState.STARTING_BALANCE)
