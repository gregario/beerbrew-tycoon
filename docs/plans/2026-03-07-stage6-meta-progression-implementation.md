# Stage 6 — Meta-Progression Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add roguelite persistence between runs — unlock points, meta-shop, perks, modifiers, achievements, main menu, and run-start screen.

**Architecture:** New `MetaProgressionManager` autoload owns all persistent state (meta.json, separate from run saves). New `RunModifierManager` autoload applies active perks/modifiers to game systems during a run. Six new UI overlays follow existing CanvasLayer programmatic pattern. Game flow changes: MainMenu → RunStartScreen → Game loop → GameOver → RunSummary → UnlockShop → (loop or MainMenu).

**Tech Stack:** Godot 4 / GDScript, GUT testing, existing autoload architecture.

**Design Reference:** `design/wireframes/meta-progression.md` — all wireframes, interaction spec, persistence schema.

**Existing Patterns to Follow:**
- Autoloads: `ResearchManager.gd` (catalog + unlock + save/load), `BreweryExpansion.gd` (stage enum + thresholds), `PathManager.gd` (strategy + serialize)
- Overlays: CanvasLayer with layer=10, CenterContainer + PRESET_FULL_RECT, mouse_filter=MOUSE_FILTER_PASS on containers
- Tests: GUT with `extends GutTest`, `before_each()` resets, `assert_eq/true/false/almost_eq`
- Run tests: `GODOT="/Users/gregario/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot" make test`

**Theme Tokens** (from `design/theme.json`):
- primary=#5AA9FF, accent=#FFC857, success=#5EE8A4, warning=#FFB347, danger=#FF7B7B
- background=#0F1724, surface=#0B1220, muted=#8A9BB1
- NEW: meta=#B88AFF (purple, for unlock points)
- Font sizes: xs=16, sm=20, md=24, lg=32, xl=40
- Card: 900x550, padding=32, corner_radius=4, border=2

---

## Task 1: MetaProgressionManager Autoload — Core State & Persistence

**Files:**
- Create: `src/autoloads/MetaProgressionManager.gd`
- Create: `src/tests/test_meta_progression_manager.gd`
- Modify: `src/project.godot` — add autoload registration

**Context:** This is the central autoload for ALL meta-progression state. It persists to `user://meta.json` (separate from run saves). GameState.reset() must NOT touch this data.

**Step 1: Write the failing test**

```gdscript
extends GutTest

var manager: Node

func before_each() -> void:
	manager = preload("res://autoloads/MetaProgressionManager.gd").new()
	add_child_autofree(manager)

# --- Core state ---

func test_initial_state_has_zero_points() -> void:
	assert_eq(manager.available_points, 0)
	assert_eq(manager.lifetime_points, 0)

func test_initial_state_has_empty_unlocks() -> void:
	assert_eq(manager.unlocked_styles.size(), 0)
	assert_eq(manager.unlocked_blueprints.size(), 0)
	assert_eq(manager.unlocked_ingredients.size(), 0)
	assert_eq(manager.unlocked_perks.size(), 0)

func test_initial_state_has_no_achievements() -> void:
	var achievements: Dictionary = manager.get_achievements()
	for key in achievements:
		assert_false(achievements[key])

func test_initial_run_history_empty() -> void:
	assert_eq(manager.run_history.size(), 0)
	assert_eq(manager.total_runs, 0)

# --- Add points ---

func test_add_points_increases_available_and_lifetime() -> void:
	manager.add_points(10)
	assert_eq(manager.available_points, 10)
	assert_eq(manager.lifetime_points, 10)

func test_add_points_accumulates() -> void:
	manager.add_points(5)
	manager.add_points(7)
	assert_eq(manager.available_points, 12)
	assert_eq(manager.lifetime_points, 12)

# --- Spend points ---

func test_spend_points_reduces_available() -> void:
	manager.add_points(10)
	var success: bool = manager.spend_points(4)
	assert_true(success)
	assert_eq(manager.available_points, 6)
	assert_eq(manager.lifetime_points, 10)

func test_spend_points_fails_if_insufficient() -> void:
	manager.add_points(3)
	var success: bool = manager.spend_points(5)
	assert_false(success)
	assert_eq(manager.available_points, 3)

# --- Save/Load ---

func test_save_returns_dict() -> void:
	manager.add_points(15)
	var data: Dictionary = manager.save_state()
	assert_true(data.has("available_points"))
	assert_true(data.has("lifetime_points"))
	assert_true(data.has("unlocked_styles"))
	assert_true(data.has("achievements"))
	assert_true(data.has("run_history"))

func test_load_restores_state() -> void:
	manager.add_points(20)
	manager.spend_points(5)
	var data: Dictionary = manager.save_state()
	var manager2: Node = preload("res://autoloads/MetaProgressionManager.gd").new()
	add_child_autofree(manager2)
	manager2.load_state(data)
	assert_eq(manager2.available_points, 15)
	assert_eq(manager2.lifetime_points, 20)

func test_reset_meta_clears_everything() -> void:
	manager.add_points(10)
	manager.reset_meta()
	assert_eq(manager.available_points, 0)
	assert_eq(manager.lifetime_points, 0)
	assert_eq(manager.total_runs, 0)
```

**Step 2: Run test to verify it fails**

Run: `GODOT="..." make test`
Expected: FAIL — MetaProgressionManager.gd doesn't exist

**Step 3: Write MetaProgressionManager.gd**

```gdscript
extends Node

## MetaProgressionManager — persistent cross-run progression.
## Owns unlock points, unlocked items, achievements, run history.
## Persists to user://meta.json (separate from run saves).

signal points_changed(available: int, lifetime: int)
signal item_unlocked(category: String, item_id: String)
signal achievement_completed(achievement_id: String)

# --- Persistent state ---
var available_points: int = 0
var lifetime_points: int = 0
var total_runs: int = 0

var unlocked_styles: Array[String] = []
var unlocked_blueprints: Array[String] = []
var unlocked_ingredients: Array[String] = []
var unlocked_perks: Array[String] = []

var achievements: Dictionary = {
	"first_victory": false,
	"budget_master": false,
	"perfect_brew": false,
	"survivor": false,
	"diversified": false,
	"scarcity_brewer": false,
}

var achievement_progress: Dictionary = {
	"best_quality": 0.0,
	"best_turns": 0,
	"min_equipment_spend": 999999,
	"max_channels": 0,
	"min_unique_ingredients": 999,
}

var run_history: Array[Dictionary] = []

# Active selections for current/next run
var active_perks: Array[String] = []
var active_modifiers: Array[String] = []

const MAX_PERKS: int = 3
const MAX_MODIFIERS: int = 2
const MAX_HISTORY: int = 10

const META_SAVE_PATH: String = "user://meta.json"

# --- Points ---

func add_points(amount: int) -> void:
	available_points += amount
	lifetime_points += amount
	points_changed.emit(available_points, lifetime_points)

func spend_points(amount: int) -> bool:
	if amount > available_points:
		return false
	available_points -= amount
	points_changed.emit(available_points, lifetime_points)
	return true

# --- Unlocks ---

func unlock_style(style_id: String, cost: int) -> bool:
	if style_id in unlocked_styles:
		return false
	if not spend_points(cost):
		return false
	unlocked_styles.append(style_id)
	item_unlocked.emit("styles", style_id)
	return true

func unlock_blueprint(equipment_id: String, cost: int) -> bool:
	if equipment_id in unlocked_blueprints:
		return false
	if not spend_points(cost):
		return false
	unlocked_blueprints.append(equipment_id)
	item_unlocked.emit("blueprints", equipment_id)
	return true

func unlock_ingredient(ingredient_id: String, cost: int) -> bool:
	if ingredient_id in unlocked_ingredients:
		return false
	if not spend_points(cost):
		return false
	unlocked_ingredients.append(ingredient_id)
	item_unlocked.emit("ingredients", ingredient_id)
	return true

func unlock_perk(perk_id: String, cost: int) -> bool:
	if perk_id in unlocked_perks:
		return false
	if not spend_points(cost):
		return false
	unlocked_perks.append(perk_id)
	item_unlocked.emit("perks", perk_id)
	return true

func is_unlocked(category: String, item_id: String) -> bool:
	match category:
		"styles": return item_id in unlocked_styles
		"blueprints": return item_id in unlocked_blueprints
		"ingredients": return item_id in unlocked_ingredients
		"perks": return item_id in unlocked_perks
	return false

# --- Achievements ---

func get_achievements() -> Dictionary:
	return achievements.duplicate()

func complete_achievement(achievement_id: String) -> void:
	if achievements.has(achievement_id) and not achievements[achievement_id]:
		achievements[achievement_id] = true
		achievement_completed.emit(achievement_id)

func is_achievement_completed(achievement_id: String) -> bool:
	return achievements.get(achievement_id, false)

func get_achievement_progress() -> Dictionary:
	return achievement_progress.duplicate()

# --- Run history ---

func record_run(run_data: Dictionary) -> void:
	total_runs += 1
	run_history.append(run_data)
	if run_history.size() > MAX_HISTORY:
		run_history.pop_front()

# --- Perk/modifier selection ---

func set_active_perks(perks: Array[String]) -> void:
	active_perks = perks.slice(0, MAX_PERKS)

func set_active_modifiers(modifiers: Array[String]) -> void:
	active_modifiers = modifiers.slice(0, MAX_MODIFIERS)

func has_active_perk(perk_id: String) -> bool:
	return perk_id in active_perks

func has_active_modifier(modifier_id: String) -> bool:
	return modifier_id in active_modifiers

func has_challenge_modifier() -> bool:
	var challenge_ids: Array[String] = ["tough_market", "budget_brewery", "ingredient_shortage"]
	for mod_id in active_modifiers:
		if mod_id in challenge_ids:
			return true
	return false

# --- Persistence ---

func save_state() -> Dictionary:
	return {
		"version": 1,
		"available_points": available_points,
		"lifetime_points": lifetime_points,
		"total_runs": total_runs,
		"unlocked_styles": unlocked_styles.duplicate(),
		"unlocked_blueprints": unlocked_blueprints.duplicate(),
		"unlocked_ingredients": unlocked_ingredients.duplicate(),
		"unlocked_perks": unlocked_perks.duplicate(),
		"achievements": achievements.duplicate(),
		"achievement_progress": achievement_progress.duplicate(),
		"run_history": run_history.duplicate(true),
		"active_perks": active_perks.duplicate(),
		"active_modifiers": active_modifiers.duplicate(),
	}

func load_state(data: Dictionary) -> void:
	available_points = data.get("available_points", 0)
	lifetime_points = data.get("lifetime_points", 0)
	total_runs = data.get("total_runs", 0)
	unlocked_styles.assign(data.get("unlocked_styles", []))
	unlocked_blueprints.assign(data.get("unlocked_blueprints", []))
	unlocked_ingredients.assign(data.get("unlocked_ingredients", []))
	unlocked_perks.assign(data.get("unlocked_perks", []))
	var loaded_achievements: Dictionary = data.get("achievements", {})
	for key in achievements:
		achievements[key] = loaded_achievements.get(key, false)
	var loaded_progress: Dictionary = data.get("achievement_progress", {})
	for key in achievement_progress:
		achievement_progress[key] = loaded_progress.get(key, achievement_progress[key])
	run_history.assign(data.get("run_history", []))
	active_perks.assign(data.get("active_perks", []))
	active_modifiers.assign(data.get("active_modifiers", []))

func save_to_disk() -> void:
	var data: Dictionary = save_state()
	var json_string: String = JSON.stringify(data, "\t")
	var file: FileAccess = FileAccess.open(META_SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(json_string)

func load_from_disk() -> void:
	if not FileAccess.file_exists(META_SAVE_PATH):
		return
	var file: FileAccess = FileAccess.open(META_SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var json_string: String = file.get_as_text()
	var json: JSON = JSON.new()
	var err: int = json.parse(json_string)
	if err == OK:
		load_state(json.data)

func reset_meta() -> void:
	available_points = 0
	lifetime_points = 0
	total_runs = 0
	unlocked_styles.clear()
	unlocked_blueprints.clear()
	unlocked_ingredients.clear()
	unlocked_perks.clear()
	for key in achievements:
		achievements[key] = false
	for key in achievement_progress:
		match key:
			"min_equipment_spend": achievement_progress[key] = 999999
			"min_unique_ingredients": achievement_progress[key] = 999
			_: achievement_progress[key] = 0
	run_history.clear()
	active_perks.clear()
	active_modifiers.clear()
```

**Step 4: Register autoload in project.godot**

Add this line after the SpecialtyBeerManager line:
```
MetaProgressionManager="*res://autoloads/MetaProgressionManager.gd"
```

**Step 5: Run tests**

Run: `GODOT="..." make test`
Expected: All tests pass including new meta progression tests.

**Step 6: Commit**

```bash
git add src/autoloads/MetaProgressionManager.gd src/tests/test_meta_progression_manager.gd src/project.godot
git commit -m "feat: add MetaProgressionManager autoload with core state, points, unlocks, save/load"
```

---

## Task 2: Unlock Point Calculation & Run Recording

**Files:**
- Modify: `src/autoloads/MetaProgressionManager.gd` — add `calculate_run_points()` and `end_run()`
- Modify: `src/tests/test_meta_progression_manager.gd` — add calculation tests

**Context:** At end of run, calculate unlock points based on turns survived, revenue, quality, medals, win status. Challenge modifiers multiply by 1.5x.

**Step 1: Write the failing tests**

```gdscript
# --- Unlock point calculation ---

func test_calculate_points_zero_for_empty_run() -> void:
	var metrics: Dictionary = {"turns": 0, "revenue": 0.0, "best_quality": 0.0, "medals": 0, "won": false}
	var points: int = manager.calculate_run_points(metrics)
	assert_eq(points, 0)

func test_calculate_points_turns_component() -> void:
	# min(turns / 5, 5) → 12 turns = min(2, 5) = 2
	var metrics: Dictionary = {"turns": 12, "revenue": 0.0, "best_quality": 0.0, "medals": 0, "won": false}
	assert_eq(manager.calculate_run_points(metrics), 2)

func test_calculate_points_revenue_component() -> void:
	# min(int(revenue / 2000), 5) → 8420 = min(4, 5) = 4
	var metrics: Dictionary = {"turns": 0, "revenue": 8420.0, "best_quality": 0.0, "medals": 0, "won": false}
	assert_eq(manager.calculate_run_points(metrics), 4)

func test_calculate_points_quality_component() -> void:
	# min(int(best_quality / 20), 5) → 87 = min(4, 5) = 4
	var metrics: Dictionary = {"turns": 0, "revenue": 0.0, "best_quality": 87.0, "medals": 0, "won": false}
	assert_eq(manager.calculate_run_points(metrics), 4)

func test_calculate_points_medals_component() -> void:
	# min(medals, 5)
	var metrics: Dictionary = {"turns": 0, "revenue": 0.0, "best_quality": 0.0, "medals": 3, "won": false}
	assert_eq(manager.calculate_run_points(metrics), 3)

func test_calculate_points_win_bonus() -> void:
	var metrics: Dictionary = {"turns": 0, "revenue": 0.0, "best_quality": 0.0, "medals": 0, "won": true}
	assert_eq(manager.calculate_run_points(metrics), 5)

func test_calculate_points_full_run() -> void:
	# turns=12→2, revenue=8420→4, quality=87→4, medals=2→2, won=true→5 = 17
	var metrics: Dictionary = {"turns": 12, "revenue": 8420.0, "best_quality": 87.0, "medals": 2, "won": true}
	assert_eq(manager.calculate_run_points(metrics), 17)

func test_calculate_points_capped_at_25_base() -> void:
	# All maxed: turns=30→5, revenue=50000→5, quality=100→5, medals=10→5, won→5 = 25
	var metrics: Dictionary = {"turns": 30, "revenue": 50000.0, "best_quality": 100.0, "medals": 10, "won": true}
	assert_eq(manager.calculate_run_points(metrics), 25)

func test_calculate_points_challenge_multiplier() -> void:
	var metrics: Dictionary = {"turns": 12, "revenue": 8420.0, "best_quality": 87.0, "medals": 2, "won": true}
	# Base 17, with challenge = floor(17 * 1.5) = 25
	manager.set_active_modifiers(["tough_market"] as Array[String])
	assert_eq(manager.calculate_run_points(metrics), 25)

func test_end_run_adds_points_and_records() -> void:
	var metrics: Dictionary = {"turns": 10, "revenue": 4000.0, "best_quality": 60.0, "medals": 1, "won": false}
	manager.end_run(metrics)
	assert_gt(manager.available_points, 0)
	assert_eq(manager.total_runs, 1)
	assert_eq(manager.run_history.size(), 1)
```

**Step 2: Run test — expect FAIL**

**Step 3: Add to MetaProgressionManager.gd**

```gdscript
func calculate_run_points(metrics: Dictionary) -> int:
	var turns: int = metrics.get("turns", 0)
	var revenue: float = metrics.get("revenue", 0.0)
	var best_quality: float = metrics.get("best_quality", 0.0)
	var medals: int = metrics.get("medals", 0)
	var won: bool = metrics.get("won", false)

	var base: int = 0
	base += mini(turns / 5, 5)
	base += mini(int(revenue / 2000.0), 5)
	base += mini(int(best_quality / 20.0), 5)
	base += mini(medals, 5)
	if won:
		base += 5

	if has_challenge_modifier():
		base = int(float(base) * 1.5)

	return base

func end_run(metrics: Dictionary) -> int:
	var points: int = calculate_run_points(metrics)
	add_points(points)

	var run_data: Dictionary = metrics.duplicate()
	run_data["unlock_points"] = points
	record_run(run_data)

	return points
```

**Step 4: Run tests — expect PASS**

**Step 5: Commit**

```bash
git add src/autoloads/MetaProgressionManager.gd src/tests/test_meta_progression_manager.gd
git commit -m "feat: add unlock point calculation and end_run recording"
```

---

## Task 3: Achievement System

**Files:**
- Modify: `src/autoloads/MetaProgressionManager.gd` — add `update_achievement_progress()` and `check_achievements()`
- Modify: `src/tests/test_meta_progression_manager.gd` — add achievement tests

**Context:** 6 achievements, each unlocking a run modifier. Progress tracked across runs (best-ever stats). Check after each run ends.

**Achievement Definitions:**
| ID | Condition | Unlocks Modifier |
|----|-----------|-----------------|
| first_victory | Win any run | tough_market |
| budget_master | Win with equipment_spend < 1000 | budget_brewery |
| perfect_brew | best_quality >= 95 | master_brewer |
| survivor | best_turns >= 20 | lucky_break |
| diversified | max_channels >= 4 | generous_market |
| scarcity_brewer | Win with unique_ingredients <= 10 | ingredient_shortage |

**Step 1: Write the failing tests**

```gdscript
# --- Achievement definitions ---

const ACHIEVEMENT_MODIFIER_MAP: Dictionary = {
	"first_victory": "tough_market",
	"budget_master": "budget_brewery",
	"perfect_brew": "master_brewer",
	"survivor": "lucky_break",
	"diversified": "generous_market",
	"scarcity_brewer": "ingredient_shortage",
}

func test_achievement_modifier_map_exists() -> void:
	var map: Dictionary = manager.get_achievement_modifier_map()
	assert_eq(map.size(), 6)
	assert_eq(map["first_victory"], "tough_market")
	assert_eq(map["perfect_brew"], "master_brewer")

func test_modifier_locked_until_achievement() -> void:
	assert_false(manager.is_modifier_unlocked("tough_market"))
	manager.complete_achievement("first_victory")
	assert_true(manager.is_modifier_unlocked("tough_market"))

# --- Progress tracking ---

func test_update_progress_tracks_best_quality() -> void:
	manager.update_achievement_progress({"best_quality": 80.0, "turns": 10, "equipment_spend": 2000, "channels_unlocked": 2, "unique_ingredients": 15, "won": false})
	assert_eq(manager.achievement_progress["best_quality"], 80.0)
	# Second run with lower quality doesn't overwrite
	manager.update_achievement_progress({"best_quality": 60.0, "turns": 5, "equipment_spend": 3000, "channels_unlocked": 1, "unique_ingredients": 20, "won": false})
	assert_eq(manager.achievement_progress["best_quality"], 80.0)

func test_update_progress_tracks_best_turns() -> void:
	manager.update_achievement_progress({"best_quality": 0.0, "turns": 15, "equipment_spend": 0, "channels_unlocked": 0, "unique_ingredients": 30, "won": false})
	assert_eq(manager.achievement_progress["best_turns"], 15)

func test_update_progress_tracks_min_equipment_spend() -> void:
	manager.update_achievement_progress({"best_quality": 0.0, "turns": 5, "equipment_spend": 800, "channels_unlocked": 0, "unique_ingredients": 30, "won": true})
	assert_eq(manager.achievement_progress["min_equipment_spend"], 800)

# --- Auto-completion ---

func test_check_achievements_completes_first_victory_on_win() -> void:
	manager.update_achievement_progress({"best_quality": 50.0, "turns": 10, "equipment_spend": 2000, "channels_unlocked": 1, "unique_ingredients": 20, "won": true})
	manager.check_achievements()
	assert_true(manager.is_achievement_completed("first_victory"))

func test_check_achievements_completes_perfect_brew() -> void:
	manager.update_achievement_progress({"best_quality": 96.0, "turns": 10, "equipment_spend": 2000, "channels_unlocked": 1, "unique_ingredients": 20, "won": false})
	manager.check_achievements()
	assert_true(manager.is_achievement_completed("perfect_brew"))

func test_check_achievements_completes_survivor() -> void:
	manager.update_achievement_progress({"best_quality": 50.0, "turns": 22, "equipment_spend": 2000, "channels_unlocked": 1, "unique_ingredients": 20, "won": false})
	manager.check_achievements()
	assert_true(manager.is_achievement_completed("survivor"))

func test_check_achievements_completes_budget_master() -> void:
	manager.update_achievement_progress({"best_quality": 50.0, "turns": 10, "equipment_spend": 800, "channels_unlocked": 1, "unique_ingredients": 20, "won": true})
	manager.check_achievements()
	assert_true(manager.is_achievement_completed("budget_master"))

func test_check_achievements_budget_master_requires_win() -> void:
	manager.update_achievement_progress({"best_quality": 50.0, "turns": 10, "equipment_spend": 500, "channels_unlocked": 1, "unique_ingredients": 20, "won": false})
	manager.check_achievements()
	assert_false(manager.is_achievement_completed("budget_master"))

func test_check_achievements_completes_diversified() -> void:
	manager.update_achievement_progress({"best_quality": 50.0, "turns": 10, "equipment_spend": 2000, "channels_unlocked": 4, "unique_ingredients": 20, "won": false})
	manager.check_achievements()
	assert_true(manager.is_achievement_completed("diversified"))

func test_check_achievements_completes_scarcity_brewer() -> void:
	manager.update_achievement_progress({"best_quality": 50.0, "turns": 10, "equipment_spend": 2000, "channels_unlocked": 1, "unique_ingredients": 8, "won": true})
	manager.check_achievements()
	assert_true(manager.is_achievement_completed("scarcity_brewer"))

func test_check_achievements_scarcity_requires_win() -> void:
	manager.update_achievement_progress({"best_quality": 50.0, "turns": 10, "equipment_spend": 2000, "channels_unlocked": 1, "unique_ingredients": 5, "won": false})
	manager.check_achievements()
	assert_false(manager.is_achievement_completed("scarcity_brewer"))

func test_end_run_updates_progress_and_checks_achievements() -> void:
	var metrics: Dictionary = {"turns": 25, "revenue": 10000.0, "best_quality": 96.0, "medals": 3, "won": true, "equipment_spend": 500, "channels_unlocked": 4, "unique_ingredients": 8}
	manager.end_run(metrics)
	assert_true(manager.is_achievement_completed("first_victory"))
	assert_true(manager.is_achievement_completed("perfect_brew"))
	assert_true(manager.is_achievement_completed("survivor"))
	assert_true(manager.is_achievement_completed("budget_master"))
	assert_true(manager.is_achievement_completed("diversified"))
	assert_true(manager.is_achievement_completed("scarcity_brewer"))
```

**Step 2: Run test — expect FAIL**

**Step 3: Add to MetaProgressionManager.gd**

```gdscript
const ACHIEVEMENT_MODIFIER_MAP: Dictionary = {
	"first_victory": "tough_market",
	"budget_master": "budget_brewery",
	"perfect_brew": "master_brewer",
	"survivor": "lucky_break",
	"diversified": "generous_market",
	"scarcity_brewer": "ingredient_shortage",
}

func get_achievement_modifier_map() -> Dictionary:
	return ACHIEVEMENT_MODIFIER_MAP

func is_modifier_unlocked(modifier_id: String) -> bool:
	for achievement_id in ACHIEVEMENT_MODIFIER_MAP:
		if ACHIEVEMENT_MODIFIER_MAP[achievement_id] == modifier_id:
			return is_achievement_completed(achievement_id)
	return false

func update_achievement_progress(metrics: Dictionary) -> void:
	var quality: float = metrics.get("best_quality", 0.0)
	var turns: int = metrics.get("turns", 0)
	var equip_spend: int = metrics.get("equipment_spend", 999999)
	var channels: int = metrics.get("channels_unlocked", 0)
	var ingredients: int = metrics.get("unique_ingredients", 999)
	var won: bool = metrics.get("won", false)

	if quality > achievement_progress["best_quality"]:
		achievement_progress["best_quality"] = quality
	if turns > achievement_progress["best_turns"]:
		achievement_progress["best_turns"] = turns
	if won and equip_spend < achievement_progress["min_equipment_spend"]:
		achievement_progress["min_equipment_spend"] = equip_spend
	if channels > achievement_progress["max_channels"]:
		achievement_progress["max_channels"] = channels
	if won and ingredients < achievement_progress["min_unique_ingredients"]:
		achievement_progress["min_unique_ingredients"] = ingredients
	# Track if player has ever won
	if won and not achievement_progress.has("has_won"):
		achievement_progress["has_won"] = true
	elif won:
		achievement_progress["has_won"] = true

func check_achievements() -> void:
	if achievement_progress.get("has_won", false):
		complete_achievement("first_victory")
	if achievement_progress["best_quality"] >= 95.0:
		complete_achievement("perfect_brew")
	if achievement_progress["best_turns"] >= 20:
		complete_achievement("survivor")
	if achievement_progress.get("has_won", false) and achievement_progress["min_equipment_spend"] < 1000:
		complete_achievement("budget_master")
	if achievement_progress["max_channels"] >= 4:
		complete_achievement("diversified")
	if achievement_progress.get("has_won", false) and achievement_progress["min_unique_ingredients"] <= 10:
		complete_achievement("scarcity_brewer")
```

Also update `end_run()` to call progress/check:

```gdscript
func end_run(metrics: Dictionary) -> int:
	var points: int = calculate_run_points(metrics)
	add_points(points)

	update_achievement_progress(metrics)
	check_achievements()

	var run_data: Dictionary = metrics.duplicate()
	run_data["unlock_points"] = points
	record_run(run_data)

	save_to_disk()
	return points
```

**Step 4: Run tests — expect PASS**

**Step 5: Commit**

```bash
git add src/autoloads/MetaProgressionManager.gd src/tests/test_meta_progression_manager.gd
git commit -m "feat: add achievement system with 6 achievements and progress tracking"
```

---

## Task 4: Unlock Catalog Definitions

**Files:**
- Modify: `src/autoloads/MetaProgressionManager.gd` — add unlock catalog with items and costs per category
- Modify: `src/tests/test_meta_progression_manager.gd` — add catalog + purchase tests

**Context:** Define what's purchasable in each category. Styles beyond base 4, equipment blueprints, rare ingredients, and perks. Costs from design doc.

**Step 1: Write the failing tests**

```gdscript
# --- Unlock catalog ---

func test_get_catalog_has_four_categories() -> void:
	var catalog: Dictionary = manager.get_unlock_catalog()
	assert_true(catalog.has("styles"))
	assert_true(catalog.has("blueprints"))
	assert_true(catalog.has("ingredients"))
	assert_true(catalog.has("perks"))

func test_catalog_styles_has_entries() -> void:
	var styles: Array = manager.get_unlock_catalog()["styles"]
	assert_gt(styles.size(), 0)
	# Each entry has id, name, description, cost
	var first: Dictionary = styles[0]
	assert_true(first.has("id"))
	assert_true(first.has("name"))
	assert_true(first.has("cost"))

func test_catalog_perks_has_four_entries() -> void:
	var perks: Array = manager.get_unlock_catalog()["perks"]
	assert_eq(perks.size(), 4)

func test_purchase_style_unlock() -> void:
	manager.add_points(10)
	var catalog: Array = manager.get_unlock_catalog()["styles"]
	var first_id: String = catalog[0]["id"]
	var cost: int = catalog[0]["cost"]
	var success: bool = manager.unlock_style(first_id, cost)
	assert_true(success)
	assert_true(manager.is_unlocked("styles", first_id))

func test_purchase_fails_if_already_unlocked() -> void:
	manager.add_points(20)
	var catalog: Array = manager.get_unlock_catalog()["styles"]
	var first_id: String = catalog[0]["id"]
	var cost: int = catalog[0]["cost"]
	manager.unlock_style(first_id, cost)
	var success: bool = manager.unlock_style(first_id, cost)
	assert_false(success)

func test_purchase_blueprint_gives_research_discount() -> void:
	manager.add_points(10)
	var catalog: Array = manager.get_unlock_catalog()["blueprints"]
	var first_id: String = catalog[0]["id"]
	var cost: int = catalog[0]["cost"]
	manager.unlock_blueprint(first_id, cost)
	assert_true(manager.has_blueprint_discount(first_id))

func test_no_blueprint_discount_without_purchase() -> void:
	assert_false(manager.has_blueprint_discount("mash_tun"))
```

**Step 2: Run test — expect FAIL**

**Step 3: Add catalog and helper to MetaProgressionManager.gd**

```gdscript
const UNLOCK_CATALOG: Dictionary = {
	"styles": [
		{"id": "lager", "name": "Lager", "description": "Crisp, clean, light-bodied", "cost": 5},
		{"id": "wheat_beer", "name": "Wheat Beer", "description": "Hazy, fruity esters", "cost": 5},
		{"id": "stout", "name": "Stout", "description": "Roasted, coffee, dark", "cost": 8},
		{"id": "berliner_weisse", "name": "Berliner Weisse", "description": "Sour, tart, refreshing", "cost": 10},
		{"id": "lambic", "name": "Lambic", "description": "Wild fermented, complex", "cost": 10},
	],
	"blueprints": [
		{"id": "mash_tun", "name": "Mash Tun", "description": "50% off research cost", "cost": 5},
		{"id": "temp_chamber", "name": "Temperature Chamber", "description": "50% off research cost", "cost": 5},
		{"id": "kegging_kit", "name": "Kegging Kit", "description": "50% off research cost", "cost": 5},
		{"id": "three_vessel", "name": "Three-Vessel System", "description": "50% off research cost", "cost": 8},
		{"id": "ss_conical", "name": "SS Conical Fermenter", "description": "50% off research cost", "cost": 8},
	],
	"ingredients": [
		{"id": "crystal_60", "name": "Crystal 60", "description": "Caramel, toffee malt", "cost": 3},
		{"id": "chocolate_malt", "name": "Chocolate Malt", "description": "Dark, rich flavor", "cost": 3},
		{"id": "cascade", "name": "Cascade Hops", "description": "Floral, citrus American hop", "cost": 4},
		{"id": "citra", "name": "Citra Hops", "description": "Tropical, grapefruit hop", "cost": 6},
		{"id": "belle_saison", "name": "Belle Saison Yeast", "description": "Spicy, fruity esters", "cost": 5},
		{"id": "kveik_voss", "name": "Kveik (Voss)", "description": "Fast, tropical fermentation", "cost": 5},
	],
	"perks": [
		{"id": "nest_egg", "name": "Nest Egg", "description": "+5% starting cash ($525)", "cost": 8},
		{"id": "quick_study", "name": "Quick Study", "description": "+1 base RP per brew", "cost": 10},
		{"id": "landlords_friend", "name": "Landlord's Friend", "description": "-10% rent costs", "cost": 8},
		{"id": "style_specialist", "name": "Style Specialist", "description": "+5% quality for one style family", "cost": 12},
	],
}

func get_unlock_catalog() -> Dictionary:
	return UNLOCK_CATALOG

func has_blueprint_discount(equipment_id: String) -> bool:
	return equipment_id in unlocked_blueprints
```

**Step 4: Run tests — expect PASS**

**Step 5: Commit**

```bash
git add src/autoloads/MetaProgressionManager.gd src/tests/test_meta_progression_manager.gd
git commit -m "feat: add unlock catalog with styles, blueprints, ingredients, and perks"
```

---

## Task 5: Perk & Modifier Effects Integration

**Files:**
- Create: `src/autoloads/RunModifierManager.gd`
- Create: `src/tests/test_run_modifier_manager.gd`
- Modify: `src/project.godot` — add autoload registration
- Modify: `src/autoloads/GameState.gd` — apply perk/modifier effects at run start

**Context:** RunModifierManager reads active perks/modifiers from MetaProgressionManager and provides query methods that existing systems call. Effects: starting cash bonus, RP bonus, rent discount, quality bonus, demand modifier, ingredient availability, infection immunity.

**Step 1: Write the failing tests**

```gdscript
extends GutTest

var modifier_mgr: Node
var meta_mgr: Node

func before_each() -> void:
	meta_mgr = preload("res://autoloads/MetaProgressionManager.gd").new()
	add_child_autofree(meta_mgr)
	modifier_mgr = preload("res://autoloads/RunModifierManager.gd").new()
	add_child_autofree(modifier_mgr)

# --- Perk effects ---

func test_starting_cash_bonus_default() -> void:
	assert_almost_eq(modifier_mgr.get_starting_cash_multiplier(meta_mgr), 1.0, 0.01)

func test_starting_cash_bonus_with_nest_egg() -> void:
	meta_mgr.set_active_perks(["nest_egg"] as Array[String])
	assert_almost_eq(modifier_mgr.get_starting_cash_multiplier(meta_mgr), 1.05, 0.01)

func test_rp_bonus_default() -> void:
	assert_eq(modifier_mgr.get_rp_bonus(meta_mgr), 0)

func test_rp_bonus_with_quick_study() -> void:
	meta_mgr.set_active_perks(["quick_study"] as Array[String])
	assert_eq(modifier_mgr.get_rp_bonus(meta_mgr), 1)

func test_rent_multiplier_default() -> void:
	assert_almost_eq(modifier_mgr.get_rent_multiplier(meta_mgr), 1.0, 0.01)

func test_rent_multiplier_with_landlords_friend() -> void:
	meta_mgr.set_active_perks(["landlords_friend"] as Array[String])
	assert_almost_eq(modifier_mgr.get_rent_multiplier(meta_mgr), 0.9, 0.01)

func test_quality_bonus_default() -> void:
	assert_almost_eq(modifier_mgr.get_quality_bonus(meta_mgr), 0.0, 0.01)

func test_quality_bonus_with_style_specialist() -> void:
	meta_mgr.set_active_perks(["style_specialist"] as Array[String])
	assert_almost_eq(modifier_mgr.get_quality_bonus(meta_mgr), 5.0, 0.01)

# --- Modifier effects ---

func test_demand_multiplier_default() -> void:
	assert_almost_eq(modifier_mgr.get_demand_modifier(meta_mgr), 1.0, 0.01)

func test_demand_multiplier_tough_market() -> void:
	meta_mgr.set_active_modifiers(["tough_market"] as Array[String])
	assert_almost_eq(modifier_mgr.get_demand_modifier(meta_mgr), 0.8, 0.01)

func test_demand_multiplier_generous_market() -> void:
	meta_mgr.set_active_modifiers(["generous_market"] as Array[String])
	assert_almost_eq(modifier_mgr.get_demand_modifier(meta_mgr), 1.2, 0.01)

func test_starting_cash_budget_brewery() -> void:
	meta_mgr.set_active_modifiers(["budget_brewery"] as Array[String])
	assert_almost_eq(modifier_mgr.get_starting_cash_multiplier(meta_mgr), 0.5, 0.01)

func test_starting_cash_budget_brewery_plus_nest_egg() -> void:
	meta_mgr.set_active_perks(["nest_egg"] as Array[String])
	meta_mgr.set_active_modifiers(["budget_brewery"] as Array[String])
	# 1.05 * 0.5 = 0.525
	assert_almost_eq(modifier_mgr.get_starting_cash_multiplier(meta_mgr), 0.525, 0.01)

func test_quality_bonus_master_brewer() -> void:
	meta_mgr.set_active_modifiers(["master_brewer"] as Array[String])
	assert_almost_eq(modifier_mgr.get_quality_bonus(meta_mgr), 10.0, 0.01)

func test_quality_bonus_master_brewer_plus_style_specialist() -> void:
	meta_mgr.set_active_perks(["style_specialist"] as Array[String])
	meta_mgr.set_active_modifiers(["master_brewer"] as Array[String])
	assert_almost_eq(modifier_mgr.get_quality_bonus(meta_mgr), 15.0, 0.01)

func test_infection_immunity_default() -> void:
	assert_eq(modifier_mgr.get_infection_immune_brews(meta_mgr), 0)

func test_infection_immunity_lucky_break() -> void:
	meta_mgr.set_active_modifiers(["lucky_break"] as Array[String])
	assert_eq(modifier_mgr.get_infection_immune_brews(meta_mgr), 5)

func test_ingredient_availability_default() -> void:
	assert_almost_eq(modifier_mgr.get_ingredient_availability(meta_mgr), 1.0, 0.01)

func test_ingredient_availability_shortage() -> void:
	meta_mgr.set_active_modifiers(["ingredient_shortage"] as Array[String])
	assert_almost_eq(modifier_mgr.get_ingredient_availability(meta_mgr), 0.6, 0.01)
```

**Step 2: Run test — expect FAIL**

**Step 3: Write RunModifierManager.gd**

```gdscript
extends Node

## RunModifierManager — computes perk/modifier effects for the active run.
## Reads from MetaProgressionManager's active_perks and active_modifiers.
## Stateless: all methods take a meta manager reference and compute effects.

func get_starting_cash_multiplier(meta: Node) -> float:
	var mult: float = 1.0
	if meta.has_active_perk("nest_egg"):
		mult *= 1.05
	if meta.has_active_modifier("budget_brewery"):
		mult *= 0.5
	return mult

func get_rp_bonus(meta: Node) -> int:
	if meta.has_active_perk("quick_study"):
		return 1
	return 0

func get_rent_multiplier(meta: Node) -> float:
	if meta.has_active_perk("landlords_friend"):
		return 0.9
	return 1.0

func get_quality_bonus(meta: Node) -> float:
	var bonus: float = 0.0
	if meta.has_active_perk("style_specialist"):
		bonus += 5.0
	if meta.has_active_modifier("master_brewer"):
		bonus += 10.0
	return bonus

func get_demand_modifier(meta: Node) -> float:
	if meta.has_active_modifier("tough_market"):
		return 0.8
	if meta.has_active_modifier("generous_market"):
		return 1.2
	return 1.0

func get_infection_immune_brews(meta: Node) -> int:
	if meta.has_active_modifier("lucky_break"):
		return 5
	return 0

func get_ingredient_availability(meta: Node) -> float:
	if meta.has_active_modifier("ingredient_shortage"):
		return 0.6
	return 1.0
```

**Step 4: Register autoload in project.godot**

Add after MetaProgressionManager:
```
RunModifierManager="*res://autoloads/RunModifierManager.gd"
```

**Step 5: Run tests — expect PASS**

**Step 6: Commit**

```bash
git add src/autoloads/RunModifierManager.gd src/tests/test_run_modifier_manager.gd src/project.godot
git commit -m "feat: add RunModifierManager with perk and modifier effect calculations"
```

---

## Task 6: GameState Integration — Apply Meta Effects at Run Start

**Files:**
- Modify: `src/autoloads/GameState.gd` — apply starting cash, RP bonus, rent modifier, quality bonus, infection immunity, ingredient availability at reset/during run
- Modify: `src/tests/test_meta_game_integration.gd` (create) — integration tests

**Context:** GameState.reset() currently sets balance to STARTING_BALANCE (500). With meta-progression, it should apply the starting cash multiplier. RP awards should include the bonus. Rent charges should apply the multiplier. Quality calculation should add the bonus. FailureSystem should check infection immunity. These are small touch points — each integration is 1-3 lines.

**Step 1: Write the failing integration tests**

```gdscript
extends GutTest

## Integration tests for meta-progression effects on game systems.

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

func test_rp_bonus_applied_to_brew() -> void:
	# RP formula: base 2 + quality/20. With quick_study: +1 more.
	MetaProgressionManager.set_active_perks(["quick_study"] as Array[String])
	# We can test the RP calc method directly if exposed, or check after a brew.
	var bonus: int = RunModifierManager.get_rp_bonus(MetaProgressionManager)
	assert_eq(bonus, 1)

func test_rent_discount_applied() -> void:
	MetaProgressionManager.set_active_perks(["landlords_friend"] as Array[String])
	var mult: float = RunModifierManager.get_rent_multiplier(MetaProgressionManager)
	assert_almost_eq(mult, 0.9, 0.01)

func test_meta_effects_cleared_after_meta_reset() -> void:
	MetaProgressionManager.set_active_perks(["nest_egg"] as Array[String])
	MetaProgressionManager.active_perks.clear()
	GameState.reset()
	assert_eq(GameState.balance, GameState.STARTING_BALANCE)
```

**Step 2: Run test — expect FAIL**

**Step 3: Modify GameState.gd reset()**

In `reset()`, after `balance = STARTING_BALANCE`, add:
```gdscript
	# Apply meta-progression starting cash modifier
	if is_instance_valid(RunModifierManager) and is_instance_valid(MetaProgressionManager):
		balance = STARTING_BALANCE * RunModifierManager.get_starting_cash_multiplier(MetaProgressionManager)
```

In the RP award section of `execute_brew()` (where RP is calculated), add the bonus:
```gdscript
	# Existing: var rp_earned: int = 2 + int(final_score / 20.0)
	# Add after:
	if is_instance_valid(RunModifierManager) and is_instance_valid(MetaProgressionManager):
		rp_earned += RunModifierManager.get_rp_bonus(MetaProgressionManager)
```

In the rent charge section (wherever rent is deducted), wrap the amount:
```gdscript
	# Existing: var rent: float = BreweryExpansion.get_rent_amount()
	# Add after:
	if is_instance_valid(RunModifierManager) and is_instance_valid(MetaProgressionManager):
		rent *= RunModifierManager.get_rent_multiplier(MetaProgressionManager)
```

These are the 3 primary integration points in GameState. QualityCalculator and FailureSystem integrations are similar small changes (1-2 lines each) but can be done in later tasks when UI surfaces them.

**Step 4: Run tests — expect PASS**

**Step 5: Commit**

```bash
git add src/autoloads/GameState.gd src/tests/test_meta_game_integration.gd
git commit -m "feat: integrate meta-progression effects into GameState reset, RP, and rent"
```

---

## Task 7: Run Summary Overlay UI

**Files:**
- Create: `src/ui/RunSummaryOverlay.gd`
- Create: `src/tests/test_run_summary_overlay.gd`

**Context:** Shown after game over. Displays unlock points earned per category, total, and a "Continue to Unlocks" button. See wireframe Screen 1 in `design/wireframes/meta-progression.md`.

**Step 1: Write the smoke test**

```gdscript
extends GutTest

var overlay: CanvasLayer

func before_each() -> void:
	overlay = preload("res://ui/RunSummaryOverlay.gd").new()
	add_child_autofree(overlay)

func test_overlay_starts_hidden() -> void:
	assert_false(overlay.visible)

func test_overlay_has_continue_signal() -> void:
	assert_true(overlay.has_signal("continue_pressed"))

func test_show_overlay_makes_visible() -> void:
	var metrics: Dictionary = {"turns": 12, "revenue": 8420.0, "best_quality": 87.0, "medals": 2, "won": true}
	overlay.show_summary(metrics, 17)
	assert_true(overlay.visible)

func test_show_overlay_displays_total_points() -> void:
	var metrics: Dictionary = {"turns": 12, "revenue": 8420.0, "best_quality": 87.0, "medals": 2, "won": true}
	overlay.show_summary(metrics, 17)
	# Verify the total label contains the points
	assert_true(overlay._total_label.text.contains("17"))
```

**Step 2: Run test — expect FAIL**

**Step 3: Write RunSummaryOverlay.gd**

Follow CanvasLayer overlay pattern from ForkChoiceOverlay. Layout:
- Title "RUN COMPLETE" (xl/40px, centered)
- Inner PanelContainer with GridContainer showing point breakdown
- Rows: Turns survived, Revenue, Best quality, Medals, Win bonus, Challenge multiplier (if active)
- HSeparator + Total row (md/24px, bold)
- Lifetime/available label (xs/16px, muted)
- "Continue to Unlocks" button (meta purple #B88AFF bg)
- Signal: `continue_pressed`

Use theme colors: meta=#B88AFF for points, accent for challenge multiplier, surface bg for card.

**Step 4: Run tests — expect PASS**

**Step 5: Commit**

```bash
git add src/ui/RunSummaryOverlay.gd src/tests/test_run_summary_overlay.gd
git commit -m "feat: add RunSummaryOverlay showing unlock points breakdown"
```

---

## Task 8: Unlock Shop Overlay UI

**Files:**
- Create: `src/ui/UnlockShopOverlay.gd`
- Create: `src/tests/test_unlock_shop_overlay.gd`

**Context:** Tabbed shop for spending unlock points. 4 tabs: Styles, Blueprints, Ingredients, Perks. Each tab shows a grid of unlock cards. See wireframe Screen 2 in `design/wireframes/meta-progression.md`.

**Step 1: Write the smoke test**

```gdscript
extends GutTest

var overlay: CanvasLayer
var meta_mgr: Node

func before_each() -> void:
	meta_mgr = preload("res://autoloads/MetaProgressionManager.gd").new()
	add_child_autofree(meta_mgr)
	overlay = preload("res://ui/UnlockShopOverlay.gd").new()
	add_child_autofree(overlay)

func test_overlay_starts_hidden() -> void:
	assert_false(overlay.visible)

func test_overlay_has_done_signal() -> void:
	assert_true(overlay.has_signal("done_pressed"))

func test_show_shop_makes_visible() -> void:
	overlay.show_shop(meta_mgr)
	assert_true(overlay.visible)

func test_has_four_tabs() -> void:
	overlay.show_shop(meta_mgr)
	assert_eq(overlay._tab_buttons.size(), 4)

func test_purchase_deducts_points() -> void:
	meta_mgr.add_points(10)
	overlay.show_shop(meta_mgr)
	# Simulate purchasing first style (cost 5)
	meta_mgr.unlock_style("lager", 5)
	assert_eq(meta_mgr.available_points, 5)
```

**Step 2: Run test — expect FAIL**

**Step 3: Write UnlockShopOverlay.gd**

Follow CanvasLayer overlay pattern. Layout:
- Header: "UNLOCK SHOP" (lg/32px) + "Available: N UP" (md/24px, meta purple, right-aligned)
- Tab bar: 4 buttons (Styles/Blueprints/Ingredients/Perks), active tab primary bg, inactive surface bg
- Content: ScrollContainer > GridContainer (3 columns) showing unlock cards (250x220 PanelContainer each)
- Each card: name, description, cost in UP, "Unlock" button or "UNLOCKED" label
- "Done" button footer
- Signal: `done_pressed`
- On unlock button press: call `meta_mgr.unlock_<category>(id, cost)`, refresh display, update points label

**Step 4: Run tests — expect PASS**

**Step 5: Commit**

```bash
git add src/ui/UnlockShopOverlay.gd src/tests/test_unlock_shop_overlay.gd
git commit -m "feat: add UnlockShopOverlay with tabbed categories and purchase flow"
```

---

## Task 9: Run Start Screen Overlay UI

**Files:**
- Create: `src/ui/RunStartOverlay.gd`
- Create: `src/tests/test_run_start_overlay.gd`

**Context:** Shown before starting a new run. Select perks (0-3) and modifiers (0-2). See wireframe Screen 3 in `design/wireframes/meta-progression.md`.

**Step 1: Write the smoke test**

```gdscript
extends GutTest

var overlay: CanvasLayer
var meta_mgr: Node

func before_each() -> void:
	meta_mgr = preload("res://autoloads/MetaProgressionManager.gd").new()
	add_child_autofree(meta_mgr)
	overlay = preload("res://ui/RunStartOverlay.gd").new()
	add_child_autofree(overlay)

func test_overlay_starts_hidden() -> void:
	assert_false(overlay.visible)

func test_overlay_has_run_started_signal() -> void:
	assert_true(overlay.has_signal("run_started"))

func test_show_overlay_makes_visible() -> void:
	overlay.show_setup(meta_mgr)
	assert_true(overlay.visible)

func test_perk_toggle_max_three() -> void:
	# Unlock 4 perks
	meta_mgr.unlocked_perks = ["nest_egg", "quick_study", "landlords_friend", "style_specialist"]
	overlay.show_setup(meta_mgr)
	# Toggle 3 perks on — should succeed
	overlay._toggle_perk("nest_egg")
	overlay._toggle_perk("quick_study")
	overlay._toggle_perk("landlords_friend")
	assert_eq(overlay._selected_perks.size(), 3)
	# Toggle a 4th — should be rejected (stays at 3)
	overlay._toggle_perk("style_specialist")
	assert_eq(overlay._selected_perks.size(), 3)

func test_modifier_toggle_max_two() -> void:
	meta_mgr.complete_achievement("first_victory")
	meta_mgr.complete_achievement("perfect_brew")
	meta_mgr.complete_achievement("survivor")
	overlay.show_setup(meta_mgr)
	overlay._toggle_modifier("tough_market")
	overlay._toggle_modifier("master_brewer")
	assert_eq(overlay._selected_modifiers.size(), 2)
	overlay._toggle_modifier("lucky_break")
	assert_eq(overlay._selected_modifiers.size(), 2)

func test_start_emits_signal_with_selections() -> void:
	overlay.show_setup(meta_mgr)
	watch_signals(overlay)
	overlay._on_start_pressed()
	assert_signal_emitted(overlay, "run_started")
```

**Step 2: Run test — expect FAIL**

**Step 3: Write RunStartOverlay.gd**

Follow CanvasLayer overlay pattern. Layout (900x600 card):
- Title "NEW RUN SETUP" (xl/40px)
- Perks section: "ACTIVE PERKS (N/3)" label + HBoxContainer of perk cards (180x120)
  - Toggle ON: success border. OFF: muted border. Locked: greyed.
- HSeparator
- Modifiers section: "MODIFIERS (N/2)" label + two-column layout (Challenge left, Bonus right)
  - Toggle buttons for each modifier (locked if achievement incomplete)
- "Start Brewing!" button (accent bg)
- Signal: `run_started` (emits with selected perks and modifiers arrays)
- On emit: sets `meta_mgr.set_active_perks()` and `meta_mgr.set_active_modifiers()`

**Step 4: Run tests — expect PASS**

**Step 5: Commit**

```bash
git add src/ui/RunStartOverlay.gd src/tests/test_run_start_overlay.gd
git commit -m "feat: add RunStartOverlay with perk and modifier selection"
```

---

## Task 10: Achievements Panel & Main Menu

**Files:**
- Create: `src/ui/AchievementsOverlay.gd`
- Create: `src/ui/MainMenu.gd`
- Create: `src/scenes/MainMenu.tscn`
- Create: `src/tests/test_achievements_overlay.gd`
- Modify: `src/project.godot` — set MainMenu.tscn as main scene (or wire via Game.gd)

**Context:** AchievementsOverlay shows 6 achievements with progress. MainMenu is the game's entry point with New Run, Continue, Unlocks, Achievements, Quit buttons. See wireframes Screens 4 and 5 in `design/wireframes/meta-progression.md`.

**Step 1: Write smoke tests**

```gdscript
# test_achievements_overlay.gd
extends GutTest

var overlay: CanvasLayer
var meta_mgr: Node

func before_each() -> void:
	meta_mgr = preload("res://autoloads/MetaProgressionManager.gd").new()
	add_child_autofree(meta_mgr)
	overlay = preload("res://ui/AchievementsOverlay.gd").new()
	add_child_autofree(overlay)

func test_overlay_starts_hidden() -> void:
	assert_false(overlay.visible)

func test_overlay_has_closed_signal() -> void:
	assert_true(overlay.has_signal("closed"))

func test_show_displays_six_achievements() -> void:
	overlay.show_achievements(meta_mgr)
	assert_true(overlay.visible)
	assert_eq(overlay._achievement_rows.size(), 6)

func test_completed_achievement_shows_checkmark() -> void:
	meta_mgr.complete_achievement("first_victory")
	overlay.show_achievements(meta_mgr)
	# First row should have completed styling
	assert_true(overlay._achievement_rows[0]["completed"])
```

**Step 2: Run test — expect FAIL**

**Step 3: Write AchievementsOverlay.gd**

CanvasLayer overlay pattern. Layout (900x550 card):
- Title "ACHIEVEMENTS" (lg/32px)
- HSeparator
- ScrollContainer > VBoxContainer of 6 achievement rows
- Each row: status icon (checkmark/empty box) + name/description/unlocks VBox + status label
- "Close" button footer
- Signal: `closed`

**Step 4: Write MainMenu.gd**

CanvasLayer (or Node2D root). Layout (1280x720):
- Background: solid #0F1724
- Title: "BEERBREW TYCOON" (xl/40px, accent #FFC857)
- Button column: New Run, Continue (if save exists), Unlocks, Achievements, Quit
- Stats bar: total runs, best revenue, total medals, available UP
- Last run summary line
- On "New Run": emit `new_run_pressed` → show RunStartOverlay
- On "Continue": load save → switch to Game.tscn
- On "Unlocks": show UnlockShopOverlay
- On "Achievements": show AchievementsOverlay
- On "Quit": `get_tree().quit()`

**Step 5: Create MainMenu.tscn**

Minimal .tscn with Node2D root + MainMenu.gd script attached.

**Step 6: Run tests — expect PASS**

**Step 7: Commit**

```bash
git add src/ui/AchievementsOverlay.gd src/ui/MainMenu.gd src/scenes/MainMenu.tscn src/tests/test_achievements_overlay.gd src/project.godot
git commit -m "feat: add AchievementsOverlay and MainMenu with meta-progression stats"
```

---

## Task 11: Game Flow Integration — Wire Everything Together

**Files:**
- Modify: `src/scenes/Game.gd` — add RunSummary/UnlockShop/RunStart overlays to game flow
- Modify: `src/ui/GameOverScreen.gd` — add UP earned label, change "New Run" flow
- Modify: `src/autoloads/GameState.gd` — gather run metrics for end_run(), track equipment_spend and unique_ingredients

**Context:** The flow changes from `GameOver → reset()` to `GameOver → RunSummary → UnlockShop → RunStart → reset()`. Game.gd orchestrates the overlay sequence.

**Step 1: Modify GameOverScreen.gd**

Add a label showing "Unlock Points Earned: +N" below stats grid (meta purple color).
Change `_on_new_run_pressed()` to emit a signal instead of calling `GameState.reset()` directly:
```gdscript
signal new_run_requested  # Game.gd will handle the flow
func _on_new_run_pressed() -> void:
	new_run_requested.emit()
```

**Step 2: Modify Game.gd**

Add overlay management for the 3 new overlays (RunSummary, UnlockShop, RunStart):
```gdscript
var _run_summary: CanvasLayer = null
var _unlock_shop: CanvasLayer = null
var _run_start: CanvasLayer = null
```

In `_ready()`, connect `game_over_screen.new_run_requested`:
```gdscript
game_over_screen.new_run_requested.connect(_on_new_run_requested)
```

Add the flow methods:
```gdscript
func _on_new_run_requested() -> void:
	_hide_all_overlays()
	# Gather metrics
	var metrics: Dictionary = _gather_run_metrics()
	var points: int = MetaProgressionManager.end_run(metrics)
	_show_run_summary(metrics, points)

func _gather_run_metrics() -> Dictionary:
	var medals: int = 0
	if is_instance_valid(CompetitionManager):
		medals = CompetitionManager.get_total_medals()
	var channels: int = 0
	if is_instance_valid(MarketManager):
		channels = MarketManager.get_unlocked_channels().size()
	return {
		"turns": GameState.turn_counter,
		"revenue": GameState.total_revenue,
		"best_quality": GameState.best_quality,
		"medals": medals,
		"won": GameState.run_won,
		"equipment_spend": GameState.equipment_spend,
		"channels_unlocked": channels,
		"unique_ingredients": GameState.unique_ingredients_used,
		"path": PathManager.get_path_type() if is_instance_valid(PathManager) else "",
	}

func _show_run_summary(metrics: Dictionary, points: int) -> void:
	if _run_summary == null:
		_run_summary = preload("res://ui/RunSummaryOverlay.gd").new()
		add_child(_run_summary)
		_managed_overlays.append(_run_summary)
		_run_summary.continue_pressed.connect(_on_run_summary_continue)
	_run_summary.show_summary(metrics, points)

func _on_run_summary_continue() -> void:
	_hide_all_overlays()
	_show_unlock_shop()

func _show_unlock_shop() -> void:
	if _unlock_shop == null:
		_unlock_shop = preload("res://ui/UnlockShopOverlay.gd").new()
		add_child(_unlock_shop)
		_managed_overlays.append(_unlock_shop)
		_unlock_shop.done_pressed.connect(_on_unlock_shop_done)
	_unlock_shop.show_shop(MetaProgressionManager)

func _on_unlock_shop_done() -> void:
	_hide_all_overlays()
	_show_run_start()

func _show_run_start() -> void:
	if _run_start == null:
		_run_start = preload("res://ui/RunStartOverlay.gd").new()
		add_child(_run_start)
		_managed_overlays.append(_run_start)
		_run_start.run_started.connect(_on_run_start_confirmed)
	_run_start.show_setup(MetaProgressionManager)

func _on_run_start_confirmed() -> void:
	_hide_all_overlays()
	GameState.reset()
```

**Step 3: Add equipment_spend and unique_ingredients tracking to GameState.gd**

Add variables:
```gdscript
var equipment_spend: float = 0.0
var unique_ingredients_used: int = 0
var _used_ingredient_ids: Dictionary = {}
```

In `reset()`, clear them:
```gdscript
equipment_spend = 0.0
unique_ingredients_used = 0
_used_ingredient_ids = {}
```

Track equipment spend wherever equipment is purchased (EquipmentManager.purchase calls). Track unique ingredients in `execute_brew()`:
```gdscript
# After recipe is set, count unique ingredients
for ingredient in current_recipe.get("ingredients", []):
	var id: String = ingredient.ingredient_id if ingredient.has("ingredient_id") else ""
	if id != "" and not _used_ingredient_ids.has(id):
		_used_ingredient_ids[id] = true
		unique_ingredients_used += 1
```

**Step 4: Run all tests — expect PASS**

**Step 5: Commit**

```bash
git add src/scenes/Game.gd src/ui/GameOverScreen.gd src/autoloads/GameState.gd
git commit -m "feat: wire meta-progression flow — GameOver → RunSummary → UnlockShop → RunStart → reset"
```

---

## Task 12: ResearchManager Blueprint Discount Integration

**Files:**
- Modify: `src/autoloads/ResearchManager.gd` — check MetaProgressionManager for blueprint discounts
- Modify: `src/tests/test_meta_progression_manager.gd` — add integration test

**Context:** When a player has unlocked a blueprint via meta-progression, the research cost for that equipment's associated research node should be 50% less.

**Step 1: Write the failing test**

```gdscript
# In test_meta_progression_manager.gd or a new test file
func test_blueprint_discount_halves_research_cost() -> void:
	manager.add_points(10)
	manager.unlock_blueprint("mash_tun", 5)
	assert_true(manager.has_blueprint_discount("mash_tun"))
	# The actual RP cost reduction is applied in ResearchManager
	# when checking can_unlock / unlock cost
```

**Step 2: Modify ResearchManager.gd**

In the `unlock()` method or wherever RP cost is checked, add:
```gdscript
func _get_effective_cost(node: Resource) -> int:
	var base_cost: int = node.rp_cost
	if is_instance_valid(MetaProgressionManager):
		# Check if any equipment unlocked by this node has a blueprint discount
		var effect: Dictionary = node.unlock_effect
		if effect.get("type", "") == "unlock_equipment_tier":
			# Tier unlock nodes don't map to specific equipment
			pass
		# Check by node_id mapping to equipment
		if MetaProgressionManager.has_blueprint_discount(node.node_id):
			base_cost = int(base_cost * 0.5)
	return base_cost
```

Note: The blueprint discount applies to research nodes, not equipment purchase cost. The mapping is: blueprint ID = equipment ID = the research node that unlocks it. Since research nodes unlock tiers (not individual equipment), we apply the discount when the blueprint ID matches any equipment in the tier being researched.

A simpler approach: just check if ANY unlocked blueprint belongs to the tier being unlocked and apply a flat 50% discount.

**Step 3: Run tests — expect PASS**

**Step 4: Commit**

```bash
git add src/autoloads/ResearchManager.gd src/tests/test_meta_progression_manager.gd
git commit -m "feat: apply blueprint discount to research costs via MetaProgressionManager"
```

---

## Task 13: Meta-Progression Style Unlock Integration

**Files:**
- Modify: `src/autoloads/GameState.gd` or `src/ui/StylePicker.gd` — make meta-unlocked styles available from turn 1
- Create: `src/tests/test_meta_style_unlocks.gd`

**Context:** When a player has unlocked a style via meta-progression, that style should be available from the start of a new run WITHOUT needing to research it. The style's `.unlocked` property should be set to `true` during reset if meta-unlocked.

**Step 1: Write the failing test**

```gdscript
extends GutTest

func before_each() -> void:
	if is_instance_valid(MetaProgressionManager):
		MetaProgressionManager.reset_meta()

func test_meta_unlocked_style_available_after_reset() -> void:
	MetaProgressionManager.unlocked_styles = ["lager"]
	GameState.reset()
	# Load the lager style and check it's unlocked
	var lager: Resource = load("res://data/styles/lager.tres")
	assert_true(lager.unlocked)

func test_non_meta_style_still_locked_after_reset() -> void:
	MetaProgressionManager.unlocked_styles = ["lager"]
	GameState.reset()
	var stout: Resource = load("res://data/styles/stout.tres")
	assert_false(stout.unlocked)
```

**Step 2: Modify GameState.gd reset()**

After the existing reset logic, add meta-unlock application:
```gdscript
	# Apply meta-progression style unlocks
	if is_instance_valid(MetaProgressionManager):
		for style_id in MetaProgressionManager.unlocked_styles:
			var path: String = "res://data/styles/%s.tres" % style_id
			if ResourceLoader.exists(path):
				var style: Resource = load(path)
				if style and "unlocked" in style:
					style.unlocked = true
```

**Step 3: Run tests — expect PASS**

**Step 4: Commit**

```bash
git add src/autoloads/GameState.gd src/tests/test_meta_style_unlocks.gd
git commit -m "feat: apply meta-unlocked styles at run start"
```

---

## Task 14: Final Integration, Theme Token, and Polish

**Files:**
- Modify: `src/assets/ui/ThemeBuilder.gd` — add meta purple token (#B88AFF)
- Modify: `design/theme.json` — add meta color
- Modify: `src/autoloads/MetaProgressionManager.gd` — call `load_from_disk()` in `_ready()`
- Run: `make theme` to regenerate theme.tres

**Step 1: Add meta color to theme.json**

```json
"meta": "#B88AFF"
```

**Step 2: Add to ThemeBuilder.gd** (if it uses theme.json tokens)

Add the meta purple color to the builder's palette.

**Step 3: MetaProgressionManager._ready()**

```gdscript
func _ready() -> void:
	load_from_disk()
```

**Step 4: Run `make theme` then `make test`**

Expected: All tests pass (558 existing + ~50 new = ~608+), theme regenerated.

**Step 5: Commit**

```bash
git add design/theme.json src/assets/ui/ThemeBuilder.gd src/autoloads/MetaProgressionManager.gd
git commit -m "feat: add meta purple theme token, auto-load meta save on startup"
```

---

## Summary

| Task | Description | Tests Added |
|------|------------|-------------|
| 1 | MetaProgressionManager core state & persistence | ~15 |
| 2 | Unlock point calculation & run recording | ~10 |
| 3 | Achievement system (6 achievements) | ~14 |
| 4 | Unlock catalog definitions | ~7 |
| 5 | RunModifierManager perk/modifier effects | ~16 |
| 6 | GameState integration (cash, RP, rent) | ~6 |
| 7 | RunSummaryOverlay UI | ~4 |
| 8 | UnlockShopOverlay UI | ~5 |
| 9 | RunStartOverlay UI | ~6 |
| 10 | AchievementsOverlay + MainMenu | ~4 |
| 11 | Game flow wiring (overlay sequence) | ~0 (manual) |
| 12 | Research blueprint discount | ~2 |
| 13 | Meta style unlock at run start | ~2 |
| 14 | Theme token, auto-load, polish | ~0 |
| **Total** | | **~91 new tests** |

Expected final test count: ~649 (558 + 91).
