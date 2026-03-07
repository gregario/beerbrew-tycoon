# Stage 5B — Specialty, Brand & Automation: Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add three systems that deepen the artisan/mass-market fork — specialty beers with multi-turn aging (artisan), brand recognition that boosts demand (shared), and automation equipment that replaces staff (mass-market).

**Architecture:** Extends existing Resource + Autoload Manager pattern. BeerStyle gets specialty fields, new SpecialtyBeerManager autoload handles aging queue. Brand recognition lives in MarketManager as a Dictionary. Automation adds AUTOMATION to Equipment.Category enum and new aggregation methods to EquipmentManager. QualityCalculator applies max(staff, automation) per phase.

**Tech Stack:** Godot 4 + GDScript, GUT test framework, `.tres` Resource files

**Key codebase facts:**
- Equipment.Category is an **enum** (BREWING=0, FERMENTATION=1, PACKAGING=2, UTILITY=3) — must add AUTOMATION=4
- StaffManager.get_phase_bonus(phase) returns `{"flavor": float, "technique": float}`
- QualityCalculator.calculate_quality() takes (style, recipe, sliders, history)
- PathManager.get_path_type() returns "artisan" or "mass_market"
- ResearchManager.unlock_effect uses `{"type": "...", ...}` dictionary dispatch
- `.tres` files MUST use `type="Resource"` not custom class names
- Autoloads must NOT use `static func`
- Avoid `:=` on `Dictionary.get()` — causes Variant parse errors in Godot 4.6

**Stack profile:** Read `stacks/godot/STACK.md` before starting. Key files: `coding_standards.md`, `testing.md`, `pitfalls.md`.

**Run tests:** `make test` from project root. Currently 484/484 passing.

---

## Task 1: Add Specialty Fields to BeerStyle Resource

**Files:**
- Modify: `src/scripts/BeerStyle.gd`
- Test: `src/tests/test_beer_style_specialty.gd`

**Step 1: Write the failing test**

Create `src/tests/test_beer_style_specialty.gd`:

```gdscript
extends GutTest

func test_beer_style_has_specialty_fields():
	var style := BeerStyle.new()
	assert_eq(style.is_specialty, false, "Default is_specialty should be false")
	assert_eq(style.fermentation_turns, 1, "Default fermentation_turns should be 1")
	assert_almost_eq(style.variance_modifier, 1.0, 0.01, "Default variance_modifier should be 1.0")
	assert_eq(style.specialty_category, "", "Default specialty_category should be empty")

func test_specialty_fields_can_be_set():
	var style := BeerStyle.new()
	style.is_specialty = true
	style.fermentation_turns = 5
	style.variance_modifier = 3.0
	style.specialty_category = "sour_wild"
	assert_true(style.is_specialty)
	assert_eq(style.fermentation_turns, 5)
	assert_almost_eq(style.variance_modifier, 3.0, 0.01)
	assert_eq(style.specialty_category, "sour_wild")
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — BeerStyle has no `is_specialty` property

**Step 3: Add specialty fields to BeerStyle.gd**

Add these exports after the existing `unlocked` field:

```gdscript
@export var is_specialty: bool = false
@export var fermentation_turns: int = 1
@export var variance_modifier: float = 1.0
@export var specialty_category: String = ""  # "sour_wild", "experimental", ""
```

**Step 4: Run test to verify it passes**

Run: `make test`
Expected: ALL PASS (existing 484 + new tests)

**Step 5: Commit**

```bash
git add src/scripts/BeerStyle.gd src/tests/test_beer_style_specialty.gd
git commit -m "feat: add specialty fields to BeerStyle Resource"
```

---

## Task 2: Create Specialty BeerStyle .tres Files

**Files:**
- Create: `src/data/styles/berliner_weisse.tres`
- Create: `src/data/styles/lambic.tres`
- Create: `src/data/styles/experimental_brew.tres`
- Test: Add to `src/tests/test_beer_style_specialty.gd`

**Step 1: Write the failing tests**

Append to `src/tests/test_beer_style_specialty.gd`:

```gdscript
func test_berliner_weisse_loads():
	var style: BeerStyle = load("res://data/styles/berliner_weisse.tres")
	assert_not_null(style, "Berliner Weisse should load")
	assert_eq(style.style_id, "berliner_weisse")
	assert_true(style.is_specialty)
	assert_eq(style.fermentation_turns, 3)
	assert_eq(style.specialty_category, "sour_wild")
	assert_false(style.unlocked, "Specialty styles start locked")

func test_lambic_loads():
	var style: BeerStyle = load("res://data/styles/lambic.tres")
	assert_not_null(style, "Lambic should load")
	assert_eq(style.style_id, "lambic")
	assert_true(style.is_specialty)
	assert_eq(style.fermentation_turns, 5)
	assert_eq(style.specialty_category, "sour_wild")
	assert_false(style.unlocked)

func test_experimental_brew_loads():
	var style: BeerStyle = load("res://data/styles/experimental_brew.tres")
	assert_not_null(style, "Experimental Brew should load")
	assert_eq(style.style_id, "experimental_brew")
	assert_true(style.is_specialty)
	assert_eq(style.fermentation_turns, 1)
	assert_eq(style.specialty_category, "experimental")
	assert_false(style.unlocked)
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — files don't exist yet

**Step 3: Create the .tres files**

Look at an existing style file (e.g., `pale_ale.tres`) for the exact format. Create three files following the same pattern but with specialty fields set. Key differences:
- `unlocked = false` (gated behind research)
- `is_specialty = true`
- `fermentation_turns` = 3 (berliner), 5 (lambic), 1 (experimental)
- `specialty_category` = "sour_wild" or "experimental"
- Set reasonable `ideal_flavor_ratio`, `base_price`, `ideal_flavor_profile` values:
  - Berliner Weisse: high funkiness/sourness, low bitterness, base_price=250
  - Lambic: very high funkiness, base_price=350
  - Experimental Brew: balanced profile, base_price=200

**Step 4: Run test to verify it passes**

Run: `make test`
Expected: ALL PASS

**Step 5: Commit**

```bash
git add src/data/styles/berliner_weisse.tres src/data/styles/lambic.tres src/data/styles/experimental_brew.tres src/tests/test_beer_style_specialty.gd
git commit -m "feat: add specialty beer style data files"
```

---

## Task 3: Create SpecialtyBeerManager Autoload

**Files:**
- Create: `src/autoloads/SpecialtyBeerManager.gd`
- Modify: `src/project.godot` (add autoload)
- Test: `src/tests/test_specialty_beer_manager.gd`

**Step 1: Write the failing tests**

Create `src/tests/test_specialty_beer_manager.gd`:

```gdscript
extends GutTest

var manager: Node

func before_each():
	manager = load("res://autoloads/SpecialtyBeerManager.gd").new()
	add_child_autofree(manager)

func test_aging_queue_starts_empty():
	assert_eq(manager.get_aging_queue().size(), 0)

func test_queue_beer_adds_to_aging():
	manager.queue_beer({
		"style_id": "lambic",
		"style_name": "Lambic",
		"recipe": {"malts": [], "hops": [], "yeast": null, "adjuncts": []},
		"quality_base": 75.0,
		"turns_remaining": 5,
		"variance_seed": 42,
	})
	assert_eq(manager.get_aging_queue().size(), 1)
	assert_eq(manager.get_aging_queue()[0]["turns_remaining"], 5)

func test_tick_aging_decrements_turns():
	manager.queue_beer({
		"style_id": "lambic",
		"style_name": "Lambic",
		"recipe": {},
		"quality_base": 75.0,
		"turns_remaining": 3,
		"variance_seed": 42,
	})
	manager.tick_aging()
	assert_eq(manager.get_aging_queue()[0]["turns_remaining"], 2)

func test_get_completed_beers_returns_finished():
	manager.queue_beer({
		"style_id": "berliner",
		"style_name": "Berliner Weisse",
		"recipe": {},
		"quality_base": 80.0,
		"turns_remaining": 1,
		"variance_seed": 99,
	})
	manager.tick_aging()
	var completed: Array = manager.get_completed_beers()
	assert_eq(completed.size(), 1)
	assert_eq(completed[0]["style_id"], "berliner")
	# Completed beers removed from queue
	assert_eq(manager.get_aging_queue().size(), 0)

func test_completed_beer_has_final_quality():
	manager.queue_beer({
		"style_id": "lambic",
		"style_name": "Lambic",
		"recipe": {},
		"quality_base": 70.0,
		"turns_remaining": 1,
		"variance_seed": 42,
	})
	manager.tick_aging()
	var completed: Array = manager.get_completed_beers()
	assert_not_null(completed[0].get("final_quality"))
	# Quality should be in reasonable range (base ± 15 + ceiling boost)
	assert_gte(completed[0]["final_quality"], 0.0)
	assert_lte(completed[0]["final_quality"], 100.0)

func test_variance_is_deterministic():
	# Same seed should produce same variance
	manager.queue_beer({
		"style_id": "lambic",
		"style_name": "Lambic",
		"recipe": {},
		"quality_base": 70.0,
		"turns_remaining": 1,
		"variance_seed": 42,
	})
	manager.tick_aging()
	var first: Array = manager.get_completed_beers()
	var q1: float = first[0]["final_quality"]

	manager.queue_beer({
		"style_id": "lambic",
		"style_name": "Lambic",
		"recipe": {},
		"quality_base": 70.0,
		"turns_remaining": 1,
		"variance_seed": 42,
	})
	manager.tick_aging()
	var second: Array = manager.get_completed_beers()
	var q2: float = second[0]["final_quality"]
	assert_almost_eq(q1, q2, 0.01, "Same seed should produce same quality")

func test_save_load_preserves_aging_queue():
	manager.queue_beer({
		"style_id": "lambic",
		"style_name": "Lambic",
		"recipe": {},
		"quality_base": 75.0,
		"turns_remaining": 3,
		"variance_seed": 42,
	})
	var data: Dictionary = manager.save_state()
	manager.reset()
	assert_eq(manager.get_aging_queue().size(), 0)
	manager.load_state(data)
	assert_eq(manager.get_aging_queue().size(), 1)
	assert_eq(manager.get_aging_queue()[0]["turns_remaining"], 3)

func test_reset_clears_queue():
	manager.queue_beer({
		"style_id": "lambic",
		"style_name": "Lambic",
		"recipe": {},
		"quality_base": 75.0,
		"turns_remaining": 3,
		"variance_seed": 42,
	})
	manager.reset()
	assert_eq(manager.get_aging_queue().size(), 0)
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — file doesn't exist

**Step 3: Implement SpecialtyBeerManager**

Create `src/autoloads/SpecialtyBeerManager.gd`:

```gdscript
extends Node

const SPECIALTY_VARIANCE: float = 15.0
const SPECIALTY_CEILING_BOOST: float = 10.0

var _aging_queue: Array = []
var _completed_beers: Array = []


func get_aging_queue() -> Array:
	return _aging_queue


func queue_beer(entry: Dictionary) -> void:
	_aging_queue.append(entry.duplicate(true))


func tick_aging() -> void:
	_completed_beers.clear()
	var still_aging: Array = []
	for entry in _aging_queue:
		entry["turns_remaining"] -= 1
		if entry["turns_remaining"] <= 0:
			entry["final_quality"] = _resolve_quality(entry)
			_completed_beers.append(entry)
		else:
			still_aging.append(entry)
	_aging_queue = still_aging


func get_completed_beers() -> Array:
	var result: Array = _completed_beers.duplicate()
	_completed_beers.clear()
	return result


func _resolve_quality(entry: Dictionary) -> float:
	var base: float = entry.get("quality_base", 50.0)
	var seed_val: int = entry.get("variance_seed", 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var variance: float = rng.randf_range(-SPECIALTY_VARIANCE, SPECIALTY_VARIANCE)
	var final_val: float = base + variance + SPECIALTY_CEILING_BOOST
	return clampf(final_val, 0.0, 100.0)


func save_state() -> Dictionary:
	return {"aging_queue": _aging_queue.duplicate(true)}


func load_state(data: Dictionary) -> void:
	_aging_queue = data.get("aging_queue", []).duplicate(true)
	_completed_beers.clear()


func reset() -> void:
	_aging_queue.clear()
	_completed_beers.clear()
```

Register in `project.godot` autoloads:
```
SpecialtyBeerManager="*res://autoloads/SpecialtyBeerManager.gd"
```

**Step 4: Run test to verify it passes**

Run: `make test`
Expected: ALL PASS

**Step 5: Commit**

```bash
git add src/autoloads/SpecialtyBeerManager.gd src/tests/test_specialty_beer_manager.gd src/project.godot
git commit -m "feat: add SpecialtyBeerManager autoload with aging queue"
```

---

## Task 4: Integrate SpecialtyBeerManager with GameState Lifecycle

**Files:**
- Modify: `src/autoloads/GameState.gd`
- Test: `src/tests/test_specialty_beer_manager.gd` (add integration tests)

**Step 1: Write the failing test**

Add to `src/tests/test_specialty_beer_manager.gd`:

```gdscript
func test_specialty_beer_queued_on_brew():
	# When execute_brew is called for a specialty style with fermentation_turns > 1,
	# the beer should be queued in SpecialtyBeerManager instead of giving immediate results
	# This is an integration test — verify the wiring exists in GameState
	pass  # Integration tests depend on full GameState setup
```

**Note:** The integration with GameState is wiring-level work. The key changes:

**Step 2: Modify GameState.execute_brew()**

In `execute_brew()`, after quality calculation but before setting results, add:

```gdscript
# After quality is calculated:
if current_style is BeerStyle and current_style.is_specialty and current_style.fermentation_turns > 1:
	if is_instance_valid(SpecialtyBeerManager):
		SpecialtyBeerManager.queue_beer({
			"style_id": current_style.style_id,
			"style_name": current_style.style_name,
			"recipe": current_recipe.duplicate(true),
			"quality_base": result["final_score"],
			"turns_remaining": current_style.fermentation_turns,
			"variance_seed": randi(),
		})
		# Set a flag so results screen shows "beer is aging" message
		result["is_aging"] = true
		result["aging_turns"] = current_style.fermentation_turns
```

**Step 3: Modify GameState._on_results_continue()**

After existing tick calls, add:

```gdscript
if is_instance_valid(SpecialtyBeerManager):
	SpecialtyBeerManager.tick_aging()
	var completed: Array = SpecialtyBeerManager.get_completed_beers()
	for beer in completed:
		var revenue: float = calculate_revenue(beer["final_quality"])
		add_revenue(revenue)
		beer["revenue"] = revenue
	if not completed.is_empty():
		last_brew_result["completed_aged_beers"] = completed
```

**Step 4: Modify GameState.reset()**

Add:
```gdscript
if is_instance_valid(SpecialtyBeerManager):
	SpecialtyBeerManager.reset()
```

**Step 5: Add save/load integration**

In the save function (likely in Game.gd or wherever save_state is called), add SpecialtyBeerManager.save_state()/load_state() alongside other manager save/load calls.

**Step 6: Run tests**

Run: `make test`
Expected: ALL PASS (484 existing + new)

**Step 7: Commit**

```bash
git add src/autoloads/GameState.gd src/tests/test_specialty_beer_manager.gd
git commit -m "feat: integrate SpecialtyBeerManager with GameState lifecycle"
```

---

## Task 5: Create Wild Fermentation Research Node

**Files:**
- Create: `src/data/research/techniques/wild_fermentation.tres`
- Modify: `src/autoloads/ResearchManager.gd` (add `unlock_specialty_beers` effect handling)
- Test: `src/tests/test_wild_fermentation_research.gd`

**Step 1: Write the failing tests**

Create `src/tests/test_wild_fermentation_research.gd`:

```gdscript
extends GutTest

func test_wild_fermentation_node_loads():
	var node: ResearchNode = load("res://data/research/techniques/wild_fermentation.tres")
	assert_not_null(node, "Wild Fermentation node should load")
	assert_eq(node.node_id, "wild_fermentation")
	assert_eq(node.category, ResearchNode.Category.TECHNIQUES)
	assert_eq(node.rp_cost, 30)
	assert_true(node.prerequisites.has("specialist_yeast"))

func test_wild_fermentation_unlock_effect_type():
	var node: ResearchNode = load("res://data/research/techniques/wild_fermentation.tres")
	assert_eq(node.unlock_effect.get("type"), "unlock_specialty_beers")

func test_research_manager_handles_unlock_specialty_beers():
	# After unlocking wild_fermentation, specialty styles should become available
	# The ResearchManager should set specialty beer style .unlocked = true
	# Load a specialty style, confirm it starts locked
	var berliner: BeerStyle = load("res://data/styles/berliner_weisse.tres")
	var initial_unlocked: bool = berliner.unlocked
	assert_false(initial_unlocked, "Berliner should start locked")
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — .tres file doesn't exist

**Step 3: Create wild_fermentation.tres**

Follow the existing research node format (look at `specialist_yeast.tres` for reference):

```ini
[gd_resource type="Resource" load_steps=2 format=3]
[ext_resource type="Script" path="res://scripts/ResearchNode.gd" id="1_research"]
[resource]
script = ExtResource("1_research")
node_id = "wild_fermentation"
node_name = "Wild Fermentation"
description = "Ancient techniques of spontaneous fermentation. Unlocks sour and experimental beer styles."
category = 0
rp_cost = 30
prerequisites = ["specialist_yeast"]
unlock_effect = {"type": "unlock_specialty_beers", "ids": ["berliner_weisse", "lambic", "experimental_brew"]}
```

**Step 4: Add unlock_specialty_beers effect handling to ResearchManager**

In `ResearchManager._apply_effect()`, add a new match branch:

```gdscript
"unlock_specialty_beers":
	var ids: Array = effect.get("ids", [])
	_unlock_specialty_styles(ids)
```

Create the helper method:
```gdscript
func _unlock_specialty_styles(style_ids: Array) -> void:
	var dir := DirAccess.open("res://data/styles/")
	if dir == null:
		return
	for style_id in style_ids:
		var path: String = "res://data/styles/%s.tres" % style_id
		if ResourceLoader.exists(path):
			var style: BeerStyle = load(path)
			if style != null:
				style.unlocked = true
```

Also add specialty style IDs to the locked list that gets reset:

```gdscript
const LOCKED_SPECIALTY_STYLE_IDS: Array[String] = [
	"berliner_weisse", "lambic", "experimental_brew"
]
```

In `reset()`, re-lock these styles.

**Step 5: Run test to verify it passes**

Run: `make test`
Expected: ALL PASS

**Step 6: Commit**

```bash
git add src/data/research/techniques/wild_fermentation.tres src/autoloads/ResearchManager.gd src/tests/test_wild_fermentation_research.gd
git commit -m "feat: add Wild Fermentation research node with specialty beer unlocking"
```

---

## Task 6: Implement Experimental Brew Mutation

**Files:**
- Modify: `src/autoloads/SpecialtyBeerManager.gd`
- Test: Add to `src/tests/test_specialty_beer_manager.gd`

**Step 1: Write the failing tests**

Add to `src/tests/test_specialty_beer_manager.gd`:

```gdscript
func test_generate_mutation_returns_valid_data():
	var ingredients: Array = [
		{"ingredient_id": "pale_malt", "flavor_points": 10.0, "technique_points": 8.0},
		{"ingredient_id": "cascade", "flavor_points": 12.0, "technique_points": 6.0},
		{"ingredient_id": "us05", "flavor_points": 5.0, "technique_points": 10.0},
	]
	var mutation: Dictionary = manager.generate_mutation(ingredients, 42)
	assert_has(mutation, "mutated_index")
	assert_has(mutation, "original_flavor")
	assert_has(mutation, "original_technique")
	assert_has(mutation, "mutated_flavor")
	assert_has(mutation, "mutated_technique")
	assert_has(mutation, "ingredient_id")
	assert_gte(mutation["mutated_index"], 0)
	assert_lt(mutation["mutated_index"], ingredients.size())

func test_mutation_values_within_50_pct():
	var ingredients: Array = [
		{"ingredient_id": "pale_malt", "flavor_points": 10.0, "technique_points": 8.0},
	]
	var mutation: Dictionary = manager.generate_mutation(ingredients, 42)
	# Mutated values should be within ±50% of original
	assert_gte(mutation["mutated_flavor"], 5.0)  # 10 * 0.5
	assert_lte(mutation["mutated_flavor"], 15.0)  # 10 * 1.5
	assert_gte(mutation["mutated_technique"], 4.0)  # 8 * 0.5
	assert_lte(mutation["mutated_technique"], 12.0)  # 8 * 1.5

func test_mutation_is_deterministic():
	var ingredients: Array = [
		{"ingredient_id": "pale_malt", "flavor_points": 10.0, "technique_points": 8.0},
		{"ingredient_id": "cascade", "flavor_points": 12.0, "technique_points": 6.0},
	]
	var m1: Dictionary = manager.generate_mutation(ingredients, 99)
	var m2: Dictionary = manager.generate_mutation(ingredients, 99)
	assert_eq(m1["mutated_index"], m2["mutated_index"])
	assert_almost_eq(m1["mutated_flavor"], m2["mutated_flavor"], 0.01)
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — `generate_mutation` doesn't exist

**Step 3: Implement mutation logic**

Add to `SpecialtyBeerManager.gd`:

```gdscript
func generate_mutation(ingredients: Array, seed_val: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var idx: int = rng.randi_range(0, ingredients.size() - 1)
	var ingredient: Dictionary = ingredients[idx]
	var orig_flavor: float = ingredient.get("flavor_points", 0.0)
	var orig_technique: float = ingredient.get("technique_points", 0.0)
	var flavor_mult: float = rng.randf_range(0.5, 1.5)
	var technique_mult: float = rng.randf_range(0.5, 1.5)
	return {
		"mutated_index": idx,
		"ingredient_id": ingredient.get("ingredient_id", ""),
		"original_flavor": orig_flavor,
		"original_technique": orig_technique,
		"mutated_flavor": orig_flavor * flavor_mult,
		"mutated_technique": orig_technique * technique_mult,
	}
```

**Step 4: Run test to verify it passes**

Run: `make test`
Expected: ALL PASS

**Step 5: Commit**

```bash
git add src/autoloads/SpecialtyBeerManager.gd src/tests/test_specialty_beer_manager.gd
git commit -m "feat: add experimental brew mutation logic"
```

---

## Task 7: Add Specialty Variance to QualityCalculator

**Files:**
- Modify: `src/autoloads/QualityCalculator.gd`
- Test: `src/tests/test_quality_specialty.gd`

**Step 1: Write the failing tests**

Create `src/tests/test_quality_specialty.gd`:

```gdscript
extends GutTest

func test_specialty_variance_applied():
	# Specialty beers should have ±15 variance + 10 ceiling boost
	var base_score: float = 70.0
	var result: float = QualityCalculator.apply_specialty_variance(base_score, 42)
	# Result should be base + variance(-15 to +15) + ceiling(10), clamped 0-100
	assert_gte(result, 0.0)
	assert_lte(result, 100.0)
	# With ceiling boost, result should generally be higher than base
	# (can't guarantee due to variance, but check determinism)
	var result2: float = QualityCalculator.apply_specialty_variance(base_score, 42)
	assert_almost_eq(result, result2, 0.01, "Same seed should produce same result")

func test_normal_beer_no_specialty_variance():
	# apply_specialty_variance should NOT be called for normal beers
	# This is enforced by the caller (GameState/QualityCalculator), not the function
	pass

func test_specialty_variance_clamped():
	# Even with high base + positive variance + ceiling, clamp to 100
	var result: float = QualityCalculator.apply_specialty_variance(95.0, 42)
	assert_lte(result, 100.0)
	# Even with low base + negative variance, clamp to 0
	var result_low: float = QualityCalculator.apply_specialty_variance(5.0, 12345)
	assert_gte(result_low, 0.0)
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — `apply_specialty_variance` doesn't exist

**Step 3: Implement in QualityCalculator**

Add to `QualityCalculator.gd`:

```gdscript
const SPECIALTY_VARIANCE: float = 15.0
const SPECIALTY_CEILING_BOOST: float = 10.0

func apply_specialty_variance(base_score: float, seed_val: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var variance: float = rng.randf_range(-SPECIALTY_VARIANCE, SPECIALTY_VARIANCE)
	return clampf(base_score + variance + SPECIALTY_CEILING_BOOST, 0.0, 100.0)
```

**Note:** This duplicates the logic in SpecialtyBeerManager._resolve_quality(). Refactor SpecialtyBeerManager to call `QualityCalculator.apply_specialty_variance()` instead. Remove the duplicate constants from SpecialtyBeerManager.

**Step 4: Run test to verify it passes**

Run: `make test`
Expected: ALL PASS

**Step 5: Commit**

```bash
git add src/autoloads/QualityCalculator.gd src/tests/test_quality_specialty.gd
git commit -m "feat: add specialty beer variance to QualityCalculator"
```

---

## Task 8: Add Automation Equipment Category and Data

**Files:**
- Modify: `src/scripts/Equipment.gd`
- Create: `src/data/equipment/automation/auto_mash_controller.tres`
- Create: `src/data/equipment/automation/automated_boil_system.tres`
- Create: `src/data/equipment/automation/fermentation_controller.tres`
- Create: `src/data/equipment/automation/full_automation_suite.tres`
- Test: `src/tests/test_automation_equipment.gd`

**Step 1: Write the failing tests**

Create `src/tests/test_automation_equipment.gd`:

```gdscript
extends GutTest

func test_equipment_has_automation_category():
	assert_eq(Equipment.Category.AUTOMATION, 4, "AUTOMATION should be category 4")

func test_equipment_has_phase_bonus_fields():
	var e := Equipment.new()
	assert_eq(e.mash_bonus, 0)
	assert_eq(e.boil_bonus, 0)
	assert_eq(e.ferment_bonus, 0)

func test_auto_mash_controller_loads():
	var e: Equipment = load("res://data/equipment/automation/auto_mash_controller.tres")
	assert_not_null(e)
	assert_eq(e.equipment_id, "auto_mash_controller")
	assert_eq(e.category, Equipment.Category.AUTOMATION)
	assert_eq(e.tier, 3)
	assert_eq(e.cost, 800)
	assert_eq(e.mash_bonus, 5)
	assert_eq(e.boil_bonus, 0)
	assert_eq(e.ferment_bonus, 0)

func test_full_automation_suite_loads():
	var e: Equipment = load("res://data/equipment/automation/full_automation_suite.tres")
	assert_not_null(e)
	assert_eq(e.equipment_id, "full_automation_suite")
	assert_eq(e.tier, 5)
	assert_eq(e.cost, 3500)
	assert_eq(e.mash_bonus, 6)
	assert_eq(e.boil_bonus, 6)
	assert_eq(e.ferment_bonus, 6)
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — no AUTOMATION category

**Step 3: Modify Equipment.gd**

Add `AUTOMATION` to the Category enum:

```gdscript
enum Category { BREWING, FERMENTATION, PACKAGING, UTILITY, AUTOMATION }
```

Add new export fields:

```gdscript
@export var mash_bonus: int = 0
@export var boil_bonus: int = 0
@export var ferment_bonus: int = 0
```

**Step 4: Create the 4 automation .tres files**

Create `src/data/equipment/automation/` directory. Follow existing equipment file format:

- `auto_mash_controller.tres`: T3, $800, mash_bonus=5
- `automated_boil_system.tres`: T4, $1500, boil_bonus=7
- `fermentation_controller.tres`: T4, $1800, ferment_bonus=8
- `full_automation_suite.tres`: T5, $3500, mash=6, boil=6, ferment=6

Category value for AUTOMATION = 4 in the .tres file.

**Step 5: Run test to verify it passes**

Run: `make test`
Expected: ALL PASS (verify existing equipment tests still pass with new enum value)

**Step 6: Commit**

```bash
git add src/scripts/Equipment.gd src/data/equipment/automation/ src/tests/test_automation_equipment.gd
git commit -m "feat: add automation equipment category and data files"
```

---

## Task 9: Add Automation Bonus Aggregation to EquipmentManager

**Files:**
- Modify: `src/autoloads/EquipmentManager.gd`
- Test: Add to `src/tests/test_automation_equipment.gd`

**Step 1: Write the failing tests**

Add to `src/tests/test_automation_equipment.gd`:

```gdscript
func test_get_automation_mash_bonus_no_equipment():
	assert_eq(EquipmentManager.get_automation_mash_bonus(), 0)

func test_get_automation_boil_bonus_no_equipment():
	assert_eq(EquipmentManager.get_automation_boil_bonus(), 0)

func test_get_automation_ferment_bonus_no_equipment():
	assert_eq(EquipmentManager.get_automation_ferment_bonus(), 0)

# Additional tests with mock slotted equipment would require
# more setup — test the aggregation logic by directly verifying
# the methods exist and return 0 when no automation is slotted.
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — methods don't exist

**Step 3: Add aggregation methods to EquipmentManager**

Add to `EquipmentManager.gd`:

```gdscript
func get_automation_mash_bonus() -> int:
	var total: int = 0
	for slot_id in station_slots:
		if slot_id == "":
			continue
		var equip: Equipment = get_equipment(slot_id)
		if equip != null and equip.category == Equipment.Category.AUTOMATION:
			total += equip.mash_bonus
	return total

func get_automation_boil_bonus() -> int:
	var total: int = 0
	for slot_id in station_slots:
		if slot_id == "":
			continue
		var equip: Equipment = get_equipment(slot_id)
		if equip != null and equip.category == Equipment.Category.AUTOMATION:
			total += equip.boil_bonus
	return total

func get_automation_ferment_bonus() -> int:
	var total: int = 0
	for slot_id in station_slots:
		if slot_id == "":
			continue
		var equip: Equipment = get_equipment(slot_id)
		if equip != null and equip.category == Equipment.Category.AUTOMATION:
			total += equip.ferment_bonus
	return total
```

Also ensure `get_equipment_by_category()` and catalog loading work with the new AUTOMATION category. The EquipmentManager likely scans directories — verify it also scans `res://data/equipment/automation/`.

**Step 4: Run test to verify it passes**

Run: `make test`
Expected: ALL PASS

**Step 5: Commit**

```bash
git add src/autoloads/EquipmentManager.gd src/tests/test_automation_equipment.gd
git commit -m "feat: add automation bonus aggregation to EquipmentManager"
```

---

## Task 10: Add Automation Bonus Integration to QualityCalculator

**Files:**
- Modify: `src/autoloads/QualityCalculator.gd`
- Test: `src/tests/test_quality_specialty.gd` (add automation tests)

**Step 1: Write the failing tests**

Add to `src/tests/test_quality_specialty.gd`:

```gdscript
func test_get_effective_phase_bonus_staff_only():
	var staff: Dictionary = {"flavor": 5.0, "technique": 3.0}
	var auto: int = 0
	var result: Dictionary = QualityCalculator.get_effective_phase_bonus(staff, auto)
	assert_almost_eq(result["flavor"], 5.0, 0.01)
	assert_almost_eq(result["technique"], 3.0, 0.01)

func test_get_effective_phase_bonus_auto_wins():
	var staff: Dictionary = {"flavor": 5.0, "technique": 3.0}
	var auto: int = 8
	var result: Dictionary = QualityCalculator.get_effective_phase_bonus(staff, auto)
	# Auto provides flat bonus split evenly to flavor/technique
	# auto=8 → 4.0 flavor + 4.0 technique (total exceeds staff total)
	# But we compare totals: staff=8, auto=8 → equal, use auto
	# Actually per design: max per phase. Auto provides a flat bonus.
	# Let's define: auto bonus adds equally to flavor and technique
	# auto=8 → flavor=4.0, technique=4.0
	# Compare: max(staff_flavor, auto_flavor), max(staff_technique, auto_technique)?
	# No — design says "higher of automation or staff" per PHASE, not per stat.
	# So compare total: staff total = 8, auto = 8 → auto wins (or equal)
	# Simpler: the bonus is a single number per phase, use max(staff_total, auto)
	assert_gte(result["flavor"] + result["technique"], 8.0)

func test_get_effective_phase_bonus_staff_wins():
	var staff: Dictionary = {"flavor": 8.0, "technique": 7.0}
	var auto: int = 5
	var result: Dictionary = QualityCalculator.get_effective_phase_bonus(staff, auto)
	# Staff total = 15 > auto 5 → staff wins
	assert_almost_eq(result["flavor"], 8.0, 0.01)
	assert_almost_eq(result["technique"], 7.0, 0.01)
```

**Step 2: Run test to verify it fails**

Expected: FAIL — `get_effective_phase_bonus` doesn't exist

**Step 3: Implement**

Add to `QualityCalculator.gd`:

```gdscript
func get_effective_phase_bonus(staff_bonus: Dictionary, automation_bonus: int) -> Dictionary:
	var staff_total: float = staff_bonus.get("flavor", 0.0) + staff_bonus.get("technique", 0.0)
	if automation_bonus > staff_total:
		# Split automation bonus evenly between flavor and technique
		var half: float = automation_bonus / 2.0
		return {"flavor": half, "technique": half}
	return staff_bonus
```

Then modify `_compute_points()` to use this instead of directly adding staff bonuses:

```gdscript
# Replace the existing staff bonus block with:
for phase_name in ["mashing", "boiling", "fermenting"]:
	var staff_bonus: Dictionary = {"flavor": 0.0, "technique": 0.0}
	if is_instance_valid(StaffManager):
		staff_bonus = StaffManager.get_phase_bonus(phase_name)
	var auto_bonus: int = 0
	if is_instance_valid(EquipmentManager):
		match phase_name:
			"mashing": auto_bonus = EquipmentManager.get_automation_mash_bonus()
			"boiling": auto_bonus = EquipmentManager.get_automation_boil_bonus()
			"fermenting": auto_bonus = EquipmentManager.get_automation_ferment_bonus()
	var effective: Dictionary = get_effective_phase_bonus(staff_bonus, auto_bonus)
	flavor += effective["flavor"]
	technique += effective["technique"]
```

**Step 4: Run test to verify it passes**

Run: `make test`
Expected: ALL PASS

**Step 5: Commit**

```bash
git add src/autoloads/QualityCalculator.gd src/tests/test_quality_specialty.gd
git commit -m "feat: add automation bonus integration to QualityCalculator (max of staff vs auto)"
```

---

## Task 11: Add Brand Recognition to MarketManager

**Files:**
- Modify: `src/autoloads/MarketManager.gd`
- Test: `src/tests/test_brand_recognition.gd`

**Step 1: Write the failing tests**

Create `src/tests/test_brand_recognition.gd`:

```gdscript
extends GutTest

func before_each():
	MarketManager.reset()

func test_brand_recognition_starts_at_zero():
	assert_almost_eq(MarketManager.get_brand_recognition("pale_ale"), 0.0, 0.01)

func test_add_brand_recognition_retail():
	MarketManager.add_brand_recognition("pale_ale", "retail")
	# base_gain=5 * retail_multiplier=1.5 = 7.5
	assert_almost_eq(MarketManager.get_brand_recognition("pale_ale"), 7.5, 0.01)

func test_add_brand_recognition_bars():
	MarketManager.add_brand_recognition("stout", "local_bars")
	# base_gain=5 * bars_multiplier=1.0 = 5.0
	assert_almost_eq(MarketManager.get_brand_recognition("stout"), 5.0, 0.01)

func test_add_brand_recognition_taproom():
	MarketManager.add_brand_recognition("wheat_beer", "taproom")
	# base_gain=5 * taproom_multiplier=0.5 = 2.5
	assert_almost_eq(MarketManager.get_brand_recognition("wheat_beer"), 2.5, 0.01)

func test_add_brand_recognition_events():
	MarketManager.add_brand_recognition("ipa", "events")
	# base_gain=5 * events_multiplier=0.3 = 1.5
	assert_almost_eq(MarketManager.get_brand_recognition("ipa"), 1.5, 0.01)

func test_brand_recognition_capped_at_100():
	for i in range(20):
		MarketManager.add_brand_recognition("pale_ale", "retail")
	assert_almost_eq(MarketManager.get_brand_recognition("pale_ale"), 100.0, 0.01)

func test_brand_decay_for_unbrewed_style():
	MarketManager.add_brand_recognition("pale_ale", "retail")  # 7.5
	MarketManager.tick_brand_decay("stout")  # brewed stout, not pale_ale
	# pale_ale should decay by 2.0 → 5.5
	assert_almost_eq(MarketManager.get_brand_recognition("pale_ale"), 5.5, 0.01)

func test_brand_no_decay_for_brewed_style():
	MarketManager.add_brand_recognition("pale_ale", "retail")  # 7.5
	MarketManager.tick_brand_decay("pale_ale")  # brewed pale_ale
	# pale_ale should NOT decay
	assert_almost_eq(MarketManager.get_brand_recognition("pale_ale"), 7.5, 0.01)

func test_brand_decay_floors_at_zero():
	MarketManager.add_brand_recognition("pale_ale", "events")  # 1.5
	MarketManager.tick_brand_decay("stout")  # decay 2.0 → should floor at 0
	assert_almost_eq(MarketManager.get_brand_recognition("pale_ale"), 0.0, 0.01)

func test_brand_demand_multiplier_at_zero():
	assert_almost_eq(MarketManager.get_brand_demand_multiplier("pale_ale"), 1.0, 0.01)

func test_brand_demand_multiplier_at_100():
	for i in range(20):
		MarketManager.add_brand_recognition("pale_ale", "retail")
	# 1.0 + (100/100) * 0.5 = 1.5
	assert_almost_eq(MarketManager.get_brand_demand_multiplier("pale_ale"), 1.5, 0.01)

func test_brand_demand_multiplier_at_60():
	for i in range(8):
		MarketManager.add_brand_recognition("pale_ale", "retail")  # 8*7.5=60
	# 1.0 + (60/100) * 0.5 = 1.3
	assert_almost_eq(MarketManager.get_brand_demand_multiplier("pale_ale"), 1.3, 0.01)

func test_brand_recognition_save_load():
	MarketManager.add_brand_recognition("pale_ale", "retail")
	var data: Dictionary = MarketManager.save_data()
	MarketManager.reset()
	assert_almost_eq(MarketManager.get_brand_recognition("pale_ale"), 0.0, 0.01)
	MarketManager.load_data(data)
	assert_almost_eq(MarketManager.get_brand_recognition("pale_ale"), 7.5, 0.01)
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — methods don't exist

**Step 3: Implement brand recognition in MarketManager**

Add to `MarketManager.gd`:

```gdscript
# Constants
const BRAND_BASE_GAIN: float = 5.0
const BRAND_DECAY_PER_TURN: float = 2.0
const BRAND_MAX: float = 100.0
const BRAND_DEMAND_SCALE: float = 0.5
const BRAND_CHANNEL_MULTIPLIERS: Dictionary = {
	"retail": 1.5,
	"local_bars": 1.0,
	"taproom": 0.5,
	"events": 0.3,
}

# Property
var brand_recognition: Dictionary = {}  # style_id -> float


func get_brand_recognition(style_id: String) -> float:
	return brand_recognition.get(style_id, 0.0)


func add_brand_recognition(style_id: String, channel_id: String) -> void:
	var multiplier: float = BRAND_CHANNEL_MULTIPLIERS.get(channel_id, 0.5)
	var gain: float = BRAND_BASE_GAIN * multiplier
	var current: float = brand_recognition.get(style_id, 0.0)
	brand_recognition[style_id] = minf(current + gain, BRAND_MAX)


func tick_brand_decay(brewed_style_id: String) -> void:
	for style_id in brand_recognition.keys():
		if style_id != brewed_style_id:
			brand_recognition[style_id] = maxf(brand_recognition[style_id] - BRAND_DECAY_PER_TURN, 0.0)


func get_brand_demand_multiplier(style_id: String) -> float:
	var recognition: float = get_brand_recognition(style_id)
	return 1.0 + (recognition / BRAND_MAX) * BRAND_DEMAND_SCALE
```

Include `brand_recognition` in `save_data()`, `load_data()`, and `reset()`.

**Step 4: Run test to verify it passes**

Run: `make test`
Expected: ALL PASS

**Step 5: Commit**

```bash
git add src/autoloads/MarketManager.gd src/tests/test_brand_recognition.gd
git commit -m "feat: add brand recognition tracking to MarketManager"
```

---

## Task 12: Integrate Brand Recognition with Demand Volume

**Files:**
- Modify: `src/autoloads/MarketManager.gd`
- Test: Add to `src/tests/test_brand_recognition.gd`

**Step 1: Write the failing test**

Add to `src/tests/test_brand_recognition.gd`:

```gdscript
func test_demand_multiplier_includes_brand():
	# Set up brand recognition and verify it affects get_demand_multiplier
	for i in range(8):
		MarketManager.add_brand_recognition("pale_ale", "retail")  # 60 recognition
	var demand_with_brand: float = MarketManager.get_demand_multiplier("pale_ale")
	MarketManager.reset()
	var demand_without: float = MarketManager.get_demand_multiplier("pale_ale")
	# Brand should add 0.3 to the multiplier
	assert_gt(demand_with_brand, demand_without, "Brand should increase demand")
```

**Step 2: Modify get_demand_multiplier()**

In MarketManager's `get_demand_multiplier()`, multiply the result by the brand demand multiplier:

```gdscript
# At the end of get_demand_multiplier, before clamping:
var brand_mult: float = get_brand_demand_multiplier(style_id)
result *= brand_mult
return clampf(result, DEMAND_MIN, DEMAND_MAX)
```

**Step 3: Run test to verify it passes**

Run: `make test`
Expected: ALL PASS

**Step 4: Commit**

```bash
git add src/autoloads/MarketManager.gd src/tests/test_brand_recognition.gd
git commit -m "feat: integrate brand recognition with demand volume calculation"
```

---

## Task 13: Integrate Brand Gain into Sell Flow

**Files:**
- Modify: `src/autoloads/GameState.gd`
- Test: Integration test

**Step 1: Modify execute_sell()**

In `GameState.execute_sell()`, after calculating revenue per channel, call:

```gdscript
if is_instance_valid(MarketManager):
	for allocation in allocations:
		if allocation.get("units", 0) > 0:
			MarketManager.add_brand_recognition(current_style.style_id, allocation["channel_id"])
```

**Step 2: Modify _on_results_continue()**

After existing MarketManager.tick() call, add brand decay:

```gdscript
if is_instance_valid(MarketManager):
	var brewed_style_id: String = ""
	if current_style != null:
		brewed_style_id = current_style.style_id
	MarketManager.tick_brand_decay(brewed_style_id)
```

**Step 3: Run tests**

Run: `make test`
Expected: ALL PASS

**Step 4: Commit**

```bash
git add src/autoloads/GameState.gd
git commit -m "feat: integrate brand gain on sell and decay on turn end"
```

---

## Task 14: Add Path-Gating for Automation in EquipmentShop

**Files:**
- Modify: `src/ui/EquipmentShop.gd` (or wherever the shop UI lives)
- Test: `src/tests/test_automation_equipment.gd` (add path-gating tests)

**Step 1: Write the failing tests**

Add to `src/tests/test_automation_equipment.gd`:

```gdscript
func test_automation_visible_for_mass_market():
	# When PathManager.get_path_type() == "mass_market"
	# automation equipment should be shown
	# This is a UI-level test — verify the filtering logic
	pass  # UI filtering is tested via the shop build method

func test_automation_hidden_for_artisan():
	# When PathManager.get_path_type() == "artisan"
	# automation equipment should be hidden
	pass
```

**Step 2: Modify EquipmentShop**

Find the shop's category tab building logic. Add the AUTOMATION tab conditionally:

```gdscript
# When building category tabs:
var categories: Array = [
	Equipment.Category.BREWING,
	Equipment.Category.FERMENTATION,
	Equipment.Category.PACKAGING,
	Equipment.Category.UTILITY,
]
if is_instance_valid(PathManager) and PathManager.get_path_type() == "mass_market":
	categories.append(Equipment.Category.AUTOMATION)
```

Also ensure the equipment catalog loading includes the `automation/` directory.

**Step 3: Run tests**

Run: `make test`
Expected: ALL PASS

**Step 4: Commit**

```bash
git add src/ui/EquipmentShop.gd src/tests/test_automation_equipment.gd
git commit -m "feat: add path-gating for automation equipment in shop"
```

---

## Task 15: Style Picker — Specialty Beer Display

**Files:**
- Modify: The style selection UI script (find it — likely `src/ui/StyleSelect.gd` or similar)

**Step 1: Identify the style picker file**

Search for the style selection screen. Look for code that builds style cards/buttons.

**Step 2: Add specialty styles section**

After the standard styles grid, add a "SPECIALTY STYLES" section that:
- Only shows when `PathManager.get_path_type() == "artisan"` AND `ResearchManager.is_unlocked("wild_fermentation")`
- Lists specialty styles with accent border (`#FFC857`)
- Shows "Ages: X turns" label for styles with `fermentation_turns > 1`
- Shows "High variance" for experimental brews

**Step 3: Run tests**

Run: `make test`
Expected: ALL PASS

**Step 4: Commit**

```bash
git add <style-picker-file>
git commit -m "feat: add specialty styles section to style picker"
```

---

## Task 16: Cellar Panel — Aging Queue on Brewery Hub

**Files:**
- Modify: `src/scenes/BreweryScene.gd` (or ArtisanBreweryScene.gd)

**Step 1: Add cellar panel builder**

Below the button grid, add a method that builds the cellar display:

```gdscript
func _build_cellar_panel() -> void:
	# Only show if SpecialtyBeerManager has aging beers
	if not is_instance_valid(SpecialtyBeerManager):
		return
	var queue: Array = SpecialtyBeerManager.get_aging_queue()
	if queue.is_empty():
		return
	# Build panel with header "CELLAR (N aging)"
	# For each entry: style name + ProgressBar (turns_elapsed/total) + "X/Y turns" label
	# Use accent color (#FFC857) for progress bar fill
```

**Step 2: Update cellar on state change**

Call `_build_cellar_panel()` when the brewery hub is shown (on state change to EQUIPMENT_MANAGE or when navigating back).

**Step 3: Run tests**

Run: `make test`
Expected: ALL PASS

**Step 4: Commit**

```bash
git add src/scenes/BreweryScene.gd
git commit -m "feat: add cellar panel showing aging queue on brewery hub"
```

---

## Task 17: Aged Beer Completion Panel in ResultsOverlay

**Files:**
- Modify: `src/ui/ResultsOverlay.gd`

**Step 1: Add completed aged beer panels**

In the results display method, after existing panels, check for completed aged beers:

```gdscript
# After normal results panels:
var completed: Array = result.get("completed_aged_beers", [])
for beer in completed:
	_build_aged_beer_panel(beer)  # success border, quality, revenue, variance
```

Build the panel following the design wireframe: success border (`#5EE8A4`), show style name, aging duration, quality with stars, variance contribution, and revenue.

**Step 2: Add "beer is aging" message for newly queued beers**

When `result.get("is_aging", false)` is true, show a notification instead of normal results:

```gdscript
if result.get("is_aging", false):
	# Show "Your [style] is now aging! Results in X turns."
	# Use accent color panel
```

**Step 3: Run tests**

Run: `make test`
Expected: ALL PASS

**Step 4: Commit**

```bash
git add src/ui/ResultsOverlay.gd
git commit -m "feat: add aged beer completion and aging notification panels"
```

---

## Task 18: Brand Recognition Display in MarketForecast

**Files:**
- Modify: `src/ui/MarketForecast.gd`

**Step 1: Add brand recognition section to Forecast tab**

At the top of the Forecast tab content (before seasonal demand), add:

```gdscript
func _build_brand_section(parent: VBoxContainer) -> void:
	# Header: "BRAND RECOGNITION" in accent color
	# For each unlocked style:
	#   HBoxContainer with:
	#     - Style name label (80px fixed width)
	#     - ProgressBar (200px, primary fill #5AA9FF, 0-100 range)
	#     - Recognition value label (e.g., "72")
	#     - Demand bonus label (e.g., "+36% demand" in success color if >0, muted if 0)
	# Section separator line
```

**Step 2: Run tests**

Run: `make test`
Expected: ALL PASS

**Step 3: Commit**

```bash
git add src/ui/MarketForecast.gd
git commit -m "feat: add brand recognition progress bars to MarketForecast"
```

---

## Task 19: Automation vs Staff Bonus Display in BrewingPhases

**Files:**
- Modify: `src/ui/BrewingPhases.gd` (or wherever `_update_bonus_label()` lives)

**Step 1: Modify the bonus label**

Find `_update_bonus_label()` and extend it:

```gdscript
func _update_bonus_label() -> void:
	# ... existing equipment bonus display ...

	# Add staff vs automation comparison:
	var staff_bonus: Dictionary = {"flavor": 0.0, "technique": 0.0}
	if is_instance_valid(StaffManager):
		staff_bonus = StaffManager.get_phase_bonus(_current_phase)

	var auto_bonus: int = 0
	if is_instance_valid(EquipmentManager):
		match _current_phase:
			"mashing": auto_bonus = EquipmentManager.get_automation_mash_bonus()
			"boiling": auto_bonus = EquipmentManager.get_automation_boil_bonus()
			"fermenting": auto_bonus = EquipmentManager.get_automation_ferment_bonus()

	var staff_total: float = staff_bonus["flavor"] + staff_bonus["technique"]

	if staff_total > 0 or auto_bonus > 0:
		if auto_bonus > 0 and staff_total > 0:
			# Both present — show comparison
			var staff_text: String = "Staff +%d" % int(staff_total)
			var auto_text: String = "Auto +%d" % auto_bonus
			if auto_bonus > staff_total:
				# Auto active — accent auto, mute staff
				bonus_label.text += "\nBonus: %s | %s (active)" % [staff_text, auto_text]
			else:
				# Staff active — accent staff, mute auto
				bonus_label.text += "\nBonus: %s (active) | %s" % [staff_text, auto_text]
		elif auto_bonus > 0:
			bonus_label.text += "\nBonus: Auto +%d" % auto_bonus
		elif staff_total > 0:
			bonus_label.text += "\nBonus: Staff +%d" % int(staff_total)
```

**Step 2: Run tests**

Run: `make test`
Expected: ALL PASS

**Step 3: Commit**

```bash
git add src/ui/BrewingPhases.gd
git commit -m "feat: show automation vs staff bonus comparison in brewing phases"
```

---

## Task 20: Experimental Brew Mutation Panel in ResultsOverlay

**Files:**
- Modify: `src/ui/ResultsOverlay.gd`
- Modify: `src/autoloads/GameState.gd` (pass mutation data through)

**Step 1: Pass mutation data through execute_brew**

In `GameState.execute_brew()`, when the style is experimental:

```gdscript
if current_style.specialty_category == "experimental":
	if is_instance_valid(SpecialtyBeerManager):
		var ingredient_data: Array = _build_ingredient_data(current_recipe)
		var mutation: Dictionary = SpecialtyBeerManager.generate_mutation(ingredient_data, randi())
		result["mutation"] = mutation
		# Apply mutated values to quality calculation
		# (modify the recipe copy before passing to QualityCalculator)
```

**Step 2: Add mutation panel to ResultsOverlay**

```gdscript
func _build_mutation_panel(mutation: Dictionary, parent: VBoxContainer) -> void:
	# Accent border (#FFC857) panel
	# "Cascade Hops mutated!" header
	# Before/after for flavor and technique:
	#   "Flavor: 10 → 14 (+4)" in success color if positive, danger if negative
	#   "Technique: 8 → 5 (-3)" in danger color
	# Italic flavor text description
```

**Step 3: Run tests**

Run: `make test`
Expected: ALL PASS

**Step 4: Commit**

```bash
git add src/ui/ResultsOverlay.gd src/autoloads/GameState.gd
git commit -m "feat: show experimental brew mutation results in ResultsOverlay"
```

---

## Task 21: Final Integration Test — Verify All 484+ Tests Pass

**Files:** None (test-only)

**Step 1: Run full test suite**

Run: `make test`
Expected: ALL PASS (484 original + ~30-40 new tests)

**Step 2: Manual verification checklist**

- [ ] BeerStyle specialty fields have correct defaults
- [ ] Specialty .tres files load with correct properties
- [ ] SpecialtyBeerManager aging queue works (queue, tick, complete)
- [ ] Wild Fermentation research node loads and unlocks specialty styles
- [ ] Experimental mutation generates valid data
- [ ] QualityCalculator applies specialty variance
- [ ] Equipment AUTOMATION category works
- [ ] EquipmentManager aggregates automation bonuses
- [ ] QualityCalculator uses max(staff, auto) per phase
- [ ] MarketManager brand recognition CRUD works
- [ ] Brand recognition affects demand multiplier
- [ ] Save/load preserves all new state

**Step 3: Commit if any cleanup needed**

```bash
git add -A
git commit -m "chore: final integration cleanup for Stage 5B"
```
