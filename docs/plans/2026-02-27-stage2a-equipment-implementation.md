# Stage 2A: Equipment System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add purchasable, upgradeable brewing equipment with station slots that provide stat bonuses, managed contextually from the BreweryScene.

**Architecture:** Equipment as Godot Resources (.tres catalog), new EquipmentManager autoload for purchase/upgrade/slot logic, contextual UI on BreweryScene with popup + full shop overlay. New EQUIPMENT_MANAGE state in GameState between RESULTS and STYLE_SELECT.

**Tech Stack:** Godot 4 + GDScript, GUT for testing, Resource-based data model.

**Stack Profile:** Read `../../stacks/godot/STACK.md` before starting. Key files: `coding_standards.md`, `testing.md`, `pitfalls.md`.

**Design Doc:** `docs/plans/2026-02-27-stage2a-equipment-system-design.md`

---

### Task 1: Equipment Resource Class

**Files:**
- Create: `src/scripts/Equipment.gd`
- Test: `src/tests/test_equipment.gd`

**Step 1: Write the failing test**

Create `src/tests/test_equipment.gd`:

```gdscript
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
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — `Equipment` class not found.

**Step 3: Write minimal implementation**

Create `src/scripts/Equipment.gd`:

```gdscript
class_name Equipment
extends Resource

enum Category { BREWING, FERMENTATION, PACKAGING, UTILITY }

@export var equipment_id: String = ""
@export var equipment_name: String = ""
@export var description: String = ""
@export var tier: int = 1
@export var category: Category = Category.BREWING
@export var cost: int = 0
@export var sanitation_bonus: int = 0
@export var temp_control_bonus: int = 0
@export var efficiency_bonus: float = 0.0
@export var batch_size_multiplier: float = 1.0
@export var upgrades_to: String = ""
@export var upgrade_cost: int = 0
```

**Step 4: Run test to verify it passes**

Run: `make test`
Expected: All new tests PASS, all 158 existing tests still PASS.

**Step 5: Commit**

```bash
git add src/scripts/Equipment.gd src/tests/test_equipment.gd
git commit -m "feat: add Equipment resource class with TDD"
```

---

### Task 2: Equipment Catalog (.tres files)

**Files:**
- Create: `src/data/equipment/brewing/extract_kit.tres`
- Create: `src/data/equipment/brewing/biab_setup.tres`
- Create: `src/data/equipment/brewing/mash_tun.tres`
- Create: `src/data/equipment/brewing/three_vessel.tres`
- Create: `src/data/equipment/fermentation/bucket_fermenter.tres`
- Create: `src/data/equipment/fermentation/glass_carboy.tres`
- Create: `src/data/equipment/fermentation/temp_chamber.tres`
- Create: `src/data/equipment/fermentation/ss_conical.tres`
- Create: `src/data/equipment/packaging/bottles_capper.tres`
- Create: `src/data/equipment/packaging/bench_capper.tres`
- Create: `src/data/equipment/packaging/kegging_kit.tres`
- Create: `src/data/equipment/packaging/counter_pressure.tres`
- Create: `src/data/equipment/utility/cleaning_bucket.tres`
- Create: `src/data/equipment/utility/star_san_kit.tres`
- Create: `src/data/equipment/utility/cip_pump.tres`
- Test: `src/tests/test_equipment.gd` (add catalog load tests)

**Step 1: Create all .tres files**

Follow the existing .tres pattern from `src/data/styles/pale_ale.tres`. IMPORTANT: Use `type="Resource"` not `type="Equipment"` — custom class names fail at load time (see pitfalls.md).

Example `src/data/equipment/brewing/extract_kit.tres`:
```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/Equipment.gd" id="1_equip"]

[resource]
script = ExtResource("1_equip")
equipment_id = "extract_kit"
equipment_name = "Extract Kit"
description = "Basic stovetop setup for extract brewing. Simple but limited."
tier = 1
category = 0
cost = 0
sanitation_bonus = 0
temp_control_bonus = 0
efficiency_bonus = 0.0
batch_size_multiplier = 1.0
upgrades_to = "biab_setup"
upgrade_cost = 90
```

Create all 15 files using the catalog from the design doc:

| File | ID | Tier | Cat | San | Temp | Eff | Cost | Upgrades To | Upgrade Cost |
|------|----|------|-----|-----|------|-----|------|-------------|-------------|
| brewing/extract_kit.tres | extract_kit | 1 | 0 | 0 | 0 | 0.0 | 0 | biab_setup | 90 |
| brewing/biab_setup.tres | biab_setup | 2 | 0 | 5 | 5 | 0.05 | 150 | mash_tun | 300 |
| brewing/mash_tun.tres | mash_tun | 3 | 0 | 10 | 10 | 0.10 | 500 | three_vessel | 720 |
| brewing/three_vessel.tres | three_vessel | 4 | 0 | 15 | 15 | 0.15 | 1200 | "" | 0 |
| fermentation/bucket_fermenter.tres | bucket_fermenter | 1 | 1 | 0 | 0 | 0.0 | 0 | glass_carboy | 60 |
| fermentation/glass_carboy.tres | glass_carboy | 2 | 1 | 5 | 5 | 0.05 | 100 | temp_chamber | 240 |
| fermentation/temp_chamber.tres | temp_chamber | 3 | 1 | 5 | 15 | 0.10 | 400 | ss_conical | 540 |
| fermentation/ss_conical.tres | ss_conical | 4 | 1 | 15 | 10 | 0.10 | 900 | "" | 0 |
| packaging/bottles_capper.tres | bottles_capper | 1 | 2 | 0 | 0 | 0.0 | 0 | bench_capper | 48 |
| packaging/bench_capper.tres | bench_capper | 2 | 2 | 5 | 0 | 0.05 | 80 | kegging_kit | 210 |
| packaging/kegging_kit.tres | kegging_kit | 3 | 2 | 10 | 5 | 0.05 | 350 | counter_pressure | 480 |
| packaging/counter_pressure.tres | counter_pressure | 4 | 2 | 10 | 5 | 0.10 | 800 | "" | 0 |
| utility/cleaning_bucket.tres | cleaning_bucket | 1 | 3 | 5 | 0 | 0.0 | 0 | star_san_kit | 36 |
| utility/star_san_kit.tres | star_san_kit | 2 | 3 | 10 | 0 | 0.05 | 60 | cip_pump | 180 |
| utility/cip_pump.tres | cip_pump | 3 | 3 | 20 | 0 | 0.05 | 300 | "" | 0 |

**Step 2: Add catalog load tests**

Append to `src/tests/test_equipment.gd`:

```gdscript
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
```

**Step 3: Run tests**

Run: `make test`
Expected: All catalog tests PASS.

**Step 4: Commit**

```bash
git add src/data/equipment/ src/tests/test_equipment.gd
git commit -m "feat: add 15-item equipment catalog (tiers 1-4)"
```

---

### Task 3: EquipmentManager Autoload — Core Logic

**Files:**
- Create: `src/autoloads/EquipmentManager.gd`
- Modify: `src/project.godot` (add autoload)
- Test: `src/tests/test_equipment_manager.gd`

**Step 1: Write the failing tests**

Create `src/tests/test_equipment_manager.gd`:

```gdscript
extends GutTest

# EquipmentManager is an autoload, so we test it directly.
# Tests rely on GameState.balance for purchase checks.

func before_each():
	EquipmentManager.reset()
	GameState.reset()

# --- Purchase tests ---

func test_purchase_equipment():
	GameState.balance = 500.0
	var result := EquipmentManager.purchase("biab_setup")
	assert_true(result, "Should succeed with enough balance")
	assert_has(EquipmentManager.owned_equipment, "biab_setup")
	assert_almost_eq(GameState.balance, 350.0, 0.01)  # 500 - 150

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
	assert_false(result, "Should not buy already-owned item")
	assert_almost_eq(GameState.balance, balance_after_first, 0.01)

func test_purchase_free_tier1():
	GameState.balance = 0.0
	var result := EquipmentManager.purchase("extract_kit")
	assert_true(result, "Free items should work at zero balance")
	assert_has(EquipmentManager.owned_equipment, "extract_kit")

# --- Upgrade tests ---

func test_upgrade_equipment():
	GameState.balance = 500.0
	EquipmentManager.purchase("extract_kit")
	var result := EquipmentManager.upgrade("extract_kit")
	assert_true(result, "Should upgrade successfully")
	assert_does_not_have(EquipmentManager.owned_equipment, "extract_kit")
	assert_has(EquipmentManager.owned_equipment, "biab_setup")
	# Upgrade cost is 90 (60% of 150)
	assert_almost_eq(GameState.balance, 410.0, 0.01)  # 500 - 90

func test_upgrade_keeps_slot():
	GameState.balance = 500.0
	EquipmentManager.purchase("extract_kit")
	EquipmentManager.assign_to_slot(0, "extract_kit")
	EquipmentManager.upgrade("extract_kit")
	assert_eq(EquipmentManager.station_slots[0], "biab_setup",
		"Upgraded item should stay in its slot")

func test_upgrade_no_path():
	GameState.balance = 5000.0
	EquipmentManager.purchase("three_vessel")
	var result := EquipmentManager.upgrade("three_vessel")
	assert_false(result, "Tier 4 has no upgrade path")

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
	# Swap
	EquipmentManager.assign_to_slot(0, "glass_carboy")
	assert_eq(EquipmentManager.station_slots[0], "glass_carboy")
	# biab_setup should be unslotted (or in slot 1 if auto-swap)
	assert_ne(EquipmentManager.station_slots[1], "glass_carboy")

func test_max_slots_enforced():
	EquipmentManager.owned_equipment.append("extract_kit")
	EquipmentManager.owned_equipment.append("bucket_fermenter")
	EquipmentManager.owned_equipment.append("bottles_capper")
	EquipmentManager.owned_equipment.append("cleaning_bucket")
	EquipmentManager.assign_to_slot(0, "extract_kit")
	EquipmentManager.assign_to_slot(1, "bucket_fermenter")
	EquipmentManager.assign_to_slot(2, "bottles_capper")
	# Slot 3 doesn't exist in garage
	var result := EquipmentManager.assign_to_slot(3, "cleaning_bucket")
	assert_false(result, "Should reject slot index >= max_slots")

# --- Bonus aggregation tests ---

func test_bonus_aggregation_empty():
	EquipmentManager.recalculate_bonuses()
	assert_eq(EquipmentManager.active_bonuses.get("sanitation", 0), 0)
	assert_eq(EquipmentManager.active_bonuses.get("temp_control", 0), 0)
	assert_almost_eq(EquipmentManager.active_bonuses.get("efficiency", 0.0), 0.0, 0.001)

func test_bonus_aggregation_with_equipment():
	EquipmentManager.owned_equipment.append("biab_setup")
	EquipmentManager.owned_equipment.append("glass_carboy")
	EquipmentManager.assign_to_slot(0, "biab_setup")       # san +5, temp +5, eff +0.05
	EquipmentManager.assign_to_slot(1, "glass_carboy")     # san +5, temp +5, eff +0.05
	assert_eq(EquipmentManager.active_bonuses["sanitation"], 10)
	assert_eq(EquipmentManager.active_bonuses["temp_control"], 10)
	assert_almost_eq(EquipmentManager.active_bonuses["efficiency"], 0.10, 0.001)

func test_bonuses_apply_to_gamestate():
	EquipmentManager.owned_equipment.append("biab_setup")
	EquipmentManager.assign_to_slot(0, "biab_setup")  # san +5, temp +5
	assert_eq(GameState.sanitation_quality, 55)   # 50 base + 5
	assert_eq(GameState.temp_control_quality, 55) # 50 base + 5

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
	# Tier 1 items have zero bonuses (except cleaning_bucket with +5 sanitation)
	# But none are slotted yet, so active bonuses should be zero
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
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — `EquipmentManager` autoload not found.

**Step 3: Write the implementation**

Create `src/autoloads/EquipmentManager.gd`:

```gdscript
extends Node

## EquipmentManager — handles equipment purchasing, upgrading, slot assignment,
## and bonus aggregation.

const BASE_SANITATION: int = 50
const BASE_TEMP_CONTROL: int = 50
const MAX_SLOTS_GARAGE: int = 3

const TIER1_IDS: Array[String] = [
	"extract_kit", "bucket_fermenter", "bottles_capper", "cleaning_bucket"
]

signal equipment_purchased(equipment_id: String)
signal equipment_slotted(slot_index: int, equipment_id: String)
signal bonuses_updated(bonuses: Dictionary)

var owned_equipment: Array[String] = []
var station_slots: Array[String] = ["", "", ""]
var active_bonuses: Dictionary = {
	"sanitation": 0,
	"temp_control": 0,
	"efficiency": 0.0,
	"batch_size": 1.0,
}

var _catalog: Dictionary = {}  # equipment_id → Equipment resource

# Equipment catalog paths
const EQUIPMENT_PATHS: Array[String] = [
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

func _ready() -> void:
	_load_catalog()

func _load_catalog() -> void:
	for path in EQUIPMENT_PATHS:
		var equip = load(path) as Equipment
		if equip:
			_catalog[equip.equipment_id] = equip

func get_equipment(equipment_id: String) -> Equipment:
	return _catalog.get(equipment_id, null)

func get_all_equipment() -> Array:
	return _catalog.values()

func get_equipment_by_category(category: Equipment.Category) -> Array:
	var result: Array = []
	for equip in _catalog.values():
		if equip.category == category:
			result.append(equip)
	result.sort_custom(func(a, b): return a.tier < b.tier)
	return result

# --- Purchase ---

func purchase(equipment_id: String) -> bool:
	if equipment_id in owned_equipment:
		return false
	var equip := get_equipment(equipment_id)
	if equip == null:
		return false
	if GameState.balance < equip.cost:
		return false
	GameState.balance -= equip.cost
	GameState.balance_changed.emit(GameState.balance)
	owned_equipment.append(equipment_id)
	equipment_purchased.emit(equipment_id)
	return true

# --- Upgrade ---

func upgrade(equipment_id: String) -> bool:
	if equipment_id not in owned_equipment:
		return false
	var equip := get_equipment(equipment_id)
	if equip == null or equip.upgrades_to == "":
		return false
	if GameState.balance < equip.upgrade_cost:
		return false

	var target_id := equip.upgrades_to
	GameState.balance -= equip.upgrade_cost
	GameState.balance_changed.emit(GameState.balance)

	# If slotted, replace in slot
	var slot_idx := _find_slot(equipment_id)
	owned_equipment.erase(equipment_id)
	owned_equipment.append(target_id)

	if slot_idx >= 0:
		station_slots[slot_idx] = target_id
		recalculate_bonuses()
		equipment_slotted.emit(slot_idx, target_id)

	equipment_purchased.emit(target_id)
	return true

# --- Slot management ---

func assign_to_slot(slot_index: int, equipment_id: String) -> bool:
	if slot_index < 0 or slot_index >= MAX_SLOTS_GARAGE:
		return false
	if equipment_id not in owned_equipment:
		return false

	# Remove from any current slot
	var old_slot := _find_slot(equipment_id)
	if old_slot >= 0:
		station_slots[old_slot] = ""

	station_slots[slot_index] = equipment_id
	recalculate_bonuses()
	equipment_slotted.emit(slot_index, equipment_id)
	return true

func unassign_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= MAX_SLOTS_GARAGE:
		return
	station_slots[slot_index] = ""
	recalculate_bonuses()
	equipment_slotted.emit(slot_index, "")

func _find_slot(equipment_id: String) -> int:
	for i in range(station_slots.size()):
		if station_slots[i] == equipment_id:
			return i
	return -1

func get_unslotted_owned() -> Array:
	var result: Array = []
	for id in owned_equipment:
		if id not in station_slots:
			result.append(id)
	return result

# --- Bonus aggregation ---

func recalculate_bonuses() -> void:
	var san := 0
	var temp := 0
	var eff := 0.0
	var batch := 1.0
	for id in station_slots:
		if id == "":
			continue
		var equip := get_equipment(id)
		if equip == null:
			continue
		san += equip.sanitation_bonus
		temp += equip.temp_control_bonus
		eff += equip.efficiency_bonus
		batch *= equip.batch_size_multiplier
	active_bonuses = {
		"sanitation": san,
		"temp_control": temp,
		"efficiency": eff,
		"batch_size": batch,
	}
	# Apply to GameState
	GameState.sanitation_quality = BASE_SANITATION + san
	GameState.temp_control_quality = BASE_TEMP_CONTROL + temp
	bonuses_updated.emit(active_bonuses)

# --- Initialization ---

func initialize_starting_equipment() -> void:
	for id in TIER1_IDS:
		if id not in owned_equipment:
			owned_equipment.append(id)

# --- Reset ---

func reset() -> void:
	owned_equipment = []
	station_slots = ["", "", ""]
	active_bonuses = {
		"sanitation": 0,
		"temp_control": 0,
		"efficiency": 0.0,
		"batch_size": 1.0,
	}
	GameState.sanitation_quality = BASE_SANITATION
	GameState.temp_control_quality = BASE_TEMP_CONTROL
```

**Step 4: Register autoload in project.godot**

Add to `src/project.godot` in the `[autoload]` section:

```
EquipmentManager="*res://autoloads/EquipmentManager.gd"
```

**Step 5: Run tests**

Run: `make test`
Expected: All new tests PASS, all existing tests still PASS.

**Step 6: Commit**

```bash
git add src/autoloads/EquipmentManager.gd src/tests/test_equipment_manager.gd src/project.godot
git commit -m "feat: add EquipmentManager autoload with purchase, upgrade, slot logic"
```

---

### Task 4: GameState Integration — EQUIPMENT_MANAGE State

**Files:**
- Modify: `src/autoloads/GameState.gd` (add EQUIPMENT_MANAGE state)
- Modify: `src/scenes/Game.gd` (handle new state)
- Test: `src/tests/test_equipment_manager.gd` (add state transition tests)

**Step 1: Add state transition tests**

Append to `src/tests/test_equipment_manager.gd`:

```gdscript
# --- State transition tests ---

func test_results_advances_to_equipment_manage():
	GameState.current_state = GameState.State.RESULTS
	# Simulate conditions where game continues (no win/loss)
	GameState.balance = 500.0
	GameState.turn_counter = 0
	GameState.advance_state()
	# After RESULTS, should go to EQUIPMENT_MANAGE (then manually to MARKET_CHECK)
	assert_eq(GameState.current_state, GameState.State.EQUIPMENT_MANAGE)

func test_equipment_manage_advances_to_market_check():
	GameState.current_state = GameState.State.EQUIPMENT_MANAGE
	GameState.advance_state()
	assert_eq(GameState.current_state, GameState.State.MARKET_CHECK)
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — `EQUIPMENT_MANAGE` not in State enum.

**Step 3: Modify GameState.gd**

Add `EQUIPMENT_MANAGE` to the State enum (after RESULTS, before GAME_OVER):

```gdscript
enum State {
	MARKET_CHECK,
	STYLE_SELECT,
	RECIPE_DESIGN,
	BREWING_PHASES,
	RESULTS,
	EQUIPMENT_MANAGE,  # NEW: player manages equipment between brews
	GAME_OVER
}
```

Update `advance_state()`:

```gdscript
func advance_state() -> void:
	match current_state:
		State.MARKET_CHECK:
			_set_state(State.STYLE_SELECT)
		State.STYLE_SELECT:
			_set_state(State.RECIPE_DESIGN)
		State.RECIPE_DESIGN:
			_set_state(State.BREWING_PHASES)
		State.BREWING_PHASES:
			_set_state(State.RESULTS)
		State.RESULTS:
			_on_results_continue()
		State.EQUIPMENT_MANAGE:
			_set_state(State.MARKET_CHECK)
		State.GAME_OVER:
			pass
```

Update `_on_results_continue()` to go to EQUIPMENT_MANAGE instead of MARKET_CHECK:

```gdscript
func _on_results_continue() -> void:
	turn_counter += 1
	if MarketSystem.should_rotate(turn_counter):
		MarketSystem.rotate_demand()
	rent_due_this_turn = check_rent_due()
	if rent_due_this_turn:
		deduct_rent()
	if check_win_condition():
		run_won = true
		_set_state(State.GAME_OVER)
		game_won.emit()
	elif check_loss_condition():
		run_won = false
		_set_state(State.GAME_OVER)
		game_lost.emit()
	else:
		_set_state(State.EQUIPMENT_MANAGE)
```

Update `reset()` to also reset EquipmentManager and initialize starting equipment:

```gdscript
func reset() -> void:
	balance = STARTING_BALANCE
	turn_counter = 0
	current_style = null
	current_recipe = {}
	recipe_history = []
	last_brew_result = {}
	total_revenue = 0.0
	best_quality = 0.0
	is_brewing = false
	run_won = false
	rent_due_this_turn = false
	general_taste = 0
	style_taste = {}
	discoveries = {}
	temp_control_quality = 50
	sanitation_quality = 50
	if is_instance_valid(EquipmentManager):
		EquipmentManager.reset()
		EquipmentManager.initialize_starting_equipment()
	MarketSystem.initialize_demand()
	_set_state(State.MARKET_CHECK)
```

**Step 4: Update Game.gd state handler**

Add EQUIPMENT_MANAGE case to `_on_state_changed()` in `src/scenes/Game.gd`:

```gdscript
GameState.State.EQUIPMENT_MANAGE:
	# Show brewery scene with equipment slots visible
	# For now, auto-advance (UI added in Task 6)
	brewery_scene.set_brewing(false)
	GameState.advance_state()
```

**Step 5: Run tests**

Run: `make test`
Expected: All tests PASS. The EQUIPMENT_MANAGE state auto-advances for now until UI is built.

**Step 6: Commit**

```bash
git add src/autoloads/GameState.gd src/scenes/Game.gd src/tests/test_equipment_manager.gd
git commit -m "feat: add EQUIPMENT_MANAGE state to game flow"
```

---

### Task 5: QualityCalculator Integration — Efficiency Bonus

**Files:**
- Modify: `src/autoloads/QualityCalculator.gd` (apply efficiency bonus to technique points)
- Modify: `src/autoloads/GameState.gd` (apply batch_size to revenue)
- Test: `src/tests/test_equipment_manager.gd` (add integration tests)

**Step 1: Write integration tests**

Append to `src/tests/test_equipment_manager.gd`:

```gdscript
# --- QualityCalculator integration ---

func test_efficiency_bonus_multiplies_technique():
	# With no equipment bonus, technique points are base
	var sliders := {"mashing": 65.0, "boiling": 60.0, "fermenting": 20.0}
	var base_result := QualityCalculator._compute_points(sliders)
	var base_technique: float = base_result["total_technique"]

	# Apply efficiency bonus via EquipmentManager
	EquipmentManager.owned_equipment.append("biab_setup")
	EquipmentManager.assign_to_slot(0, "biab_setup")  # +0.05 efficiency

	# QualityCalculator should factor in EquipmentManager.active_bonuses.efficiency
	var boosted_result := QualityCalculator._compute_points(sliders)
	var boosted_technique: float = boosted_result["total_technique"]
	assert_gt(boosted_technique, base_technique,
		"Efficiency bonus should increase technique points")

	EquipmentManager.reset()

func test_batch_size_affects_revenue():
	# This tests that batch_size_multiplier from equipment affects revenue
	GameState.current_style = load("res://data/styles/pale_ale.tres")
	var base_revenue := GameState.calculate_revenue(50.0)

	# batch_size_multiplier is 1.0 for all current equipment, so this is a
	# placeholder test. When batch_size > 1.0 equipment is added, revenue
	# should increase proportionally.
	assert_gt(base_revenue, 0.0)
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — `_compute_points` doesn't account for efficiency bonus yet.

**Step 3: Modify QualityCalculator.gd**

In the `_compute_points()` method, after computing technique points, multiply by efficiency:

Find the point calculation section and add efficiency multiplier. The exact edit depends on the method structure, but the key change is:

```gdscript
# After computing total_technique points:
if is_instance_valid(EquipmentManager):
	var eff_bonus: float = EquipmentManager.active_bonuses.get("efficiency", 0.0)
	total_technique *= (1.0 + eff_bonus)
```

For batch_size in revenue, modify `GameState.calculate_revenue()`:

```gdscript
func calculate_revenue(quality_score: float) -> float:
	if current_style == null:
		return 0.0
	var style_id: String = current_style.style_id
	var demand_multiplier := MarketSystem.get_demand_weight(style_id)
	var quality_mult := quality_to_multiplier(quality_score)
	var batch_mult := 1.0
	if is_instance_valid(EquipmentManager):
		batch_mult = EquipmentManager.active_bonuses.get("batch_size", 1.0)
	return current_style.base_price * quality_mult * demand_multiplier * batch_mult
```

**Step 4: Run tests**

Run: `make test`
Expected: All tests PASS.

**Step 5: Commit**

```bash
git add src/autoloads/QualityCalculator.gd src/autoloads/GameState.gd src/tests/test_equipment_manager.gd
git commit -m "feat: integrate equipment bonuses with quality scoring and revenue"
```

---

### Task 6: BreweryScene UI — Station Slots

**Files:**
- Modify: `src/scenes/BreweryScene.gd` (add clickable station slots)
- Modify: `src/scenes/BreweryScene.tscn` (add slot UI nodes)
- Modify: `src/scenes/Game.gd` (handle EQUIPMENT_MANAGE state properly)

**Step 1: Update BreweryScene.gd**

Add station slot interaction to `src/scenes/BreweryScene.gd`:

```gdscript
extends Node2D

signal slot_clicked(slot_index: int)
signal start_brewing_pressed()

@onready var kettle_node: ColorRect = $Stations/Kettle
@onready var fermenter_node: ColorRect = $Stations/Fermenter
@onready var bottler_node: ColorRect = $Stations/Bottler
@onready var brew_animation: AnimationPlayer = $BrewAnimation
@onready var character_node: ColorRect = $Character

# Station slot buttons (added to scene tree)
var _slot_buttons: Array[Button] = []
var _slot_labels: Array[Label] = []
var _start_button: Button = null
var _balance_label: Label = null

func _ready() -> void:
	_create_slot_ui()
	_create_start_button()
	set_equipment_mode(false)

func _create_slot_ui() -> void:
	var slot_positions := [
		kettle_node.position,
		fermenter_node.position,
		bottler_node.position,
	]
	for i in range(3):
		var btn := Button.new()
		btn.text = "[ Empty Slot ]"
		btn.custom_minimum_size = Vector2(120, 40)
		btn.position = slot_positions[i] + Vector2(0, -50)
		btn.pressed.connect(_on_slot_pressed.bind(i))
		btn.visible = false
		add_child(btn)
		_slot_buttons.append(btn)

		var lbl := Label.new()
		lbl.text = ""
		lbl.position = slot_positions[i] + Vector2(0, -70)
		lbl.visible = false
		add_child(lbl)
		_slot_labels.append(lbl)

func _create_start_button() -> void:
	_start_button = Button.new()
	_start_button.text = "Start Brewing →"
	_start_button.custom_minimum_size = Vector2(200, 50)
	_start_button.position = Vector2(540, 620)  # Bottom center
	_start_button.pressed.connect(func(): start_brewing_pressed.emit())
	_start_button.visible = false
	add_child(_start_button)

	_balance_label = Label.new()
	_balance_label.text = ""
	_balance_label.position = Vector2(540, 20)  # Top center
	_balance_label.visible = false
	add_child(_balance_label)

func set_equipment_mode(active: bool) -> void:
	for btn in _slot_buttons:
		btn.visible = active
	for lbl in _slot_labels:
		lbl.visible = active
	if _start_button:
		_start_button.visible = active
	if _balance_label:
		_balance_label.visible = active
	if active:
		refresh_slots()

func refresh_slots() -> void:
	for i in range(3):
		var equip_id: String = EquipmentManager.station_slots[i]
		if equip_id == "":
			_slot_buttons[i].text = "[ + Empty ]"
			_slot_labels[i].text = ""
		else:
			var equip := EquipmentManager.get_equipment(equip_id)
			_slot_buttons[i].text = equip.equipment_name if equip else equip_id
			_slot_labels[i].text = "Tier %d" % equip.tier if equip else ""
	if _balance_label:
		_balance_label.text = "Balance: $%d" % int(GameState.balance)

func _on_slot_pressed(slot_index: int) -> void:
	slot_clicked.emit(slot_index)

func set_brewing(active: bool) -> void:
	if active:
		if brew_animation and brew_animation.has_animation("brewing"):
			brew_animation.play("brewing")
		if kettle_node:
			kettle_node.color = Color(0.8, 0.4, 0.1)
	else:
		if brew_animation and brew_animation.is_playing():
			brew_animation.stop()
		if kettle_node:
			kettle_node.color = Color(0.5, 0.5, 0.5)
```

**Step 2: Update Game.gd EQUIPMENT_MANAGE handler**

Replace the auto-advance with actual equipment management:

```gdscript
GameState.State.EQUIPMENT_MANAGE:
	brewery_scene.set_brewing(false)
	brewery_scene.set_equipment_mode(true)
```

Connect signals in `_ready()`:

```gdscript
# Equipment management
brewery_scene.slot_clicked.connect(_on_slot_clicked)
brewery_scene.start_brewing_pressed.connect(_on_start_brewing)
```

Add handler methods:

```gdscript
func _on_slot_clicked(slot_index: int) -> void:
	# Open equipment popup for this slot (Task 7)
	pass

func _on_start_brewing() -> void:
	brewery_scene.set_equipment_mode(false)
	GameState.advance_state()
```

Also update other state handlers to disable equipment mode:

In `_on_state_changed`, add at the top:
```gdscript
brewery_scene.set_equipment_mode(false)
```

**Step 3: Run tests and verify manually**

Run: `make test`
Expected: All tests PASS.

**Step 4: Commit**

```bash
git add src/scenes/BreweryScene.gd src/scenes/BreweryScene.tscn src/scenes/Game.gd
git commit -m "feat: add station slot UI to BreweryScene with equipment mode"
```

---

### Task 7: Equipment Popup UI

**Files:**
- Create: `src/ui/EquipmentPopup.gd`
- Create: `src/ui/EquipmentPopup.tscn`
- Modify: `src/scenes/Game.gd` (wire popup to slot clicks)

**Step 1: Create EquipmentPopup**

Create `src/ui/EquipmentPopup.gd`:

```gdscript
extends Control

## EquipmentPopup — mini-card shown when clicking a station slot.
## Shows equipped item or available items for an empty slot.

signal item_assigned(slot_index: int, equipment_id: String)
signal browse_shop_requested()
signal upgrade_requested(equipment_id: String)
signal closed()

@onready var panel: PanelContainer = $DimOverlay/Panel
@onready var title_label: Label = $DimOverlay/Panel/VBox/Header/Title
@onready var item_list: VBoxContainer = $DimOverlay/Panel/VBox/ItemList
@onready var close_btn: Button = $DimOverlay/Panel/VBox/Footer/CloseBtn
@onready var shop_btn: Button = $DimOverlay/Panel/VBox/Footer/ShopBtn
@onready var dim_overlay: ColorRect = $DimOverlay

var _slot_index: int = -1

func _ready() -> void:
	close_btn.pressed.connect(func(): closed.emit())
	shop_btn.pressed.connect(func(): browse_shop_requested.emit())
	dim_overlay.gui_input.connect(_on_dim_input)
	visible = false

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		closed.emit()

func show_for_slot(slot_index: int) -> void:
	_slot_index = slot_index
	_rebuild_ui()
	visible = true
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)

func _rebuild_ui() -> void:
	# Clear old items
	for child in item_list.get_children():
		child.queue_free()

	var current_id: String = EquipmentManager.station_slots[_slot_index]

	if current_id != "":
		# Show equipped item with stats
		title_label.text = "Slot %d — Equipped" % (_slot_index + 1)
		var equip := EquipmentManager.get_equipment(current_id)
		if equip:
			_add_equipped_item(equip)
	else:
		# Show available items to assign
		title_label.text = "Slot %d — Choose Equipment" % (_slot_index + 1)
		var unslotted := EquipmentManager.get_unslotted_owned()
		if unslotted.size() == 0:
			var lbl := Label.new()
			lbl.text = "No unassigned equipment.\nVisit the shop to buy more."
			item_list.add_child(lbl)
		else:
			for id in unslotted:
				var equip := EquipmentManager.get_equipment(id)
				if equip:
					_add_assignable_item(equip)

func _add_equipped_item(equip: Equipment) -> void:
	var vbox := VBoxContainer.new()

	var name_lbl := Label.new()
	name_lbl.text = "%s (Tier %d)" % [equip.equipment_name, equip.tier]
	vbox.add_child(name_lbl)

	var stats_lbl := Label.new()
	var parts: Array[String] = []
	if equip.sanitation_bonus > 0:
		parts.append("+%d sanitation" % equip.sanitation_bonus)
	if equip.temp_control_bonus > 0:
		parts.append("+%d temp control" % equip.temp_control_bonus)
	if equip.efficiency_bonus > 0.0:
		parts.append("+%d%% efficiency" % int(equip.efficiency_bonus * 100))
	stats_lbl.text = ", ".join(parts) if parts.size() > 0 else "No bonuses"
	vbox.add_child(stats_lbl)

	var btn_row := HBoxContainer.new()

	var swap_btn := Button.new()
	swap_btn.text = "Swap"
	swap_btn.pressed.connect(func():
		EquipmentManager.unassign_slot(_slot_index)
		_rebuild_ui()
	)
	btn_row.add_child(swap_btn)

	if equip.upgrades_to != "":
		var target := EquipmentManager.get_equipment(equip.upgrades_to)
		var upgrade_btn := Button.new()
		upgrade_btn.text = "Upgrade → %s ($%d)" % [
			target.equipment_name if target else equip.upgrades_to,
			equip.upgrade_cost
		]
		upgrade_btn.pressed.connect(func():
			upgrade_requested.emit(equip.equipment_id)
		)
		if GameState.balance < equip.upgrade_cost:
			upgrade_btn.disabled = true
		btn_row.add_child(upgrade_btn)

	vbox.add_child(btn_row)
	item_list.add_child(vbox)

func _add_assignable_item(equip: Equipment) -> void:
	var hbox := HBoxContainer.new()

	var lbl := Label.new()
	lbl.text = "%s (T%d)" % [equip.equipment_name, equip.tier]
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(lbl)

	var btn := Button.new()
	btn.text = "Assign"
	btn.pressed.connect(func():
		item_assigned.emit(_slot_index, equip.equipment_id)
	)
	hbox.add_child(btn)

	item_list.add_child(hbox)
```

**Step 2: Create EquipmentPopup.tscn**

Build the scene tree matching the node references above. Follow the card pattern from existing overlays (DimOverlay + PanelContainer).

Scene structure:
```
EquipmentPopup (Control, full_rect)
  └─ DimOverlay (ColorRect, full_rect, color=#0F172499)
     └─ Panel (PanelContainer, centered, min_size=500x400)
        └─ VBox (VBoxContainer, margin=32)
           ├─ Header (HBoxContainer)
           │  └─ Title (Label)
           ├─ HSeparator
           ├─ ItemList (VBoxContainer, size_flags_vertical=EXPAND_FILL)
           └─ Footer (HBoxContainer, alignment=END)
              ├─ ShopBtn (Button, text="Browse Shop")
              └─ CloseBtn (Button, text="Close")
```

**Step 3: Wire in Game.gd**

Add popup to Game scene, connect signals:

```gdscript
@onready var equipment_popup: Control = $EquipmentPopup

func _ready() -> void:
	# ... existing code ...
	equipment_popup.item_assigned.connect(_on_equipment_assigned)
	equipment_popup.browse_shop_requested.connect(_on_browse_shop)
	equipment_popup.upgrade_requested.connect(_on_equipment_upgrade)
	equipment_popup.closed.connect(_on_popup_closed)

func _on_slot_clicked(slot_index: int) -> void:
	equipment_popup.show_for_slot(slot_index)

func _on_equipment_assigned(slot_index: int, equipment_id: String) -> void:
	EquipmentManager.assign_to_slot(slot_index, equipment_id)
	equipment_popup.visible = false
	brewery_scene.refresh_slots()

func _on_equipment_upgrade(equipment_id: String) -> void:
	if EquipmentManager.upgrade(equipment_id):
		if is_instance_valid(ToastManager):
			var equip := EquipmentManager.get_equipment(equipment_id)
			var target_name := ""
			if equip:
				var target := EquipmentManager.get_equipment(equip.upgrades_to)
				target_name = target.equipment_name if target else ""
			ToastManager.show_toast("Upgraded to %s!" % target_name)
		equipment_popup.visible = false
		brewery_scene.refresh_slots()

func _on_browse_shop() -> void:
	equipment_popup.visible = false
	# Show equipment shop (Task 8)

func _on_popup_closed() -> void:
	equipment_popup.visible = false
```

**Step 4: Run tests and verify manually**

Run: `make test`
Expected: All tests PASS.

**Step 5: Commit**

```bash
git add src/ui/EquipmentPopup.gd src/ui/EquipmentPopup.tscn src/scenes/Game.gd
git commit -m "feat: add EquipmentPopup UI for station slot interaction"
```

---

### Task 8: Equipment Shop Card UI

**Files:**
- Create: `src/ui/EquipmentShop.gd`
- Create: `src/ui/EquipmentShop.tscn`
- Modify: `src/scenes/Game.gd` (wire shop)

**Step 1: Create EquipmentShop.gd**

```gdscript
extends Control

## EquipmentShop — full catalog overlay for browsing and purchasing equipment.

signal closed()

@onready var title_label: Label = $DimOverlay/Panel/VBox/Header/Title
@onready var balance_label: Label = $DimOverlay/Panel/VBox/Header/Balance
@onready var tab_container: HBoxContainer = $DimOverlay/Panel/VBox/Tabs
@onready var item_list: VBoxContainer = $DimOverlay/Panel/VBox/Scroll/ItemList
@onready var close_btn: Button = $DimOverlay/Panel/VBox/Footer/CloseBtn
@onready var dim_overlay: ColorRect = $DimOverlay

var _current_filter: int = -1  # -1 = all

func _ready() -> void:
	close_btn.pressed.connect(func(): closed.emit())
	dim_overlay.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed:
			closed.emit()
	)
	_create_tabs()
	visible = false

func _create_tabs() -> void:
	var tab_names := ["All", "Brewing", "Fermentation", "Packaging", "Utility"]
	for i in range(tab_names.size()):
		var btn := Button.new()
		btn.text = tab_names[i]
		btn.pressed.connect(_on_tab_pressed.bind(i - 1))  # -1 for All
		tab_container.add_child(btn)

func _on_tab_pressed(filter: int) -> void:
	_current_filter = filter
	refresh()

func show_shop() -> void:
	_current_filter = -1
	refresh()
	visible = true
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)

func refresh() -> void:
	balance_label.text = "$%d" % int(GameState.balance)

	for child in item_list.get_children():
		child.queue_free()

	var items: Array
	if _current_filter < 0:
		items = EquipmentManager.get_all_equipment()
	else:
		items = EquipmentManager.get_equipment_by_category(_current_filter as Equipment.Category)

	# Sort by tier
	items.sort_custom(func(a, b): return a.tier < b.tier)

	for equip in items:
		_add_shop_item(equip as Equipment)

func _add_shop_item(equip: Equipment) -> void:
	var hbox := HBoxContainer.new()
	hbox.custom_minimum_size.y = 48

	# Name + tier
	var name_lbl := Label.new()
	var owned := equip.equipment_id in EquipmentManager.owned_equipment
	var prefix := "✓ " if owned else ""
	name_lbl.text = "%s%s (T%d)" % [prefix, equip.equipment_name, equip.tier]
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(name_lbl)

	# Stats
	var stats_lbl := Label.new()
	var parts: Array[String] = []
	if equip.sanitation_bonus > 0:
		parts.append("+%d san" % equip.sanitation_bonus)
	if equip.temp_control_bonus > 0:
		parts.append("+%d temp" % equip.temp_control_bonus)
	if equip.efficiency_bonus > 0.0:
		parts.append("+%d%% eff" % int(equip.efficiency_bonus * 100))
	stats_lbl.text = ", ".join(parts) if parts.size() > 0 else "—"
	stats_lbl.custom_minimum_size.x = 180
	hbox.add_child(stats_lbl)

	# Action button
	if owned:
		# Check if upgradeable
		if equip.upgrades_to != "":
			var target := EquipmentManager.get_equipment(equip.upgrades_to)
			if equip.upgrades_to not in EquipmentManager.owned_equipment:
				var btn := Button.new()
				btn.text = "Upgrade → %s ($%d)" % [
					target.equipment_name if target else equip.upgrades_to,
					equip.upgrade_cost
				]
				btn.pressed.connect(func():
					if EquipmentManager.upgrade(equip.equipment_id):
						if is_instance_valid(ToastManager):
							ToastManager.show_toast("Upgraded to %s!" % (target.equipment_name if target else ""))
						refresh()
				)
				if GameState.balance < equip.upgrade_cost:
					btn.disabled = true
				hbox.add_child(btn)
			else:
				var lbl := Label.new()
				lbl.text = "Owned"
				hbox.add_child(lbl)
		else:
			var lbl := Label.new()
			lbl.text = "Owned"
			hbox.add_child(lbl)
	else:
		var btn := Button.new()
		btn.text = "Buy ($%d)" % equip.cost
		btn.pressed.connect(func():
			if EquipmentManager.purchase(equip.equipment_id):
				if is_instance_valid(ToastManager):
					ToastManager.show_toast("Purchased %s!" % equip.equipment_name)
				refresh()
		)
		if GameState.balance < equip.cost:
			btn.disabled = true
		hbox.add_child(btn)

	item_list.add_child(hbox)
```

**Step 2: Create EquipmentShop.tscn**

Scene structure (follows existing card pattern, 900x550):
```
EquipmentShop (Control, full_rect)
  └─ DimOverlay (ColorRect, full_rect, color=#0F172499)
     └─ Panel (PanelContainer, centered, min_size=900x550)
        └─ VBox (VBoxContainer, margin=32)
           ├─ Header (HBoxContainer)
           │  ├─ Title (Label, text="Equipment Shop")
           │  └─ Balance (Label, h_flags=EXPAND_FILL, h_alignment=RIGHT)
           ├─ HSeparator
           ├─ Tabs (HBoxContainer)
           ├─ Scroll (ScrollContainer, v_flags=EXPAND_FILL)
           │  └─ ItemList (VBoxContainer, h_flags=EXPAND_FILL)
           └─ Footer (HBoxContainer, alignment=END)
              └─ CloseBtn (Button, text="Close", min_size=150x44)
```

**Step 3: Wire in Game.gd**

```gdscript
@onready var equipment_shop: Control = $EquipmentShop

func _ready() -> void:
	# ... existing code ...
	equipment_shop.closed.connect(_on_shop_closed)

func _on_browse_shop() -> void:
	equipment_popup.visible = false
	equipment_shop.show_shop()

func _on_shop_closed() -> void:
	equipment_shop.visible = false
	brewery_scene.refresh_slots()
```

Add equipment_shop to `_all_overlays` list and `_hide_all_overlays`.

**Step 4: Run tests**

Run: `make test`
Expected: All tests PASS.

**Step 5: Commit**

```bash
git add src/ui/EquipmentShop.gd src/ui/EquipmentShop.tscn src/scenes/Game.gd
git commit -m "feat: add EquipmentShop card UI with category tabs"
```

---

### Task 9: BrewingPhases Bonus Display

**Files:**
- Modify: `src/ui/BrewingPhases.gd` (add equipment bonus label)

**Step 1: Add bonus display**

In `src/ui/BrewingPhases.gd`, in the `refresh()` method, add a label showing active equipment bonuses:

```gdscript
# In refresh(), after setting up sliders:
if is_instance_valid(EquipmentManager):
	var bonuses := EquipmentManager.active_bonuses
	var parts: Array[String] = []
	var san: int = bonuses.get("sanitation", 0)
	var temp: int = bonuses.get("temp_control", 0)
	var eff: float = bonuses.get("efficiency", 0.0)
	if san > 0:
		parts.append("+%d sanitation" % san)
	if temp > 0:
		parts.append("+%d temp control" % temp)
	if eff > 0.0:
		parts.append("+%d%% efficiency" % int(eff * 100))
	if parts.size() > 0:
		bonus_label.text = "Equipment: " + ", ".join(parts)
		bonus_label.visible = true
	else:
		bonus_label.visible = false
```

Add an `@onready var bonus_label: Label` reference, and add the Label node to BrewingPhases.tscn above the sliders.

**Step 2: Run tests**

Run: `make test`
Expected: All tests PASS.

**Step 3: Commit**

```bash
git add src/ui/BrewingPhases.gd src/ui/BrewingPhases.tscn
git commit -m "feat: show equipment bonuses on BrewingPhases screen"
```

---

### Task 10: Save/Load Persistence

**Files:**
- Modify: `src/autoloads/EquipmentManager.gd` (add save/load methods)
- Modify: `src/autoloads/GameState.gd` (include equipment in save/load if save system exists)
- Test: `src/tests/test_equipment_manager.gd` (add persistence tests)

**Step 1: Write persistence tests**

Append to `src/tests/test_equipment_manager.gd`:

```gdscript
# --- Persistence tests ---

func test_save_and_load_state():
	EquipmentManager.owned_equipment = ["extract_kit", "biab_setup", "glass_carboy"]
	EquipmentManager.station_slots = ["extract_kit", "biab_setup", ""]
	EquipmentManager.recalculate_bonuses()

	var save_data := EquipmentManager.save_state()
	EquipmentManager.reset()

	# Verify reset cleared everything
	assert_eq(EquipmentManager.owned_equipment.size(), 0)

	# Load
	EquipmentManager.load_state(save_data)
	assert_eq(EquipmentManager.owned_equipment.size(), 3)
	assert_has(EquipmentManager.owned_equipment, "biab_setup")
	assert_eq(EquipmentManager.station_slots[0], "extract_kit")
	assert_eq(EquipmentManager.station_slots[1], "biab_setup")
	assert_eq(EquipmentManager.station_slots[2], "")
	# Bonuses should be recalculated
	assert_eq(EquipmentManager.active_bonuses["sanitation"], 5)  # biab only (slot 1)
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — `save_state` / `load_state` methods don't exist.

**Step 3: Implement save/load**

Add to `src/autoloads/EquipmentManager.gd`:

```gdscript
func save_state() -> Dictionary:
	return {
		"owned_equipment": owned_equipment.duplicate(),
		"station_slots": station_slots.duplicate(),
	}

func load_state(data: Dictionary) -> void:
	owned_equipment = data.get("owned_equipment", [])
	station_slots = data.get("station_slots", ["", "", ""])
	recalculate_bonuses()
```

If GameState has a save/load system, integrate EquipmentManager.save_state() / load_state() into it. If no save system exists yet, these methods are ready for when one is added.

**Step 4: Run tests**

Run: `make test`
Expected: All tests PASS.

**Step 5: Commit**

```bash
git add src/autoloads/EquipmentManager.gd src/tests/test_equipment_manager.gd
git commit -m "feat: add equipment save/load persistence methods"
```

---

### Task 11: Economy Balance Test

**Files:**
- Test: `src/tests/test_equipment_manager.gd`

**Step 1: Write economy tests**

Append to `src/tests/test_equipment_manager.gd`:

```gdscript
# --- Economy balance tests ---

func test_tier2_affordable_within_few_brews():
	# Starting balance is 500. Cheapest tier-2 item is Star San Kit at 60.
	# Player should be able to afford at least one tier-2 item after 1 brew.
	assert_gte(GameState.STARTING_BALANCE, 60,
		"Starting balance should cover cheapest tier-2 equipment")

func test_tier3_requires_multiple_brews():
	# Tier 3 items cost 300-500. With starting balance 500, player can
	# barely afford one, but after ingredient costs they'll need more brews.
	var cheapest_tier3 := 300  # CIP Pump
	var min_ingredient_cost := GameState.MINIMUM_RECIPE_COST  # 50
	# After one brew cycle (cost ingredients, earn revenue), check range
	assert_gt(cheapest_tier3, min_ingredient_cost,
		"Tier 3 should cost more than a single brew's ingredients")

func test_tier4_is_endgame_purchase():
	# Most expensive tier-4 item is 3-Vessel at 1200.
	# This should require significant saving (multiple brews).
	var most_expensive := 1200
	assert_gt(most_expensive, GameState.STARTING_BALANCE,
		"Tier 4 should not be affordable at game start")

func test_upgrade_cheaper_than_direct_buy():
	# Verify upgrade costs are less than buying the target directly
	for path in ALL_EQUIPMENT_PATHS:
		var equip = load(path) as Equipment
		if equip.upgrades_to != "":
			var target := load(_find_path_for_id(equip.upgrades_to)) as Equipment
			if target:
				assert_lt(equip.upgrade_cost, target.cost,
					"Upgrading %s should be cheaper than buying %s directly" % [
						equip.equipment_id, target.equipment_id])

func _find_path_for_id(equipment_id: String) -> String:
	for path in ALL_EQUIPMENT_PATHS:
		var equip = load(path) as Equipment
		if equip and equip.equipment_id == equipment_id:
			return path
	return ""
```

**Step 2: Run tests**

Run: `make test`
Expected: All tests PASS.

**Step 3: Commit**

```bash
git add src/tests/test_equipment_manager.gd
git commit -m "test: add economy balance tests for equipment pricing"
```

---

### Task 12: Final Integration Test & Cleanup

**Files:**
- Test: `src/tests/test_equipment_manager.gd` (add full integration test)
- Verify: All 158+ tests pass

**Step 1: Write full integration test**

```gdscript
# --- Full integration test ---

func test_full_equipment_workflow():
	# Simulate a complete equipment workflow
	GameState.reset()

	# Starting state: 4 tier-1 items owned, nothing slotted
	assert_eq(EquipmentManager.owned_equipment.size(), 4)
	assert_eq(EquipmentManager.station_slots, ["", "", ""])

	# Assign starting equipment
	EquipmentManager.assign_to_slot(0, "extract_kit")
	EquipmentManager.assign_to_slot(1, "bucket_fermenter")
	EquipmentManager.assign_to_slot(2, "cleaning_bucket")

	# Verify starting bonuses (only cleaning_bucket has +5 sanitation)
	assert_eq(GameState.sanitation_quality, 55)  # 50 + 5
	assert_eq(GameState.temp_control_quality, 50)

	# Purchase an upgrade
	var balance_before := GameState.balance
	assert_true(EquipmentManager.purchase("star_san_kit"))
	assert_almost_eq(GameState.balance, balance_before - 60.0, 0.01)

	# Swap into slot
	EquipmentManager.assign_to_slot(2, "star_san_kit")
	assert_eq(GameState.sanitation_quality, 60)  # 50 + 10

	# Upgrade extract_kit → biab_setup (in slot 0)
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
```

**Step 2: Run ALL tests**

Run: `make test`
Expected: All tests PASS (158 existing + all new equipment tests).

**Step 3: Commit**

```bash
git add src/tests/test_equipment_manager.gd
git commit -m "test: add full integration test for equipment workflow"
```

---

## Summary

| Task | Description | New Files | Modified Files |
|------|-------------|-----------|----------------|
| 1 | Equipment Resource class | Equipment.gd, test_equipment.gd | — |
| 2 | Equipment catalog (15 .tres) | 15 .tres files | test_equipment.gd |
| 3 | EquipmentManager autoload | EquipmentManager.gd, test_equipment_manager.gd | project.godot |
| 4 | EQUIPMENT_MANAGE state | — | GameState.gd, Game.gd, test_equipment_manager.gd |
| 5 | QualityCalculator integration | — | QualityCalculator.gd, GameState.gd, test_equipment_manager.gd |
| 6 | BreweryScene station slots UI | — | BreweryScene.gd, BreweryScene.tscn, Game.gd |
| 7 | Equipment Popup UI | EquipmentPopup.gd, EquipmentPopup.tscn | Game.gd |
| 8 | Equipment Shop card UI | EquipmentShop.gd, EquipmentShop.tscn | Game.gd |
| 9 | BrewingPhases bonus display | — | BrewingPhases.gd, BrewingPhases.tscn |
| 10 | Save/Load persistence | — | EquipmentManager.gd, test_equipment_manager.gd |
| 11 | Economy balance tests | — | test_equipment_manager.gd |
| 12 | Full integration test | — | test_equipment_manager.gd |
