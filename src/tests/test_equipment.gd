extends GutTest

func _make_equipment(overrides: Dictionary = {}) -> Equipment:
	var e := Equipment.new()
	e.equipment_id = overrides.get("equipment_id", "test_kettle")
	e.equipment_name = overrides.get("equipment_name", "Test Kettle")
	e.description = overrides.get("description", "A test kettle")
	e.tier = overrides.get("tier", 1)
	e.category = overrides.get("category", Equipment.Category.BREWING)
	e.cost = overrides.get("cost", 100)
	e.sanitation_bonus = overrides.get("sanitation_bonus", 5)
	e.temp_control_bonus = overrides.get("temp_control_bonus", 10)
	e.efficiency_bonus = overrides.get("efficiency_bonus", 0.05)
	e.batch_size_multiplier = overrides.get("batch_size_multiplier", 1.0)
	e.upgrades_to = overrides.get("upgrades_to", "")
	e.upgrade_cost = overrides.get("upgrade_cost", 0)
	return e

func test_equipment_resource_properties():
	var e := _make_equipment()
	assert_eq(e.equipment_id, "test_kettle")
	assert_eq(e.equipment_name, "Test Kettle")
	assert_eq(e.tier, 1)
	assert_eq(e.category, Equipment.Category.BREWING)
	assert_eq(e.cost, 100)
	assert_eq(e.sanitation_bonus, 5)
	assert_eq(e.temp_control_bonus, 10)
	assert_almost_eq(e.efficiency_bonus, 0.05, 0.001)
	assert_almost_eq(e.batch_size_multiplier, 1.0, 0.001)

func test_equipment_default_values():
	var e := Equipment.new()
	assert_eq(e.tier, 1)
	assert_eq(e.sanitation_bonus, 0)
	assert_eq(e.temp_control_bonus, 0)
	assert_almost_eq(e.efficiency_bonus, 0.0, 0.001)
	assert_almost_eq(e.batch_size_multiplier, 1.0, 0.001)
	assert_eq(e.upgrades_to, "")

func test_equipment_categories():
	for cat in [Equipment.Category.BREWING, Equipment.Category.FERMENTATION,
				Equipment.Category.PACKAGING, Equipment.Category.UTILITY]:
		var e := _make_equipment({"category": cat})
		assert_eq(e.category, cat)

func test_equipment_upgrade_chain():
	var base := _make_equipment({"equipment_id": "base", "upgrades_to": "upgraded", "upgrade_cost": 80})
	assert_eq(base.upgrades_to, "upgraded")
	assert_eq(base.upgrade_cost, 80)
