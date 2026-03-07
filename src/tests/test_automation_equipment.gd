extends GutTest

# --- Task 8: Equipment.Category.AUTOMATION and new fields ---

func test_automation_category_exists():
	assert_eq(Equipment.Category.AUTOMATION, 4, "AUTOMATION should be enum value 4")

func test_equipment_has_mash_bonus_default():
	var e := Equipment.new()
	assert_eq(e.mash_bonus, 0)

func test_equipment_has_boil_bonus_default():
	var e := Equipment.new()
	assert_eq(e.boil_bonus, 0)

func test_equipment_has_ferment_bonus_default():
	var e := Equipment.new()
	assert_eq(e.ferment_bonus, 0)

func test_auto_mash_controller_loads():
	var equip = load("res://data/equipment/automation/auto_mash_controller.tres") as Equipment
	assert_not_null(equip)
	assert_eq(equip.equipment_id, "auto_mash_controller")
	assert_eq(equip.equipment_name, "Auto-Mash Controller")
	assert_eq(equip.tier, 3)
	assert_eq(equip.category, Equipment.Category.AUTOMATION)
	assert_eq(equip.cost, 800)
	assert_eq(equip.mash_bonus, 5)
	assert_eq(equip.boil_bonus, 0)
	assert_eq(equip.ferment_bonus, 0)

func test_automated_boil_system_loads():
	var equip = load("res://data/equipment/automation/automated_boil_system.tres") as Equipment
	assert_not_null(equip)
	assert_eq(equip.equipment_id, "automated_boil_system")
	assert_eq(equip.equipment_name, "Automated Boil System")
	assert_eq(equip.tier, 4)
	assert_eq(equip.category, Equipment.Category.AUTOMATION)
	assert_eq(equip.cost, 1500)
	assert_eq(equip.mash_bonus, 0)
	assert_eq(equip.boil_bonus, 7)
	assert_eq(equip.ferment_bonus, 0)

func test_fermentation_controller_loads():
	var equip = load("res://data/equipment/automation/fermentation_controller.tres") as Equipment
	assert_not_null(equip)
	assert_eq(equip.equipment_id, "fermentation_controller")
	assert_eq(equip.equipment_name, "Fermentation Controller")
	assert_eq(equip.tier, 4)
	assert_eq(equip.category, Equipment.Category.AUTOMATION)
	assert_eq(equip.cost, 1800)
	assert_eq(equip.mash_bonus, 0)
	assert_eq(equip.boil_bonus, 0)
	assert_eq(equip.ferment_bonus, 8)

func test_full_automation_suite_loads():
	var equip = load("res://data/equipment/automation/full_automation_suite.tres") as Equipment
	assert_not_null(equip)
	assert_eq(equip.equipment_id, "full_automation_suite")
	assert_eq(equip.equipment_name, "Full Automation Suite")
	assert_eq(equip.tier, 5)
	assert_eq(equip.category, Equipment.Category.AUTOMATION)
	assert_eq(equip.cost, 3500)
	assert_eq(equip.mash_bonus, 6)
	assert_eq(equip.boil_bonus, 6)
	assert_eq(equip.ferment_bonus, 6)

# --- Task 9: EquipmentManager automation bonus aggregation ---

func test_automation_mash_bonus_zero_when_no_automation():
	assert_eq(EquipmentManager.get_automation_mash_bonus(), 0)

func test_automation_boil_bonus_zero_when_no_automation():
	assert_eq(EquipmentManager.get_automation_boil_bonus(), 0)

func test_automation_ferment_bonus_zero_when_no_automation():
	assert_eq(EquipmentManager.get_automation_ferment_bonus(), 0)

# --- Task 10: QualityCalculator.get_effective_phase_bonus ---

func test_effective_phase_bonus_staff_only():
	var staff: Dictionary = {"flavor": 3.0, "technique": 2.0}
	var result: Dictionary = QualityCalculator.get_effective_phase_bonus(staff, 0)
	assert_almost_eq(result["flavor"], 3.0, 0.001)
	assert_almost_eq(result["technique"], 2.0, 0.001)

func test_effective_phase_bonus_auto_wins():
	var staff: Dictionary = {"flavor": 1.0, "technique": 1.0}
	# auto=5 > staff_total=2 → split 2.5/2.5
	var result: Dictionary = QualityCalculator.get_effective_phase_bonus(staff, 5)
	assert_almost_eq(result["flavor"], 2.5, 0.001)
	assert_almost_eq(result["technique"], 2.5, 0.001)

func test_effective_phase_bonus_staff_wins():
	var staff: Dictionary = {"flavor": 4.0, "technique": 4.0}
	# auto=5 < staff_total=8 → returns staff
	var result: Dictionary = QualityCalculator.get_effective_phase_bonus(staff, 5)
	assert_almost_eq(result["flavor"], 4.0, 0.001)
	assert_almost_eq(result["technique"], 4.0, 0.001)

func test_effective_phase_bonus_equal_uses_staff():
	var staff: Dictionary = {"flavor": 3.0, "technique": 2.0}
	# auto=5 == staff_total=5 → NOT greater, returns staff
	var result: Dictionary = QualityCalculator.get_effective_phase_bonus(staff, 5)
	assert_almost_eq(result["flavor"], 3.0, 0.001)
	assert_almost_eq(result["technique"], 2.0, 0.001)
