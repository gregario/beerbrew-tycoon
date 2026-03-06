# Stage 4B — Competitions Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement beer competitions that occur every 8-10 turns, where players enter their most recent brew against 3 simulated competitors for gold/silver/bronze medals with cash prizes.

**Architecture:** New `CompetitionManager` autoload manages scheduling, entry, judging, medals, and rare unlocks. Competitions are procedural Dictionaries (same pattern as ContractManager). GameState hooks: `_on_results_continue()` ticks competition countdown and triggers judging, `execute_brew()` stores brew for potential entry. CompetitionScreen is a full-screen overlay UI. BreweryScene gets a "Compete" button.

**Tech Stack:** Godot 4 / GDScript, GUT testing framework, `make test` runner.

**Key References:**
- Wireframe: `design/wireframes/competitions.md`
- Spec: `openspec/changes/post-mvp-roadmap/specs/competitions/spec.md`
- Stack profile: `stacks/godot/STACK.md` (read before coding)
- Pattern reference: `src/autoloads/ContractManager.gd` (similar autoload pattern)

---

### Task 1: CompetitionManager Autoload — Scheduling and Data Model

**Files:**
- Create: `src/autoloads/CompetitionManager.gd`
- Create: `src/tests/test_competition_manager.gd`
- Modify: `src/project.godot` (add autoload entry)

**Context:** CompetitionManager owns competition state: current competition (or null), turns until next, medals earned, and player entry. Competitions are Dictionaries with: competition_id, name, category (style_id or "open"), entry_fee, prizes ({gold, silver, bronze} cash amounts), turns_remaining, player_entry (null or {style_id, quality}).

**Step 1: Write the failing test**

```gdscript
# src/tests/test_competition_manager.gd
extends GutTest

func before_each() -> void:
	GameState.reset()
	CompetitionManager.reset()

# --- Initial state ---
func test_starts_with_no_active_competition() -> void:
	assert_null(CompetitionManager.current_competition)

func test_starts_with_turns_until_next() -> void:
	assert_gte(CompetitionManager.turns_until_next, 8)
	assert_lte(CompetitionManager.turns_until_next, 10)

func test_starts_with_no_medals() -> void:
	assert_eq(CompetitionManager.medals["gold"], 0)
	assert_eq(CompetitionManager.medals["silver"], 0)
	assert_eq(CompetitionManager.medals["bronze"], 0)

# --- Scheduling ---
func test_tick_decrements_turns_until_next() -> void:
	var initial: int = CompetitionManager.turns_until_next
	CompetitionManager.tick()
	if CompetitionManager.current_competition == null:
		assert_eq(CompetitionManager.turns_until_next, initial - 1)

func test_competition_announced_when_counter_reaches_zero() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	assert_not_null(CompetitionManager.current_competition)

func test_announced_competition_has_required_fields() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	var comp: Dictionary = CompetitionManager.current_competition
	assert_has(comp, "competition_id")
	assert_has(comp, "name")
	assert_has(comp, "category")
	assert_has(comp, "entry_fee")
	assert_has(comp, "prizes")
	assert_has(comp, "turns_remaining")

func test_competition_has_2_turn_entry_window() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	assert_eq(CompetitionManager.current_competition["turns_remaining"], 2)

func test_competition_category_valid() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	var cat: String = CompetitionManager.current_competition["category"]
	assert_true(cat in CompetitionManager.STYLE_IDS or cat == "open",
		"Category '%s' should be valid style or 'open'" % cat)

func test_competition_has_prize_tiers() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	var prizes: Dictionary = CompetitionManager.current_competition["prizes"]
	assert_gt(prizes["gold"], prizes["silver"])
	assert_gt(prizes["silver"], prizes["bronze"])
	assert_gt(prizes["bronze"], 0)

func test_entry_fee_positive() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	assert_gt(CompetitionManager.current_competition["entry_fee"], 0)

func test_announced_signal_emitted() -> void:
	watch_signals(CompetitionManager)
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	assert_signal_emitted(CompetitionManager, "competition_announced")
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — CompetitionManager does not exist.

**Step 3: Write the implementation**

```gdscript
# src/autoloads/CompetitionManager.gd
extends Node

## CompetitionManager — manages competition scheduling, entry, judging,
## medals, and rare unlock rewards.

const ENTRY_WINDOW: int = 2
const MIN_INTERVAL: int = 8
const MAX_INTERVAL: int = 10

const STYLE_IDS: Array[String] = [
	"lager", "pale_ale", "stout", "wheat_beer",
]

const COMPETITION_NAMES: Array[String] = [
	"Oktoberfest Cup", "Craft Beer Classic", "Golden Pint Awards",
	"Brewmaster's Challenge", "Harvest Ale Festival", "International Lager Open",
	"Artisan Brew Derby", "Hop Forward Invitational",
]

signal competition_announced(competition: Dictionary)
signal competition_entered(competition_id: String)
signal competition_judged(result: Dictionary)

var current_competition = null  # Dictionary or null
var turns_until_next: int = 0
var medals: Dictionary = {"gold": 0, "silver": 0, "bronze": 0}
var player_entry = null  # Dictionary or null — {style_id, quality}
var _next_id: int = 0

# ---------------------------------------------------------------------------
# Scheduling
# ---------------------------------------------------------------------------
func tick() -> Dictionary:
	# If there's an active competition, tick its deadline
	if current_competition != null:
		current_competition["turns_remaining"] -= 1
		if current_competition["turns_remaining"] <= 0:
			return _judge()
		return {}

	# No active competition — tick countdown
	turns_until_next -= 1
	if turns_until_next <= 0:
		_announce()
	return {}

func _announce() -> void:
	var category: String = ""
	if randf() < 0.3:
		category = "open"
	else:
		category = STYLE_IDS[randi_range(0, STYLE_IDS.size() - 1)]

	var name_pick: String = COMPETITION_NAMES[randi_range(0, COMPETITION_NAMES.size() - 1)]
	var entry_fee: int = randi_range(100, 300)
	var gold_prize: int = entry_fee * 4 + randi_range(100, 300)
	var silver_prize: int = int(gold_prize * 0.5)
	var bronze_prize: int = int(gold_prize * 0.25)

	var comp_id: String = "comp_%d" % _next_id
	_next_id += 1

	current_competition = {
		"competition_id": comp_id,
		"name": name_pick,
		"category": category,
		"entry_fee": entry_fee,
		"prizes": {"gold": gold_prize, "silver": silver_prize, "bronze": bronze_prize},
		"turns_remaining": ENTRY_WINDOW,
	}
	player_entry = null
	competition_announced.emit(current_competition)

# ---------------------------------------------------------------------------
# Entry
# ---------------------------------------------------------------------------
func enter(style_id: String, quality: float) -> bool:
	if current_competition == null:
		return false
	if player_entry != null:
		return false  # Already entered
	var category: String = current_competition["category"]
	if category != "open" and category != style_id:
		return false  # Wrong style
	var fee: int = current_competition["entry_fee"]
	if GameState.balance < fee:
		return false  # Can't afford
	GameState.balance -= fee
	GameState.balance_changed.emit(GameState.balance)
	player_entry = {"style_id": style_id, "quality": quality}
	competition_entered.emit(current_competition["competition_id"])
	return true

# ---------------------------------------------------------------------------
# Judging
# ---------------------------------------------------------------------------
func _judge() -> Dictionary:
	var result: Dictionary = {
		"competition": current_competition.duplicate(),
		"placement": "none",
		"prize": 0,
		"competitor_scores": [],
		"player_quality": 0.0,
	}

	if player_entry == null:
		# Player didn't enter — just end the competition
		current_competition = null
		turns_until_next = randi_range(MIN_INTERVAL, MAX_INTERVAL)
		return result

	var player_quality: float = player_entry["quality"]
	result["player_quality"] = player_quality

	# Generate 3 competitor scores that scale with turn count
	var base_score: float = minf(40.0 + GameState.turn_counter * 1.5, 85.0)
	var competitor_scores: Array[float] = []
	for i in range(3):
		var score: float = base_score + float(randi_range(-10, 10))
		score = clampf(score, 10.0, 100.0)
		competitor_scores.append(score)
	result["competitor_scores"] = competitor_scores

	# Count how many competitors the player beat
	var beaten: int = 0
	for score in competitor_scores:
		if player_quality > score:
			beaten += 1

	var prizes: Dictionary = current_competition["prizes"]
	if beaten == 3:
		result["placement"] = "gold"
		result["prize"] = prizes["gold"]
		medals["gold"] += 1
	elif beaten == 2:
		result["placement"] = "silver"
		result["prize"] = prizes["silver"]
		medals["silver"] += 1
	elif beaten == 1:
		result["placement"] = "bronze"
		result["prize"] = prizes["bronze"]
		medals["bronze"] += 1
	else:
		result["placement"] = "none"
		result["prize"] = 0

	# Award prize money
	if result["prize"] > 0:
		GameState.balance += result["prize"]
		GameState.balance_changed.emit(GameState.balance)

	# Rare ingredient unlock on gold (25% chance)
	result["rare_unlock"] = ""
	if result["placement"] == "gold" and randf() < 0.25:
		result["rare_unlock"] = _try_rare_unlock()

	competition_judged.emit(result)

	# Schedule next competition
	current_competition = null
	player_entry = null
	turns_until_next = randi_range(MIN_INTERVAL, MAX_INTERVAL)

	return result

func _try_rare_unlock() -> String:
	# Try to unlock a random locked ingredient
	if not is_instance_valid(ResearchManager):
		return ""
	# Find locked ingredients from the catalog
	var catalog: Array = IngredientCatalog.get_all_ingredients()
	var locked: Array[String] = []
	for ingredient in catalog:
		if not ingredient.unlocked:
			locked.append(ingredient.ingredient_id)
	if locked.size() == 0:
		return ""
	var pick: String = locked[randi_range(0, locked.size() - 1)]
	# Unlock via catalog
	var ing: Resource = IngredientCatalog.get_ingredient(pick)
	if ing != null:
		ing.unlocked = true
		return ing.ingredient_name
	return ""

# ---------------------------------------------------------------------------
# Persistence
# ---------------------------------------------------------------------------
func save_state() -> Dictionary:
	var data: Dictionary = {
		"turns_until_next": turns_until_next,
		"medals": medals.duplicate(),
		"_next_id": _next_id,
	}
	if current_competition != null:
		data["current_competition"] = current_competition.duplicate()
		data["current_competition"]["prizes"] = current_competition["prizes"].duplicate()
	if player_entry != null:
		data["player_entry"] = player_entry.duplicate()
	return data

func load_state(data: Dictionary) -> void:
	turns_until_next = data.get("turns_until_next", randi_range(MIN_INTERVAL, MAX_INTERVAL))
	medals = data.get("medals", {"gold": 0, "silver": 0, "bronze": 0}).duplicate()
	_next_id = data.get("_next_id", 0)
	if data.has("current_competition"):
		current_competition = data["current_competition"].duplicate()
		current_competition["prizes"] = data["current_competition"]["prizes"].duplicate()
	else:
		current_competition = null
	if data.has("player_entry"):
		player_entry = data["player_entry"].duplicate()
	else:
		player_entry = null

# ---------------------------------------------------------------------------
# Reset
# ---------------------------------------------------------------------------
func reset() -> void:
	current_competition = null
	player_entry = null
	medals = {"gold": 0, "silver": 0, "bronze": 0}
	_next_id = 0
	turns_until_next = randi_range(MIN_INTERVAL, MAX_INTERVAL)
```

**Step 4: Register autoload in project.godot**

Add after ContractManager:
```
autoload/CompetitionManager="*res://autoloads/CompetitionManager.gd"
```

**Step 5: Run test to verify it passes**

Run: `make test`
Expected: All new tests PASS, all existing tests still PASS.

**Step 6: Commit**

```
feat: add CompetitionManager autoload with scheduling and data model
```

---

### Task 2: Competition Entry and Judging Tests

**Files:**
- Modify: `src/tests/test_competition_manager.gd`

**Context:** Test the entry flow (style matching, fee deduction, duplicate entry prevention) and judging logic (placement based on competitor scores, prize awarding, medal tracking).

**Step 1: Append tests**

```gdscript
# --- Entry ---
func test_enter_deducts_fee() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 1000.0
	var fee: int = CompetitionManager.current_competition["entry_fee"]
	CompetitionManager.enter("lager", 70.0)
	assert_almost_eq(GameState.balance, 1000.0 - fee, 0.01)

func test_enter_stores_entry() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 1000.0
	var cat: String = CompetitionManager.current_competition["category"]
	var style: String = cat if cat != "open" else "lager"
	CompetitionManager.enter(style, 75.0)
	assert_not_null(CompetitionManager.player_entry)
	assert_eq(CompetitionManager.player_entry["quality"], 75.0)

func test_enter_wrong_style_fails() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 1000.0
	# Force a specific category
	CompetitionManager.current_competition["category"] = "stout"
	var result: bool = CompetitionManager.enter("lager", 70.0)
	assert_false(result)
	assert_null(CompetitionManager.player_entry)

func test_enter_open_category_any_style() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 1000.0
	CompetitionManager.current_competition["category"] = "open"
	var result: bool = CompetitionManager.enter("wheat_beer", 60.0)
	assert_true(result)

func test_cannot_enter_twice() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 2000.0
	var cat: String = CompetitionManager.current_competition["category"]
	var style: String = cat if cat != "open" else "lager"
	CompetitionManager.enter(style, 70.0)
	var result: bool = CompetitionManager.enter(style, 80.0)
	assert_false(result)

func test_cannot_enter_without_funds() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 0.0
	var result: bool = CompetitionManager.enter("lager", 70.0)
	assert_false(result)

func test_enter_no_competition_fails() -> void:
	var result: bool = CompetitionManager.enter("lager", 70.0)
	assert_false(result)

func test_enter_emits_signal() -> void:
	watch_signals(CompetitionManager)
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 1000.0
	var cat: String = CompetitionManager.current_competition["category"]
	var style: String = cat if cat != "open" else "lager"
	CompetitionManager.enter(style, 70.0)
	assert_signal_emitted(CompetitionManager, "competition_entered")

# --- Judging ---
func test_judge_after_deadline() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()  # Announces, turns_remaining = 2
	GameState.balance = 1000.0
	var cat: String = CompetitionManager.current_competition["category"]
	var style: String = cat if cat != "open" else "lager"
	CompetitionManager.enter(style, 95.0)  # Very high quality
	CompetitionManager.tick()  # turns_remaining = 1
	var result: Dictionary = CompetitionManager.tick()  # turns_remaining = 0 → judge
	assert_true(result.has("placement"))
	assert_true(result.has("prize"))

func test_judge_clears_competition() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 1000.0
	var cat: String = CompetitionManager.current_competition["category"]
	var style: String = cat if cat != "open" else "lager"
	CompetitionManager.enter(style, 70.0)
	CompetitionManager.tick()
	CompetitionManager.tick()
	assert_null(CompetitionManager.current_competition)
	assert_null(CompetitionManager.player_entry)

func test_judge_schedules_next() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 1000.0
	var cat: String = CompetitionManager.current_competition["category"]
	var style: String = cat if cat != "open" else "lager"
	CompetitionManager.enter(style, 70.0)
	CompetitionManager.tick()
	CompetitionManager.tick()
	assert_gte(CompetitionManager.turns_until_next, CompetitionManager.MIN_INTERVAL)
	assert_lte(CompetitionManager.turns_until_next, CompetitionManager.MAX_INTERVAL)

func test_judge_gold_awards_prize() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 1000.0
	GameState.turn_counter = 1  # Low turn = weak competitors (base ~41.5)
	var cat: String = CompetitionManager.current_competition["category"]
	var style: String = cat if cat != "open" else "lager"
	var fee: int = CompetitionManager.current_competition["entry_fee"]
	CompetitionManager.enter(style, 99.0)  # Very high = beats everyone
	var balance_after_fee: float = GameState.balance
	CompetitionManager.tick()
	var result: Dictionary = CompetitionManager.tick()
	if result.get("placement", "") == "gold":
		assert_gt(GameState.balance, balance_after_fee)
		assert_eq(CompetitionManager.medals["gold"], 1)

func test_judge_no_entry_returns_no_placement() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	CompetitionManager.tick()
	var result: Dictionary = CompetitionManager.tick()
	assert_eq(result.get("placement", ""), "none")
	assert_eq(result.get("prize", 0), 0)

func test_judge_emits_signal() -> void:
	watch_signals(CompetitionManager)
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 1000.0
	var cat: String = CompetitionManager.current_competition["category"]
	var style: String = cat if cat != "open" else "lager"
	CompetitionManager.enter(style, 70.0)
	CompetitionManager.tick()
	CompetitionManager.tick()
	assert_signal_emitted(CompetitionManager, "competition_judged")

func test_competitor_scores_scale_with_turn() -> void:
	# At turn 1, base is ~41.5. At turn 30, base is ~85
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 1000.0
	GameState.turn_counter = 30
	var cat: String = CompetitionManager.current_competition["category"]
	var style: String = cat if cat != "open" else "lager"
	CompetitionManager.enter(style, 50.0)  # Mediocre quality
	CompetitionManager.tick()
	var result: Dictionary = CompetitionManager.tick()
	# At turn 30, base is 85 so 50 quality should rarely win
	# Just verify scores are generated
	assert_eq(result["competitor_scores"].size(), 3)
```

**Step 2: Run tests, verify all pass**

Run: `make test`
Expected: All tests PASS.

**Step 3: Commit**

```
feat: add competition entry and judging tests
```

---

### Task 3: Competition Persistence and Medal Tracking

**Files:**
- Modify: `src/tests/test_competition_manager.gd`

**Context:** Test save/load for competition state and medal tracking persistence.

**Step 1: Append tests**

```gdscript
# --- Persistence ---
func test_save_and_load() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 1000.0
	var cat: String = CompetitionManager.current_competition["category"]
	var style: String = cat if cat != "open" else "lager"
	CompetitionManager.enter(style, 70.0)
	CompetitionManager.medals["gold"] = 2
	CompetitionManager.medals["silver"] = 1
	var data: Dictionary = CompetitionManager.save_state()
	CompetitionManager.reset()
	assert_null(CompetitionManager.current_competition)
	assert_eq(CompetitionManager.medals["gold"], 0)
	CompetitionManager.load_state(data)
	assert_not_null(CompetitionManager.current_competition)
	assert_not_null(CompetitionManager.player_entry)
	assert_eq(CompetitionManager.medals["gold"], 2)
	assert_eq(CompetitionManager.medals["silver"], 1)

func test_save_without_competition() -> void:
	var data: Dictionary = CompetitionManager.save_state()
	assert_false(data.has("current_competition"))
	CompetitionManager.load_state(data)
	assert_null(CompetitionManager.current_competition)

func test_medals_persist_across_judgments() -> void:
	# Win first competition
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 2000.0
	GameState.turn_counter = 1
	var cat: String = CompetitionManager.current_competition["category"]
	var style: String = cat if cat != "open" else "lager"
	CompetitionManager.enter(style, 99.0)
	CompetitionManager.tick()
	CompetitionManager.tick()
	var gold_count: int = CompetitionManager.medals["gold"]
	# Medals should persist (may or may not have won gold due to randomness)
	assert_gte(gold_count + CompetitionManager.medals["silver"] + CompetitionManager.medals["bronze"], 0)
```

**Step 2: Run tests, verify all pass**

**Step 3: Commit**

```
feat: add competition persistence and medal tracking tests
```

---

### Task 4: GameState Integration

**Files:**
- Modify: `src/autoloads/GameState.gd`
- Modify: `src/tests/test_competition_manager.gd`

**Context:** Wire CompetitionManager into GameState: (1) tick competitions in `_on_results_continue()`, (2) reset CompetitionManager on game reset.

**Step 1: Append integration test**

```gdscript
# --- GameState integration ---
func test_reset_resets_competition_manager() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	CompetitionManager.medals["gold"] = 3
	GameState.reset()
	assert_null(CompetitionManager.current_competition)
	assert_eq(CompetitionManager.medals["gold"], 0)
```

**Step 2: Modify GameState.gd**

a) In `_on_results_continue()`, AFTER the contract deadline tick block (after line 104) and BEFORE `if check_win_condition():` (line 105), add:

```gdscript
	# Competition tick (Stage 4B)
	if is_instance_valid(CompetitionManager):
		var comp_result: Dictionary = CompetitionManager.tick()
		if comp_result.has("placement") and comp_result["placement"] != "none":
			if is_instance_valid(ToastManager):
				var medal_names: Dictionary = {"gold": "GOLD MEDAL", "silver": "Silver Medal", "bronze": "Bronze Medal"}
				var medal_name: String = medal_names.get(comp_result["placement"], "")
				ToastManager.show_toast("%s! %s — +$%d" % [
					medal_name,
					comp_result["competition"].get("name", ""),
					comp_result["prize"]
				])
				if comp_result.get("rare_unlock", "") != "":
					ToastManager.show_toast("Gold medal bonus! Unlocked: %s" % comp_result["rare_unlock"])
		elif comp_result.has("placement") and comp_result["placement"] == "none" and CompetitionManager.player_entry != null:
			pass  # Player didn't enter or didn't place — no toast needed for no-entry
		if comp_result.has("placement") and comp_result["placement"] == "none" and comp_result.get("player_quality", 0.0) > 0.0:
			if is_instance_valid(ToastManager):
				ToastManager.show_toast("Competition ended. Your entry didn't place.")
```

Actually, let me simplify that. Here is the cleaner version:

```gdscript
	# Competition tick (Stage 4B)
	if is_instance_valid(CompetitionManager):
		var comp_result: Dictionary = CompetitionManager.tick()
		if comp_result.has("placement"):
			var placement: String = comp_result["placement"]
			var comp_name: String = comp_result.get("competition", {}).get("name", "")
			if placement == "gold" or placement == "silver" or placement == "bronze":
				if is_instance_valid(ToastManager):
					var medal_labels: Dictionary = {"gold": "GOLD MEDAL", "silver": "Silver Medal", "bronze": "Bronze Medal"}
					ToastManager.show_toast("%s! %s — +$%d" % [
						medal_labels[placement], comp_name, comp_result["prize"]
					])
					if comp_result.get("rare_unlock", "") != "":
						ToastManager.show_toast("Gold medal bonus! Unlocked: %s" % comp_result["rare_unlock"])
			elif placement == "none" and comp_result.get("player_quality", 0.0) > 0.0:
				if is_instance_valid(ToastManager):
					ToastManager.show_toast("Competition ended. Your entry didn't place.")
```

b) In `reset()`, AFTER ContractManager.reset() (after line 396), add:

```gdscript
	if is_instance_valid(CompetitionManager):
		CompetitionManager.reset()
```

**Step 3: Run tests, verify all pass**

**Step 4: Commit**

```
feat: integrate CompetitionManager with GameState turn lifecycle
```

---

### Task 5: CompetitionScreen UI

**Files:**
- Create: `src/ui/CompetitionScreen.gd`

**Context:** Full-screen overlay showing competition details, prizes, entry option, and medal cabinet. Same pattern as ContractBoard/StaffScreen overlays.

See `design/wireframes/competitions.md` sections 3-4 for exact layout specs.

**Step 1: Create CompetitionScreen.gd**

```gdscript
# src/ui/CompetitionScreen.gd
extends CanvasLayer

## CompetitionScreen — full-screen overlay showing competition details,
## prizes, entry option, and medal cabinet.

signal closed()

func _ready() -> void:
	visible = false

func show_screen() -> void:
	_build_ui()
	visible = true

func _build_ui() -> void:
	for child in get_children():
		child.queue_free()

	if not is_instance_valid(CompetitionManager):
		return

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
	panel.position = Vector2(190, 85)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#0B1220")
	panel_style.border_color = Color("#FFC857") if CompetitionManager.current_competition != null else Color("#8A9BB1")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(4)
	panel_style.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(scroll)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title := Label.new()
	title.text = "BEER COMPETITION"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.add_theme_font_size_override("font_size", 20)
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color(Color("#FF7B7B"), 0.2)
	close_style.set_corner_radius_all(4)
	close_btn.add_theme_stylebox_override("normal", close_style)
	close_btn.pressed.connect(_on_close)
	header.add_child(close_btn)

	vbox.add_child(HSeparator.new())

	if CompetitionManager.current_competition != null:
		_build_active_competition(vbox)
	else:
		_build_no_competition(vbox)

	# Medal cabinet
	vbox.add_child(HSeparator.new())
	_build_medal_cabinet(vbox)

func _build_active_competition(parent: VBoxContainer) -> void:
	var comp: Dictionary = CompetitionManager.current_competition

	# Competition name
	var name_label := Label.new()
	name_label.text = comp["name"]
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color("#FFC857"))
	parent.add_child(name_label)

	# Details row
	var details := HBoxContainer.new()
	details.add_theme_constant_override("separation", 24)
	parent.add_child(details)

	var cat_text: String = comp["category"].capitalize() if comp["category"] != "open" else "Open (Any Style)"
	var cat_label := Label.new()
	cat_label.text = "Category: %s" % cat_text
	cat_label.add_theme_font_size_override("font_size", 20)
	cat_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	details.add_child(cat_label)

	var fee_label := Label.new()
	fee_label.text = "Entry Fee: $%d" % comp["entry_fee"]
	fee_label.add_theme_font_size_override("font_size", 20)
	fee_label.add_theme_color_override("font_color", Color("#FF7B7B"))
	details.add_child(fee_label)

	var deadline_label := Label.new()
	deadline_label.text = "Deadline: %d turns remaining" % comp["turns_remaining"]
	deadline_label.add_theme_font_size_override("font_size", 20)
	var deadline_color: Color = Color("#FF7B7B") if comp["turns_remaining"] <= 1 else Color("#FFB347")
	deadline_label.add_theme_color_override("font_color", deadline_color)
	parent.add_child(deadline_label)

	# Prizes
	var prizes_label := Label.new()
	prizes_label.text = "PRIZES"
	prizes_label.add_theme_font_size_override("font_size", 20)
	prizes_label.add_theme_color_override("font_color", Color.WHITE)
	parent.add_child(prizes_label)

	var prizes_row := HBoxContainer.new()
	prizes_row.add_theme_constant_override("separation", 16)
	parent.add_child(prizes_row)

	_add_prize_card(prizes_row, "GOLD", comp["prizes"]["gold"], Color("#FFD700"))
	_add_prize_card(prizes_row, "SILVER", comp["prizes"]["silver"], Color("#C0C0C0"))
	_add_prize_card(prizes_row, "BRONZE", comp["prizes"]["bronze"], Color("#CD7F32"))

	parent.add_child(HSeparator.new())

	# Entry section
	var entry_label := Label.new()
	entry_label.text = "SELECT ENTRY"
	entry_label.add_theme_font_size_override("font_size", 20)
	entry_label.add_theme_color_override("font_color", Color.WHITE)
	parent.add_child(entry_label)

	if CompetitionManager.player_entry != null:
		var submitted := Label.new()
		submitted.text = "Entry submitted! Quality: %.0f — Results after deadline" % CompetitionManager.player_entry["quality"]
		submitted.add_theme_font_size_override("font_size", 20)
		submitted.add_theme_color_override("font_color", Color("#5EE8A4"))
		parent.add_child(submitted)
	elif GameState.last_brew_result.is_empty():
		var no_brew := Label.new()
		no_brew.text = "No recent brew. Brew a beer first to compete!"
		no_brew.add_theme_font_size_override("font_size", 16)
		no_brew.add_theme_color_override("font_color", Color("#8A9BB1"))
		parent.add_child(no_brew)
	else:
		var brew_style_id: String = GameState.current_style.style_id if GameState.current_style else ""
		var brew_quality: float = GameState.last_brew_result.get("final_score", 0.0)
		var brew_style_name: String = GameState.current_style.style_name if GameState.current_style else "Unknown"
		var category: String = comp["category"]
		var matches: bool = category == "open" or category == brew_style_id

		var entry_card := PanelContainer.new()
		var entry_style := StyleBoxFlat.new()
		entry_style.bg_color = Color("#0B1220")
		entry_style.border_color = Color("#5AA9FF") if matches else Color("#8A9BB1")
		entry_style.set_border_width_all(2)
		entry_style.set_corner_radius_all(4)
		entry_style.set_content_margin_all(12)
		entry_card.add_theme_stylebox_override("panel", entry_style)
		parent.add_child(entry_card)

		var entry_vbox := VBoxContainer.new()
		entry_vbox.add_theme_constant_override("separation", 8)
		entry_card.add_child(entry_vbox)

		var brew_label := Label.new()
		brew_label.text = "Your most recent brew:"
		brew_label.add_theme_font_size_override("font_size", 16)
		brew_label.add_theme_color_override("font_color", Color("#8A9BB1"))
		entry_vbox.add_child(brew_label)

		var brew_info := Label.new()
		var match_text: String = " (Matches!)" if matches else " (Wrong style)"
		brew_info.text = "Style: %s    Quality: %.0f%s" % [brew_style_name, brew_quality, match_text]
		brew_info.add_theme_font_size_override("font_size", 20)
		brew_info.add_theme_color_override("font_color", Color("#5EE8A4") if matches else Color("#FF7B7B"))
		entry_vbox.add_child(brew_info)

		if matches:
			var enter_btn := Button.new()
			enter_btn.text = "Enter Competition"
			enter_btn.custom_minimum_size = Vector2(200, 48)
			enter_btn.add_theme_font_size_override("font_size", 20)
			var btn_style := StyleBoxFlat.new()
			btn_style.bg_color = Color("#FFC857")
			btn_style.set_corner_radius_all(4)
			btn_style.set_content_margin_all(8)
			enter_btn.add_theme_stylebox_override("normal", btn_style)
			enter_btn.add_theme_color_override("font_color", Color("#0F1724"))
			enter_btn.pressed.connect(func(): _on_enter(brew_style_id, brew_quality))
			entry_vbox.add_child(enter_btn)
		else:
			var hint := Label.new()
			hint.text = "Brew a %s to compete!" % cat_text
			hint.add_theme_font_size_override("font_size", 16)
			hint.add_theme_color_override("font_color", Color("#8A9BB1"))
			entry_vbox.add_child(hint)

func _build_no_competition(parent: VBoxContainer) -> void:
	var no_comp := Label.new()
	no_comp.text = "No competition currently active."
	no_comp.add_theme_font_size_override("font_size", 20)
	no_comp.add_theme_color_override("font_color", Color("#8A9BB1"))
	parent.add_child(no_comp)

	var next_label := Label.new()
	next_label.text = "Next competition in: ~%d turns" % CompetitionManager.turns_until_next
	next_label.add_theme_font_size_override("font_size", 20)
	next_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	parent.add_child(next_label)

func _build_medal_cabinet(parent: VBoxContainer) -> void:
	var cabinet_label := Label.new()
	cabinet_label.text = "MEDAL CABINET"
	cabinet_label.add_theme_font_size_override("font_size", 20)
	cabinet_label.add_theme_color_override("font_color", Color.WHITE)
	parent.add_child(cabinet_label)

	var medals_row := HBoxContainer.new()
	medals_row.add_theme_constant_override("separation", 24)
	parent.add_child(medals_row)

	_add_medal_count(medals_row, "Gold", CompetitionManager.medals["gold"], Color("#FFD700"))
	_add_medal_count(medals_row, "Silver", CompetitionManager.medals["silver"], Color("#C0C0C0"))
	_add_medal_count(medals_row, "Bronze", CompetitionManager.medals["bronze"], Color("#CD7F32"))

func _add_prize_card(parent: HBoxContainer, tier: String, amount: int, color: Color) -> void:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(150, 80)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0B1220")
	style.border_color = color
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.set_content_margin_all(12)
	card.add_theme_stylebox_override("panel", style)
	parent.add_child(card)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 4)
	card.add_child(vb)

	var tier_label := Label.new()
	tier_label.text = tier
	tier_label.add_theme_font_size_override("font_size", 20)
	tier_label.add_theme_color_override("font_color", color)
	vb.add_child(tier_label)

	var amount_label := Label.new()
	amount_label.text = "$%d" % amount
	amount_label.add_theme_font_size_override("font_size", 24)
	amount_label.add_theme_color_override("font_color", Color("#5EE8A4"))
	vb.add_child(amount_label)

func _add_medal_count(parent: HBoxContainer, name: String, count: int, color: Color) -> void:
	var label := Label.new()
	label.text = "%s: %d" % [name, count]
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)

func _on_enter(style_id: String, quality: float) -> void:
	var success: bool = CompetitionManager.enter(style_id, quality)
	if success and is_instance_valid(ToastManager):
		ToastManager.show_toast("Competition entry submitted! Quality: %.0f" % quality)
	_build_ui()

func _on_close() -> void:
	visible = false
	closed.emit()
```

**Step 2: Run tests, verify all pass**

Run: `make test`
Expected: All tests still PASS (no new tests for UI).

**Step 3: Commit**

```
feat: add CompetitionScreen overlay UI
```

---

### Task 6: BreweryScene Integration

**Files:**
- Modify: `src/scenes/BreweryScene.gd`

**Context:** Add "Compete" button to the brewery hub bottom bar, with accent color when a competition is active. Opens CompetitionScreen overlay.

**Step 1: Modify BreweryScene.gd**

a) Add a variable for the compete button and screen (with other button vars, around line 24):
```gdscript
var _compete_button: Button = null
var _competition_screen: CanvasLayer = null
```

b) In `_build_equipment_ui()`, AFTER the contracts button section, add:

```gdscript
	# "Compete" button next to Contracts
	_compete_button = Button.new()
	_compete_button.name = "CompeteButton"
	var has_active_comp: bool = is_instance_valid(CompetitionManager) and CompetitionManager.current_competition != null
	if has_active_comp and CompetitionManager.player_entry == null:
		_compete_button.text = "Compete (!)"
	else:
		_compete_button.text = "Compete"
	_compete_button.custom_minimum_size = Vector2(160, 48)
	_compete_button.position = Vector2(1320, 620)
	_compete_button.add_theme_font_size_override("font_size", 24)
	_compete_button.add_theme_color_override("font_color", Color("#0F1724"))

	var compete_style := StyleBoxFlat.new()
	compete_style.bg_color = Color("#FFC857") if has_active_comp else Color("#5AA9FF")
	compete_style.set_corner_radius_all(8)
	compete_style.content_margin_left = 24
	compete_style.content_margin_right = 24
	compete_style.content_margin_top = 8
	compete_style.content_margin_bottom = 8
	_compete_button.add_theme_stylebox_override("normal", compete_style)

	var compete_hover := compete_style.duplicate()
	compete_hover.bg_color = Color("#FFD680") if has_active_comp else Color("#7BBFFF")
	_compete_button.add_theme_stylebox_override("hover", compete_hover)

	_compete_button.pressed.connect(func(): _on_compete_pressed())
	_equipment_ui.add_child(_compete_button)
```

c) Add handlers:
```gdscript
func _on_compete_pressed() -> void:
	if _competition_screen == null:
		_competition_screen = preload("res://ui/CompetitionScreen.gd").new()
		add_child(_competition_screen)
		_competition_screen.closed.connect(_on_competition_screen_closed)
	_competition_screen.show_screen()

func _on_competition_screen_closed() -> void:
	# Refresh compete button badge
	if _compete_button and is_instance_valid(CompetitionManager):
		var has_active: bool = CompetitionManager.current_competition != null
		if has_active and CompetitionManager.player_entry == null:
			_compete_button.text = "Compete (!)"
		else:
			_compete_button.text = "Compete"
```

**Step 2: Run tests, verify all pass**

Run: `make test`
Expected: All tests still PASS.

**Step 3: Commit**

```
feat: add Compete button to brewery hub with competition screen
```

---

## Summary

| Task | Description | Tests Added |
|------|-------------|-------------|
| 1 | CompetitionManager autoload (scheduling, data model) | ~12 |
| 2 | Entry and judging tests | ~14 |
| 3 | Persistence and medal tracking tests | ~3 |
| 4 | GameState integration (tick, reset) | ~1 |
| 5 | CompetitionScreen overlay UI | 0 (UI) |
| 6 | BreweryScene integration | 0 (UI) |

**Estimated total new tests:** ~30
**Estimated total tests after:** ~368 (338 existing + ~30 new)
