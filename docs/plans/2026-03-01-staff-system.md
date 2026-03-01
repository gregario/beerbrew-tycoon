# Stage 3A: Staff System Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a staff hiring, assignment, training, and specialization system that lets players hire brewers who provide stat bonuses during brewing phases.

**Architecture:** Staff are runtime-generated Dictionary objects (not `.tres` resources) managed by a StaffManager autoload. StaffScreen is a full-overlay UI (same pattern as ResearchTree). Staff bonuses integrate into QualityCalculator as flat flavor/technique additions. Salary deduction and XP awards happen in GameState's turn lifecycle.

**Tech Stack:** Godot 4 / GDScript, GUT tests, programmatic UI (no .tscn)

---

## Critical Patterns (read before implementing)

- **Resource classes**: `class_name Foo` / `extends Resource` / all `@export var` / no methods (pure data)
- **Manager autoloads**: `extends Node`, signals at top, `reset()`, `save_state()`/`load_state()` methods
- **UI overlays**: `extends Control`, built in `_build_ui()` in `_ready()`, `signal closed()`, dim bg + centered panel
- **Godot 4.6 typing**: NEVER use `:=` on `Dictionary.get()` — always `var x: int = dict.get("k", 0)`
- **Staff stored as Dictionary** (not Resource instances) to avoid resource caching issues in headless tests
- **Autoload registration**: `StaffManager="*res://autoloads/StaffManager.gd"` in project.godot after ResearchManager
- **Test pattern**: `extends GutTest`, `before_each()` calls `GameState.reset()` + `StaffManager.reset()`

---

### Task 1: Create Staff Resource class

**Files:**
- Create: `src/scripts/Staff.gd`
- Test: `src/tests/test_staff_manager.gd`

**Step 1: Write the Staff Resource class**

```gdscript
class_name Staff
extends Resource

## Staff resource — represents a hired brewer.

@export var staff_id: String = ""
@export var staff_name: String = ""
@export var creativity: int = 50
@export var precision: int = 50
@export var experience_points: int = 0
@export var level: int = 1
@export var salary_per_turn: int = 60
@export var assigned_phase: String = ""   # "" / "mashing" / "boiling" / "fermenting"
@export var specialization: String = "none"  # "none" / "mashing" / "boiling" / "fermenting"
@export var is_training: bool = false
@export var training_turns_remaining: int = 0
```

**Step 2: Write initial test**

Create `src/tests/test_staff_manager.gd`:
```gdscript
extends GutTest

func test_staff_resource_has_all_properties() -> void:
    var s := Staff.new()
    assert_eq(s.staff_id, "")
    assert_eq(s.staff_name, "")
    assert_eq(s.creativity, 50)
    assert_eq(s.precision, 50)
    assert_eq(s.experience_points, 0)
    assert_eq(s.level, 1)
    assert_eq(s.salary_per_turn, 60)
    assert_eq(s.assigned_phase, "")
    assert_eq(s.specialization, "none")
    assert_eq(s.is_training, false)
    assert_eq(s.training_turns_remaining, 0)
```

**Step 3: Run test**

Run: `GODOT="<path>" make test`
Expected: PASS

**Step 4: Commit**

```
feat(staff): add Staff Resource class with all properties
```

---

### Task 2: Create StaffManager autoload — core roster and candidates

**Files:**
- Create: `src/autoloads/StaffManager.gd`
- Modify: `src/project.godot` (add autoload registration)
- Modify: `src/autoloads/GameState.gd` (add `StaffManager.reset()` in `reset()`)
- Test: `src/tests/test_staff_manager.gd`

**Step 1: Write failing tests for candidate generation, hiring, firing**

Add to `test_staff_manager.gd`:
```gdscript
func before_each() -> void:
    GameState.reset()
    StaffManager.reset()

func test_generate_candidates_creates_correct_count() -> void:
    StaffManager.generate_candidates(3)
    assert_eq(StaffManager.candidates.size(), 3)

func test_candidates_have_valid_stats() -> void:
    StaffManager.generate_candidates(2)
    for c in StaffManager.candidates:
        assert_gte(c.get("creativity", 0), 25)
        assert_lte(c.get("creativity", 0), 75)
        assert_gte(c.get("precision", 0), 25)
        assert_lte(c.get("precision", 0), 75)

func test_candidate_salary_scales_with_stats() -> void:
    StaffManager.generate_candidates(2)
    for c in StaffManager.candidates:
        var expected_salary: int = 40 + (c.get("creativity", 0) + c.get("precision", 0)) / 4
        assert_eq(c.get("salary_per_turn", 0), expected_salary)

func test_hire_adds_to_roster() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    assert_eq(StaffManager.staff_roster.size(), 1)

func test_hire_removes_from_candidates() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    assert_eq(StaffManager.candidates.size(), 1)

func test_hire_emits_signal() -> void:
    StaffManager.generate_candidates(2)
    watch_signals(StaffManager)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    assert_signal_emitted(StaffManager, "staff_hired")

func test_fire_removes_from_roster() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    StaffManager.fire(cid)
    assert_eq(StaffManager.staff_roster.size(), 0)

func test_fire_clears_phase_assignment() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    StaffManager.assign_to_phase(cid, "mashing")
    StaffManager.fire(cid)
    var assigned: Dictionary = StaffManager.get_staff_assigned_to("mashing")
    assert_true(assigned.is_empty())

func test_fire_emits_signal() -> void:
    StaffManager.generate_candidates(2)
    watch_signals(StaffManager)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    StaffManager.fire(cid)
    assert_signal_emitted(StaffManager, "staff_fired")

func test_reset_clears_roster() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    StaffManager.reset()
    assert_eq(StaffManager.staff_roster.size(), 0)

func test_reset_regenerates_candidates() -> void:
    StaffManager.reset()
    assert_gte(StaffManager.candidates.size(), 2)
```

**Step 2: Run tests to verify they fail**

Run: `GODOT="<path>" make test`
Expected: FAIL (StaffManager not defined)

**Step 3: Implement StaffManager with core methods**

Create `src/autoloads/StaffManager.gd`:
```gdscript
extends Node

## StaffManager — manages staff roster, hiring, firing, assignment, training.

signal staff_hired(staff_id: String)
signal staff_fired(staff_id: String)
signal staff_assigned(staff_id: String, phase: String)
signal staff_leveled_up(staff_id: String, new_level: int)
signal staff_training_started(staff_id: String)
signal staff_training_completed(staff_id: String)
signal staff_specialized(staff_id: String, specialization: String)
signal roster_changed()

const MAX_STAFF_GARAGE: int = 0
const MAX_STAFF_MICRO: int = 2
const MAX_STAFF_ARTISAN: int = 4
const XP_PER_LEVEL: int = 100
const TRAINING_COST: int = 200
const TRAINING_STAT_GAIN_MIN: int = 5
const TRAINING_STAT_GAIN_MAX: int = 10
const LEVEL_UP_STAT_MIN: int = 2
const LEVEL_UP_STAT_MAX: int = 5
const SPECIALIZATION_LEVEL: int = 5
const BONUS_DIVISOR: float = 10.0

const BREWER_NAMES: Array[String] = [
    "Lars", "Eva", "Klaus", "Hilda", "Fritz",
    "Greta", "Otto", "Ingrid", "Hans", "Elsa",
    "Bruno", "Petra", "Dieter", "Helga", "Karl",
]

var staff_roster: Array = []
var candidates: Array = []
var _next_id: int = 0


func reset() -> void:
    staff_roster = []
    candidates = []
    _next_id = 0
    generate_candidates(2)


func generate_candidates(count: int) -> void:
    candidates = []
    var available_names: Array[String] = BREWER_NAMES.duplicate()
    # Remove names already in roster
    for s in staff_roster:
        var idx: int = available_names.find(s.get("staff_name", ""))
        if idx >= 0:
            available_names.remove_at(idx)
    available_names.shuffle()

    for i in range(count):
        var creativity: int = randi_range(25, 75)
        var precision: int = randi_range(25, 75)
        var salary: int = 40 + (creativity + precision) / 4
        var staff_name: String = available_names[i % available_names.size()] if available_names.size() > 0 else "Brewer %d" % _next_id
        var staff_id: String = "staff_%d" % _next_id
        _next_id += 1
        candidates.append({
            "staff_id": staff_id,
            "staff_name": staff_name,
            "creativity": creativity,
            "precision": precision,
            "experience_points": 0,
            "level": 1,
            "salary_per_turn": salary,
            "assigned_phase": "",
            "specialization": "none",
            "is_training": false,
            "training_turns_remaining": 0,
            "training_stat": "",
        })


func get_max_staff() -> int:
    # Stage 3B will gate this by brewery stage; for now allow 2 for testing
    return MAX_STAFF_MICRO


func hire(staff_id: String) -> bool:
    if staff_roster.size() >= get_max_staff():
        return false
    var idx: int = -1
    for i in range(candidates.size()):
        if candidates[i].get("staff_id", "") == staff_id:
            idx = i
            break
    if idx < 0:
        return false
    var staff: Dictionary = candidates[idx]
    candidates.remove_at(idx)
    staff_roster.append(staff)
    staff_hired.emit(staff_id)
    roster_changed.emit()
    return true


func fire(staff_id: String) -> bool:
    var idx: int = -1
    for i in range(staff_roster.size()):
        if staff_roster[i].get("staff_id", "") == staff_id:
            idx = i
            break
    if idx < 0:
        return false
    staff_roster.remove_at(idx)
    staff_fired.emit(staff_id)
    roster_changed.emit()
    return true


func assign_to_phase(staff_id: String, phase: String) -> bool:
    if phase != "" and phase != "mashing" and phase != "boiling" and phase != "fermenting":
        return false
    # Unassign anyone currently on this phase (swap logic)
    if phase != "":
        for s in staff_roster:
            if s.get("assigned_phase", "") == phase and s.get("staff_id", "") != staff_id:
                s["assigned_phase"] = ""
    # Assign the target staff
    for s in staff_roster:
        if s.get("staff_id", "") == staff_id:
            if s.get("is_training", false):
                return false
            s["assigned_phase"] = phase
            staff_assigned.emit(staff_id, phase)
            roster_changed.emit()
            return true
    return false


func get_staff_assigned_to(phase: String) -> Dictionary:
    for s in staff_roster:
        if s.get("assigned_phase", "") == phase:
            return s
    return {}


func get_phase_bonus(phase: String) -> Dictionary:
    var staff: Dictionary = get_staff_assigned_to(phase)
    if staff.is_empty():
        return {"flavor": 0.0, "technique": 0.0}
    var creativity: int = staff.get("creativity", 0)
    var precision: int = staff.get("precision", 0)
    var level: int = staff.get("level", 1)
    var spec: String = staff.get("specialization", "none")
    var level_mult: float = 1.0 + (level - 1) * 0.1
    var spec_mult: float = 1.0
    if spec != "none":
        if spec == phase:
            spec_mult = 2.0
        else:
            spec_mult = 0.5
    var flavor: float = creativity * level_mult * spec_mult / BONUS_DIVISOR
    var technique: float = precision * level_mult * spec_mult / BONUS_DIVISOR
    return {"flavor": flavor, "technique": technique}


func award_xp(phase: String, amount: int) -> bool:
    var staff: Dictionary = get_staff_assigned_to(phase)
    if staff.is_empty():
        return false
    if staff.get("assigned_phase", "") == "":
        return false
    var current_xp: int = staff.get("experience_points", 0)
    var current_level: int = staff.get("level", 1)
    staff["experience_points"] = current_xp + amount
    if staff["experience_points"] >= current_level * XP_PER_LEVEL:
        _level_up(staff)
        return true
    return false


func _level_up(staff: Dictionary) -> void:
    staff["level"] = staff.get("level", 1) + 1
    staff["experience_points"] = 0
    var c_gain: int = randi_range(LEVEL_UP_STAT_MIN, LEVEL_UP_STAT_MAX)
    var p_gain: int = randi_range(LEVEL_UP_STAT_MIN, LEVEL_UP_STAT_MAX)
    staff["creativity"] = mini(staff.get("creativity", 0) + c_gain, 100)
    staff["precision"] = mini(staff.get("precision", 0) + p_gain, 100)
    staff_leveled_up.emit(staff.get("staff_id", ""), staff["level"])
    roster_changed.emit()


func start_training(staff_id: String, stat: String) -> bool:
    if stat != "creativity" and stat != "precision":
        return false
    if GameState.balance < TRAINING_COST:
        return false
    for s in staff_roster:
        if s.get("staff_id", "") == staff_id:
            if s.get("is_training", false):
                return false
            s["is_training"] = true
            s["training_turns_remaining"] = 1
            s["training_stat"] = stat
            s["assigned_phase"] = ""  # Unassign during training
            GameState.balance -= TRAINING_COST
            GameState.balance_changed.emit(GameState.balance)
            staff_training_started.emit(staff_id)
            roster_changed.emit()
            return true
    return false


func tick_training() -> void:
    for s in staff_roster:
        if not s.get("is_training", false):
            continue
        var remaining: int = s.get("training_turns_remaining", 0) - 1
        s["training_turns_remaining"] = remaining
        if remaining <= 0:
            s["is_training"] = false
            var stat: String = s.get("training_stat", "creativity")
            var gain: int = randi_range(TRAINING_STAT_GAIN_MIN, TRAINING_STAT_GAIN_MAX)
            s[stat] = mini(s.get(stat, 0) + gain, 100)
            s["training_stat"] = ""
            staff_training_completed.emit(s.get("staff_id", ""))
            roster_changed.emit()


func specialize(staff_id: String, specialization: String) -> bool:
    if specialization != "mashing" and specialization != "boiling" and specialization != "fermenting":
        return false
    for s in staff_roster:
        if s.get("staff_id", "") == staff_id:
            if s.get("level", 1) < SPECIALIZATION_LEVEL:
                return false
            if s.get("specialization", "none") != "none":
                return false
            s["specialization"] = specialization
            staff_specialized.emit(staff_id, specialization)
            roster_changed.emit()
            return true
    return false


func deduct_salaries() -> float:
    var total: float = 0.0
    for s in staff_roster:
        total += s.get("salary_per_turn", 0)
    if total > 0.0:
        GameState.balance -= total
        GameState.balance_changed.emit(GameState.balance)
    return total


func refresh_candidates() -> void:
    generate_candidates(randi_range(2, 3))


func save_state() -> Dictionary:
    return {
        "staff_roster": staff_roster.duplicate(true),
        "candidates": candidates.duplicate(true),
        "_next_id": _next_id,
    }


func load_state(data: Dictionary) -> void:
    staff_roster = data.get("staff_roster", [])
    candidates = data.get("candidates", [])
    _next_id = data.get("_next_id", 0)
```

**Step 4: Register autoload in project.godot**

Add after ResearchManager line:
```
StaffManager="*res://autoloads/StaffManager.gd"
```

**Step 5: Add StaffManager.reset() to GameState.reset()**

In `GameState.gd` `reset()`, add after `ResearchManager.reset()`:
```gdscript
if is_instance_valid(StaffManager):
    StaffManager.reset()
```

**Step 6: Run tests**

Run: `GODOT="<path>" make test`
Expected: All PASS

**Step 7: Commit**

```
feat(staff): add StaffManager autoload with hiring, firing, assignment, training, specialization
```

---

### Task 3: Add phase assignment, bonus, XP, training, specialization tests

**Files:**
- Modify: `src/tests/test_staff_manager.gd`

**Step 1: Add remaining tests**

```gdscript
# --- Phase assignment ---
func test_assign_to_phase() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    StaffManager.assign_to_phase(cid, "mashing")
    var assigned: Dictionary = StaffManager.get_staff_assigned_to("mashing")
    assert_eq(assigned.get("staff_id", ""), cid)

func test_assign_swaps_existing() -> void:
    StaffManager.generate_candidates(3)
    var c1: String = StaffManager.candidates[0].get("staff_id", "")
    var c2: String = StaffManager.candidates[1].get("staff_id", "")
    StaffManager.hire(c1)
    StaffManager.hire(c2)
    StaffManager.assign_to_phase(c1, "mashing")
    StaffManager.assign_to_phase(c2, "mashing")
    var assigned: Dictionary = StaffManager.get_staff_assigned_to("mashing")
    assert_eq(assigned.get("staff_id", ""), c2)
    # c1 should be unassigned
    for s in StaffManager.staff_roster:
        if s.get("staff_id", "") == c1:
            assert_eq(s.get("assigned_phase", ""), "")

func test_unassign_with_empty_string() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    StaffManager.assign_to_phase(cid, "mashing")
    StaffManager.assign_to_phase(cid, "")
    var assigned: Dictionary = StaffManager.get_staff_assigned_to("mashing")
    assert_true(assigned.is_empty())

# --- Bonus calculation ---
func test_phase_bonus_unassigned_is_zero() -> void:
    var bonus: Dictionary = StaffManager.get_phase_bonus("mashing")
    assert_eq(bonus.get("flavor", -1.0), 0.0)
    assert_eq(bonus.get("technique", -1.0), 0.0)

func test_phase_bonus_scales_with_creativity() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    # Override stats for deterministic test
    StaffManager.staff_roster[0]["creativity"] = 60
    StaffManager.staff_roster[0]["precision"] = 0
    StaffManager.staff_roster[0]["level"] = 1
    StaffManager.assign_to_phase(cid, "mashing")
    var bonus: Dictionary = StaffManager.get_phase_bonus("mashing")
    # creativity(60) * level_mult(1.0) * spec_mult(1.0) / 10 = 6.0
    assert_almost_eq(bonus.get("flavor", 0.0), 6.0, 0.01)

func test_phase_bonus_scales_with_precision() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    StaffManager.staff_roster[0]["creativity"] = 0
    StaffManager.staff_roster[0]["precision"] = 80
    StaffManager.staff_roster[0]["level"] = 1
    StaffManager.assign_to_phase(cid, "boiling")
    var bonus: Dictionary = StaffManager.get_phase_bonus("boiling")
    assert_almost_eq(bonus.get("technique", 0.0), 8.0, 0.01)

func test_specialization_doubles_bonus_in_own_phase() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    StaffManager.staff_roster[0]["creativity"] = 50
    StaffManager.staff_roster[0]["precision"] = 50
    StaffManager.staff_roster[0]["level"] = 5
    StaffManager.staff_roster[0]["specialization"] = "mashing"
    StaffManager.assign_to_phase(cid, "mashing")
    var bonus: Dictionary = StaffManager.get_phase_bonus("mashing")
    # creativity(50) * level_mult(1.4) * spec_mult(2.0) / 10 = 14.0
    assert_almost_eq(bonus.get("flavor", 0.0), 14.0, 0.01)

func test_specialization_halves_bonus_in_other_phases() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    StaffManager.staff_roster[0]["creativity"] = 50
    StaffManager.staff_roster[0]["precision"] = 50
    StaffManager.staff_roster[0]["level"] = 5
    StaffManager.staff_roster[0]["specialization"] = "mashing"
    StaffManager.assign_to_phase(cid, "boiling")
    var bonus: Dictionary = StaffManager.get_phase_bonus("boiling")
    # creativity(50) * level_mult(1.4) * spec_mult(0.5) / 10 = 3.5
    assert_almost_eq(bonus.get("flavor", 0.0), 3.5, 0.01)

# --- XP and leveling ---
func test_award_xp_accumulates() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    StaffManager.assign_to_phase(cid, "mashing")
    StaffManager.award_xp("mashing", 30)
    assert_eq(StaffManager.staff_roster[0].get("experience_points", 0), 30)

func test_level_up_on_threshold() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    StaffManager.assign_to_phase(cid, "mashing")
    StaffManager.award_xp("mashing", 100)  # level 1 threshold = 100
    assert_eq(StaffManager.staff_roster[0].get("level", 1), 2)

func test_level_up_increases_stats() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    var old_c: int = StaffManager.staff_roster[0].get("creativity", 0)
    var old_p: int = StaffManager.staff_roster[0].get("precision", 0)
    StaffManager.assign_to_phase(cid, "mashing")
    StaffManager.award_xp("mashing", 100)
    assert_gt(StaffManager.staff_roster[0].get("creativity", 0), old_c)
    assert_gt(StaffManager.staff_roster[0].get("precision", 0), old_p)

func test_level_up_emits_signal() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    StaffManager.assign_to_phase(cid, "mashing")
    watch_signals(StaffManager)
    StaffManager.award_xp("mashing", 100)
    assert_signal_emitted(StaffManager, "staff_leveled_up")

func test_no_level_up_below_threshold() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    StaffManager.assign_to_phase(cid, "mashing")
    StaffManager.award_xp("mashing", 50)
    assert_eq(StaffManager.staff_roster[0].get("level", 1), 1)

# --- Training ---
func test_training_deducts_balance() -> void:
    GameState.balance = 500.0
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    StaffManager.start_training(cid, "creativity")
    assert_almost_eq(GameState.balance, 300.0, 0.01)

func test_training_marks_staff_unavailable() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    StaffManager.start_training(cid, "creativity")
    assert_true(StaffManager.staff_roster[0].get("is_training", false))

func test_training_fails_insufficient_balance() -> void:
    GameState.balance = 100.0
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    var result: bool = StaffManager.start_training(cid, "creativity")
    assert_false(result)

func test_training_completes_after_one_turn() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    StaffManager.start_training(cid, "creativity")
    StaffManager.tick_training()
    assert_false(StaffManager.staff_roster[0].get("is_training", false))

func test_training_boosts_stat() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    var old_c: int = StaffManager.staff_roster[0].get("creativity", 0)
    StaffManager.start_training(cid, "creativity")
    StaffManager.tick_training()
    assert_gt(StaffManager.staff_roster[0].get("creativity", 0), old_c)

# --- Specialization ---
func test_specialization_requires_level_5() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    StaffManager.staff_roster[0]["level"] = 4
    var result: bool = StaffManager.specialize(cid, "mashing")
    assert_false(result)

func test_specialization_sets_field() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    StaffManager.staff_roster[0]["level"] = 5
    StaffManager.specialize(cid, "mashing")
    assert_eq(StaffManager.staff_roster[0].get("specialization", "none"), "mashing")

func test_specialization_cannot_change_once_set() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    StaffManager.staff_roster[0]["level"] = 5
    StaffManager.specialize(cid, "mashing")
    var result: bool = StaffManager.specialize(cid, "boiling")
    assert_false(result)

# --- Salary ---
func test_salary_deduction() -> void:
    GameState.balance = 1000.0
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    StaffManager.staff_roster[0]["salary_per_turn"] = 80
    var deducted: float = StaffManager.deduct_salaries()
    assert_almost_eq(deducted, 80.0, 0.01)
    assert_almost_eq(GameState.balance, 920.0, 0.01)

func test_salary_deduction_two_staff() -> void:
    GameState.balance = 1000.0
    StaffManager.generate_candidates(3)
    var c1: String = StaffManager.candidates[0].get("staff_id", "")
    var c2: String = StaffManager.candidates[1].get("staff_id", "")
    StaffManager.hire(c1)
    StaffManager.hire(c2)
    StaffManager.staff_roster[0]["salary_per_turn"] = 80
    StaffManager.staff_roster[1]["salary_per_turn"] = 60
    var deducted: float = StaffManager.deduct_salaries()
    assert_almost_eq(deducted, 140.0, 0.01)

# --- Save/load ---
func test_save_and_load_state() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    StaffManager.assign_to_phase(cid, "mashing")
    var saved: Dictionary = StaffManager.save_state()
    StaffManager.reset()
    assert_eq(StaffManager.staff_roster.size(), 0)
    StaffManager.load_state(saved)
    assert_eq(StaffManager.staff_roster.size(), 1)
    assert_eq(StaffManager.staff_roster[0].get("assigned_phase", ""), "mashing")
```

**Step 2: Run tests**

Run: `GODOT="<path>" make test`
Expected: All PASS

**Step 3: Commit**

```
test(staff): add comprehensive GUT tests for StaffManager
```

---

### Task 4: Integrate staff into GameState turn lifecycle

**Files:**
- Modify: `src/autoloads/GameState.gd`

**Step 1: Add salary deduction, training tick, and candidate refresh to `_on_results_continue()`**

After `deduct_rent()` block and before win/loss checks, add:
```gdscript
# Staff salary deduction
if is_instance_valid(StaffManager):
    StaffManager.tick_training()
    var total_salary: float = StaffManager.deduct_salaries()
    if total_salary > 0.0 and is_instance_valid(ToastManager):
        ToastManager.show_toast("Salaries paid: -$%d (%d staff)" % [int(total_salary), StaffManager.staff_roster.size()])
    StaffManager.refresh_candidates()
```

**Step 2: Add XP award to `execute_brew()`**

After the RP toast (line ~281), add:
```gdscript
# Award XP to assigned staff
if is_instance_valid(StaffManager):
    var xp_per_brew: int = 25 + int(result["final_score"] / 4.0)
    for phase_name in ["mashing", "boiling", "fermenting"]:
        var leveled: bool = StaffManager.award_xp(phase_name, xp_per_brew)
        if leveled:
            var staff_dict: Dictionary = StaffManager.get_staff_assigned_to(phase_name)
            if not staff_dict.is_empty() and is_instance_valid(ToastManager):
                ToastManager.show_toast("%s leveled up! (Lv.%d)" % [staff_dict.get("staff_name", "Staff"), staff_dict.get("level", 1)])
```

**Step 3: Run tests**

Run: `GODOT="<path>" make test`
Expected: All PASS

**Step 4: Commit**

```
feat(staff): integrate salary deduction, XP awards, and training tick into turn lifecycle
```

---

### Task 5: Integrate staff bonus into QualityCalculator

**Files:**
- Modify: `src/autoloads/QualityCalculator.gd`
- Test: `src/tests/test_staff_manager.gd` (add integration tests)

**Step 1: Add staff bonus tests**

Add to `test_staff_manager.gd`:
```gdscript
func test_staff_bonus_increases_quality_score() -> void:
    StaffManager.generate_candidates(2)
    var cid: String = StaffManager.candidates[0].get("staff_id", "")
    StaffManager.hire(cid)
    StaffManager.staff_roster[0]["creativity"] = 80
    StaffManager.staff_roster[0]["precision"] = 80
    StaffManager.assign_to_phase(cid, "mashing")
    var bonus: Dictionary = StaffManager.get_phase_bonus("mashing")
    assert_gt(bonus.get("flavor", 0.0), 0.0)
    assert_gt(bonus.get("technique", 0.0), 0.0)
```

**Step 2: Read QualityCalculator.gd to find exact insertion point**

Find `_compute_points()` method and locate where equipment bonuses are applied.

**Step 3: Add staff bonus after equipment bonus block**

```gdscript
# Staff bonuses — flat flavor/technique addition per phase
if is_instance_valid(StaffManager):
    for phase_name in ["mashing", "boiling", "fermenting"]:
        var staff_bonus: Dictionary = StaffManager.get_phase_bonus(phase_name)
        flavor += staff_bonus.get("flavor", 0.0)
        technique += staff_bonus.get("technique", 0.0)
```

**Step 4: Run tests**

Run: `GODOT="<path>" make test`
Expected: All PASS

**Step 5: Commit**

```
feat(staff): integrate staff bonus into QualityCalculator scoring
```

---

### Task 6: Add Staff button to BreweryScene

**Files:**
- Modify: `src/scenes/BreweryScene.gd`

**Step 1: Add signal and button variable**

Add `signal staff_requested()` and `var _staff_button: Button = null` to class vars.

**Step 2: Add Staff button in `_build_equipment_ui()`**

After the Research button block (~line 188), add identical button with:
- `text = "Staff"`, position = `Vector2(960, 620)`, same style as Research button
- `pressed.connect(func(): staff_requested.emit())`

**Step 3: Run tests**

Run: `GODOT="<path>" make test`
Expected: All PASS

**Step 4: Commit**

```
feat(staff): add Staff button to brewery hub
```

---

### Task 7: Build StaffScreen overlay UI

**Files:**
- Create: `src/ui/StaffScreen.gd`

**Step 1: Implement the full StaffScreen**

Follow the wireframe at `design/wireframes/staff-system.md`. Build using the exact same pattern as `ResearchTree.gd`:

- `extends Control`, `signal closed()`
- `_ready()` calls `_build_ui()`, sets `visible = false`
- `show_screen()` sets `modulate.a = 1.0`, `visible = true`, calls `_refresh()`
- Dim background with click-to-close
- 900x550 centered panel
- Header: "STAFF MANAGEMENT" + staff count + close button
- YOUR STAFF section: `_roster_container` (VBoxContainer) rebuilt on `_refresh()`
- CANDIDATES section: `_candidates_container` (HBoxContainer) rebuilt on `_refresh()`
- Roster cards: name/level/salary header, creativity ProgressBar, precision ProgressBar, assignment text, action buttons
- Candidate cards: name, stats, salary, Hire button
- Assign popup: small centered dialog with phase buttons
- Training popup: creativity/precision choice with cost
- Specialization popup: phase choice with permanent warning + confirmation
- Fire: ConfirmationDialog

**Step 2: Run tests**

Run: `GODOT="<path>" make test`
Expected: All PASS (no new tests for UI — tested via manual play)

**Step 3: Commit**

```
feat(staff): add StaffScreen overlay UI with hiring, assignment, training, specialization
```

---

### Task 8: Add staff bonus display to BrewingPhases

**Files:**
- Modify: `src/ui/BrewingPhases.gd`

**Step 1: Read BrewingPhases.gd to find where to add staff labels**

Each phase has a VBoxContainer with slider and value label. Add a staff bonus label after each.

**Step 2: Add `_update_staff_labels()` method**

```gdscript
var _staff_labels: Dictionary = {}  # phase -> Label

func _update_staff_labels() -> void:
    if not is_instance_valid(StaffManager):
        return
    for phase in ["mashing", "boiling", "fermenting"]:
        var staff: Dictionary = StaffManager.get_staff_assigned_to(phase)
        var label: Label = _staff_labels.get(phase, null)
        if label == null:
            continue
        if staff.is_empty():
            label.text = "(no staff assigned)"
            label.add_theme_color_override("font_color", Color("#8A9BB1"))
        else:
            var bonus: Dictionary = StaffManager.get_phase_bonus(phase)
            var flavor: int = int(bonus.get("flavor", 0.0))
            var technique: int = int(bonus.get("technique", 0.0))
            label.text = "%s: +%d flavor, +%d technique" % [staff.get("staff_name", "Staff"), flavor, technique]
            label.add_theme_color_override("font_color", Color("#5EE8A4"))
```

Call from `refresh()`.

**Step 3: Create the labels during `_build_ui()` and store in `_staff_labels`**

Add a Label after each phase's slider value label, store reference in `_staff_labels[phase_name]`.

**Step 4: Run tests**

Run: `GODOT="<path>" make test`
Expected: All PASS

**Step 5: Commit**

```
feat(staff): display staff bonus per phase in BrewingPhases UI
```

---

### Task 9: Wire StaffScreen into Game.gd

**Files:**
- Modify: `src/scenes/Game.gd`

**Step 1: Add StaffScreen wiring**

In `_ready()`, after research_tree block:
```gdscript
var staff_script = preload("res://ui/StaffScreen.gd")
staff_screen = Control.new()
staff_screen.set_script(staff_script)
staff_screen.name = "StaffScreen"
add_child(staff_screen)
```

Add `staff_screen` to `_all_overlays`.

Wire signals:
```gdscript
brewery_scene.staff_requested.connect(_on_staff_requested)
staff_screen.closed.connect(_on_staff_screen_closed)
```

Add handlers:
```gdscript
func _on_staff_requested() -> void:
    staff_screen.show_screen()

func _on_staff_screen_closed() -> void:
    pass
```

**Step 2: Run tests**

Run: `GODOT="<path>" make test`
Expected: All PASS

**Step 3: Commit**

```
feat(staff): wire StaffScreen into Game.gd scene controller
```

---

### Task 10: Final integration test run

**Step 1: Run full test suite**

Run: `GODOT="<path>" make test`
Expected: All tests PASS (237 existing + ~35 new staff tests)

**Step 2: Verify no regressions**

Check that all 237 existing tests still pass alongside new staff tests.

**Step 3: Final commit if any cleanup needed**

```
chore(staff): Stage 3A complete — staff system with hiring, assignment, training, specialization
```
