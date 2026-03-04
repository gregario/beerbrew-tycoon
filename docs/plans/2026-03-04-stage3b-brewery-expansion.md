# Stage 3B — Brewery Expansion Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement brewery stage transitions (Garage → Microbrewery) with dynamic station slots, rent scaling, staff/equipment gating, and expansion UI.

**Architecture:** New `BreweryExpansion` autoload manages brewery stage state, thresholds, costs, and transition logic. GameState gets a `beers_brewed` counter and dynamic rent. EquipmentManager and StaffManager read the current stage to gate features. BreweryScene renders a dynamic number of station slots based on stage. An `ExpansionOverlay` UI handles the expansion confirmation screen.

**Tech Stack:** Godot 4 / GDScript, GUT testing framework, `make test` runner.

**Key References:**
- Wireframe: `design/wireframes/brewery-expansion.md`
- Spec: `openspec/changes/post-mvp-roadmap/specs/brewery-expansion/spec.md`
- Stack profile: `stacks/godot/STACK.md` (read before coding)

---

### Task 1: BreweryExpansion Autoload — Stage Management

**Files:**
- Create: `src/autoloads/BreweryExpansion.gd`
- Create: `src/tests/test_brewery_expansion.gd`
- Modify: `src/project.godot` (add autoload entry)

**Context:** This autoload owns the brewery stage enum, transition thresholds, costs, and the `beers_brewed` counter. It exposes `can_expand()`, `expand()`, and stage-dependent getters for max slots, max staff, rent amount, and equipment tier cap.

**Step 1: Write the failing test**

```gdscript
# src/tests/test_brewery_expansion.gd
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

# --- Expand signal ---
func test_expand_emits_signal() -> void:
	watch_signals(BreweryExpansion)
	GameState.balance = 6000.0
	BreweryExpansion.beers_brewed = 12
	BreweryExpansion.expand()
	assert_signal_emitted(BreweryExpansion, "brewery_expanded")
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — `BreweryExpansion` autoload does not exist yet.

**Step 3: Write the implementation**

```gdscript
# src/autoloads/BreweryExpansion.gd
extends Node

## BreweryExpansion — manages brewery stage, expansion thresholds, and
## stage-dependent configuration (slots, staff cap, rent, equipment tier).

enum Stage { GARAGE, MICROBREWERY, ARTISAN, MASS_MARKET }

# ---------------------------------------------------------------------------
# Thresholds and costs
# ---------------------------------------------------------------------------
const EXPAND_BALANCE_THRESHOLD: float = 5000.0
const EXPAND_BEERS_THRESHOLD: int = 10
const EXPAND_COST: float = 3000.0

const SLOTS_PER_STAGE: Dictionary = {
	Stage.GARAGE: 3,
	Stage.MICROBREWERY: 5,
	Stage.ARTISAN: 7,
	Stage.MASS_MARKET: 7,
}

const STAFF_PER_STAGE: Dictionary = {
	Stage.GARAGE: 0,
	Stage.MICROBREWERY: 2,
	Stage.ARTISAN: 3,
	Stage.MASS_MARKET: 4,
}

const RENT_PER_STAGE: Dictionary = {
	Stage.GARAGE: 150.0,
	Stage.MICROBREWERY: 400.0,
	Stage.ARTISAN: 600.0,
	Stage.MASS_MARKET: 800.0,
}

const TIER_CAP_PER_STAGE: Dictionary = {
	Stage.GARAGE: 2,
	Stage.MICROBREWERY: 4,
	Stage.ARTISAN: 4,
	Stage.MASS_MARKET: 4,
}

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal brewery_expanded(new_stage: int)
signal threshold_reached()

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var current_stage: Stage = Stage.GARAGE
var beers_brewed: int = 0

# ---------------------------------------------------------------------------
# Threshold checks
# ---------------------------------------------------------------------------
func can_expand() -> bool:
	if current_stage != Stage.GARAGE:
		return false
	return GameState.balance >= EXPAND_BALANCE_THRESHOLD and beers_brewed >= EXPAND_BEERS_THRESHOLD

func can_afford_expansion() -> bool:
	return GameState.balance >= EXPAND_COST

# ---------------------------------------------------------------------------
# Expansion
# ---------------------------------------------------------------------------
func expand() -> bool:
	if not can_expand():
		return false
	if not can_afford_expansion():
		return false
	GameState.balance -= EXPAND_COST
	GameState.balance_changed.emit(GameState.balance)
	current_stage = Stage.MICROBREWERY
	brewery_expanded.emit(Stage.MICROBREWERY)
	return true

# ---------------------------------------------------------------------------
# Stage-dependent getters
# ---------------------------------------------------------------------------
func get_max_slots() -> int:
	return SLOTS_PER_STAGE.get(current_stage, 3)

func get_max_staff() -> int:
	return STAFF_PER_STAGE.get(current_stage, 0)

func get_rent_amount() -> float:
	return RENT_PER_STAGE.get(current_stage, 150.0)

func get_equipment_tier_cap() -> int:
	return TIER_CAP_PER_STAGE.get(current_stage, 2)

func get_stage_name() -> String:
	match current_stage:
		Stage.GARAGE:
			return "EQUIPMENT MANAGEMENT"
		Stage.MICROBREWERY:
			return "MICROBREWERY"
		Stage.ARTISAN:
			return "ARTISAN BREWERY"
		Stage.MASS_MARKET:
			return "MASS-MARKET BREWERY"
	return "BREWERY"

# ---------------------------------------------------------------------------
# Beer counter
# ---------------------------------------------------------------------------
func record_brew() -> void:
	beers_brewed += 1
	if current_stage == Stage.GARAGE and can_expand():
		threshold_reached.emit()

# ---------------------------------------------------------------------------
# Persistence
# ---------------------------------------------------------------------------
func save_state() -> Dictionary:
	return {
		"current_stage": current_stage,
		"beers_brewed": beers_brewed,
	}

func load_state(data: Dictionary) -> void:
	current_stage = data.get("current_stage", Stage.GARAGE) as Stage
	beers_brewed = data.get("beers_brewed", 0)

# ---------------------------------------------------------------------------
# Reset
# ---------------------------------------------------------------------------
func reset() -> void:
	current_stage = Stage.GARAGE
	beers_brewed = 0
```

**Step 4: Register autoload in project.godot**

Add `BreweryExpansion` autoload entry after StaffManager in `src/project.godot`. The line to add:
```
autoload/BreweryExpansion="*res://autoloads/BreweryExpansion.gd"
```
Place it after the last existing autoload line.

**Step 5: Run test to verify it passes**

Run: `make test`
Expected: All new tests PASS, all existing tests still PASS.

**Step 6: Commit**

```
feat: add BreweryExpansion autoload with stage management
```

---

### Task 2: Integrate BreweryExpansion with GameState

**Files:**
- Modify: `src/autoloads/GameState.gd`
- Modify: `src/tests/test_brewery_expansion.gd`

**Context:** GameState needs to: (1) use `BreweryExpansion.get_rent_amount()` instead of hardcoded `RENT_AMOUNT`, (2) call `BreweryExpansion.record_brew()` after each brew, and (3) reset BreweryExpansion on game reset.

**Step 1: Add integration tests**

Append to `src/tests/test_brewery_expansion.gd`:

```gdscript
# --- GameState integration ---
func test_rent_uses_brewery_stage() -> void:
	GameState.balance = 1000.0
	BreweryExpansion.current_stage = BreweryExpansion.Stage.GARAGE
	GameState.deduct_rent()
	assert_eq(GameState.balance, 850.0)  # 1000 - 150

func test_rent_scales_at_microbrewery() -> void:
	GameState.balance = 1000.0
	BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY
	GameState.deduct_rent()
	assert_eq(GameState.balance, 600.0)  # 1000 - 400

func test_reset_resets_brewery_expansion() -> void:
	BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY
	BreweryExpansion.beers_brewed = 20
	GameState.reset()
	assert_eq(BreweryExpansion.current_stage, BreweryExpansion.Stage.GARAGE)
	assert_eq(BreweryExpansion.beers_brewed, 0)
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — `deduct_rent` still uses hardcoded RENT_AMOUNT.

**Step 3: Modify GameState.gd**

Changes to `src/autoloads/GameState.gd`:

1. **Line 11 — remove `RENT_AMOUNT` constant** (it's now in BreweryExpansion):
   - Delete: `const RENT_AMOUNT: float = 150.0`

2. **Line 178-181 — `deduct_rent()` uses dynamic rent:**
   Replace:
   ```gdscript
   func deduct_rent() -> void:
   	balance -= RENT_AMOUNT
   	balance_changed.emit(balance)
   	rent_charged.emit(RENT_AMOUNT, balance)
   ```
   With:
   ```gdscript
   func deduct_rent() -> void:
   	var amount: float = BreweryExpansion.get_rent_amount() if is_instance_valid(BreweryExpansion) else 150.0
   	balance -= amount
   	balance_changed.emit(balance)
   	rent_charged.emit(amount, balance)
   ```

3. **Line 282 — after `record_brew()` call, also record in BreweryExpansion:**
   After `record_brew(result["final_score"])` (line 282), add:
   ```gdscript
   	if is_instance_valid(BreweryExpansion):
   		BreweryExpansion.record_brew()
   ```

4. **In `reset()` — add BreweryExpansion reset** after StaffManager reset (line 364):
   ```gdscript
   	if is_instance_valid(BreweryExpansion):
   		BreweryExpansion.reset()
   ```

**Step 4: Fix any existing tests that reference RENT_AMOUNT**

Check `src/tests/test_economy.gd` — if any test uses `GameState.RENT_AMOUNT`, change to `150.0` literal or `BreweryExpansion.get_rent_amount()`.

**Step 5: Run test to verify it passes**

Run: `make test`
Expected: All tests PASS.

**Step 6: Commit**

```
feat: integrate BreweryExpansion with GameState rent and brew counter
```

---

### Task 3: Dynamic Station Slots in EquipmentManager

**Files:**
- Modify: `src/autoloads/EquipmentManager.gd`
- Add tests to: `src/tests/test_brewery_expansion.gd`

**Context:** EquipmentManager currently hardcodes 3 slots. It needs to: (1) use `BreweryExpansion.get_max_slots()` for slot bounds checking, (2) resize `station_slots` array on expansion, (3) keep existing slot assignments when expanding.

**Step 1: Add tests**

Append to `src/tests/test_brewery_expansion.gd`:

```gdscript
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
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — `resize_slots()` doesn't exist, slot 3 rejected.

**Step 3: Modify EquipmentManager.gd**

1. **Replace hardcoded `MAX_SLOTS_GARAGE` usage with dynamic getter:**

   Change `assign_to_slot` (line 108-109):
   ```gdscript
   func assign_to_slot(slot_index: int, equipment_id: String) -> bool:
   	var max_slots: int = BreweryExpansion.get_max_slots() if is_instance_valid(BreweryExpansion) else MAX_SLOTS_GARAGE
   	if slot_index < 0 or slot_index >= max_slots:
   		return false
   ```

   Change `unassign_slot` (line 121-123):
   ```gdscript
   func unassign_slot(slot_index: int) -> void:
   	var max_slots: int = BreweryExpansion.get_max_slots() if is_instance_valid(BreweryExpansion) else MAX_SLOTS_GARAGE
   	if slot_index < 0 or slot_index >= max_slots:
   		return
   ```

2. **Add `resize_slots()` method** (after `get_unslotted_owned`, ~line 139):
   ```gdscript
   func resize_slots() -> void:
   	var target: int = BreweryExpansion.get_max_slots() if is_instance_valid(BreweryExpansion) else MAX_SLOTS_GARAGE
   	while station_slots.size() < target:
   		station_slots.append("")
   ```

3. **Update `reset()` to use dynamic slot count:**
   ```gdscript
   func reset() -> void:
   	owned_equipment = []
   	var slot_count: int = BreweryExpansion.get_max_slots() if is_instance_valid(BreweryExpansion) else MAX_SLOTS_GARAGE
   	station_slots = []
   	for i in range(slot_count):
   		station_slots.append("")
   	active_bonuses = {
   		"sanitation": 0,
   		"temp_control": 0,
   		"efficiency": 0.0,
   		"batch_size": 1.0,
   	}
   	GameState.sanitation_quality = BASE_SANITATION
   	GameState.temp_control_quality = BASE_TEMP_CONTROL
   ```

4. **Update `load_state()` to handle variable slot sizes:**
   ```gdscript
   func load_state(data: Dictionary) -> void:
   	owned_equipment = data.get("owned_equipment", [])
   	station_slots = data.get("station_slots", ["", "", ""])
   	# Ensure slot array matches current stage
   	var target: int = BreweryExpansion.get_max_slots() if is_instance_valid(BreweryExpansion) else MAX_SLOTS_GARAGE
   	while station_slots.size() < target:
   		station_slots.append("")
   	recalculate_bonuses()
   ```

**Step 4: Run test to verify it passes**

Run: `make test`
Expected: All tests PASS (new + existing).

**Step 5: Commit**

```
feat: dynamic station slots based on brewery stage
```

---

### Task 4: Gate Staff Hiring Behind Microbrewery

**Files:**
- Modify: `src/autoloads/StaffManager.gd`
- Add tests to: `src/tests/test_brewery_expansion.gd`

**Context:** `StaffManager.get_max_staff()` currently returns `MAX_STAFF_MICRO` (2) always. It needs to read `BreweryExpansion.get_max_staff()` instead.

**Step 1: Add tests**

Append to `src/tests/test_brewery_expansion.gd`:

```gdscript
# --- Staff gating ---
func test_garage_blocks_hiring() -> void:
	StaffManager.reset()
	BreweryExpansion.current_stage = BreweryExpansion.Stage.GARAGE
	assert_eq(StaffManager.get_max_staff(), 0)
	# Try to hire — should fail
	if StaffManager.candidates.size() > 0:
		var result: bool = StaffManager.hire(StaffManager.candidates[0]["staff_id"])
		assert_false(result)

func test_microbrewery_allows_hiring() -> void:
	StaffManager.reset()
	BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY
	assert_eq(StaffManager.get_max_staff(), 2)
	if StaffManager.candidates.size() > 0:
		var result: bool = StaffManager.hire(StaffManager.candidates[0]["staff_id"])
		assert_true(result)
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — garage doesn't block hiring (returns 2 instead of 0).

**Step 3: Modify StaffManager.gd**

Change `get_max_staff()` (lines 95-96):
```gdscript
func get_max_staff() -> int:
	if is_instance_valid(BreweryExpansion):
		return BreweryExpansion.get_max_staff()
	return MAX_STAFF_MICRO
```

**Step 4: Run test to verify it passes**

Run: `make test`
Expected: All tests PASS. **Note:** Check that existing `test_staff_manager.gd` tests still pass — some may assume they can hire. If they fail, add `BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY` to their `before_each()`.

**Step 5: Commit**

```
feat: gate staff hiring behind microbrewery stage
```

---

### Task 5: Gate Equipment Tiers Behind Brewery Stage

**Files:**
- Modify: `src/ui/EquipmentShop.gd`
- Add tests to: `src/tests/test_brewery_expansion.gd`

**Context:** EquipmentShop currently gates equipment by `ResearchManager.unlocked_equipment_tier`. It needs an additional gate: `BreweryExpansion.get_equipment_tier_cap()`. Equipment is locked if its tier exceeds EITHER the research tier OR the brewery stage tier cap.

**Step 1: Add tests**

Append to `src/tests/test_brewery_expansion.gd`:

```gdscript
# --- Equipment tier gating ---
func test_garage_tier_cap_is_2() -> void:
	BreweryExpansion.current_stage = BreweryExpansion.Stage.GARAGE
	assert_eq(BreweryExpansion.get_equipment_tier_cap(), 2)

func test_microbrewery_tier_cap_is_4() -> void:
	BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY
	assert_eq(BreweryExpansion.get_equipment_tier_cap(), 4)
```

These are already covered in Task 1. The real work is modifying EquipmentShop — but EquipmentShop is a UI script that's hard to unit test (it builds nodes programmatically). We test the gating logic through the getter and verify visually.

**Step 2: Modify EquipmentShop.gd**

Find the line where items are filtered by tier (around line 204 based on exploration):
```gdscript
if tier > ResearchManager.unlocked_equipment_tier:
```

Change to:
```gdscript
var stage_cap: int = BreweryExpansion.get_equipment_tier_cap() if is_instance_valid(BreweryExpansion) else 4
var max_tier: int = mini(ResearchManager.unlocked_equipment_tier, stage_cap)
if tier > max_tier:
```

Also update the locked row text — if tier exceeds stage cap, show "Requires Microbrewery" instead of "Research Required":
```gdscript
if tier > stage_cap:
	_add_locked_row(item, items_vbox, "Requires Microbrewery")
else:
	_add_locked_row(item, items_vbox, "Research Required")
```

If `_add_locked_row` doesn't accept a message parameter, add one (with a default of "Research Required").

**Step 3: Run test to verify it passes**

Run: `make test`
Expected: All tests PASS.

**Step 4: Commit**

```
feat: gate T3-T4 equipment behind microbrewery stage
```

---

### Task 6: Rent Scaling — Dynamic Rent Amount

**Files:**
- Already done in Task 2 (GameState.deduct_rent uses BreweryExpansion.get_rent_amount())
- Modify: `src/ui/ResultsOverlay.gd` (if it displays rent amount — update to use dynamic rent)

**Context:** Verify that the rent display in ResultsOverlay or any toast shows the correct stage-dependent amount.

**Step 1: Check and update rent display**

Search `src/` for any hardcoded `150` or `RENT_AMOUNT` references and update them to use `BreweryExpansion.get_rent_amount()`.

**Step 2: Add a test for rent toast amount**

Append to `src/tests/test_brewery_expansion.gd`:

```gdscript
func test_rent_amount_in_toast_matches_stage() -> void:
	# This is an integration check — rent at microbrewery is 400
	GameState.balance = 2000.0
	BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY
	GameState.deduct_rent()
	assert_eq(GameState.balance, 1600.0)
```

**Step 3: Run test to verify it passes**

Run: `make test`
Expected: All tests PASS.

**Step 4: Commit**

```
feat: dynamic rent scaling per brewery stage
```

---

### Task 7: Expansion UI — Banner and Overlay

**Files:**
- Create: `src/ui/ExpansionOverlay.gd`
- Modify: `src/scenes/BreweryScene.gd`

**Context:** When the player meets expansion thresholds, an accent-colored banner appears at the top of the brewery hub. Clicking "View Details" opens a full-screen overlay showing benefits, costs, and a confirmation button. On expand, the scene transitions to the microbrewery layout.

See `design/wireframes/brewery-expansion.md` sections 1 and 2 for exact layout specs.

**Step 1: Create ExpansionOverlay.gd**

```gdscript
# src/ui/ExpansionOverlay.gd
extends CanvasLayer

signal expansion_confirmed()
signal closed()

var _panel: PanelContainer
var _balance_after_label: Label

func _ready() -> void:
	visible = false

func show_overlay() -> void:
	_build_ui()
	visible = true

func _build_ui() -> void:
	# Clear previous
	for child in get_children():
		child.queue_free()

	# Dim background
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# Center panel 900x550
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 550)
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(190, 85)  # Centered in 1280x720
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#0B1220")
	panel_style.border_color = Color("#FFC857")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(4)
	panel_style.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# Header row
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title := Label.new()
	title.text = "EXPAND YOUR BREWERY"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.pressed.connect(_on_close)
	header.add_child(close_btn)

	# Separator
	vbox.add_child(HSeparator.new())

	# Stage transition
	var stage_row := HBoxContainer.new()
	stage_row.add_theme_constant_override("separation", 16)
	stage_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(stage_row)
	var from_label := Label.new()
	from_label.text = "GARAGE"
	from_label.add_theme_font_size_override("font_size", 24)
	from_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	stage_row.add_child(from_label)
	var arrow := Label.new()
	arrow.text = "  ───>  "
	arrow.add_theme_font_size_override("font_size", 24)
	arrow.add_theme_color_override("font_color", Color("#FFC857"))
	stage_row.add_child(arrow)
	var to_label := Label.new()
	to_label.text = "MICROBREWERY"
	to_label.add_theme_font_size_override("font_size", 24)
	to_label.add_theme_color_override("font_color", Color("#FFC857"))
	stage_row.add_child(to_label)

	# Benefits section
	_add_section_label(vbox, "WHAT YOU GET:", Color("#5EE8A4"))
	var benefits_box := _add_info_box(vbox, Color("#5EE8A4"))
	_add_info_line(benefits_box, "Station Slots: 3 → 5 (+2 new slots)")
	_add_info_line(benefits_box, "Staff Hiring: Locked → Unlocked (max 2)")
	_add_info_line(benefits_box, "Equipment: T1-T2 → T1-T4 unlocked")
	_add_info_line(benefits_box, "Larger Space: Industrial brewery layout")

	# Costs section
	_add_section_label(vbox, "COSTS:", Color("#FFB347"))
	var costs_box := _add_info_box(vbox, Color("#FFB347"))
	_add_info_line(costs_box, "Upgrade Cost: $%d (one-time)" % int(BreweryExpansion.EXPAND_COST))
	_add_info_line(costs_box, "Rent Increase: $150 → $400 per period")

	# Balance after
	_balance_after_label = Label.new()
	var after_amount: float = GameState.balance - BreweryExpansion.EXPAND_COST
	_balance_after_label.text = "Balance after: $%d" % int(after_amount)
	_balance_after_label.add_theme_font_size_override("font_size", 20)
	var after_color: Color = Color("#FF7B7B") if after_amount < 200 else Color("#8A9BB1")
	_balance_after_label.add_theme_color_override("font_color", after_color)
	vbox.add_child(_balance_after_label)

	# Buttons row
	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 24)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)
	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(160, 48)
	cancel_btn.pressed.connect(_on_close)
	btn_row.add_child(cancel_btn)
	var expand_btn := Button.new()
	expand_btn.text = "Expand — $%d" % int(BreweryExpansion.EXPAND_COST)
	expand_btn.custom_minimum_size = Vector2(240, 48)
	expand_btn.disabled = not BreweryExpansion.can_afford_expansion()
	expand_btn.pressed.connect(_on_expand)
	var expand_style := StyleBoxFlat.new()
	expand_style.bg_color = Color("#FFC857")
	expand_style.set_corner_radius_all(8)
	expand_style.set_content_margin_all(8)
	expand_btn.add_theme_stylebox_override("normal", expand_style)
	expand_btn.add_theme_color_override("font_color", Color("#0F1724"))
	btn_row.add_child(expand_btn)

func _add_section_label(parent: VBoxContainer, text: String, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)

func _add_info_box(parent: VBoxContainer, border_color: Color) -> VBoxContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0B1220")
	style.border_color = border_color
	style.border_width_left = 2
	style.set_content_margin_all(12)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	panel.add_child(vbox)
	return vbox

func _add_info_line(parent: VBoxContainer, text: String) -> void:
	var label := Label.new()
	label.text = "  ✦  " + text
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color.WHITE)
	parent.add_child(label)

func _on_expand() -> void:
	var success: bool = BreweryExpansion.expand()
	if success:
		if is_instance_valid(EquipmentManager):
			EquipmentManager.resize_slots()
		if is_instance_valid(ToastManager):
			ToastManager.show_toast("Welcome to your Microbrewery! 2 new station slots unlocked.")
			ToastManager.show_toast("Rent increased: $150 → $400 per period")
		expansion_confirmed.emit()
		visible = false

func _on_close() -> void:
	visible = false
	closed.emit()
```

**Step 2: Add expansion banner and overlay to BreweryScene.gd**

In `src/scenes/BreweryScene.gd`, add to `_build_equipment_ui()`:

1. After building the title label, check `BreweryExpansion.can_expand()` and add a banner:
   ```gdscript
   # Expansion banner (if threshold met)
   if is_instance_valid(BreweryExpansion) and BreweryExpansion.can_expand():
   	var banner := PanelContainer.new()
   	var banner_style := StyleBoxFlat.new()
   	banner_style.bg_color = Color("#0B1220", 0.95)
   	banner_style.border_color = Color("#FFC857")
   	banner_style.set_border_width_all(2)
   	banner_style.set_corner_radius_all(4)
   	banner_style.set_content_margin_all(12)
   	banner.add_theme_stylebox_override("panel", banner_style)
   	banner.position = Vector2(200, 50)
   	banner.size = Vector2(880, 48)
   	_equipment_ui.add_child(banner)
   	var banner_hbox := HBoxContainer.new()
   	banner_hbox.add_theme_constant_override("separation", 16)
   	banner.add_child(banner_hbox)
   	var banner_text := Label.new()
   	banner_text.text = "★ Ready to expand! Upgrade to Microbrewery — $%d" % int(BreweryExpansion.EXPAND_COST)
   	banner_text.add_theme_font_size_override("font_size", 20)
   	banner_text.add_theme_color_override("font_color", Color("#FFC857"))
   	banner_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
   	banner_hbox.add_child(banner_text)
   	var details_btn := Button.new()
   	details_btn.text = "View Details >"
   	details_btn.custom_minimum_size = Vector2(160, 36)
   	details_btn.pressed.connect(_on_expansion_details)
   	var btn_style := StyleBoxFlat.new()
   	btn_style.bg_color = Color("#FFC857")
   	btn_style.set_corner_radius_all(4)
   	btn_style.set_content_margin_all(4)
   	details_btn.add_theme_stylebox_override("normal", btn_style)
   	details_btn.add_theme_color_override("font_color", Color("#0F1724"))
   	banner_hbox.add_child(details_btn)
   ```

2. Update the title label to use `BreweryExpansion.get_stage_name()`:
   Replace `"EQUIPMENT MANAGEMENT"` with:
   ```gdscript
   var stage_name: String = BreweryExpansion.get_stage_name() if is_instance_valid(BreweryExpansion) else "EQUIPMENT MANAGEMENT"
   ```

3. Add the expansion overlay signal handler:
   ```gdscript
   var _expansion_overlay: CanvasLayer = null

   func _on_expansion_details() -> void:
   	if _expansion_overlay == null:
   		_expansion_overlay = preload("res://ui/ExpansionOverlay.gd").new()
   		add_child(_expansion_overlay)
   		_expansion_overlay.expansion_confirmed.connect(_on_expansion_confirmed)
   	_expansion_overlay.show_overlay()

   func _on_expansion_confirmed() -> void:
   	# Rebuild equipment UI with new slot count
   	_build_equipment_ui()
   	refresh_slots()
   ```

**Step 3: Update `refresh_slots()` for dynamic slot count**

In `BreweryScene.gd`, the `SLOT_NAMES` and `SLOT_POSITIONS` arrays are hardcoded to 3. Add extended arrays for microbrewery:

```gdscript
const SLOT_NAMES_MICRO: Array[String] = ["Kettle", "Fermenter", "Bottler", "Station 4", "Station 5"]
const SLOT_POSITIONS_MICRO: Array[Vector2] = [
	Vector2(140, 312), Vector2(340, 296), Vector2(540, 312), Vector2(740, 296), Vector2(940, 312)
]
```

Update `_build_equipment_ui()` to use the correct arrays based on stage:
```gdscript
var slot_names: Array[String] = SLOT_NAMES
var slot_positions: Array[Vector2] = SLOT_POSITIONS
var max_slots: int = 3
if is_instance_valid(BreweryExpansion):
	max_slots = BreweryExpansion.get_max_slots()
	if max_slots > 3:
		slot_names = SLOT_NAMES_MICRO
		slot_positions = SLOT_POSITIONS_MICRO
```

Update the slot button loop to use `max_slots` instead of `SLOT_NAMES.size()`.

Update `refresh_slots()` to iterate over all current slots.

**Step 4: Run test to verify it passes**

Run: `make test`
Expected: All tests PASS.

**Step 5: Commit**

```
feat: add expansion banner and overlay UI to BreweryScene
```

---

### Task 8: Integration Tests and Polish

**Files:**
- Add tests to: `src/tests/test_brewery_expansion.gd`
- Modify: `src/scenes/BreweryScene.gd` (minor polish)

**Context:** Full integration tests for the complete expansion flow: meet thresholds → expand → verify all systems update correctly. Also add the beers brewed progress indicator on the hub header.

**Step 1: Write integration tests**

Append to `src/tests/test_brewery_expansion.gd`:

```gdscript
# --- Full integration ---
func test_full_expansion_flow() -> void:
	GameState.reset()
	BreweryExpansion.reset()
	EquipmentManager.reset()
	EquipmentManager.initialize_starting_equipment()
	StaffManager.reset()

	# Verify initial state
	assert_eq(BreweryExpansion.current_stage, BreweryExpansion.Stage.GARAGE)
	assert_eq(EquipmentManager.station_slots.size(), 3)
	assert_eq(StaffManager.get_max_staff(), 0)

	# Simulate meeting thresholds
	GameState.balance = 7000.0
	for i in range(12):
		BreweryExpansion.record_brew()
	assert_true(BreweryExpansion.can_expand())

	# Expand
	var result: bool = BreweryExpansion.expand()
	assert_true(result)
	EquipmentManager.resize_slots()

	# Verify post-expansion state
	assert_eq(BreweryExpansion.current_stage, BreweryExpansion.Stage.MICROBREWERY)
	assert_eq(GameState.balance, 4000.0)  # 7000 - 3000
	assert_eq(EquipmentManager.station_slots.size(), 5)
	assert_eq(StaffManager.get_max_staff(), 2)
	assert_eq(BreweryExpansion.get_rent_amount(), 400.0)
	assert_eq(BreweryExpansion.get_equipment_tier_cap(), 4)

func test_save_load_preserves_expansion() -> void:
	GameState.reset()
	BreweryExpansion.reset()
	EquipmentManager.reset()
	EquipmentManager.initialize_starting_equipment()

	# Expand first
	GameState.balance = 7000.0
	BreweryExpansion.beers_brewed = 12
	BreweryExpansion.expand()
	EquipmentManager.resize_slots()
	EquipmentManager.assign_to_slot(3, "extract_kit")

	# Save all state
	var expansion_data: Dictionary = BreweryExpansion.save_state()
	var equipment_data: Dictionary = EquipmentManager.save_state()

	# Reset everything
	BreweryExpansion.reset()
	EquipmentManager.reset()

	# Load state
	BreweryExpansion.load_state(expansion_data)
	EquipmentManager.load_state(equipment_data)

	# Verify restored state
	assert_eq(BreweryExpansion.current_stage, BreweryExpansion.Stage.MICROBREWERY)
	assert_eq(EquipmentManager.station_slots.size(), 5)
	assert_eq(EquipmentManager.station_slots[3], "extract_kit")

func test_cannot_double_expand() -> void:
	GameState.balance = 10000.0
	BreweryExpansion.beers_brewed = 12
	BreweryExpansion.expand()
	var result: bool = BreweryExpansion.expand()
	assert_false(result)
	assert_eq(BreweryExpansion.current_stage, BreweryExpansion.Stage.MICROBREWERY)
```

**Step 2: Add beers brewed counter to hub header**

In `BreweryScene.gd`, within `_build_equipment_ui()`, after the balance label, add a beers brewed counter (only at microbrewery stage, showing progress to fork threshold):

```gdscript
if is_instance_valid(BreweryExpansion) and BreweryExpansion.current_stage == BreweryExpansion.Stage.MICROBREWERY:
	var beers_label := Label.new()
	beers_label.text = "Beers: %d/25" % BreweryExpansion.beers_brewed
	beers_label.add_theme_font_size_override("font_size", 20)
	beers_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	# Position right side of header
```

**Step 3: Add Staff button disabled state in garage**

In `BreweryScene.gd`, when building the Staff button, disable it in garage:

```gdscript
if is_instance_valid(BreweryExpansion) and BreweryExpansion.current_stage == BreweryExpansion.Stage.GARAGE:
	_staff_button.disabled = true
	_staff_button.tooltip_text = "Upgrade to Microbrewery to hire staff"
```

**Step 4: Add threshold toast**

In `GameState.execute_brew()`, after the `BreweryExpansion.record_brew()` call, check for threshold notification:

```gdscript
if is_instance_valid(BreweryExpansion):
	BreweryExpansion.record_brew()
	if BreweryExpansion.can_expand() and is_instance_valid(ToastManager):
		ToastManager.show_toast("★ Your brewery is ready to expand!")
```

**Step 5: Run test to verify it passes**

Run: `make test`
Expected: All tests PASS. Target: previous count + ~25 new tests.

**Step 6: Commit**

```
feat: complete Stage 3B brewery expansion with integration tests
```

---

## Summary

| Task | Description | Tests Added |
|------|-------------|-------------|
| 1 | BreweryExpansion autoload (stage, thresholds, getters, save/load) | ~20 |
| 2 | GameState integration (dynamic rent, brew counter, reset) | ~3 |
| 3 | Dynamic station slots in EquipmentManager | ~4 |
| 4 | Gate staff hiring behind microbrewery | ~2 |
| 5 | Gate equipment tiers behind brewery stage | ~2 |
| 6 | Rent scaling (already done in Task 2, verify) | ~1 |
| 7 | Expansion UI (banner + overlay in BreweryScene) | 0 (UI) |
| 8 | Integration tests + polish (full flow, save/load, toasts) | ~3 |

**Estimated total new tests:** ~35
**Estimated total tests after:** ~310 (273 existing + ~35 new)
