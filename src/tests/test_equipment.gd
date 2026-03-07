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
	var rev_array: Array[String] = []
	for item in overrides.get("reveals", []):
		rev_array.append(item)
	e.reveals = rev_array
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
				Equipment.Category.PACKAGING, Equipment.Category.UTILITY,
				Equipment.Category.AUTOMATION, Equipment.Category.MEASUREMENT]:
		var e := _make_equipment({"category": cat})
		assert_eq(e.category, cat)

func test_equipment_upgrade_chain():
	var base := _make_equipment({"equipment_id": "base", "upgrades_to": "upgraded", "upgrade_cost": 80})
	assert_eq(base.upgrades_to, "upgraded")
	assert_eq(base.upgrade_cost, 80)

# --- Catalog tests (Task 2) ---

const ALL_EQUIPMENT_PATHS := [
	"res://data/equipment/brewing/extract_kit.tres",
	"res://data/equipment/brewing/biab_setup.tres",
	"res://data/equipment/brewing/mash_tun.tres",
	"res://data/equipment/brewing/three_vessel.tres",
	"res://data/equipment/fermentation/bucket_fermenter.tres",
	"res://data/equipment/fermentation/glass_carboy.tres",
	"res://data/equipment/fermentation/temp_chamber.tres",
	"res://data/equipment/fermentation/ss_conical.tres",
	"res://data/equipment/packaging/bottles_capper.tres",
	"res://data/equipment/packaging/bench_capper.tres",
	"res://data/equipment/packaging/kegging_kit.tres",
	"res://data/equipment/packaging/counter_pressure.tres",
	"res://data/equipment/utility/cleaning_bucket.tres",
	"res://data/equipment/utility/star_san_kit.tres",
	"res://data/equipment/utility/cip_pump.tres",
]

func test_all_equipment_loads():
	for path in ALL_EQUIPMENT_PATHS:
		var equip = load(path)
		assert_not_null(equip, "Failed to load: %s" % path)
		assert_true(equip is Equipment, "Not Equipment: %s" % path)
		assert_ne(equip.equipment_id, "", "Missing equipment_id: %s" % path)
		assert_ne(equip.equipment_name, "", "Missing equipment_name: %s" % path)
		assert_gte(equip.tier, 1, "Invalid tier: %s" % path)
		assert_lte(equip.tier, 4, "Tier > 4 in Stage 2A: %s" % path)

func test_equipment_count():
	var count := 0
	for path in ALL_EQUIPMENT_PATHS:
		var equip = load(path)
		if equip:
			count += 1
	assert_eq(count, 15)

func test_upgrade_chains_resolve():
	var catalog := {}
	for path in ALL_EQUIPMENT_PATHS:
		var equip = load(path) as Equipment
		catalog[equip.equipment_id] = equip
	for id in catalog:
		var equip: Equipment = catalog[id]
		if equip.upgrades_to != "":
			assert_has(catalog, equip.upgrades_to,
				"%s upgrades_to '%s' which doesn't exist" % [id, equip.upgrades_to])
			assert_gt(equip.upgrade_cost, 0,
				"%s has upgrades_to but zero upgrade_cost" % id)

func test_tier1_items_are_free():
	for path in ALL_EQUIPMENT_PATHS:
		var equip = load(path) as Equipment
		if equip.tier == 1:
			assert_eq(equip.cost, 0, "Tier 1 item %s should be free" % equip.equipment_id)

# --- Reveals tests (Task 7) ---

func test_equipment_has_reveals_property():
	var e := Equipment.new()
	e.reveals = ["temp_numbers", "ferment_profile"]
	assert_eq(e.reveals.size(), 2)
	assert_true("temp_numbers" in e.reveals)

func test_equipment_reveals_default_empty():
	var e := Equipment.new()
	assert_eq(e.reveals.size(), 0)

func test_make_equipment_with_reveals():
	var e := _make_equipment({"reveals": ["water_selector"]})
	assert_eq(e.reveals.size(), 1)
	assert_eq(e.reveals[0], "water_selector")

# --- Reveals catalog tests (Task 8) ---

func test_three_vessel_reveals_hop_schedule():
	var e = load("res://data/equipment/brewing/three_vessel.tres") as Equipment
	assert_true("hop_schedule" in e.reveals, "Three-vessel should reveal hop_schedule")

func test_ss_conical_reveals_conditioning():
	var e = load("res://data/equipment/fermentation/ss_conical.tres") as Equipment
	assert_true("conditioning_tank" in e.reveals, "SS Conical should reveal conditioning_tank")

# --- Measurement equipment tests (Task 9) ---

func test_measurement_category_exists():
	var e := Equipment.new()
	e.category = Equipment.Category.MEASUREMENT
	assert_eq(e.category, Equipment.Category.MEASUREMENT)

func test_thermometer_loads():
	var e = load("res://data/equipment/measurement/thermometer.tres") as Equipment
	assert_not_null(e)
	assert_eq(e.equipment_id, "thermometer")
	assert_eq(e.tier, 1)
	assert_eq(e.cost, 30)
	assert_eq(e.category, Equipment.Category.MEASUREMENT)
	assert_true("temp_numbers" in e.reveals)

func test_digital_thermometer_loads():
	var e = load("res://data/equipment/measurement/digital_thermometer.tres") as Equipment
	assert_not_null(e)
	assert_eq(e.equipment_id, "digital_thermometer")
	assert_eq(e.tier, 2)
	assert_true("temp_numbers" in e.reveals)
	assert_true("ferment_profile" in e.reveals)

func test_ph_meter_loads():
	var e = load("res://data/equipment/measurement/ph_meter.tres") as Equipment
	assert_not_null(e)
	assert_eq(e.equipment_id, "ph_meter")
	assert_true("ph_meter" in e.reveals)

func test_refractometer_loads():
	var e = load("res://data/equipment/measurement/refractometer.tres") as Equipment
	assert_not_null(e)
	assert_eq(e.equipment_id, "refractometer")
	assert_eq(e.tier, 3)
	assert_true("gravity_readings" in e.reveals)

func test_all_measurement_equipment_in_catalog():
	var ids := ["thermometer", "digital_thermometer", "ph_meter", "refractometer"]
	for id in ids:
		var e = EquipmentManager.get_equipment(id)
		assert_not_null(e, "%s should be in EquipmentManager catalog" % id)
