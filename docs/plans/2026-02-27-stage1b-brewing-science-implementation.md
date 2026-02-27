# Stage 1B: Brewing Science — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add brewing science calculations, physical slider UI, taste skill, and discovery system to BeerBrew Tycoon.

**Architecture:** New `BrewingScience` autoload handles all science calculations (fermentability, hop utilization, yeast accuracy, noise). `TasteSystem` autoload manages taste skill progression and discovery rolls. GameState gets new state fields. QualityCalculator gains a brewing science scoring component. BrewingPhases UI switches from abstract 0-100 sliders to real physical units. ResultsOverlay adds taste-gated tasting notes.

**Tech Stack:** Godot 4 / GDScript, GUT testing framework, Resource-based data model

**Stack Profile:** Read `../../stacks/godot/STACK.md` before any implementation. Key rules: explicit types always, never `:=` on `Dictionary.get()`, `type="Resource"` in `.tres` files, scripts under 300 lines.

**Run tests:** `cd /Users/gregario/Projects/ClaudeCode/AI-Factory/projects/beerbrew-tycoon && make test`

---

## Task 1: Add `ideal_mash_temp` and `ideal_boil_range` to BeerStyle

BeerStyle needs new fields so the brewing science engine can score style-appropriate mash temp and boil duration.

**Files:**
- Modify: `src/scripts/BeerStyle.gd`
- Modify: `src/data/styles/pale_ale.tres`
- Modify: `src/data/styles/stout.tres`
- Modify: `src/data/styles/lager.tres`
- Modify: `src/data/styles/wheat_beer.tres`
- Test: `src/tests/test_brewing_science.gd` (new file)

**Step 1: Write the failing test**

Create `src/tests/test_brewing_science.gd`:

```gdscript
## Tests for Brewing Science system.
extends GutTest

func test_beer_style_has_ideal_mash_temp_range():
	var style := BeerStyle.new()
	style.ideal_mash_temp_min = 62.0
	style.ideal_mash_temp_max = 64.0
	assert_eq(style.ideal_mash_temp_min, 62.0)
	assert_eq(style.ideal_mash_temp_max, 64.0)

func test_beer_style_has_ideal_boil_range():
	var style := BeerStyle.new()
	style.ideal_boil_min = 60.0
	style.ideal_boil_max = 90.0
	assert_eq(style.ideal_boil_min, 60.0)
	assert_eq(style.ideal_boil_max, 90.0)
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — `ideal_mash_temp_min` property doesn't exist on BeerStyle

**Step 3: Add new fields to BeerStyle.gd**

Add to `src/scripts/BeerStyle.gd` after the `ideal_flavor_profile` export (line 32):

```gdscript
## Ideal mash temperature range for this style (°C). Used by BrewingScience.
@export var ideal_mash_temp_min: float = 64.0
@export var ideal_mash_temp_max: float = 66.0

## Ideal boil duration range for this style (minutes). Used by BrewingScience.
@export var ideal_boil_min: float = 50.0
@export var ideal_boil_max: float = 70.0
```

**Step 4: Update all four .tres style files**

Add to each `.tres` file before the closing (after `ideal_flavor_profile`):

- `pale_ale.tres`: `ideal_mash_temp_min = 63.0`, `ideal_mash_temp_max = 66.0`, `ideal_boil_min = 60.0`, `ideal_boil_max = 90.0`
- `stout.tres`: `ideal_mash_temp_min = 66.0`, `ideal_mash_temp_max = 69.0`, `ideal_boil_min = 60.0`, `ideal_boil_max = 90.0`
- `lager.tres`: `ideal_mash_temp_min = 62.0`, `ideal_mash_temp_max = 65.0`, `ideal_boil_min = 60.0`, `ideal_boil_max = 90.0`
- `wheat_beer.tres`: `ideal_mash_temp_min = 64.0`, `ideal_mash_temp_max = 67.0`, `ideal_boil_min = 30.0`, `ideal_boil_max = 60.0`

**Step 5: Run tests to verify they pass**

Run: `make test`
Expected: PASS — new properties exist and hold values

**Step 6: Commit**

```bash
git add src/scripts/BeerStyle.gd src/data/styles/*.tres src/tests/test_brewing_science.gd
git commit -m "feat(1B): add ideal mash temp and boil range to BeerStyle"
```

---

## Task 2: Create BrewingScience autoload — core calculations

The BrewingScience autoload calculates fermentability, hop utilization, and yeast accuracy from physical slider values. All methods are static/stateless.

**Files:**
- Create: `src/autoloads/BrewingScience.gd`
- Modify: `src/tests/test_brewing_science.gd`
- Modify: `src/project.godot` (add autoload)

**Step 1: Write the failing tests**

Add to `src/tests/test_brewing_science.gd`:

```gdscript
# ---------------------------------------------------------------------------
# Fermentability curve
# ---------------------------------------------------------------------------

func test_low_mash_temp_gives_high_fermentability():
	var result: float = BrewingScience.calc_fermentability(62.0)
	assert_almost_eq(result, 0.82, 0.01, "62°C should give ~0.82 fermentability")

func test_high_mash_temp_gives_low_fermentability():
	var result: float = BrewingScience.calc_fermentability(69.0)
	assert_almost_eq(result, 0.57, 0.01, "69°C should give ~0.57 fermentability")

func test_mid_mash_temp_gives_mid_fermentability():
	var result: float = BrewingScience.calc_fermentability(65.0)
	var expected: float = 0.82 - ((65.0 - 62.0) / 7.0 * 0.25)
	assert_almost_eq(result, expected, 0.01)

# ---------------------------------------------------------------------------
# Hop utilization
# ---------------------------------------------------------------------------

func test_long_boil_gives_high_bittering():
	var result: Dictionary = BrewingScience.calc_hop_utilization(90.0, 6.0)
	assert_gt(result["bittering"], result["aroma"], "90 min boil should favor bittering")

func test_short_boil_gives_high_aroma():
	var result: Dictionary = BrewingScience.calc_hop_utilization(30.0, 6.0)
	assert_gt(result["aroma"], result["bittering"], "30 min boil should favor aroma")

func test_hop_util_scales_with_alpha_acid():
	var low_aa: Dictionary = BrewingScience.calc_hop_utilization(60.0, 4.0)
	var high_aa: Dictionary = BrewingScience.calc_hop_utilization(60.0, 10.0)
	assert_gt(high_aa["bittering"], low_aa["bittering"], "Higher alpha acid = more bittering")

# ---------------------------------------------------------------------------
# Yeast accuracy
# ---------------------------------------------------------------------------

func _make_test_yeast(temp_min: float, temp_max: float) -> Yeast:
	var y := Yeast.new()
	y.ingredient_id = "test_yeast"
	y.ideal_temp_min_c = temp_min
	y.ideal_temp_max_c = temp_max
	return y

func test_ferment_temp_in_ideal_range_gives_full_bonus():
	var yeast := _make_test_yeast(18.0, 22.0)
	var result: Dictionary = BrewingScience.calc_yeast_accuracy(20.0, yeast)
	assert_eq(result["quality_bonus"], 1.0, "In-range temp should give 1.0 bonus")
	assert_eq(result["off_flavors"].size(), 0, "No off-flavors in ideal range")

func test_ferment_temp_slightly_outside_gives_mild_penalty():
	var yeast := _make_test_yeast(18.0, 22.0)
	var result: Dictionary = BrewingScience.calc_yeast_accuracy(24.0, yeast)
	assert_almost_eq(result["quality_bonus"], 0.85, 0.01, "1-2°C outside should give 0.85")

func test_ferment_temp_far_above_gives_heavy_penalty():
	var yeast := _make_test_yeast(18.0, 22.0)
	var result: Dictionary = BrewingScience.calc_yeast_accuracy(25.0, yeast)
	assert_almost_eq(result["quality_bonus"], 0.6, 0.01, "3°C+ above should give 0.6")
	assert_true(result["off_flavors"].has("fruity_esters") or result["off_flavors"].has("fusel_alcohols"),
		"Should have ester or fusel off-flavors")

func test_ferment_temp_far_below_gives_heavy_penalty():
	var yeast := _make_test_yeast(18.0, 22.0)
	var result: Dictionary = BrewingScience.calc_yeast_accuracy(15.0, yeast)
	assert_almost_eq(result["quality_bonus"], 0.6, 0.01, "3°C+ below should give 0.6")
	assert_true(result["off_flavors"].has("stalled_ferment"),
		"Should have stalling off-flavor")

# ---------------------------------------------------------------------------
# Equipment noise
# ---------------------------------------------------------------------------

func test_garage_equipment_adds_drift():
	# With temp_control_quality=50, drift = ±2°C
	var drift: float = BrewingScience.calc_temp_drift(50)
	assert_almost_eq(absf(drift), 0.0, 2.01, "Garage drift should be within ±2°C")

func test_perfect_equipment_no_drift():
	var drift: float = BrewingScience.calc_temp_drift(100)
	assert_eq(drift, 0.0, "Perfect equipment should have no drift")

# ---------------------------------------------------------------------------
# Stochastic noise
# ---------------------------------------------------------------------------

func test_stochastic_noise_within_bounds():
	# Run multiple times, all should be within ±5%
	for i in range(20):
		var noised: float = BrewingScience.apply_noise(1.0, i)
		assert_gte(noised, 0.95, "Noised value should be >= 0.95")
		assert_lte(noised, 1.05, "Noised value should be <= 1.05")

func test_same_seed_gives_same_noise():
	var a: float = BrewingScience.apply_noise(1.0, 42)
	var b: float = BrewingScience.apply_noise(1.0, 42)
	assert_eq(a, b, "Same seed should produce same noise")

# ---------------------------------------------------------------------------
# Mash temp scoring (distance from style ideal)
# ---------------------------------------------------------------------------

func test_mash_score_perfect_temp():
	var style := BeerStyle.new()
	style.ideal_mash_temp_min = 66.0
	style.ideal_mash_temp_max = 68.0
	var score: float = BrewingScience.calc_mash_score(67.0, style)
	assert_almost_eq(score, 1.0, 0.01, "Temp in ideal range should score 1.0")

func test_mash_score_outside_range():
	var style := BeerStyle.new()
	style.ideal_mash_temp_min = 66.0
	style.ideal_mash_temp_max = 68.0
	var score: float = BrewingScience.calc_mash_score(62.0, style)
	assert_lt(score, 0.6, "Temp far outside ideal should score low")

# ---------------------------------------------------------------------------
# Boil duration scoring
# ---------------------------------------------------------------------------

func test_boil_score_perfect_duration():
	var style := BeerStyle.new()
	style.ideal_boil_min = 60.0
	style.ideal_boil_max = 90.0
	var score: float = BrewingScience.calc_boil_score(70.0, style)
	assert_almost_eq(score, 1.0, 0.01, "Duration in ideal range should score 1.0")

func test_boil_score_outside_range():
	var style := BeerStyle.new()
	style.ideal_boil_min = 60.0
	style.ideal_boil_max = 90.0
	var score: float = BrewingScience.calc_boil_score(30.0, style)
	assert_lt(score, 0.6, "Duration far outside ideal should score low")
```

**Step 2: Run tests to verify they fail**

Run: `make test`
Expected: FAIL — `BrewingScience` autoload not found

**Step 3: Create `src/autoloads/BrewingScience.gd`**

```gdscript
extends Node

## BrewingScience — pure brewing science calculations.
## All methods are stateless. Converts physical slider values (temp, time)
## into quality-relevant outputs (fermentability, hop utilization, yeast accuracy).

# ---------------------------------------------------------------------------
# Fermentability (mashing)
# ---------------------------------------------------------------------------

## Calculates fermentability from mash temperature.
## 62°C → 0.82 (dry/crisp), 69°C → 0.57 (full/sweet).
static func calc_fermentability(mash_temp_c: float) -> float:
	return 0.82 - ((mash_temp_c - 62.0) / 7.0 * 0.25)

# ---------------------------------------------------------------------------
# Hop utilization (boiling)
# ---------------------------------------------------------------------------

## Calculates hop bittering and aroma from boil duration and alpha acid.
## Returns { "bittering": float, "aroma": float }.
static func calc_hop_utilization(boil_min: float, alpha_acid_pct: float) -> Dictionary:
	var utilization: float = boil_min / 90.0
	var bittering: float = alpha_acid_pct * utilization
	var aroma: float = alpha_acid_pct * (1.0 - utilization)
	return {"bittering": bittering, "aroma": aroma}

# ---------------------------------------------------------------------------
# Yeast accuracy (fermenting)
# ---------------------------------------------------------------------------

## Calculates quality bonus and off-flavors based on fermentation temp vs yeast range.
## Returns { "quality_bonus": float, "off_flavors": Array[String] }.
static func calc_yeast_accuracy(ferment_temp_c: float, yeast: Yeast) -> Dictionary:
	var off_flavors: Array[String] = []
	var quality_bonus: float = 1.0

	if ferment_temp_c >= yeast.ideal_temp_min_c and ferment_temp_c <= yeast.ideal_temp_max_c:
		quality_bonus = 1.0
	else:
		var distance: float = 0.0
		if ferment_temp_c > yeast.ideal_temp_max_c:
			distance = ferment_temp_c - yeast.ideal_temp_max_c
		else:
			distance = yeast.ideal_temp_min_c - ferment_temp_c

		if distance <= 2.0:
			quality_bonus = 0.85
		else:
			quality_bonus = 0.6
			if ferment_temp_c > yeast.ideal_temp_max_c:
				if distance >= 5.0:
					off_flavors.append("fusel_alcohols")
				else:
					off_flavors.append("fruity_esters")
			else:
				off_flavors.append("stalled_ferment")

	return {"quality_bonus": quality_bonus, "off_flavors": off_flavors}

# ---------------------------------------------------------------------------
# Equipment noise
# ---------------------------------------------------------------------------

## Calculates temperature drift based on equipment quality (0-100).
## Garage (50) = ±2°C, Perfect (100) = ±0°C.
static func calc_temp_drift(temp_control_quality: int) -> float:
	var max_drift: float = float(100 - temp_control_quality) / 25.0
	if max_drift <= 0.0:
		return 0.0
	return randf_range(-max_drift, max_drift)

# ---------------------------------------------------------------------------
# Stochastic noise
# ---------------------------------------------------------------------------

## Applies ±5% multiplicative noise to a value. Seeded for reproducibility.
static func apply_noise(value: float, brew_seed: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = brew_seed
	return value * rng.randf_range(0.95, 1.05)

# ---------------------------------------------------------------------------
# Style scoring helpers
# ---------------------------------------------------------------------------

## Scores mash temp against style's ideal range. Returns 0.0-1.0.
## Perfect = in range, penalty = distance outside range / 7.0 (full slider range).
static func calc_mash_score(mash_temp_c: float, style: BeerStyle) -> float:
	if mash_temp_c >= style.ideal_mash_temp_min and mash_temp_c <= style.ideal_mash_temp_max:
		return 1.0
	var distance: float = 0.0
	if mash_temp_c < style.ideal_mash_temp_min:
		distance = style.ideal_mash_temp_min - mash_temp_c
	else:
		distance = mash_temp_c - style.ideal_mash_temp_max
	return maxf(0.0, 1.0 - (distance / 7.0))

## Scores boil duration against style's ideal range. Returns 0.0-1.0.
## Perfect = in range, penalty = distance outside range / 60.0 (full slider range).
static func calc_boil_score(boil_min: float, style: BeerStyle) -> float:
	if boil_min >= style.ideal_boil_min and boil_min <= style.ideal_boil_max:
		return 1.0
	var distance: float = 0.0
	if boil_min < style.ideal_boil_min:
		distance = style.ideal_boil_min - boil_min
	else:
		distance = boil_min - style.ideal_boil_max
	return maxf(0.0, 1.0 - (distance / 60.0))

# ---------------------------------------------------------------------------
# Flavor attribute detection (for discovery system)
# ---------------------------------------------------------------------------

## Determines which flavor attributes are present in this brew's output.
## Returns Array[String] of attribute keys from the discovery pool.
static func detect_brew_attributes(mash_temp_c: float, boil_min: float, ferment_temp_c: float, yeast: Yeast, hops: Array) -> Array[String]:
	var attributes: Array[String] = []

	# Body attributes from mash temp
	if mash_temp_c <= 63.0:
		attributes.append("dry_body")
	elif mash_temp_c <= 64.0:
		attributes.append("crisp_body")
	elif mash_temp_c <= 66.0:
		attributes.append("medium_body")
	elif mash_temp_c <= 68.0:
		attributes.append("full_body")
	else:
		attributes.append("sweet_body")

	# Bitterness attributes from boil duration
	if boil_min <= 40.0:
		attributes.append("low_bitter")
	elif boil_min <= 70.0:
		attributes.append("balanced_bitter")
	else:
		attributes.append("assertive_bitter")

	# Aroma attributes from boil duration + hop variety
	if boil_min <= 50.0:
		for hop in hops:
			if hop is Hop:
				var family: String = hop.variety_family if hop.variety_family != "" else "neutral"
				if family == "american":
					attributes.append("citrus_aroma")
				elif family == "english":
					attributes.append("earthy_aroma")
				elif family == "noble":
					attributes.append("floral_aroma")
				elif family == "pacific":
					attributes.append("piney_aroma")
				else:
					attributes.append("spicy_aroma")

	# Fermentation attributes from yeast accuracy
	var yeast_result: Dictionary = calc_yeast_accuracy(ferment_temp_c, yeast)
	if yeast_result["off_flavors"].size() == 0:
		attributes.append("clean_ferment")
	for off_flavor in yeast_result["off_flavors"]:
		attributes.append(off_flavor)

	return attributes
```

**Step 4: Register autoload in project.godot**

Add `BrewingScience` as an autoload in `src/project.godot` in the `[autoload]` section:
```
BrewingScience="*res://autoloads/BrewingScience.gd"
```

**Step 5: Run tests to verify they pass**

Run: `make test`
Expected: ALL PASS

**Step 6: Commit**

```bash
git add src/autoloads/BrewingScience.gd src/tests/test_brewing_science.gd src/project.godot
git commit -m "feat(1B): add BrewingScience autoload with core calculations"
```

---

## Task 3: Integrate BrewingScience into QualityCalculator

Add a brewing science scoring component to QualityCalculator. The existing scoring weights shift to make room for the new component.

**Files:**
- Modify: `src/autoloads/QualityCalculator.gd`
- Modify: `src/tests/test_quality_calculator.gd`

**Step 1: Write the failing tests**

Add to `src/tests/test_quality_calculator.gd`:

```gdscript
# ---------------------------------------------------------------------------
# Tests: brewing science scoring component
# ---------------------------------------------------------------------------

func _make_style_with_science(style_id: String, ideal_flavor_ratio: float,
		mash_min: float, mash_max: float, boil_min: float, boil_max: float) -> BeerStyle:
	var s := _make_style(style_id, ideal_flavor_ratio)
	s.ideal_mash_temp_min = mash_min
	s.ideal_mash_temp_max = mash_max
	s.ideal_boil_min = boil_min
	s.ideal_boil_max = boil_max
	return s

func _make_yeast_with_temp(id: String, temp_min: float, temp_max: float) -> Yeast:
	var y := _make_yeast_res(id, _default_fp)
	y.ideal_temp_min_c = temp_min
	y.ideal_temp_max_c = temp_max
	return y

func test_result_has_science_score():
	var style := _make_style_with_science("test", 0.5, 64.0, 66.0, 50.0, 70.0)
	var recipe := _make_neutral_recipe("test")
	recipe["yeast"] = _make_yeast_with_temp("test_yeast", 18.0, 22.0)
	var sliders := {"mashing": 65.0, "boiling": 60.0, "fermenting": 20.0}
	var result := QualityCalculator.calculate_quality(style, recipe, sliders, [])
	assert_has(result, "science_score")

func test_perfect_science_scores_high():
	var style := _make_style_with_science("stout", 0.45, 66.0, 69.0, 60.0, 90.0)
	var recipe := _make_neutral_recipe("stout")
	recipe["yeast"] = _make_yeast_with_temp("test_yeast", 18.0, 22.0)
	# Perfect: mash=67 (in 66-69), boil=70 (in 60-90), ferment=20 (in 18-22)
	var sliders := {"mashing": 67.0, "boiling": 70.0, "fermenting": 20.0}
	var result := QualityCalculator.calculate_quality(style, recipe, sliders, [])
	assert_gte(result["science_score"], 90.0, "Perfect science should score high")

func test_bad_science_scores_low():
	var style := _make_style_with_science("stout", 0.45, 66.0, 69.0, 60.0, 90.0)
	var recipe := _make_neutral_recipe("stout")
	recipe["yeast"] = _make_yeast_with_temp("test_yeast", 18.0, 22.0)
	# Bad: mash=62 (far from 66-69), boil=30 (outside 60-90), ferment=25 (3°C above 22)
	var sliders := {"mashing": 62.0, "boiling": 30.0, "fermenting": 25.0}
	var result := QualityCalculator.calculate_quality(style, recipe, sliders, [])
	assert_lte(result["science_score"], 50.0, "Bad science should score low")

func test_science_affects_final_score():
	var style := _make_style_with_science("test", 0.5, 64.0, 66.0, 50.0, 70.0)
	var recipe := _make_neutral_recipe("test")
	recipe["yeast"] = _make_yeast_with_temp("test_yeast", 18.0, 22.0)
	# Good science
	var good_sliders := {"mashing": 65.0, "boiling": 60.0, "fermenting": 20.0}
	# Bad science
	var bad_sliders := {"mashing": 62.0, "boiling": 30.0, "fermenting": 25.0}
	var good_result := QualityCalculator.calculate_quality(style, recipe, good_sliders, [])
	var bad_result := QualityCalculator.calculate_quality(style, recipe, bad_sliders, [])
	assert_gt(good_result["final_score"], bad_result["final_score"],
		"Good brewing science should improve final score")
```

**Step 2: Run tests to verify they fail**

Run: `make test`
Expected: FAIL — `science_score` key not in result

**Step 3: Modify QualityCalculator.gd**

Update the weight constants (lines 15-18):
```gdscript
const WEIGHT_RATIO: float = 0.40        # was 0.50
const WEIGHT_INGREDIENTS: float = 0.20   # was 0.25
const WEIGHT_NOVELTY: float = 0.10       # was 0.15
const WEIGHT_BASE: float = 0.10          # unchanged
const WEIGHT_SCIENCE: float = 0.20       # NEW
```

Add to `calculate_quality()` method — after ingredient score calculation, before final weighted sum:

```gdscript
# Brewing science score
var science_score: float = _compute_science_score(style, recipe, sliders)
```

Add to the weighted sum:
```gdscript
var final_score: float = (
	ratio_score * WEIGHT_RATIO +
	ingredient_score * WEIGHT_INGREDIENTS +
	novelty_score * WEIGHT_NOVELTY +
	base_score * WEIGHT_BASE +
	science_score * WEIGHT_SCIENCE
)
```

Add `"science_score": science_score` to the return dictionary.

Add the new private method:

```gdscript
## Computes brewing science score from physical slider parameters.
## Evaluates mash temp, boil duration, and ferment temp appropriateness.
func _compute_science_score(style: BeerStyle, recipe: Dictionary, sliders: Dictionary) -> float:
	var mash_temp: float = sliders.get("mashing", 65.0)
	var boil_duration: float = sliders.get("boiling", 60.0)
	var ferment_temp: float = sliders.get("fermenting", 20.0)

	# Mash temp scoring (33%)
	var mash_score: float = BrewingScience.calc_mash_score(mash_temp, style)

	# Boil duration scoring (33%)
	var boil_score: float = BrewingScience.calc_boil_score(boil_duration, style)

	# Yeast accuracy scoring (34%)
	var yeast: Yeast = recipe.get("yeast", null) as Yeast
	var yeast_score: float = 0.5
	if yeast != null:
		var yeast_result: Dictionary = BrewingScience.calc_yeast_accuracy(ferment_temp, yeast)
		yeast_score = yeast_result["quality_bonus"]

	return (mash_score * 33.0 + boil_score * 33.0 + yeast_score * 34.0)
```

**Step 4: Run tests to verify they pass**

Run: `make test`
Expected: ALL PASS (existing tests may need slider value adjustments — see step 5)

**Step 5: Fix any existing test failures**

Existing tests use sliders with values `0.0-100.0`. With the new science scoring, these abstract values will now be interpreted as physical parameters (e.g., mashing=0.0 would mean 0°C, which is nonsensical). The existing tests need their slider values to remain in the 0-100 range since `_compute_points()` still uses 0-100 for flavor/technique calculations.

**Important**: The `_compute_science_score` method reads sliders directly. Existing tests pass `{"mashing": 50.0, ...}` which would mean 50°C for mash temp — that's outside the 62-69 range and would score 0. We need to handle this gracefully:

In `_compute_science_score`, if the BeerStyle doesn't have the new fields set (they default to 64-66), the scoring still works. The existing test helper `_make_style()` creates BeerStyle with defaults, so mash 50°C would score low. **This is expected** — existing tests verify relative comparisons (greater/less than), not absolute values, so they should still pass.

Run the tests and fix any that break due to the weight rebalancing. The most likely issue: `test_perfect_ratio_scores_high` might shift due to lower WEIGHT_RATIO (0.40 vs 0.50).

**Step 6: Commit**

```bash
git add src/autoloads/QualityCalculator.gd src/tests/test_quality_calculator.gd
git commit -m "feat(1B): add brewing science scoring component to QualityCalculator"
```

---

## Task 4: Update BrewingPhases UI — physical slider ranges

Change the sliders from abstract 0-100 to real physical units with discrete stops.

**Files:**
- Modify: `src/ui/BrewingPhases.tscn`
- Modify: `src/ui/BrewingPhases.gd`

**Step 1: Modify BrewingPhases.tscn**

For each slider row (MashingRow, BoilingRow, FermentingRow), restructure from VBox with slider+value to VBox with title, subtitle, HBox(min+slider+max), and value label.

**MashingRow changes:**
- Change `MashingTitle` text from `"MASHING  (Technique-heavy)"` to `"MASHING"`
- Add `MashingSubtitle` Label after title: text `"Mash Temperature"`, font_size=20, font_color=muted (#8A9BB1)
- Wrap `MashingSlider` in new `MashingSliderRow` HBoxContainer (separation=8)
- Add `MashingMin` Label before slider: text `"62°C"`, font_size=16, font_color=muted
- Add `MashingMax` Label after slider: text `"69°C"`, font_size=16, font_color=muted
- Update `MashingSlider`: min_value=62.0, max_value=69.0, step=1.0, value=65.0, tick_count=8, ticks_on_borders=true
- Update `MashingValue` text to `"65°C"`

**BoilingRow changes:**
- Change `BoilingTitle` text to `"BOILING"`
- Add `BoilingSubtitle`: text `"Boil Duration"`, font_size=20, font_color=muted
- Wrap slider in `BoilingSliderRow` HBox
- Add `BoilingMin` Label: text `"30 min"`, font_size=16, font_color=muted
- Add `BoilingMax` Label: text `"90 min"`, font_size=16, font_color=muted
- Update `BoilingSlider`: min_value=30.0, max_value=90.0, step=10.0, value=60.0, tick_count=7, ticks_on_borders=true
- Update `BoilingValue` text to `"60 min"`

**FermentingRow changes:**
- Change `FermentingTitle` text to `"FERMENTING"`
- Add `FermentingSubtitle`: text `"Fermentation Temperature"`, font_size=20, font_color=muted
- Wrap slider in `FermentingSliderRow` HBox
- Add `FermentingMin` Label: text `"15°C"`, font_size=16, font_color=muted
- Add `FermentingMax` Label: text `"25°C"`, font_size=16, font_color=muted
- Update `FermentingSlider`: min_value=15.0, max_value=25.0, step=1.0, value=20.0, tick_count=11, ticks_on_borders=true
- Update `FermentingValue` text to `"20°C"`

**Step 2: Update BrewingPhases.gd**

Update `@onready` node paths to match new scene tree structure (sliders are now inside SliderRow HBoxes).

Update `_on_slider_changed()` (line 41-43) to format with units:
```gdscript
func _on_slider_changed() -> void:
	mashing_value.text = "%d°C" % int(mashing_slider.value)
	boiling_value.text = "%d min" % int(boiling_slider.value)
	fermenting_value.text = "%d°C" % int(fermenting_slider.value)
	_update_preview()
```

Update `_reset_sliders()` (line 28-31) with new defaults:
```gdscript
func _reset_sliders() -> void:
	mashing_slider.value = 65.0
	boiling_slider.value = 60.0
	fermenting_slider.value = 20.0
```

Update `refresh()` (line 55-60) with new default text:
```gdscript
func refresh() -> void:
	_reset_sliders()
	mashing_value.text = "65°C"
	boiling_value.text = "60 min"
	fermenting_value.text = "20°C"
	_update_preview()
```

**Step 3: Run tests to verify nothing breaks**

Run: `make test`
Expected: ALL PASS

**Step 4: Commit**

```bash
git add src/ui/BrewingPhases.tscn src/ui/BrewingPhases.gd
git commit -m "feat(1B): update BrewingPhases sliders to physical units with discrete stops"
```

---

## Task 5: Add taste skill to GameState

Add `general_taste`, `style_taste`, and `discoveries` fields to GameState. Increment taste after each brew.

**Files:**
- Modify: `src/autoloads/GameState.gd`
- Create: `src/tests/test_taste_system.gd`

**Step 1: Write the failing tests**

Create `src/tests/test_taste_system.gd`:

```gdscript
## Tests for taste skill system.
extends GutTest

func before_each() -> void:
	GameState.reset()

# ---------------------------------------------------------------------------
# Taste skill progression
# ---------------------------------------------------------------------------

func test_general_taste_starts_at_zero():
	assert_eq(GameState.general_taste, 0)

func test_style_taste_starts_empty():
	assert_eq(GameState.style_taste.size(), 0)

func test_discoveries_starts_empty():
	assert_eq(GameState.discoveries.size(), 0)

func test_general_taste_increments_after_brew():
	GameState.general_taste = 0
	GameState.increment_taste("IPA")
	assert_eq(GameState.general_taste, 1)

func test_style_taste_increments_after_brew():
	GameState.increment_taste("IPA")
	assert_eq(GameState.style_taste.get("IPA", 0), 1)

func test_style_taste_tracks_multiple_styles():
	GameState.increment_taste("IPA")
	GameState.increment_taste("IPA")
	GameState.increment_taste("Stout")
	assert_eq(GameState.style_taste.get("IPA", 0), 2)
	assert_eq(GameState.style_taste.get("Stout", 0), 1)

func test_reset_clears_taste():
	GameState.general_taste = 5
	GameState.style_taste = {"IPA": 3}
	GameState.discoveries = {"dry_body": {"discovered": true}}
	GameState.reset()
	assert_eq(GameState.general_taste, 0)
	assert_eq(GameState.style_taste.size(), 0)
	assert_eq(GameState.discoveries.size(), 0)

# ---------------------------------------------------------------------------
# Palate level names
# ---------------------------------------------------------------------------

func test_palate_level_novice():
	GameState.general_taste = 0
	assert_eq(GameState.get_palate_name(), "Novice")
	GameState.general_taste = 1
	assert_eq(GameState.get_palate_name(), "Novice")

func test_palate_level_developing():
	GameState.general_taste = 2
	assert_eq(GameState.get_palate_name(), "Developing")
	GameState.general_taste = 3
	assert_eq(GameState.get_palate_name(), "Developing")

func test_palate_level_experienced():
	GameState.general_taste = 4
	assert_eq(GameState.get_palate_name(), "Experienced")

func test_palate_level_expert():
	GameState.general_taste = 6
	assert_eq(GameState.get_palate_name(), "Expert")
```

**Step 2: Run tests to verify they fail**

Run: `make test`
Expected: FAIL — `general_taste` not found on GameState

**Step 3: Add taste fields and methods to GameState.gd**

Add new state variables after line 43 (`last_brew_result`):
```gdscript
# Taste skill
var general_taste: int = 0
var style_taste: Dictionary = {}
var discoveries: Dictionary = {}
var temp_control_quality: int = 50
```

Add taste methods after `check_loss_condition()`:
```gdscript
## Increment taste after a brew. Called with the style name.
func increment_taste(style_name: String) -> void:
	general_taste += 1
	var current: int = style_taste.get(style_name, 0)
	style_taste[style_name] = current + 1

## Returns the palate level display name based on general_taste.
func get_palate_name() -> String:
	if general_taste <= 1:
		return "Novice"
	elif general_taste <= 3:
		return "Developing"
	elif general_taste <= 5:
		return "Experienced"
	else:
		return "Expert"
```

Update `reset()` to clear new fields:
```gdscript
	general_taste = 0
	style_taste = {}
	discoveries = {}
	temp_control_quality = 50
```

**Step 4: Integrate taste increment into execute_brew()**

In `execute_brew()`, after `record_brew(result["final_score"])` (line 217), add:
```gdscript
	if current_style:
		increment_taste(current_style.style_name)
```

**Step 5: Run tests to verify they pass**

Run: `make test`
Expected: ALL PASS

**Step 6: Commit**

```bash
git add src/autoloads/GameState.gd src/tests/test_taste_system.gd
git commit -m "feat(1B): add taste skill progression to GameState"
```

---

## Task 6: Create TasteSystem — tasting notes generation

TasteSystem generates tasting notes text based on taste level, brewing outputs, and discoveries.

**Files:**
- Create: `src/autoloads/TasteSystem.gd`
- Modify: `src/tests/test_taste_system.gd`
- Modify: `src/project.godot` (add autoload)

**Step 1: Write the failing tests**

Add to `src/tests/test_taste_system.gd`:

```gdscript
# ---------------------------------------------------------------------------
# Tasting notes generation
# ---------------------------------------------------------------------------

func test_taste_level_0_gives_vague_notes():
	GameState.general_taste = 0
	var attributes: Array[String] = ["dry_body", "citrus_aroma", "clean_ferment"]
	var notes: String = TasteSystem.generate_tasting_notes(attributes, "IPA", {})
	assert_true(notes.length() > 0, "Should generate some text")
	# At level 0, should NOT mention specific attributes
	assert_false(notes.containsn("citrus"), "Level 0 should not reveal citrus")

func test_taste_level_3_reveals_some_attributes():
	GameState.general_taste = 3
	var attributes: Array[String] = ["dry_body", "citrus_aroma", "clean_ferment"]
	var notes: String = TasteSystem.generate_tasting_notes(attributes, "IPA", {})
	assert_true(notes.length() > 10, "Should generate meaningful text")

func test_taste_level_5_gives_detailed_breakdown():
	GameState.general_taste = 5
	var attributes: Array[String] = ["dry_body", "citrus_aroma", "clean_ferment"]
	var sliders := {"mashing": 63.0, "boiling": 40.0, "fermenting": 20.0}
	var notes: String = TasteSystem.generate_tasting_notes(attributes, "IPA", sliders)
	# At level 5+, should mention specific slider values
	assert_true(notes.containsn("63") or notes.containsn("mash"), "Level 5 should reference process details")

func test_discovered_attributes_are_highlighted():
	GameState.general_taste = 4
	GameState.discoveries = {"citrus_aroma": {"discovered": true, "linked_to": "", "linked_detail": ""}}
	var attributes: Array[String] = ["citrus_aroma", "clean_ferment"]
	var notes: String = TasteSystem.generate_tasting_notes(attributes, "IPA", {})
	# Discovered attributes should use the display name
	assert_true(notes.containsn("citrus") or notes.containsn("Citrus"), "Discovered attribute should appear in notes")
```

**Step 2: Run tests to verify they fail**

Run: `make test`
Expected: FAIL — `TasteSystem` not found

**Step 3: Create `src/autoloads/TasteSystem.gd`**

```gdscript
extends Node

## TasteSystem — generates tasting notes based on taste level and brew attributes.
## Handles discovery chance rolls and tasting note text generation.

## Display names for attribute keys.
const ATTRIBUTE_NAMES := {
	"dry_body": "Dry Body",
	"crisp_body": "Crisp Body",
	"medium_body": "Medium Body",
	"full_body": "Full Body",
	"sweet_body": "Sweet Body",
	"low_bitter": "Low Bitterness",
	"balanced_bitter": "Balanced Bitterness",
	"assertive_bitter": "Assertive Bitterness",
	"floral_aroma": "Floral Aroma",
	"citrus_aroma": "Citrus Aroma",
	"piney_aroma": "Piney Aroma",
	"earthy_aroma": "Earthy Aroma",
	"spicy_aroma": "Spicy Aroma",
	"clean_ferment": "Clean Fermentation",
	"fruity_esters": "Fruity Esters",
	"fusel_alcohols": "Fusel Alcohols",
	"stalled_ferment": "Stalled Fermentation",
}

## Process link descriptions for discovered attributes.
const ATTRIBUTE_LINKS := {
	"dry_body": {"phase": "mashing", "detail": "low mash temperature"},
	"crisp_body": {"phase": "mashing", "detail": "low-mid mash temperature"},
	"medium_body": {"phase": "mashing", "detail": "moderate mash temperature"},
	"full_body": {"phase": "mashing", "detail": "high mash temperature"},
	"sweet_body": {"phase": "mashing", "detail": "very high mash temperature"},
	"low_bitter": {"phase": "boiling", "detail": "short boil time"},
	"balanced_bitter": {"phase": "boiling", "detail": "moderate boil time"},
	"assertive_bitter": {"phase": "boiling", "detail": "long boil time + high alpha hops"},
	"floral_aroma": {"phase": "boiling", "detail": "short boil + floral hop variety"},
	"citrus_aroma": {"phase": "boiling", "detail": "short boil + citrus hop variety"},
	"piney_aroma": {"phase": "boiling", "detail": "short-mid boil + piney hop variety"},
	"earthy_aroma": {"phase": "boiling", "detail": "any boil + earthy hop variety"},
	"spicy_aroma": {"phase": "boiling", "detail": "short boil + spicy hop variety"},
	"clean_ferment": {"phase": "fermenting", "detail": "temp within yeast ideal range"},
	"fruity_esters": {"phase": "fermenting", "detail": "temp above yeast ideal range"},
	"fusel_alcohols": {"phase": "fermenting", "detail": "temp well above yeast ideal range"},
	"stalled_ferment": {"phase": "fermenting", "detail": "temp below yeast ideal range"},
}

# ---------------------------------------------------------------------------
# Tasting notes generation
# ---------------------------------------------------------------------------

## Generates tasting notes text based on taste level, detected attributes, and discoveries.
## taste_level is read from GameState.general_taste.
## attributes is the Array[String] of attribute keys present in this brew.
## sliders is the raw slider Dictionary (for level 5+ process details).
static func generate_tasting_notes(attributes: Array[String], style_name: String, sliders: Dictionary) -> String:
	var taste: int = GameState.general_taste
	var discoveries: Dictionary = GameState.discoveries

	if taste == 0:
		return _level_0_notes()
	elif taste == 1:
		return _level_1_notes(attributes)
	elif taste == 2:
		return _level_2_notes(attributes)
	elif taste == 3:
		return _level_3_notes(attributes, discoveries)
	elif taste == 4:
		return _level_4_notes(attributes, discoveries, style_name)
	else:
		return _level_5_notes(attributes, discoveries, style_name, sliders)

static func _level_0_notes() -> String:
	var phrases: Array[String] = [
		"Your friends try it... \"It's definitely beer!\"",
		"Your friends take a sip... \"Yeah, that's beer alright.\"",
		"You taste it. It's... beer? Probably.",
	]
	return phrases[randi() % phrases.size()]

static func _level_1_notes(attributes: Array[String]) -> String:
	if attributes.size() == 0:
		return "Seems... okay?"
	# Pick one vague descriptor
	var attr: String = attributes[0]
	if attr.containsn("body"):
		return "Seems kinda %s." % ["thin", "light", "medium", "heavy", "sweet"][clampi(_body_index(attr), 0, 4)]
	elif attr.containsn("bitter"):
		return "Seems kinda bitter." if attr != "low_bitter" else "Not very bitter."
	elif attr.containsn("aroma"):
		return "Has an interesting smell."
	else:
		return "Tastes... interesting."

static func _level_2_notes(attributes: Array[String]) -> String:
	var parts: Array[String] = []
	# Body
	for attr in attributes:
		if attr.containsn("body") and parts.size() < 1:
			parts.append(_get_display_name(attr).to_lower())
	# One more descriptor
	for attr in attributes:
		if not attr.containsn("body") and parts.size() < 2:
			parts.append(_get_display_name(attr).to_lower())
	if parts.size() == 0:
		return "Not bad. Not great either."
	return "Has a %s. Not bad." % (" with ".join(parts))

static func _level_3_notes(attributes: Array[String], discoveries: Dictionary) -> String:
	var parts: Array[String] = []
	for attr in attributes:
		if parts.size() >= 3:
			break
		var name: String = _get_display_name(attr)
		if discoveries.has(attr) and discoveries[attr].get("discovered", false):
			parts.append("[color=#FFC857]%s[/color]" % name)
		else:
			parts.append(name.to_lower())
	var notes: String = ", ".join(parts) + "."
	# Add one process hint
	for attr in attributes:
		if discoveries.has(attr):
			var link_info: Dictionary = ATTRIBUTE_LINKS.get(attr, {})
			if link_info.size() > 0 and discoveries[attr].get("linked_to", "") != "":
				notes += " The %s felt right." % link_info["phase"]
				break
	return notes

static func _level_4_notes(attributes: Array[String], discoveries: Dictionary, style_name: String) -> String:
	var style_taste: int = GameState.style_taste.get(style_name, 0)
	var parts: Array[String] = []
	for attr in attributes:
		var name: String = _get_display_name(attr)
		if discoveries.has(attr) and discoveries[attr].get("discovered", false):
			parts.append("[color=#FFC857]%s[/color]" % name)
		else:
			parts.append(name.to_lower())
	var notes: String = ", ".join(parts) + "."
	# Process attributions for linked discoveries
	for attr in attributes:
		if discoveries.has(attr) and discoveries[attr].get("linked_to", "") != "":
			var link: Dictionary = ATTRIBUTE_LINKS.get(attr, {})
			notes += " %s from %s." % [_get_display_name(attr), link.get("detail", "unknown")]
	# Style expertise comment
	if style_taste >= 2:
		notes += " This is a solid %s." % style_name
	return notes

static func _level_5_notes(attributes: Array[String], discoveries: Dictionary, style_name: String, sliders: Dictionary) -> String:
	var notes: String = _level_4_notes(attributes, discoveries, style_name)
	# Add process detail with actual values
	if sliders.size() > 0:
		var mash: float = sliders.get("mashing", 0.0)
		var boil: float = sliders.get("boiling", 0.0)
		var ferment: float = sliders.get("fermenting", 0.0)
		notes += " [Mash %d°C, Boil %d min, Ferment %d°C]" % [int(mash), int(boil), int(ferment)]
	return notes

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

static func _get_display_name(attr_key: String) -> String:
	return ATTRIBUTE_NAMES.get(attr_key, attr_key.replace("_", " ").capitalize())

static func _body_index(attr: String) -> int:
	var bodies: Array[String] = ["dry_body", "crisp_body", "medium_body", "full_body", "sweet_body"]
	return bodies.find(attr)
```

**Step 4: Register autoload in project.godot**

Add to `[autoload]` section:
```
TasteSystem="*res://autoloads/TasteSystem.gd"
```

**Step 5: Run tests to verify they pass**

Run: `make test`
Expected: ALL PASS

**Step 6: Commit**

```bash
git add src/autoloads/TasteSystem.gd src/tests/test_taste_system.gd src/project.godot
git commit -m "feat(1B): add TasteSystem with tasting notes generation"
```

---

## Task 7: Create discovery system — chance rolls after each brew

Add discovery chance rolls to TasteSystem and integrate into the brew flow.

**Files:**
- Modify: `src/autoloads/TasteSystem.gd`
- Modify: `src/autoloads/GameState.gd`
- Modify: `src/tests/test_taste_system.gd`

**Step 1: Write the failing tests**

Add to `src/tests/test_taste_system.gd`:

```gdscript
# ---------------------------------------------------------------------------
# Discovery system
# ---------------------------------------------------------------------------

func test_discovery_roll_can_discover_attribute():
	GameState.general_taste = 10  # High taste = high chance
	GameState.discoveries = {}
	var attributes: Array[String] = ["dry_body", "citrus_aroma"]
	# Force discovery by running many attempts
	var discovered := false
	for i in range(50):
		var result: Dictionary = TasteSystem.roll_discoveries(attributes, "IPA")
		if result.get("attribute_discovered", "") != "":
			discovered = true
			break
	assert_true(discovered, "High taste should eventually discover an attribute")

func test_discovery_roll_stores_in_gamestate():
	GameState.general_taste = 10
	GameState.discoveries = {}
	var attributes: Array[String] = ["dry_body"]
	# Run until discovered
	for i in range(100):
		TasteSystem.roll_discoveries(attributes, "IPA")
		if GameState.discoveries.has("dry_body"):
			break
	assert_true(GameState.discoveries.has("dry_body"), "Discovery should be stored in GameState")
	assert_true(GameState.discoveries["dry_body"]["discovered"], "discovered flag should be true")

func test_already_discovered_not_rediscovered():
	GameState.general_taste = 10
	GameState.discoveries = {"dry_body": {"discovered": true, "linked_to": "", "linked_detail": ""}}
	var attributes: Array[String] = ["dry_body"]
	var result: Dictionary = TasteSystem.roll_discoveries(attributes, "IPA")
	# Should not re-discover, might try to link instead
	assert_ne(result.get("attribute_discovered", ""), "dry_body", "Should not re-discover existing attribute")

func test_process_link_roll():
	GameState.general_taste = 5
	GameState.style_taste = {"IPA": 10}  # High style taste = high link chance
	GameState.discoveries = {"citrus_aroma": {"discovered": true, "linked_to": "", "linked_detail": ""}}
	var attributes: Array[String] = ["citrus_aroma"]
	var linked := false
	for i in range(100):
		TasteSystem.roll_discoveries(attributes, "IPA")
		if GameState.discoveries["citrus_aroma"]["linked_to"] != "":
			linked = true
			break
	assert_true(linked, "High style taste should eventually link an attribute")

func test_discovery_chance_scales_with_taste():
	# Taste 0: 20% chance, Taste 8: 60% chance
	var low_chance: float = TasteSystem.get_discovery_chance(0)
	var high_chance: float = TasteSystem.get_discovery_chance(8)
	assert_almost_eq(low_chance, 0.20, 0.01)
	assert_almost_eq(high_chance, 0.60, 0.01)

func test_link_chance_scales_with_style_taste():
	var low_chance: float = TasteSystem.get_link_chance(0)
	var high_chance: float = TasteSystem.get_link_chance(8)
	assert_almost_eq(low_chance, 0.10, 0.01)
	assert_almost_eq(high_chance, 0.50, 0.01)
```

**Step 2: Run tests to verify they fail**

Run: `make test`
Expected: FAIL — `roll_discoveries` method not found

**Step 3: Add discovery methods to TasteSystem.gd**

Add to `src/autoloads/TasteSystem.gd`:

```gdscript
# ---------------------------------------------------------------------------
# Discovery chance rolls
# ---------------------------------------------------------------------------

## Returns the discovery chance for the current general taste level.
static func get_discovery_chance(general_taste: int) -> float:
	return minf(0.20 + float(general_taste) * 0.05, 0.80)

## Returns the process link chance for a given style taste level.
static func get_link_chance(style_taste_level: int) -> float:
	return minf(0.10 + float(style_taste_level) * 0.05, 0.80)

## Performs discovery rolls after a brew. Returns a Dictionary with results:
## { "attribute_discovered": String (empty if none), "process_linked": String (empty if none) }
## Side effect: updates GameState.discoveries.
static func roll_discoveries(brew_attributes: Array[String], style_name: String) -> Dictionary:
	var result := {"attribute_discovered": "", "process_linked": ""}

	# Roll 1: Attribute discovery
	var discovery_chance: float = get_discovery_chance(GameState.general_taste)
	if randf() < discovery_chance:
		# Find undiscovered attributes present in this brew
		var undiscovered: Array[String] = []
		for attr in brew_attributes:
			if not GameState.discoveries.has(attr):
				undiscovered.append(attr)
		if undiscovered.size() > 0:
			var chosen: String = undiscovered[randi() % undiscovered.size()]
			GameState.discoveries[chosen] = {"discovered": true, "linked_to": "", "linked_detail": ""}
			result["attribute_discovered"] = chosen

	# Roll 2: Process attribution (only for already-discovered, unlinked attributes)
	var style_taste_level: int = GameState.style_taste.get(style_name, 0)
	var link_chance: float = get_link_chance(style_taste_level)
	if randf() < link_chance:
		# Find discovered but unlinked attributes present in this brew
		var unlinked: Array[String] = []
		for attr in brew_attributes:
			if GameState.discoveries.has(attr):
				var entry: Dictionary = GameState.discoveries[attr]
				if entry.get("linked_to", "") == "":
					unlinked.append(attr)
		if unlinked.size() > 0:
			var chosen: String = unlinked[randi() % unlinked.size()]
			var link_info: Dictionary = ATTRIBUTE_LINKS.get(chosen, {})
			GameState.discoveries[chosen]["linked_to"] = link_info.get("phase", "")
			GameState.discoveries[chosen]["linked_detail"] = link_info.get("detail", "")
			result["process_linked"] = chosen

	return result
```

**Step 4: Run tests to verify they pass**

Run: `make test`
Expected: ALL PASS

**Step 5: Commit**

```bash
git add src/autoloads/TasteSystem.gd src/tests/test_taste_system.gd
git commit -m "feat(1B): add discovery chance rolls to TasteSystem"
```

---

## Task 8: Integrate discovery + tasting notes into brew flow

Wire up the discovery rolls and tasting notes generation into the brew execution flow and pass results to the UI.

**Files:**
- Modify: `src/autoloads/GameState.gd` (execute_brew)
- Modify: `src/autoloads/QualityCalculator.gd` (add attribute detection to result)

**Step 1: Add attribute detection to QualityCalculator result**

In `QualityCalculator.calculate_quality()`, after computing the science score, add:

```gdscript
# Detect flavor attributes for discovery system
var yeast_for_attrs: Yeast = recipe.get("yeast", null) as Yeast
var hops_for_attrs: Array = recipe.get("hops", [])
var brew_attributes: Array[String] = []
if yeast_for_attrs != null:
	brew_attributes = BrewingScience.detect_brew_attributes(
		sliders.get("mashing", 65.0),
		sliders.get("boiling", 60.0),
		sliders.get("fermenting", 20.0),
		yeast_for_attrs,
		hops_for_attrs
	)
```

Add to the return dictionary:
```gdscript
"brew_attributes": brew_attributes,
```

**Step 2: Integrate into execute_brew()**

In `GameState.execute_brew()`, after `increment_taste()`, add:

```gdscript
	# Discovery rolls
	var brew_attributes: Array[String] = result.get("brew_attributes", [] as Array[String])
	var discovery_result: Dictionary = TasteSystem.roll_discoveries(brew_attributes, current_style.style_name)
	result["discovery_result"] = discovery_result

	# Generate tasting notes
	var tasting_notes: String = TasteSystem.generate_tasting_notes(
		brew_attributes, current_style.style_name, sliders
	)
	result["tasting_notes"] = tasting_notes
```

**Step 3: Run tests to verify nothing breaks**

Run: `make test`
Expected: ALL PASS

**Step 4: Commit**

```bash
git add src/autoloads/GameState.gd src/autoloads/QualityCalculator.gd
git commit -m "feat(1B): integrate discovery rolls and tasting notes into brew flow"
```

---

## Task 9: Update ResultsOverlay — add tasting notes display

Add the tasting notes section and palate level to the results screen. Also fix the pre-1A recipe display bug.

**Files:**
- Modify: `src/ui/ResultsOverlay.tscn`
- Modify: `src/ui/ResultsOverlay.gd`

**Step 1: Add tasting notes UI elements to ResultsOverlay.tscn**

After `BreakdownGrid` and before `HSeparator2`, add:

```
[node name="TastingSeparator" type="HSeparator" parent="CardPanel/MarginContainer/VBox"]

[node name="TastingHeader" type="Label" parent="CardPanel/MarginContainer/VBox"]
text = "TASTING NOTES"
theme_override_font_sizes/font_size = 20

[node name="TastingNotes" type="RichTextLabel" parent="CardPanel/MarginContainer/VBox"]
bbcode_enabled = true
fit_content = true
text = ""
custom_minimum_size = Vector2(0, 40)

[node name="PalateLabel" type="Label" parent="CardPanel/MarginContainer/VBox"]
text = "Your palate: Novice (Lv 0)"
theme_override_font_sizes/font_size = 16
theme_override_colors/font_color = Color(0.541, 0.608, 0.694, 1)
horizontal_alignment = 2
```

Note: Using `RichTextLabel` with `bbcode_enabled` allows colored text for discovered attributes (the `[color=#FFC857]...[/color]` tags from TasteSystem).

**Step 2: Update ResultsOverlay.gd**

Add `@onready` references:
```gdscript
@onready var tasting_notes: RichTextLabel = $CardPanel/MarginContainer/VBox/TastingNotes
@onready var palate_label: Label = $CardPanel/MarginContainer/VBox/PalateLabel
```

Fix the recipe display in `populate()` (lines 34-41) to handle multi-ingredient recipes:
```gdscript
	# Recipe identity (Stage 1A: multi-ingredient)
	var malts: Array = recipe.get("malts", [])
	var hops: Array = recipe.get("hops", [])
	var yeast_ingredient = recipe.get("yeast", null)
	var malt_names: String = ", ".join(malts.map(func(m): return m.ingredient_name)) if malts.size() > 0 else "—"
	var hop_names: String = ", ".join(hops.map(func(h): return h.ingredient_name)) if hops.size() > 0 else "—"
	var yeast_name: String = yeast_ingredient.ingredient_name if yeast_ingredient else "—"
	recipe_label.text = "Recipe: %s / %s / %s" % [malt_names, hop_names, yeast_name]
```

Add tasting notes population at end of `populate()`:
```gdscript
	# Tasting notes
	var notes: String = result.get("tasting_notes", "")
	tasting_notes.text = "[i]%s[/i]" % notes if notes != "" else ""

	# Palate level
	palate_label.text = "Your palate: %s (Lv %d)" % [GameState.get_palate_name(), GameState.general_taste]
```

**Step 3: Add science score to breakdown grid**

Add a new label to the breakdown grid in the .tscn for the science score, and update `populate()`:
```gdscript
	# In the breakdown section, add:
	science_label.text = "Science: %.0f" % result.get("science_score", 0.0)
```

Add the `@onready` reference and label node accordingly.

**Step 4: Run tests to verify nothing breaks**

Run: `make test`
Expected: ALL PASS

**Step 5: Commit**

```bash
git add src/ui/ResultsOverlay.tscn src/ui/ResultsOverlay.gd
git commit -m "feat(1B): add tasting notes and palate level to ResultsOverlay"
```

---

## Task 10: Add discovery toast notifications

Show toast messages when the player discovers an attribute or links it to a process.

**Files:**
- Modify: `src/autoloads/GameState.gd` (execute_brew — fire toasts)

**Step 1: Add toast calls after discovery rolls**

In `GameState.execute_brew()`, after the discovery roll code, add:

```gdscript
	# Discovery toasts
	if discovery_result.get("attribute_discovered", "") != "":
		var attr_name: String = TasteSystem.ATTRIBUTE_NAMES.get(
			discovery_result["attribute_discovered"],
			discovery_result["attribute_discovered"]
		)
		ToastManager.show_toast("You noticed something... this beer has %s." % attr_name)

	if discovery_result.get("process_linked", "") != "":
		var linked_attr: String = discovery_result["process_linked"]
		var attr_name: String = TasteSystem.ATTRIBUTE_NAMES.get(linked_attr, linked_attr)
		var link_detail: String = GameState.discoveries[linked_attr].get("linked_detail", "")
		ToastManager.show_toast("%s seems to come from %s." % [attr_name, link_detail])
```

**Step 2: Run tests to verify nothing breaks**

Run: `make test`
Expected: ALL PASS (ToastManager may not be available in headless tests — the calls should be guarded or ToastManager should handle headless gracefully. Check existing ToastManager.gd — it extends CanvasLayer, so it should exist as an autoload but `show_toast` may fail without a viewport. If tests fail, wrap toast calls in `if is_instance_valid(ToastManager):`)

**Step 3: Commit**

```bash
git add src/autoloads/GameState.gd
git commit -m "feat(1B): add discovery toast notifications"
```

---

## Task 11: Add hop variety_family to remaining hop .tres files

The discovery system uses `hop.variety_family` to determine aroma attributes. Ensure all 8 hops have this field set correctly.

**Files:**
- Check/Modify: `src/data/ingredients/hops/*.tres`

**Step 1: Verify and update all hop .tres files**

Read each hop file and set `variety_family` if not already present:

- `cascade.tres`: `variety_family = "american"` (already set)
- `centennial.tres`: `variety_family = "american"`
- `citra.tres`: `variety_family = "american"`
- `simcoe.tres`: `variety_family = "american"`
- `saaz.tres`: `variety_family = "noble"`
- `hallertau.tres`: `variety_family = "noble"`
- `east_kent_goldings.tres`: `variety_family = "english"`
- `fuggle.tres`: `variety_family = "english"`

**Step 2: Run tests**

Run: `make test`
Expected: ALL PASS

**Step 3: Commit**

```bash
git add src/data/ingredients/hops/*.tres
git commit -m "feat(1B): set variety_family on all hop ingredients for discovery system"
```

---

## Task 12: Write integration tests

Verify the full brewing science flow end-to-end: sliders → science → quality → taste → discovery → tasting notes.

**Files:**
- Modify: `src/tests/test_brewing_science.gd` (add integration tests)

**Step 1: Write integration tests**

Add to `src/tests/test_brewing_science.gd`:

```gdscript
# ---------------------------------------------------------------------------
# Integration: full brew flow with brewing science
# ---------------------------------------------------------------------------

func _make_full_style() -> BeerStyle:
	var s := BeerStyle.new()
	s.style_id = "test_ipa"
	s.style_name = "IPA"
	s.ideal_flavor_ratio = 0.55
	s.base_price = 200.0
	s.preferred_ingredients = {"pale_malt": 0.9, "cascade": 0.95, "us05_clean_ale": 0.9}
	s.ideal_flavor_profile = {"bitterness": 0.6, "sweetness": 0.2, "roastiness": 0.1, "fruitiness": 0.5, "funkiness": 0.0}
	s.ideal_mash_temp_min = 63.0
	s.ideal_mash_temp_max = 66.0
	s.ideal_boil_min = 60.0
	s.ideal_boil_max = 90.0
	return s

func _make_full_recipe() -> Dictionary:
	var malt := Malt.new()
	malt.ingredient_id = "pale_malt"
	malt.ingredient_name = "Pale Malt"
	malt.category = Ingredient.Category.MALT
	malt.cost = 20
	malt.flavor_profile = {"bitterness": 0.1, "sweetness": 0.2, "roastiness": 0.1, "fruitiness": 0.1, "funkiness": 0.0}
	malt.is_base_malt = true

	var hop := Hop.new()
	hop.ingredient_id = "cascade"
	hop.ingredient_name = "Cascade"
	hop.category = Ingredient.Category.HOP
	hop.cost = 25
	hop.alpha_acid_pct = 6.0
	hop.aroma_intensity = 0.8
	hop.variety_family = "american"
	hop.flavor_profile = {"bitterness": 0.4, "sweetness": 0.0, "roastiness": 0.0, "fruitiness": 0.6, "funkiness": 0.0}

	var yeast := Yeast.new()
	yeast.ingredient_id = "us05_clean_ale"
	yeast.ingredient_name = "US-05"
	yeast.category = Ingredient.Category.YEAST
	yeast.cost = 15
	yeast.ideal_temp_min_c = 15.0
	yeast.ideal_temp_max_c = 24.0
	yeast.flavor_profile = {"bitterness": 0.0, "sweetness": 0.1, "roastiness": 0.0, "fruitiness": 0.05, "funkiness": 0.0}

	return {"malts": [malt], "hops": [hop], "yeast": yeast, "adjuncts": []}

func test_brew_attributes_detected_for_ipa():
	var yeast := Yeast.new()
	yeast.ideal_temp_min_c = 15.0
	yeast.ideal_temp_max_c = 24.0
	var hop := Hop.new()
	hop.variety_family = "american"
	var attrs: Array[String] = BrewingScience.detect_brew_attributes(63.0, 40.0, 20.0, yeast, [hop])
	assert_has(attrs, "dry_body", "63°C should produce dry body")
	assert_has(attrs, "citrus_aroma", "Short boil + american hop = citrus aroma")
	assert_has(attrs, "clean_ferment", "20°C in range 15-24 = clean")

func test_quality_includes_science_and_attributes():
	var style := _make_full_style()
	var recipe := _make_full_recipe()
	var sliders := {"mashing": 65.0, "boiling": 70.0, "fermenting": 20.0}
	var result := QualityCalculator.calculate_quality(style, recipe, sliders, [])
	assert_has(result, "science_score", "Result should include science score")
	assert_has(result, "brew_attributes", "Result should include brew attributes")
	assert_gt(result["science_score"], 0.0, "Science score should be positive")
	assert_gt(result["brew_attributes"].size(), 0, "Should detect some attributes")

func test_full_brew_flow_produces_tasting_notes():
	GameState.reset()
	GameState.general_taste = 3
	var style := _make_full_style()
	var recipe := _make_full_recipe()
	var sliders := {"mashing": 65.0, "boiling": 70.0, "fermenting": 20.0}
	var result := QualityCalculator.calculate_quality(style, recipe, sliders, [])
	var notes: String = TasteSystem.generate_tasting_notes(
		result["brew_attributes"], "IPA", sliders
	)
	assert_true(notes.length() > 0, "Should generate tasting notes")
```

**Step 2: Run tests**

Run: `make test`
Expected: ALL PASS

**Step 3: Commit**

```bash
git add src/tests/test_brewing_science.gd
git commit -m "test(1B): add integration tests for full brewing science flow"
```

---

## Task 13: Final verification and cleanup

Run full test suite, verify no regressions, clean up any issues.

**Step 1: Run full test suite**

Run: `make test`
Expected: ALL PASS — all existing tests plus new brewing science, taste, and discovery tests

**Step 2: Verify test count increased**

Count should be significantly higher than the previous 73 tests (expect ~100+).

**Step 3: Review for any leftover issues**

- Check that `_compute_points()` in QualityCalculator still works with the new slider ranges (it uses slider values 0-100 for flavor/technique math — with physical ranges like 62-69 for mashing, the points will be much lower). **This is a critical integration point** — `_compute_points()` may need updating to normalize physical slider values back to 0-100 for the flavor/technique calculation. If so, add a normalization step:

```gdscript
## Normalizes physical slider values to 0-100 for points calculation.
static func _normalize_sliders(sliders: Dictionary) -> Dictionary:
	return {
		"mashing": (sliders.get("mashing", 65.0) - 62.0) / 7.0 * 100.0,
		"boiling": (sliders.get("boiling", 60.0) - 30.0) / 60.0 * 100.0,
		"fermenting": (sliders.get("fermenting", 20.0) - 15.0) / 10.0 * 100.0,
	}
```

Call this in `_compute_points()` and `calculate_quality()` before passing to the existing flavor/technique calculation.

**Step 4: Update existing test slider values if needed**

If tests use `{"mashing": 50.0, ...}` and those now represent physical temps, update them to use the new ranges or ensure normalization handles backward compatibility.

**Step 5: Commit final cleanup**

```bash
git add -A
git commit -m "chore(1B): final verification and slider normalization cleanup"
```
