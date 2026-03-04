extends GutTest

func before_each() -> void:
	GameState.reset()
	BreweryExpansion.reset()

# --- Stage defaults ---
func test_initial_stage_is_garage() -> void:
	assert_eq(BreweryExpansion.current_stage, BreweryExpansion.Stage.GARAGE)

func test_beers_brewed_starts_at_zero() -> void:
	assert_eq(BreweryExpansion.beers_brewed, 0)

# --- Threshold checks ---
func test_cannot_expand_without_meeting_thresholds() -> void:
	assert_false(BreweryExpansion.can_expand())

func test_cannot_expand_with_only_balance() -> void:
	GameState.balance = 6000.0
	assert_false(BreweryExpansion.can_expand())

func test_cannot_expand_with_only_beers() -> void:
	BreweryExpansion.beers_brewed = 12
	assert_false(BreweryExpansion.can_expand())

func test_can_expand_when_both_thresholds_met() -> void:
	GameState.balance = 6000.0
	BreweryExpansion.beers_brewed = 12
	assert_true(BreweryExpansion.can_expand())

func test_cannot_expand_if_already_microbrewery() -> void:
	GameState.balance = 6000.0
	BreweryExpansion.beers_brewed = 12
	BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY
	assert_false(BreweryExpansion.can_expand())

# --- Expansion ---
func test_expand_deducts_cost() -> void:
	GameState.balance = 6000.0
	BreweryExpansion.beers_brewed = 12
	var result: bool = BreweryExpansion.expand()
	assert_true(result)
	assert_eq(GameState.balance, 3000.0)

func test_expand_changes_stage() -> void:
	GameState.balance = 6000.0
	BreweryExpansion.beers_brewed = 12
	BreweryExpansion.expand()
	assert_eq(BreweryExpansion.current_stage, BreweryExpansion.Stage.MICROBREWERY)

func test_expand_fails_if_cannot_afford() -> void:
	GameState.balance = 2000.0
	BreweryExpansion.beers_brewed = 12
	var result: bool = BreweryExpansion.expand()
	assert_false(result)
	assert_eq(BreweryExpansion.current_stage, BreweryExpansion.Stage.GARAGE)

# --- Stage getters ---
func test_garage_max_slots() -> void:
	assert_eq(BreweryExpansion.get_max_slots(), 3)

func test_microbrewery_max_slots() -> void:
	BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY
	assert_eq(BreweryExpansion.get_max_slots(), 5)

func test_garage_max_staff() -> void:
	assert_eq(BreweryExpansion.get_max_staff(), 0)

func test_microbrewery_max_staff() -> void:
	BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY
	assert_eq(BreweryExpansion.get_max_staff(), 2)

func test_garage_rent() -> void:
	assert_eq(BreweryExpansion.get_rent_amount(), 150.0)

func test_microbrewery_rent() -> void:
	BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY
	assert_eq(BreweryExpansion.get_rent_amount(), 400.0)

func test_garage_equipment_tier_cap() -> void:
	assert_eq(BreweryExpansion.get_equipment_tier_cap(), 2)

func test_microbrewery_equipment_tier_cap() -> void:
	BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY
	assert_eq(BreweryExpansion.get_equipment_tier_cap(), 4)

# --- Beer counter ---
func test_record_brew_increments_counter() -> void:
	BreweryExpansion.record_brew()
	assert_eq(BreweryExpansion.beers_brewed, 1)

# --- Persistence ---
func test_save_and_load() -> void:
	BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY
	BreweryExpansion.beers_brewed = 15
	var data: Dictionary = BreweryExpansion.save_state()
	BreweryExpansion.reset()
	assert_eq(BreweryExpansion.current_stage, BreweryExpansion.Stage.GARAGE)
	BreweryExpansion.load_state(data)
	assert_eq(BreweryExpansion.current_stage, BreweryExpansion.Stage.MICROBREWERY)
	assert_eq(BreweryExpansion.beers_brewed, 15)

# --- Signals ---
func test_expand_emits_signal() -> void:
	watch_signals(BreweryExpansion)
	GameState.balance = 6000.0
	BreweryExpansion.beers_brewed = 12
	BreweryExpansion.expand()
	assert_signal_emitted(BreweryExpansion, "brewery_expanded")

func test_threshold_reached_signal() -> void:
	watch_signals(BreweryExpansion)
	GameState.balance = 6000.0
	BreweryExpansion.beers_brewed = 9
	BreweryExpansion.record_brew()  # 10th brew crosses threshold
	assert_signal_emitted(BreweryExpansion, "threshold_reached")

# --- GameState integration ---
func test_rent_uses_brewery_stage() -> void:
	GameState.balance = 1000.0
	BreweryExpansion.current_stage = BreweryExpansion.Stage.GARAGE
	GameState.deduct_rent()
	assert_eq(GameState.balance, 850.0)

func test_rent_scales_at_microbrewery() -> void:
	GameState.balance = 1000.0
	BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY
	GameState.deduct_rent()
	assert_eq(GameState.balance, 600.0)

func test_reset_resets_brewery_expansion() -> void:
	BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY
	BreweryExpansion.beers_brewed = 20
	GameState.reset()
	assert_eq(BreweryExpansion.current_stage, BreweryExpansion.Stage.GARAGE)
	assert_eq(BreweryExpansion.beers_brewed, 0)

# --- Equipment slot scaling ---
func test_garage_rejects_slot_4() -> void:
	EquipmentManager.reset()
	EquipmentManager.initialize_starting_equipment()
	var result: bool = EquipmentManager.assign_to_slot(3, "extract_kit")
	assert_false(result)

func test_microbrewery_allows_slot_4() -> void:
	EquipmentManager.reset()
	EquipmentManager.initialize_starting_equipment()
	BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY
	EquipmentManager.resize_slots()
	var result: bool = EquipmentManager.assign_to_slot(3, "extract_kit")
	assert_true(result)
	assert_eq(EquipmentManager.station_slots[3], "extract_kit")

func test_resize_preserves_existing_slots() -> void:
	EquipmentManager.reset()
	EquipmentManager.initialize_starting_equipment()
	EquipmentManager.assign_to_slot(0, "extract_kit")
	EquipmentManager.assign_to_slot(1, "bucket_fermenter")
	BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY
	EquipmentManager.resize_slots()
	assert_eq(EquipmentManager.station_slots.size(), 5)
	assert_eq(EquipmentManager.station_slots[0], "extract_kit")
	assert_eq(EquipmentManager.station_slots[1], "bucket_fermenter")
	assert_eq(EquipmentManager.station_slots[3], "")
	assert_eq(EquipmentManager.station_slots[4], "")

func test_station_slots_size_matches_stage() -> void:
	EquipmentManager.reset()
	assert_eq(EquipmentManager.station_slots.size(), 3)
	BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY
	EquipmentManager.resize_slots()
	assert_eq(EquipmentManager.station_slots.size(), 5)
