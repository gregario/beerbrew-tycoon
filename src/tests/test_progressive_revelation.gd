extends GutTest

## Tests for progressive revelation: temp_numbers reveal, yeast-dependent
## ferment slider range, and Measurement tab in EquipmentShop.

const BrewingPhasesScript = preload("res://ui/BrewingPhases.gd")
const EquipmentShopScript = preload("res://ui/EquipmentShop.gd")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _make_equipment(overrides: Dictionary = {}) -> Equipment:
	var e := Equipment.new()
	e.equipment_id = overrides.get("equipment_id", "test_equip")
	e.equipment_name = overrides.get("equipment_name", "Test Equipment")
	e.tier = overrides.get("tier", 1)
	e.category = overrides.get("category", Equipment.Category.BREWING)
	e.cost = overrides.get("cost", 0)
	var rev_array: Array[String] = []
	for item in overrides.get("reveals", []):
		rev_array.append(item)
	e.reveals = rev_array
	return e

func _make_yeast(overrides: Dictionary = {}) -> Yeast:
	var y := Yeast.new()
	y.ingredient_id = overrides.get("ingredient_id", "test_yeast")
	y.ingredient_name = overrides.get("ingredient_name", "Test Ale Yeast")
	y.ideal_temp_min_c = overrides.get("ideal_temp_min_c", 15.0)
	y.ideal_temp_max_c = overrides.get("ideal_temp_max_c", 24.0)
	y.attenuation_pct = overrides.get("attenuation_pct", 0.75)
	return y

## Create a bare Control with the BrewingPhases script attached (no scene tree).
## Only works for methods that don't rely on @onready vars.
func _make_brewing_phases() -> Control:
	var bp := Control.new()
	bp.set_script(BrewingPhasesScript)
	return bp

# ---------------------------------------------------------------------------
# is_revealed tests
# ---------------------------------------------------------------------------

func test_is_revealed_false_when_no_equipment_slotted():
	EquipmentManager.reset()
	assert_false(EquipmentManager.is_revealed("temp_numbers"))

func test_is_revealed_true_when_equipment_with_reveal_is_slotted():
	EquipmentManager.reset()
	var equip := _make_equipment({"equipment_id": "test_thermo", "reveals": ["temp_numbers"]})
	EquipmentManager._catalog["test_thermo"] = equip
	EquipmentManager.owned_equipment.append("test_thermo")
	EquipmentManager.station_slots[0] = "test_thermo"
	assert_true(EquipmentManager.is_revealed("temp_numbers"))
	# Cleanup
	EquipmentManager._catalog.erase("test_thermo")
	EquipmentManager.reset()

func test_is_revealed_false_when_equipment_owned_but_not_slotted():
	EquipmentManager.reset()
	var equip := _make_equipment({"equipment_id": "test_thermo2", "reveals": ["temp_numbers"]})
	EquipmentManager._catalog["test_thermo2"] = equip
	EquipmentManager.owned_equipment.append("test_thermo2")
	# Not in station_slots
	assert_false(EquipmentManager.is_revealed("temp_numbers"))
	# Cleanup
	EquipmentManager._catalog.erase("test_thermo2")
	EquipmentManager.reset()

# ---------------------------------------------------------------------------
# Measurement category tests
# ---------------------------------------------------------------------------

func test_measurement_category_exists():
	var e := Equipment.new()
	e.category = Equipment.Category.MEASUREMENT
	assert_eq(e.category, Equipment.Category.MEASUREMENT)

func test_measurement_equipment_in_catalog():
	var measurement_ids := ["thermometer", "digital_thermometer", "ph_meter", "refractometer", "water_kit"]
	for id in measurement_ids:
		var e = EquipmentManager.get_equipment(id)
		assert_not_null(e, "%s should be in catalog" % id)
		assert_eq(e.category, Equipment.Category.MEASUREMENT, "%s should be MEASUREMENT category" % id)

func test_get_equipment_by_measurement_category():
	var items: Array = EquipmentManager.get_equipment_by_category(Equipment.Category.MEASUREMENT)
	assert_gte(items.size(), 4, "Should have at least 4 measurement items")

# ---------------------------------------------------------------------------
# EquipmentShop Measurement tab tests
# ---------------------------------------------------------------------------

func test_equipment_shop_has_measurement_in_category_labels():
	var shop := CanvasLayer.new()
	shop.set_script(EquipmentShopScript)
	assert_true("Measurement" in shop.CATEGORY_LABELS, "CATEGORY_LABELS should include Measurement")
	shop.free()

func test_equipment_shop_measurement_category_map():
	var shop := CanvasLayer.new()
	shop.set_script(EquipmentShopScript)
	var has_measurement := false
	for key in shop.CATEGORY_MAP:
		if shop.CATEGORY_MAP[key] == Equipment.Category.MEASUREMENT:
			has_measurement = true
			break
	assert_true(has_measurement, "CATEGORY_MAP should include MEASUREMENT")
	shop.free()

# ---------------------------------------------------------------------------
# BrewingPhases vague label tests
# ---------------------------------------------------------------------------

func test_vague_mashing_low():
	var bp := _make_brewing_phases()
	assert_eq(bp._get_vague_mashing(62), "Low")
	assert_eq(bp._get_vague_mashing(64), "Low")
	bp.free()

func test_vague_mashing_medium():
	var bp := _make_brewing_phases()
	assert_eq(bp._get_vague_mashing(65), "Medium")
	assert_eq(bp._get_vague_mashing(67), "Medium")
	bp.free()

func test_vague_mashing_high():
	var bp := _make_brewing_phases()
	assert_eq(bp._get_vague_mashing(68), "High")
	assert_eq(bp._get_vague_mashing(69), "High")
	bp.free()

func test_vague_boiling_short():
	var bp := _make_brewing_phases()
	assert_eq(bp._get_vague_boiling(30), "Short")
	assert_eq(bp._get_vague_boiling(50), "Short")
	bp.free()

func test_vague_boiling_medium():
	var bp := _make_brewing_phases()
	assert_eq(bp._get_vague_boiling(60), "Medium")
	assert_eq(bp._get_vague_boiling(70), "Medium")
	bp.free()

func test_vague_boiling_long():
	var bp := _make_brewing_phases()
	assert_eq(bp._get_vague_boiling(80), "Long")
	assert_eq(bp._get_vague_boiling(90), "Long")
	bp.free()

func test_vague_fermenting_cool():
	var bp := _make_brewing_phases()
	assert_eq(bp._get_vague_fermenting(15), "Cool")
	assert_eq(bp._get_vague_fermenting(18), "Cool")
	bp.free()

func test_vague_fermenting_moderate():
	var bp := _make_brewing_phases()
	assert_eq(bp._get_vague_fermenting(19), "Moderate")
	assert_eq(bp._get_vague_fermenting(22), "Moderate")
	bp.free()

func test_vague_fermenting_warm():
	var bp := _make_brewing_phases()
	assert_eq(bp._get_vague_fermenting(23), "Warm")
	assert_eq(bp._get_vague_fermenting(25), "Warm")
	bp.free()

# ---------------------------------------------------------------------------
# Yeast-dependent ferment slider range tests
# ---------------------------------------------------------------------------

func test_classify_yeast_lager():
	var bp := _make_brewing_phases()
	var yeast := _make_yeast({"ingredient_name": "W-34/70 (Lager)", "ideal_temp_min_c": 9.0, "ideal_temp_max_c": 15.0})
	assert_eq(bp._classify_yeast(yeast), "lager")
	bp.free()

func test_classify_yeast_saison():
	var bp := _make_brewing_phases()
	var yeast := _make_yeast({"ingredient_name": "Belle Saison", "ideal_temp_min_c": 17.0, "ideal_temp_max_c": 35.0})
	assert_eq(bp._classify_yeast(yeast), "saison")
	bp.free()

func test_classify_yeast_wheat():
	var bp := _make_brewing_phases()
	var yeast := _make_yeast({"ingredient_name": "WB-06 (Wheat)", "ideal_temp_min_c": 15.0, "ideal_temp_max_c": 24.0})
	assert_eq(bp._classify_yeast(yeast), "wheat")
	bp.free()

func test_classify_yeast_ale_default():
	var bp := _make_brewing_phases()
	var yeast := _make_yeast({"ingredient_name": "US-05 (Clean Ale)", "ideal_temp_min_c": 15.0, "ideal_temp_max_c": 24.0})
	assert_eq(bp._classify_yeast(yeast), "ale")
	bp.free()

func test_classify_yeast_by_temp_when_no_keyword():
	var bp := _make_brewing_phases()
	# Cold yeast without "lager" in name -> classify by temp
	var cold_yeast := _make_yeast({"ingredient_name": "Cold Fermenter", "ideal_temp_min_c": 4.0, "ideal_temp_max_c": 12.0})
	assert_eq(bp._classify_yeast(cold_yeast), "lager")
	# Hot yeast without "saison" in name -> classify by temp
	var hot_yeast := _make_yeast({"ingredient_name": "Hot Fermenter", "ideal_temp_min_c": 25.0, "ideal_temp_max_c": 35.0})
	assert_eq(bp._classify_yeast(hot_yeast), "saison")
	bp.free()

func test_yeast_ferment_ranges_lager():
	var bp := _make_brewing_phases()
	var range_data: Dictionary = bp.YEAST_FERMENT_RANGES["lager"]
	assert_eq(range_data["min"], 4)
	assert_eq(range_data["max"], 12)
	bp.free()

func test_yeast_ferment_ranges_saison():
	var bp := _make_brewing_phases()
	var range_data: Dictionary = bp.YEAST_FERMENT_RANGES["saison"]
	assert_eq(range_data["min"], 20)
	assert_eq(range_data["max"], 35)
	bp.free()

func test_yeast_ferment_ranges_wheat():
	var bp := _make_brewing_phases()
	var range_data: Dictionary = bp.YEAST_FERMENT_RANGES["wheat"]
	assert_eq(range_data["min"], 16)
	assert_eq(range_data["max"], 26)
	bp.free()

func test_yeast_ferment_ranges_ale():
	var bp := _make_brewing_phases()
	var range_data: Dictionary = bp.YEAST_FERMENT_RANGES["ale"]
	assert_eq(range_data["min"], 15)
	assert_eq(range_data["max"], 24)
	bp.free()
