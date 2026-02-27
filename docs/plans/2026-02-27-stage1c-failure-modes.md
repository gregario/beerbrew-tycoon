# Stage 1C — Failure Modes & QA Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add infection and off-flavor failure modes that probabilistically penalize quality, plus QA checkpoint toasts during brewing.

**Architecture:** A new `FailureSystem.gd` autoload handles probability calculations and penalty application. GameState tracks `sanitation_quality` and `temp_control_quality` stats. QA checkpoints fire toasts via existing ToastManager. ResultsOverlay conditionally shows failure panels. All failure logic is tested independently via GUT.

**Tech Stack:** Godot 4 + GDScript, GUT testing framework, existing autoload architecture

---

### Task 1: Add sanitation_quality stat to GameState

**Files:**
- Modify: `src/autoloads/GameState.gd`
- Test: `src/tests/test_failure_modes.gd` (create)

**Step 1: Create test file with first test**

Create `src/tests/test_failure_modes.gd`:

```gdscript
## Tests for failure modes and QA system.
extends GutTest

# ---------------------------------------------------------------------------
# GameState stat defaults
# ---------------------------------------------------------------------------

func test_sanitation_quality_defaults_to_50() -> void:
	GameState.reset()
	assert_eq(GameState.sanitation_quality, 50, "sanitation_quality should default to 50")
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — `sanitation_quality` not found on GameState (note: it may already exist partially, but verify the reset clears it)

**Step 3: Add sanitation_quality to GameState**

In `src/autoloads/GameState.gd`, the variable `sanitation_quality` needs to be declared (if not already present — check first) and reset in `reset()`:

Add to runtime state section (near `temp_control_quality`):
```gdscript
var sanitation_quality: int = 50
```

In `reset()`, add:
```gdscript
sanitation_quality = 50
```

**Step 4: Run test to verify it passes**

Run: `make test`
Expected: PASS — all 122+ tests passing

**Step 5: Commit**

```
feat: add sanitation_quality stat to GameState (Stage 1C task 3.1)
```

---

### Task 2: Create FailureSystem autoload with infection probability

**Files:**
- Create: `src/autoloads/FailureSystem.gd`
- Test: `src/tests/test_failure_modes.gd` (add tests)

**Step 1: Write failing tests for infection probability**

Add to `src/tests/test_failure_modes.gd`:

```gdscript
# ---------------------------------------------------------------------------
# Infection probability
# ---------------------------------------------------------------------------

func test_infection_chance_at_sanitation_80() -> void:
	var chance: float = FailureSystem.calc_infection_chance(80)
	assert_lte(chance, 0.10, "Sanitation 80+ should give <=10% infection chance")

func test_infection_chance_at_sanitation_100() -> void:
	var chance: float = FailureSystem.calc_infection_chance(100)
	assert_eq(chance, 0.0, "Sanitation 100 should give 0% infection chance")

func test_infection_chance_at_sanitation_30() -> void:
	var chance: float = FailureSystem.calc_infection_chance(30)
	assert_almost_eq(chance, 0.35, 0.01, "Sanitation 30 should give 35% infection chance")

func test_infection_chance_at_sanitation_50() -> void:
	var chance: float = FailureSystem.calc_infection_chance(50)
	assert_almost_eq(chance, 0.25, 0.01, "Sanitation 50 should give 25% infection chance")

func test_infection_chance_never_negative() -> void:
	var chance: float = FailureSystem.calc_infection_chance(100)
	assert_gte(chance, 0.0, "Infection chance should never be negative")
```

**Step 2: Run tests to verify they fail**

Run: `make test`
Expected: FAIL — FailureSystem not found

**Step 3: Create FailureSystem autoload**

Create `src/autoloads/FailureSystem.gd`:

```gdscript
extends Node

## FailureSystem — infection and off-flavor probability calculations.
## All calculation methods are stateless (pass stats in, get results out).
## Roll methods use RNG and modify brew results.


## Calculates infection probability from sanitation quality.
## Formula: max(0, (100 - sanitation_quality) / 200.0)
static func calc_infection_chance(sanitation_quality: int) -> float:
	return maxf(0.0, float(100 - sanitation_quality) / 200.0)
```

Register autoload in `src/project.godot` — add under `[autoload]`:
```
FailureSystem="*res://autoloads/FailureSystem.gd"
```

**Step 4: Run tests to verify they pass**

Run: `make test`
Expected: PASS

**Step 5: Commit**

```
feat: add FailureSystem autoload with infection probability calculation
```

---

### Task 3: Add infection penalty and roll logic

**Files:**
- Modify: `src/autoloads/FailureSystem.gd`
- Test: `src/tests/test_failure_modes.gd` (add tests)

**Step 1: Write failing tests for infection penalty**

Add to `src/tests/test_failure_modes.gd`:

```gdscript
# ---------------------------------------------------------------------------
# Infection penalty
# ---------------------------------------------------------------------------

func test_apply_infection_penalty_reduces_score() -> void:
	var result: Dictionary = FailureSystem.apply_infection_penalty(80.0)
	assert_gte(result["penalized_score"], 80.0 * 0.4, "Infected score should be >= 40% of original")
	assert_lte(result["penalized_score"], 80.0 * 0.6, "Infected score should be <= 60% of original")

func test_apply_infection_penalty_flags_infected() -> void:
	var result: Dictionary = FailureSystem.apply_infection_penalty(80.0)
	assert_true(result["infected"], "Result should be flagged as infected")

func test_apply_infection_penalty_has_message() -> void:
	var result: Dictionary = FailureSystem.apply_infection_penalty(80.0)
	assert_true(result["message"].length() > 0, "Infection result should have a message")
```

**Step 2: Run tests to verify they fail**

Run: `make test`
Expected: FAIL — `apply_infection_penalty` not defined

**Step 3: Implement infection penalty**

Add to `src/autoloads/FailureSystem.gd`:

```gdscript
## Applies infection penalty to a quality score.
## Returns {penalized_score: float, infected: bool, message: String}
static func apply_infection_penalty(score: float) -> Dictionary:
	var multiplier: float = randf_range(0.4, 0.6)
	return {
		"penalized_score": score * multiplier,
		"infected": true,
		"message": "Bacteria contaminated your batch. Your beer tastes sour and unpleasant.",
	}
```

**Step 4: Run tests to verify they pass**

Run: `make test`
Expected: PASS

**Step 5: Commit**

```
feat: add infection penalty logic to FailureSystem
```

---

### Task 4: Add off-flavor probability and penalty

**Files:**
- Modify: `src/autoloads/FailureSystem.gd`
- Test: `src/tests/test_failure_modes.gd` (add tests)

**Step 1: Write failing tests for off-flavor probability and penalty**

Add to `src/tests/test_failure_modes.gd`:

```gdscript
# ---------------------------------------------------------------------------
# Off-flavor probability
# ---------------------------------------------------------------------------

func test_off_flavor_chance_at_temp_control_80() -> void:
	var chance: float = FailureSystem.calc_off_flavor_chance(80)
	assert_lte(chance, 0.10, "Temp control 80+ should give <=10% off-flavor chance")

func test_off_flavor_chance_at_temp_control_30() -> void:
	var chance: float = FailureSystem.calc_off_flavor_chance(30)
	assert_almost_eq(chance, 0.35, 0.01, "Temp control 30 should give 35% off-flavor chance")

func test_off_flavor_chance_at_temp_control_100() -> void:
	var chance: float = FailureSystem.calc_off_flavor_chance(100)
	assert_eq(chance, 0.0, "Temp control 100 should give 0% off-flavor chance")

# ---------------------------------------------------------------------------
# Off-flavor penalty
# ---------------------------------------------------------------------------

func test_off_flavor_penalty_reduces_score() -> void:
	var result: Dictionary = FailureSystem.apply_off_flavor_penalty(80.0)
	assert_gte(result["penalized_score"], 80.0 * 0.7, "Off-flavor score should be >= 70% of original")
	assert_lte(result["penalized_score"], 80.0 * 0.85, "Off-flavor score should be <= 85% of original")

func test_off_flavor_penalty_has_tag() -> void:
	var result: Dictionary = FailureSystem.apply_off_flavor_penalty(80.0)
	assert_true(result["off_flavor_tags"].size() > 0, "Off-flavor result should have tags")

func test_off_flavor_tag_is_valid_type() -> void:
	var valid_types: Array[String] = ["esters", "fusel_alcohols", "dms"]
	var result: Dictionary = FailureSystem.apply_off_flavor_penalty(80.0)
	var tag: String = result["off_flavor_tags"][0]
	assert_true(valid_types.has(tag), "Off-flavor tag should be a valid type: %s" % tag)

func test_off_flavor_penalty_has_message() -> void:
	var result: Dictionary = FailureSystem.apply_off_flavor_penalty(80.0)
	assert_true(result["message"].length() > 0, "Off-flavor result should have a message")
```

**Step 2: Run tests to verify they fail**

Run: `make test`
Expected: FAIL

**Step 3: Implement off-flavor probability and penalty**

Add to `src/autoloads/FailureSystem.gd`:

```gdscript
## Off-flavor descriptions for display.
const OFF_FLAVOR_INFO := {
	"esters": {
		"name": "Esters",
		"description": "Fruity, banana-like character.",
		"tip": "Better temperature control during fermentation helps avoid off-flavors.",
	},
	"fusel_alcohols": {
		"name": "Fusel Alcohols",
		"description": "Hot, solvent-like, boozy character.",
		"tip": "Better temperature control during fermentation helps avoid off-flavors.",
	},
	"dms": {
		"name": "DMS",
		"description": "Cooked corn, vegetal character from short boil.",
		"tip": "A longer, more vigorous boil drives off DMS precursors.",
	},
}


## Calculates off-flavor probability from temperature control quality.
## Same formula as infection: max(0, (100 - stat) / 200.0)
static func calc_off_flavor_chance(temp_control_quality: int) -> float:
	return maxf(0.0, float(100 - temp_control_quality) / 200.0)


## Applies off-flavor penalty to a quality score.
## Returns {penalized_score: float, off_flavor_tags: Array[String], message: String}
static func apply_off_flavor_penalty(score: float) -> Dictionary:
	var multiplier: float = randf_range(0.7, 0.85)
	var types: Array[String] = ["esters", "fusel_alcohols", "dms"]
	var tag: String = types[randi() % types.size()]
	var info: Dictionary = OFF_FLAVOR_INFO[tag]
	return {
		"penalized_score": score * multiplier,
		"off_flavor_tags": [tag] as Array[String],
		"message": "%s — %s" % [info["name"], info["description"]],
	}
```

**Step 4: Run tests to verify they pass**

Run: `make test`
Expected: PASS

**Step 5: Commit**

```
feat: add off-flavor probability and penalty to FailureSystem
```

---

### Task 5: Add combined failure roll method

**Files:**
- Modify: `src/autoloads/FailureSystem.gd`
- Test: `src/tests/test_failure_modes.gd` (add tests)

**Step 1: Write failing tests for the combined roll**

Add to `src/tests/test_failure_modes.gd`:

```gdscript
# ---------------------------------------------------------------------------
# Combined failure roll
# ---------------------------------------------------------------------------

func test_roll_failures_returns_expected_keys() -> void:
	var result: Dictionary = FailureSystem.roll_failures(80.0, 80, 80)
	assert_has(result, "final_score", "Result should have final_score")
	assert_has(result, "infected", "Result should have infected flag")
	assert_has(result, "off_flavor_tags", "Result should have off_flavor_tags")
	assert_has(result, "failure_messages", "Result should have failure_messages")

func test_roll_failures_perfect_stats_no_failures() -> void:
	# With sanitation=100 and temp_control=100, chances are 0%
	var infected_count: int = 0
	var off_flavor_count: int = 0
	for i in range(50):
		var result: Dictionary = FailureSystem.roll_failures(80.0, 100, 100)
		if result["infected"]:
			infected_count += 1
		if result["off_flavor_tags"].size() > 0:
			off_flavor_count += 1
	assert_eq(infected_count, 0, "Perfect sanitation should never infect")
	assert_eq(off_flavor_count, 0, "Perfect temp control should never produce off-flavors")

func test_roll_failures_preserves_score_when_clean() -> void:
	var result: Dictionary = FailureSystem.roll_failures(75.0, 100, 100)
	assert_eq(result["final_score"], 75.0, "Clean brew should preserve original score")

func test_roll_failures_infection_reduces_score() -> void:
	# Force infection by running many trials at low sanitation
	var found_infection: bool = false
	for i in range(200):
		var result: Dictionary = FailureSystem.roll_failures(80.0, 0, 100)
		if result["infected"]:
			assert_lt(result["final_score"], 80.0, "Infected brew should have lower score")
			found_infection = true
			break
	assert_true(found_infection, "Should have found at least one infection in 200 rolls at sanitation=0")
```

**Step 2: Run tests to verify they fail**

Run: `make test`
Expected: FAIL — `roll_failures` not defined

**Step 3: Implement combined roll**

Add to `src/autoloads/FailureSystem.gd`:

```gdscript
## Roll for all failure modes and apply penalties to the score.
## Returns {final_score, infected, infection_message, off_flavor_tags, off_flavor_message, failure_messages}
static func roll_failures(base_score: float, sanitation_quality: int, temp_control_quality: int) -> Dictionary:
	var final_score: float = base_score
	var infected: bool = false
	var infection_message: String = ""
	var off_flavor_tags: Array[String] = []
	var off_flavor_message: String = ""
	var failure_messages: Array[String] = []

	# Roll infection
	var infection_chance: float = calc_infection_chance(sanitation_quality)
	if infection_chance > 0.0 and randf() < infection_chance:
		var infection_result: Dictionary = apply_infection_penalty(final_score)
		final_score = infection_result["penalized_score"]
		infected = true
		infection_message = infection_result["message"]
		failure_messages.append(infection_message)

	# Roll off-flavor
	var off_flavor_chance: float = calc_off_flavor_chance(temp_control_quality)
	if off_flavor_chance > 0.0 and randf() < off_flavor_chance:
		var off_flavor_result: Dictionary = apply_off_flavor_penalty(final_score)
		final_score = off_flavor_result["penalized_score"]
		off_flavor_tags = off_flavor_result["off_flavor_tags"]
		off_flavor_message = off_flavor_result["message"]
		failure_messages.append(off_flavor_message)

	return {
		"final_score": final_score,
		"infected": infected,
		"infection_message": infection_message,
		"off_flavor_tags": off_flavor_tags,
		"off_flavor_message": off_flavor_message,
		"failure_messages": failure_messages,
	}
```

**Step 4: Run tests to verify they pass**

Run: `make test`
Expected: PASS

**Step 5: Commit**

```
feat: add combined roll_failures method to FailureSystem
```

---

### Task 6: Integrate FailureSystem into GameState.execute_brew

**Files:**
- Modify: `src/autoloads/GameState.gd`
- Test: `src/tests/test_failure_modes.gd` (add integration tests)

**Step 1: Write failing integration tests**

Add to `src/tests/test_failure_modes.gd`:

```gdscript
# ---------------------------------------------------------------------------
# Integration: execute_brew includes failure rolls
# ---------------------------------------------------------------------------

func _make_test_style() -> BeerStyle:
	var s := BeerStyle.new()
	s.style_id = "test_ipa"
	s.style_name = "IPA"
	s.ideal_flavor_ratio = 0.5
	s.base_price = 200.0
	s.preferred_ingredients = {}
	s.ideal_flavor_profile = {"bitterness": 0.8, "sweetness": 0.2, "roastiness": 0.0, "fruitiness": 0.3, "funkiness": 0.0}
	s.ideal_mash_temp_c = 65.0
	s.ideal_boil_min = 60.0
	return s

func _make_test_malt() -> Malt:
	var m := Malt.new()
	m.ingredient_id = "pale_malt"
	m.ingredient_name = "Pale Malt"
	m.cost = 15
	m.flavor_profile = {"bitterness": 0.1, "sweetness": 0.3, "roastiness": 0.1, "fruitiness": 0.0, "funkiness": 0.0}
	return m

func _make_test_hop() -> Hop:
	var h := Hop.new()
	h.ingredient_id = "centennial"
	h.ingredient_name = "Centennial"
	h.cost = 20
	h.alpha_acid_pct = 10.0
	h.flavor_profile = {"bitterness": 0.8, "sweetness": 0.0, "roastiness": 0.0, "fruitiness": 0.3, "funkiness": 0.0}
	return h

func _make_test_yeast() -> Yeast:
	var y := Yeast.new()
	y.ingredient_id = "ale_yeast"
	y.ingredient_name = "Ale Yeast"
	y.cost = 15
	y.ideal_temp_min_c = 18.0
	y.ideal_temp_max_c = 22.0
	y.attenuation = 0.75
	y.flavor_profile = {"bitterness": 0.0, "sweetness": 0.1, "roastiness": 0.0, "fruitiness": 0.2, "funkiness": 0.0}
	return y

func test_execute_brew_result_has_failure_keys() -> void:
	GameState.reset()
	GameState.balance = 5000.0
	GameState.current_style = _make_test_style()
	GameState.current_recipe = {"malts": [_make_test_malt()], "hops": [_make_test_hop()], "yeast": _make_test_yeast(), "adjuncts": []}
	var sliders: Dictionary = {"mashing": 65.0, "boiling": 60.0, "fermenting": 20.0}
	var result: Dictionary = GameState.execute_brew(sliders)
	assert_has(result, "infected", "Brew result should have infected flag")
	assert_has(result, "off_flavor_tags", "Brew result should have off_flavor_tags")
	assert_has(result, "failure_messages", "Brew result should have failure_messages")

func test_execute_brew_perfect_stats_preserves_score() -> void:
	GameState.reset()
	GameState.balance = 5000.0
	GameState.sanitation_quality = 100
	GameState.temp_control_quality = 100
	GameState.current_style = _make_test_style()
	GameState.current_recipe = {"malts": [_make_test_malt()], "hops": [_make_test_hop()], "yeast": _make_test_yeast(), "adjuncts": []}
	var sliders: Dictionary = {"mashing": 65.0, "boiling": 60.0, "fermenting": 20.0}
	var result: Dictionary = GameState.execute_brew(sliders)
	assert_false(result["infected"], "Perfect sanitation should not cause infection")
	assert_eq(result["off_flavor_tags"].size(), 0, "Perfect temp control should produce no off-flavors")
```

**Step 2: Run tests to verify they fail**

Run: `make test`
Expected: FAIL — result missing `infected`, `off_flavor_tags` keys

**Step 3: Integrate FailureSystem into execute_brew**

In `src/autoloads/GameState.gd`, in the `execute_brew()` method, after `QualityCalculator.calculate_quality()` and before `calculate_revenue()`, add failure rolls:

```gdscript
	# Failure mode rolls (Stage 1C)
	var failure_result: Dictionary = FailureSystem.roll_failures(
		result["final_score"], sanitation_quality, temp_control_quality
	)
	result["final_score"] = failure_result["final_score"]
	result["infected"] = failure_result["infected"]
	result["infection_message"] = failure_result["infection_message"]
	result["off_flavor_tags"] = failure_result["off_flavor_tags"]
	result["off_flavor_message"] = failure_result["off_flavor_message"]
	result["failure_messages"] = failure_result["failure_messages"]
```

Important: this must go BEFORE `calculate_revenue()` so the penalized score affects revenue.

**Step 4: Run tests to verify they pass**

Run: `make test`
Expected: PASS — all tests including existing 121+ tests

**Step 5: Commit**

```
feat: integrate failure rolls into execute_brew pipeline
```

---

### Task 7: Add QA checkpoint toast notifications

**Files:**
- Modify: `src/autoloads/FailureSystem.gd` (add QA checkpoint methods)
- Modify: `src/autoloads/GameState.gd` (fire toasts during execute_brew)
- Test: `src/tests/test_failure_modes.gd` (add tests)

**Step 1: Write failing tests for QA checkpoint data**

Add to `src/tests/test_failure_modes.gd`:

```gdscript
# ---------------------------------------------------------------------------
# QA checkpoints
# ---------------------------------------------------------------------------

func test_pre_boil_gravity_check_returns_reading() -> void:
	var check: Dictionary = FailureSystem.calc_pre_boil_gravity(65.0)
	assert_has(check, "og", "Pre-boil check should have og reading")
	assert_has(check, "assessment", "Pre-boil check should have assessment")

func test_pre_boil_gravity_normal_mash_temp() -> void:
	var check: Dictionary = FailureSystem.calc_pre_boil_gravity(65.0)
	assert_eq(check["assessment"], "normal", "65°C mash should give normal efficiency")

func test_boil_vigor_check_returns_reading() -> void:
	var check: Dictionary = FailureSystem.calc_boil_vigor(60.0)
	assert_has(check, "vigor", "Boil check should have vigor reading")
	assert_has(check, "assessment", "Boil check should have assessment")

func test_boil_vigor_short_boil_warns() -> void:
	var check: Dictionary = FailureSystem.calc_boil_vigor(30.0)
	assert_eq(check["assessment"], "low", "30 min boil should warn about low vigor")

func test_final_gravity_check_returns_reading() -> void:
	var check: Dictionary = FailureSystem.calc_final_gravity(65.0, 0.75)
	assert_has(check, "fg", "Final gravity check should have fg reading")
	assert_has(check, "attenuation_pct", "Final gravity check should have attenuation %")
	assert_has(check, "assessment", "Final gravity check should have assessment")
```

**Step 2: Run tests to verify they fail**

Run: `make test`
Expected: FAIL

**Step 3: Implement QA checkpoint calculations**

Add to `src/autoloads/FailureSystem.gd`:

```gdscript
# ---------------------------------------------------------------------------
# QA Checkpoints
# ---------------------------------------------------------------------------

## Pre-boil gravity estimate from mash temperature.
## Lower mash temp -> higher fermentability -> lower OG estimate (more sugars converted).
static func calc_pre_boil_gravity(mash_temp_c: float) -> Dictionary:
	# Estimate OG: base 1.050, higher mash temp = slightly higher OG
	var og: float = 1.050 + (mash_temp_c - 65.0) * 0.002
	var assessment: String = "normal"
	if og < 1.045:
		assessment = "low"
	elif og > 1.060:
		assessment = "high"
	return {"og": snapped(og, 0.001), "assessment": assessment}

## Boil vigor assessment from boil duration.
static func calc_boil_vigor(boil_min: float) -> Dictionary:
	var vigor: String = "good"
	var assessment: String = "normal"
	if boil_min < 45.0:
		vigor = "weak"
		assessment = "low"
	elif boil_min >= 75.0:
		vigor = "strong"
		assessment = "high"
	var dms_note: String = "DMS driven off" if boil_min >= 60.0 else "DMS risk — consider longer boil"
	return {"vigor": vigor, "assessment": assessment, "dms_note": dms_note}

## Final gravity estimate from mash temp and yeast attenuation.
static func calc_final_gravity(mash_temp_c: float, yeast_attenuation: float) -> Dictionary:
	var og: float = 1.050 + (mash_temp_c - 65.0) * 0.002
	var fg: float = og - (og - 1.0) * yeast_attenuation
	var attenuation_pct: float = ((og - fg) / (og - 1.0)) * 100.0
	var assessment: String = "normal"
	if attenuation_pct < 65.0:
		assessment = "low"
	elif attenuation_pct > 85.0:
		assessment = "high"
	return {"fg": snapped(fg, 0.001), "attenuation_pct": snapped(attenuation_pct, 1.0), "assessment": assessment}
```

**Step 4: Run tests to verify they pass**

Run: `make test`
Expected: PASS

**Step 5: Fire QA toasts from execute_brew**

In `src/autoloads/GameState.gd`, in `execute_brew()`, after the QualityCalculator call but before the failure rolls, add:

```gdscript
	# QA checkpoint toasts (Stage 1C)
	if is_instance_valid(ToastManager):
		var mash_temp: float = sliders.get("mashing", 65.0)
		var boil_min: float = sliders.get("boiling", 60.0)
		var yeast: Yeast = current_recipe.get("yeast", null) as Yeast

		var pre_boil: Dictionary = FailureSystem.calc_pre_boil_gravity(mash_temp)
		ToastManager.show_toast("Pre-Boil Gravity: OG %s — %s efficiency" % [pre_boil["og"], pre_boil["assessment"].capitalize()])

		var boil_check: Dictionary = FailureSystem.calc_boil_vigor(boil_min)
		ToastManager.show_toast("Boil Vigor: %s — %s" % [boil_check["vigor"].capitalize(), boil_check["dms_note"]])

		if yeast != null:
			var fg_check: Dictionary = FailureSystem.calc_final_gravity(mash_temp, yeast.attenuation)
			ToastManager.show_toast("Final Gravity: FG %s — Attenuation: %s%%" % [fg_check["fg"], fg_check["attenuation_pct"]])
```

**Step 6: Run all tests**

Run: `make test`
Expected: PASS — all tests including existing ones

**Step 7: Commit**

```
feat: add QA checkpoint toasts during brewing (pre-boil, boil vigor, final gravity)
```

---

### Task 8: Update ResultsOverlay to show failure panels

**Files:**
- Modify: `src/ui/ResultsOverlay.gd`
- Modify: `src/ui/ResultsOverlay.tscn` (add failure panel containers)

**Step 1: Add failure panel container nodes to the scene**

In `src/ui/ResultsOverlay.tscn`, add two VBoxContainer nodes (InfectionPanel, OffFlavorPanel) inside the main VBox, between ScorePanel and MoneyRow. These will be created programmatically in code for simplicity.

**Step 2: Add failure display logic to ResultsOverlay.gd**

In `src/ui/ResultsOverlay.gd`, add instance variables and populate logic:

Add after existing `@onready` declarations:
```gdscript
var failure_container: VBoxContainer = null
```

In `populate()`, after the quality score section and before the revenue section, add:

```gdscript
	# Failure panels (Stage 1C)
	_clear_failure_panels()
	var infected: bool = result.get("infected", false)
	var off_flavor_tags: Array = result.get("off_flavor_tags", [])

	if infected or off_flavor_tags.size() > 0:
		_create_failure_container()

	if infected:
		var infection_msg: String = result.get("infection_message", "Bacteria contaminated your batch.")
		_add_failure_panel("INFECTION DETECTED", infection_msg,
			"Upgrade your sanitation equipment to reduce infection risk.")

	if off_flavor_tags.size() > 0:
		var off_flavor_msg: String = result.get("off_flavor_message", "Off-flavors detected.")
		var tip: String = "Better temperature control during fermentation helps avoid off-flavors."
		if off_flavor_tags.has("dms"):
			tip = "A longer, more vigorous boil drives off DMS precursors."
		_add_failure_panel("OFF-FLAVORS DETECTED", off_flavor_msg, tip)
```

Add helper methods:

```gdscript
func _clear_failure_panels() -> void:
	if failure_container != null:
		failure_container.queue_free()
		failure_container = null

func _create_failure_container() -> void:
	failure_container = VBoxContainer.new()
	failure_container.name = "FailureContainer"
	failure_container.add_theme_constant_override("separation", 8)
	# Insert after ScorePanel (index 2 in VBox children)
	var vbox: VBoxContainer = $CardPanel/MarginContainer/VBox
	var score_panel_idx: int = score_label.get_parent().get_parent().get_index()
	vbox.add_child(failure_container)
	vbox.move_child(failure_container, score_panel_idx + 1)

func _add_failure_panel(title_text: String, description: String, tip: String) -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#FF7B7B", 0.1)
	style.border_color = Color("#FF7B7B", 0.4)
	style.border_width_left = 4
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#FF7B7B"))
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = description
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color("#8A9BB1"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	var tip_label := Label.new()
	tip_label.text = "Tip: %s" % tip
	tip_label.add_theme_font_size_override("font_size", 16)
	tip_label.add_theme_color_override("font_color", Color("#5AA9FF"))
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(tip_label)

	panel.add_child(vbox)
	failure_container.add_child(panel)
```

**Step 3: Run all tests**

Run: `make test`
Expected: PASS — all existing tests still pass (UI code not tested by GUT directly)

**Step 4: Commit**

```
feat: add failure mode panels to ResultsOverlay (infection and off-flavor display)
```

---

### Task 9: Write comprehensive edge case tests

**Files:**
- Modify: `src/tests/test_failure_modes.gd` (add edge case tests)

**Step 1: Write edge case tests**

Add to `src/tests/test_failure_modes.gd`:

```gdscript
# ---------------------------------------------------------------------------
# Edge cases
# ---------------------------------------------------------------------------

func test_infection_and_off_flavor_can_stack() -> void:
	# At sanitation=0, temp_control=0, both have 50% chance
	# Over many rolls, both should occur at least once together
	var both_count: int = 0
	for i in range(500):
		var result: Dictionary = FailureSystem.roll_failures(100.0, 0, 0)
		if result["infected"] and result["off_flavor_tags"].size() > 0:
			both_count += 1
	assert_gt(both_count, 0, "Infection and off-flavor should be able to stack")

func test_stacked_penalties_severely_reduce_score() -> void:
	# When both hit, score should be significantly reduced
	var found_both: bool = false
	for i in range(500):
		var result: Dictionary = FailureSystem.roll_failures(100.0, 0, 0)
		if result["infected"] and result["off_flavor_tags"].size() > 0:
			# Infection: 40-60% then off-flavor: 70-85% of that
			# Worst case: 100 * 0.4 * 0.7 = 28, best: 100 * 0.6 * 0.85 = 51
			assert_lte(result["final_score"], 51.0, "Stacked penalties should severely reduce score")
			assert_gte(result["final_score"], 28.0, "Score should not go below minimum penalty range")
			found_both = true
			break
	assert_true(found_both, "Should find stacked failure in 500 rolls at stat=0")

func test_zero_score_stays_zero_after_failures() -> void:
	var result: Dictionary = FailureSystem.roll_failures(0.0, 0, 0)
	assert_gte(result["final_score"], 0.0, "Score should never go negative")

func test_infection_chance_at_zero_sanitation() -> void:
	var chance: float = FailureSystem.calc_infection_chance(0)
	assert_almost_eq(chance, 0.5, 0.01, "Sanitation 0 should give 50% infection chance")

func test_pre_boil_gravity_extreme_temps() -> void:
	var low: Dictionary = FailureSystem.calc_pre_boil_gravity(62.0)
	var high: Dictionary = FailureSystem.calc_pre_boil_gravity(69.0)
	assert_lt(low["og"], high["og"], "Lower mash temp should give lower OG")

func test_final_gravity_high_attenuation_yeast() -> void:
	var check: Dictionary = FailureSystem.calc_final_gravity(65.0, 0.90)
	assert_eq(check["assessment"], "high", "90% attenuation should be assessed as high")
```

**Step 2: Run tests to verify they pass**

Run: `make test`
Expected: PASS — all tests

**Step 3: Commit**

```
test: add comprehensive edge case tests for failure modes
```

---

### Task 10: Final verification and cleanup

**Step 1: Run full test suite**

Run: `make test`
Expected: ALL PASS — verify exact count (should be ~140+ total)

**Step 2: Verify the autoload is registered**

Check `src/project.godot` includes:
```
FailureSystem="*res://autoloads/FailureSystem.gd"
```

**Step 3: Update project CLAUDE.md**

In `projects/beerbrew-tycoon/CLAUDE.md`, update the Project State section:
- Mark Stage 1C as complete
- Update test count
- Set next stage

**Step 4: Commit**

```
docs: mark Stage 1C (Failure Modes & QA) complete
```
