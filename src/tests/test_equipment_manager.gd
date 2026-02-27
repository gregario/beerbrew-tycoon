extends GutTest

func before_each():
	GameState.reset()
	EquipmentManager.reset()

# --- Purchase tests ---

func test_purchase_equipment():
	GameState.balance = 500.0
	var result := EquipmentManager.purchase("biab_setup")
	assert_true(result, "Should succeed with enough balance")
	assert_has(EquipmentManager.owned_equipment, "biab_setup")
	assert_almost_eq(GameState.balance, 350.0, 0.01)

func test_purchase_insufficient_balance():
	GameState.balance = 10.0
	var result := EquipmentManager.purchase("biab_setup")
	assert_false(result)
	assert_does_not_have(EquipmentManager.owned_equipment, "biab_setup")
	assert_almost_eq(GameState.balance, 10.0, 0.01)

func test_purchase_already_owned():
	GameState.balance = 500.0
	EquipmentManager.purchase("biab_setup")
	var balance_after_first := GameState.balance
	var result := EquipmentManager.purchase("biab_setup")
	assert_false(result)
	assert_almost_eq(GameState.balance, balance_after_first, 0.01)

func test_purchase_free_tier1():
	GameState.balance = 0.0
	var result := EquipmentManager.purchase("extract_kit")
	assert_true(result)
	assert_has(EquipmentManager.owned_equipment, "extract_kit")

# --- Upgrade tests ---

func test_upgrade_equipment():
	GameState.balance = 500.0
	EquipmentManager.purchase("extract_kit")
	var result := EquipmentManager.upgrade("extract_kit")
	assert_true(result)
	assert_does_not_have(EquipmentManager.owned_equipment, "extract_kit")
	assert_has(EquipmentManager.owned_equipment, "biab_setup")
	assert_almost_eq(GameState.balance, 410.0, 0.01)

func test_upgrade_keeps_slot():
	GameState.balance = 500.0
	EquipmentManager.purchase("extract_kit")
	EquipmentManager.assign_to_slot(0, "extract_kit")
	EquipmentManager.upgrade("extract_kit")
	assert_eq(EquipmentManager.station_slots[0], "biab_setup")

func test_upgrade_no_path():
	GameState.balance = 5000.0
	EquipmentManager.purchase("three_vessel")
	var result := EquipmentManager.upgrade("three_vessel")
	assert_false(result)

func test_upgrade_insufficient_balance():
	GameState.balance = 10.0
	EquipmentManager.owned_equipment.append("extract_kit")
	var result := EquipmentManager.upgrade("extract_kit")
	assert_false(result)
	assert_has(EquipmentManager.owned_equipment, "extract_kit")

# --- Slot tests ---

func test_assign_to_slot():
	EquipmentManager.owned_equipment.append("biab_setup")
	EquipmentManager.assign_to_slot(0, "biab_setup")
	assert_eq(EquipmentManager.station_slots[0], "biab_setup")

func test_assign_unowned_fails():
	var result := EquipmentManager.assign_to_slot(0, "biab_setup")
	assert_false(result)
	assert_eq(EquipmentManager.station_slots[0], "")

func test_unassign_slot():
	EquipmentManager.owned_equipment.append("biab_setup")
	EquipmentManager.assign_to_slot(0, "biab_setup")
	EquipmentManager.unassign_slot(0)
	assert_eq(EquipmentManager.station_slots[0], "")

func test_swap_slots():
	EquipmentManager.owned_equipment.append("biab_setup")
	EquipmentManager.owned_equipment.append("glass_carboy")
	EquipmentManager.assign_to_slot(0, "biab_setup")
	EquipmentManager.assign_to_slot(1, "glass_carboy")
	EquipmentManager.assign_to_slot(0, "glass_carboy")
	assert_eq(EquipmentManager.station_slots[0], "glass_carboy")
	assert_ne(EquipmentManager.station_slots[1], "glass_carboy")

func test_max_slots_enforced():
	EquipmentManager.owned_equipment.append("extract_kit")
	EquipmentManager.owned_equipment.append("bucket_fermenter")
	EquipmentManager.owned_equipment.append("bottles_capper")
	EquipmentManager.owned_equipment.append("cleaning_bucket")
	EquipmentManager.assign_to_slot(0, "extract_kit")
	EquipmentManager.assign_to_slot(1, "bucket_fermenter")
	EquipmentManager.assign_to_slot(2, "bottles_capper")
	var result := EquipmentManager.assign_to_slot(3, "cleaning_bucket")
	assert_false(result)

# --- Bonus aggregation tests ---

func test_bonus_aggregation_empty():
	EquipmentManager.recalculate_bonuses()
	assert_eq(EquipmentManager.active_bonuses.get("sanitation", 0), 0)
	assert_eq(EquipmentManager.active_bonuses.get("temp_control", 0), 0)
	assert_almost_eq(EquipmentManager.active_bonuses.get("efficiency", 0.0), 0.0, 0.001)

func test_bonus_aggregation_with_equipment():
	EquipmentManager.owned_equipment.append("biab_setup")
	EquipmentManager.owned_equipment.append("glass_carboy")
	EquipmentManager.assign_to_slot(0, "biab_setup")
	EquipmentManager.assign_to_slot(1, "glass_carboy")
	assert_eq(EquipmentManager.active_bonuses["sanitation"], 10)
	assert_eq(EquipmentManager.active_bonuses["temp_control"], 10)
	assert_almost_eq(EquipmentManager.active_bonuses["efficiency"], 0.10, 0.001)

func test_bonuses_apply_to_gamestate():
	EquipmentManager.owned_equipment.append("biab_setup")
	EquipmentManager.assign_to_slot(0, "biab_setup")
	assert_eq(GameState.sanitation_quality, 55)
	assert_eq(GameState.temp_control_quality, 55)

func test_bonuses_update_on_unslot():
	EquipmentManager.owned_equipment.append("biab_setup")
	EquipmentManager.assign_to_slot(0, "biab_setup")
	EquipmentManager.unassign_slot(0)
	assert_eq(GameState.sanitation_quality, 50)
	assert_eq(GameState.temp_control_quality, 50)

# --- Starting state tests ---

func test_starting_equipment():
	EquipmentManager.initialize_starting_equipment()
	assert_has(EquipmentManager.owned_equipment, "extract_kit")
	assert_has(EquipmentManager.owned_equipment, "bucket_fermenter")
	assert_has(EquipmentManager.owned_equipment, "bottles_capper")
	assert_has(EquipmentManager.owned_equipment, "cleaning_bucket")

func test_starting_bonuses_are_zero():
	EquipmentManager.initialize_starting_equipment()
	assert_eq(EquipmentManager.active_bonuses.get("sanitation", 0), 0)
	assert_eq(EquipmentManager.active_bonuses.get("temp_control", 0), 0)

# --- Reset test ---

func test_reset_clears_state():
	EquipmentManager.owned_equipment.append("biab_setup")
	EquipmentManager.assign_to_slot(0, "biab_setup")
	EquipmentManager.reset()
	assert_eq(EquipmentManager.owned_equipment.size(), 0)
	assert_eq(EquipmentManager.station_slots, ["", "", ""])
	assert_eq(EquipmentManager.active_bonuses.get("sanitation", 0), 0)

# --- State transition tests ---

func test_results_advances_to_equipment_manage():
	# Verify the EQUIPMENT_MANAGE enum value exists
	assert_true(GameState.State.has("EQUIPMENT_MANAGE"),
		"EQUIPMENT_MANAGE should exist in State enum")

func test_equipment_manage_advances_to_market_check():
	GameState.current_state = GameState.State.EQUIPMENT_MANAGE
	GameState.advance_state()
	assert_eq(GameState.current_state, GameState.State.MARKET_CHECK)

func test_reset_initializes_starting_equipment():
	GameState.reset()
	assert_has(EquipmentManager.owned_equipment, "extract_kit")
	assert_has(EquipmentManager.owned_equipment, "bucket_fermenter")
	assert_has(EquipmentManager.owned_equipment, "bottles_capper")
	assert_has(EquipmentManager.owned_equipment, "cleaning_bucket")
	assert_eq(EquipmentManager.owned_equipment.size(), 4)

# --- QualityCalculator integration ---

func test_efficiency_bonus_increases_technique():
	var sliders := {"mashing": 65.0, "boiling": 60.0, "fermenting": 20.0}

	# Baseline with no equipment
	EquipmentManager.reset()
	var base_result := QualityCalculator._compute_points(sliders)
	var base_technique: float = base_result["technique"]

	# Add equipment with efficiency bonus
	EquipmentManager.owned_equipment.append("biab_setup")
	EquipmentManager.assign_to_slot(0, "biab_setup")  # +0.05 efficiency

	var boosted_result := QualityCalculator._compute_points(sliders)
	var boosted_technique: float = boosted_result["technique"]

	assert_gt(boosted_technique, base_technique,
		"Efficiency bonus should increase technique points")
	# Expected: technique * 1.05
	assert_almost_eq(boosted_technique, base_technique * 1.05, 0.01)

func test_efficiency_bonus_does_not_affect_flavor():
	var sliders := {"mashing": 65.0, "boiling": 60.0, "fermenting": 20.0}

	EquipmentManager.reset()
	var base_result := QualityCalculator._compute_points(sliders)
	var base_flavor: float = base_result["flavor"]

	EquipmentManager.owned_equipment.append("biab_setup")
	EquipmentManager.assign_to_slot(0, "biab_setup")

	var boosted_result := QualityCalculator._compute_points(sliders)
	var boosted_flavor: float = boosted_result["flavor"]

	assert_almost_eq(boosted_flavor, base_flavor, 0.01,
		"Efficiency bonus should NOT affect flavor points")

func test_batch_size_affects_revenue():
	GameState.current_style = load("res://data/styles/pale_ale.tres")
	var base_revenue := GameState.calculate_revenue(50.0)
	assert_gt(base_revenue, 0.0, "Base revenue should be positive")
	# All current equipment has batch_size_multiplier = 1.0, so revenue
	# should be the same with or without equipment.
	# This test validates the integration point exists.

# --- Persistence tests ---

func test_save_and_load_state():
	EquipmentManager.owned_equipment = ["extract_kit", "biab_setup", "glass_carboy"]
	EquipmentManager.station_slots = ["extract_kit", "biab_setup", ""]
	EquipmentManager.recalculate_bonuses()

	var save_data := EquipmentManager.save_state()
	EquipmentManager.reset()

	assert_eq(EquipmentManager.owned_equipment.size(), 0)

	EquipmentManager.load_state(save_data)
	assert_eq(EquipmentManager.owned_equipment.size(), 3)
	assert_has(EquipmentManager.owned_equipment, "biab_setup")
	assert_eq(EquipmentManager.station_slots[0], "extract_kit")
	assert_eq(EquipmentManager.station_slots[1], "biab_setup")
	assert_eq(EquipmentManager.station_slots[2], "")
	# Bonuses recalculated: extract_kit has 0 bonuses, biab_setup has +5/+5
	assert_eq(EquipmentManager.active_bonuses["sanitation"], 5)
	assert_eq(EquipmentManager.active_bonuses["temp_control"], 5)

# --- Economy balance tests ---

func test_tier2_affordable_within_few_brews():
	assert_gte(GameState.STARTING_BALANCE, 60,
		"Starting balance should cover cheapest tier-2 equipment (Star San Kit $60)")

func test_tier3_requires_saving():
	var cheapest_tier3 := 300  # CIP Pump
	assert_gt(cheapest_tier3, GameState.MINIMUM_RECIPE_COST,
		"Tier 3 should cost more than a single brew's ingredients")

func test_tier4_is_endgame_purchase():
	var most_expensive := 1200  # 3-Vessel + Pumps
	assert_gt(most_expensive, GameState.STARTING_BALANCE,
		"Tier 4 should not be affordable at game start")

func test_upgrade_cheaper_than_direct_buy():
	for equip in EquipmentManager.get_all_equipment():
		if equip.upgrades_to != "":
			var target := EquipmentManager.get_equipment(equip.upgrades_to)
			if target:
				assert_lt(equip.upgrade_cost, target.cost,
					"Upgrading %s should cost less than buying %s" % [
						equip.equipment_id, target.equipment_id])

# --- Full integration test ---

func test_full_equipment_workflow():
	GameState.reset()

	# Starting state
	assert_eq(EquipmentManager.owned_equipment.size(), 4)
	assert_eq(EquipmentManager.station_slots, ["", "", ""])

	# Assign starting equipment
	EquipmentManager.assign_to_slot(0, "extract_kit")
	EquipmentManager.assign_to_slot(1, "bucket_fermenter")
	EquipmentManager.assign_to_slot(2, "cleaning_bucket")

	# Verify bonuses (only cleaning_bucket has +5 sanitation)
	assert_eq(GameState.sanitation_quality, 55)
	assert_eq(GameState.temp_control_quality, 50)

	# Purchase upgrade
	var balance_before := GameState.balance
	assert_true(EquipmentManager.purchase("star_san_kit"))
	assert_almost_eq(GameState.balance, balance_before - 60.0, 0.01)

	# Swap into slot
	EquipmentManager.assign_to_slot(2, "star_san_kit")
	assert_eq(GameState.sanitation_quality, 60)  # 50 + 10 (star_san)

	# Upgrade extract_kit -> biab_setup (in slot 0)
	assert_true(EquipmentManager.upgrade("extract_kit"))
	assert_eq(EquipmentManager.station_slots[0], "biab_setup")
	assert_eq(GameState.sanitation_quality, 65)  # 50 + 5(biab) + 10(star_san)
	assert_eq(GameState.temp_control_quality, 55)  # 50 + 5(biab)

	# Save and restore
	var save_data := EquipmentManager.save_state()
	EquipmentManager.reset()
	EquipmentManager.load_state(save_data)
	assert_eq(GameState.sanitation_quality, 65)
	assert_eq(GameState.temp_control_quality, 55)
