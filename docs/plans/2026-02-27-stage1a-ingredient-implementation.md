# Stage 1A — Ingredient System Overhaul Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the MVP's flat ingredient system with typed subclasses (Malt, Hop, Yeast, Adjunct), expanded catalog (26 items), multi-select recipe designer, per-ingredient costs, and flavor profile scoring.

**Architecture:** Four typed Resource subclasses extend a base Ingredient class. BeerStyle gains `preferred_ingredients` and `ideal_flavor_profile` dictionaries. QualityCalculator's ingredient scoring is rewritten to use flavor profile distance + preferred ingredient matching. RecipeDesigner UI switches from radio-select to toggle-button multi-select with counter badges. GameState removes flat INGREDIENT_COST in favor of summing selected ingredient costs.

**Tech Stack:** Godot 4.6, GDScript, GUT testing framework, `.tres` resource files with `type="Resource"` (never custom class names).

**Important references:**
- Design doc: `docs/plans/2026-02-27-stage1a-ingredient-system-design.md`
- Spec: `openspec/changes/post-mvp-roadmap/specs/ingredient-system/spec.md`
- Godot pitfalls: `stacks/godot/pitfalls.md` (`.tres` files MUST use `type="Resource"`)
- Test runner: `make test` (requires `GODOT` env var set to Steam path)

---

### Task 1: Base Ingredient class refactor

**Files:**
- Modify: `src/scripts/Ingredient.gd`
- Test: `src/tests/test_ingredient_model.gd`

**Step 1: Write the failing test**

Create `src/tests/test_ingredient_model.gd`:

```gdscript
extends GutTest

func test_ingredient_has_base_fields():
	var ing := Ingredient.new()
	ing.ingredient_id = "test"
	ing.ingredient_name = "Test Ingredient"
	ing.description = "A test"
	ing.category = Ingredient.Category.MALT
	ing.cost = 20
	ing.flavor_tags = ["bready", "light"]
	ing.flavor_profile = {"bitterness": 0.1, "sweetness": 0.3, "roastiness": 0.0, "fruitiness": 0.0, "funkiness": 0.0}
	ing.unlocked = true
	assert_eq(ing.ingredient_id, "test")
	assert_eq(ing.cost, 20)
	assert_eq(ing.flavor_tags.size(), 2)
	assert_eq(ing.flavor_profile["sweetness"], 0.3)
	assert_true(ing.unlocked)

func test_ingredient_category_has_adjunct():
	var ing := Ingredient.new()
	ing.category = Ingredient.Category.ADJUNCT
	assert_eq(ing.category, Ingredient.Category.ADJUNCT)

func test_default_flavor_profile():
	var ing := Ingredient.new()
	assert_eq(ing.flavor_profile.size(), 5)
	assert_eq(ing.flavor_profile["bitterness"], 0.0)
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — `cost`, `flavor_profile`, `unlocked` properties don't exist on Ingredient yet; `ADJUNCT` not in Category enum.

**Step 3: Write minimal implementation**

Replace `src/scripts/Ingredient.gd`:

```gdscript
class_name Ingredient
extends Resource

## Base ingredient class. Extended by Malt, Hop, Yeast, Adjunct.

enum Category { MALT, HOP, YEAST, ADJUNCT }

@export var ingredient_id: String = ""
@export var ingredient_name: String = ""
@export var description: String = ""
@export var category: Category = Category.MALT
@export var cost: int = 0
@export var flavor_tags: Array[String] = []
@export var flavor_profile: Dictionary = {
	"bitterness": 0.0,
	"sweetness": 0.0,
	"roastiness": 0.0,
	"fruitiness": 0.0,
	"funkiness": 0.0,
}
@export var unlocked: bool = true
```

**Step 4: Run test to verify it passes**

Run: `make test`
Expected: PASS for all 3 new tests.

**Step 5: Commit**

```bash
git add src/scripts/Ingredient.gd src/tests/test_ingredient_model.gd
git commit -m "refactor: update base Ingredient with cost, flavor_profile, unlocked, ADJUNCT category"
```

---

### Task 2: Malt subclass

**Files:**
- Create: `src/scripts/Malt.gd`
- Test: `src/tests/test_ingredient_model.gd` (append)

**Step 1: Write the failing test**

Append to `src/tests/test_ingredient_model.gd`:

```gdscript
func test_malt_has_typed_properties():
	var m := Malt.new()
	m.ingredient_id = "pale_malt"
	m.category = Ingredient.Category.MALT
	m.cost = 15
	m.color_srm = 4.0
	m.body_contribution = 0.4
	m.sweetness = 0.3
	m.fermentability = 0.85
	m.is_base_malt = true
	assert_eq(m.color_srm, 4.0)
	assert_eq(m.body_contribution, 0.4)
	assert_eq(m.fermentability, 0.85)
	assert_true(m.is_base_malt)
	assert_true(m is Ingredient, "Malt should extend Ingredient")

func test_malt_inherits_flavor_profile():
	var m := Malt.new()
	m.flavor_profile = {"bitterness": 0.0, "sweetness": 0.5, "roastiness": 0.0, "fruitiness": 0.0, "funkiness": 0.0}
	assert_eq(m.flavor_profile["sweetness"], 0.5)
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — `Malt` class doesn't exist.

**Step 3: Write minimal implementation**

Create `src/scripts/Malt.gd`:

```gdscript
class_name Malt
extends Ingredient

## Malt ingredient with grain-specific properties.

@export var color_srm: float = 0.0
@export var body_contribution: float = 0.0
@export var sweetness: float = 0.0
@export var fermentability: float = 0.0
@export var is_base_malt: bool = false
```

**Step 4: Run test to verify it passes**

Run: `make test`
Expected: PASS.

**Step 5: Commit**

```bash
git add src/scripts/Malt.gd src/tests/test_ingredient_model.gd
git commit -m "feat: add Malt subclass with color_srm, body, sweetness, fermentability, is_base_malt"
```

---

### Task 3: Hop, Yeast, and Adjunct subclasses

**Files:**
- Create: `src/scripts/Hop.gd`
- Create: `src/scripts/Yeast.gd`
- Create: `src/scripts/Adjunct.gd`
- Test: `src/tests/test_ingredient_model.gd` (append)

**Step 1: Write the failing tests**

Append to `src/tests/test_ingredient_model.gd`:

```gdscript
func test_hop_has_typed_properties():
	var h := Hop.new()
	h.alpha_acid_pct = 12.0
	h.aroma_intensity = 0.95
	h.variety_family = "american"
	assert_eq(h.alpha_acid_pct, 12.0)
	assert_eq(h.aroma_intensity, 0.95)
	assert_eq(h.variety_family, "american")
	assert_true(h is Ingredient)

func test_yeast_has_typed_properties():
	var y := Yeast.new()
	y.attenuation_pct = 0.77
	y.ideal_temp_min_c = 15.0
	y.ideal_temp_max_c = 24.0
	y.flocculation = "medium"
	assert_eq(y.attenuation_pct, 0.77)
	assert_eq(y.ideal_temp_min_c, 15.0)
	assert_eq(y.ideal_temp_max_c, 24.0)
	assert_eq(y.flocculation, "medium")
	assert_true(y is Ingredient)

func test_adjunct_has_typed_properties():
	var a := Adjunct.new()
	a.fermentable = false
	a.adjunct_type = "sugar"
	a.effect_description = "Adds body without ABV"
	assert_false(a.fermentable)
	assert_eq(a.adjunct_type, "sugar")
	assert_eq(a.effect_description, "Adds body without ABV")
	assert_true(a is Ingredient)
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — `Hop`, `Yeast`, `Adjunct` classes don't exist.

**Step 3: Write minimal implementation**

Create `src/scripts/Hop.gd`:

```gdscript
class_name Hop
extends Ingredient

## Hop ingredient with hop-specific properties.

@export var alpha_acid_pct: float = 0.0
@export var aroma_intensity: float = 0.0
@export var variety_family: String = ""
```

Create `src/scripts/Yeast.gd`:

```gdscript
class_name Yeast
extends Ingredient

## Yeast ingredient with fermentation-specific properties.

@export var attenuation_pct: float = 0.0
@export var ideal_temp_min_c: float = 0.0
@export var ideal_temp_max_c: float = 0.0
@export var flocculation: String = ""
```

Create `src/scripts/Adjunct.gd`:

```gdscript
class_name Adjunct
extends Ingredient

## Adjunct ingredient (sugars, finings, fruit, spices, cultures).

@export var fermentable: bool = true
@export var adjunct_type: String = ""
@export var effect_description: String = ""
```

**Step 4: Run test to verify it passes**

Run: `make test`
Expected: PASS.

**Step 5: Commit**

```bash
git add src/scripts/Hop.gd src/scripts/Yeast.gd src/scripts/Adjunct.gd src/tests/test_ingredient_model.gd
git commit -m "feat: add Hop, Yeast, Adjunct subclasses with typed properties"
```

---

### Task 4: BeerStyle gains preferred_ingredients and ideal_flavor_profile

**Files:**
- Modify: `src/scripts/BeerStyle.gd`
- Modify: `src/data/styles/lager.tres`
- Modify: `src/data/styles/pale_ale.tres`
- Modify: `src/data/styles/wheat_beer.tres`
- Modify: `src/data/styles/stout.tres`
- Test: `src/tests/test_ingredient_model.gd` (append)

**Step 1: Write the failing test**

Append to `src/tests/test_ingredient_model.gd`:

```gdscript
func test_beer_style_has_preferred_ingredients():
	var s := BeerStyle.new()
	s.preferred_ingredients = {"roasted_barley": 0.9, "pale_malt": 0.7}
	assert_eq(s.preferred_ingredients["roasted_barley"], 0.9)

func test_beer_style_has_ideal_flavor_profile():
	var s := BeerStyle.new()
	s.ideal_flavor_profile = {"bitterness": 0.3, "sweetness": 0.2, "roastiness": 0.8, "fruitiness": 0.1, "funkiness": 0.0}
	assert_eq(s.ideal_flavor_profile["roastiness"], 0.8)

func test_beer_style_get_ingredient_compatibility():
	var s := BeerStyle.new()
	s.preferred_ingredients = {"roasted_barley": 0.9}
	assert_eq(s.get_ingredient_compatibility("roasted_barley"), 0.9)
	assert_eq(s.get_ingredient_compatibility("unknown_ingredient"), 0.5)
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — `preferred_ingredients`, `ideal_flavor_profile`, `get_ingredient_compatibility` don't exist.

**Step 3: Write minimal implementation**

Replace `src/scripts/BeerStyle.gd`:

```gdscript
class_name BeerStyle
extends Resource

## Defines a beer style with its ideal balance, market properties, and ingredient preferences.

@export var style_id: String = ""
@export var style_name: String = ""
@export var description: String = ""

## The ideal ratio of Flavor points to total points (Flavor + Technique).
## 0.0 = pure Technique, 1.0 = pure Flavor.
@export_range(0.0, 1.0) var ideal_flavor_ratio: float = 0.5

## Base revenue per unit before quality and demand multipliers.
@export var base_price: float = 200.0

## Starting demand weight (1.0 = normal).
@export var base_demand_weight: float = 1.0

## Ingredient compatibility. Key = ingredient_id, Value = 0.0–1.0.
## Missing ingredient defaults to 0.5 (neutral).
@export var preferred_ingredients: Dictionary = {}

## Target flavor profile for this style. Keys: bitterness, sweetness, roastiness, fruitiness, funkiness.
@export var ideal_flavor_profile: Dictionary = {
	"bitterness": 0.0,
	"sweetness": 0.0,
	"roastiness": 0.0,
	"fruitiness": 0.0,
	"funkiness": 0.0,
}

func get_ingredient_compatibility(ingredient_id: String) -> float:
	return preferred_ingredients.get(ingredient_id, 0.5)
```

Update the 4 `.tres` style files to add `preferred_ingredients` and `ideal_flavor_profile`. Example for `src/data/styles/stout.tres`:

```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/BeerStyle.gd" id="1_beer_style"]

[resource]
script = ExtResource("1_beer_style")
style_id = "stout"
style_name = "Stout"
description = "Dark, roasty, and complex. Balancing roast bitterness with smooth body demands both skill and the right ingredients."
ideal_flavor_ratio = 0.45
base_price = 220.0
base_demand_weight = 1.0
preferred_ingredients = {"roasted_barley": 0.95, "chocolate_malt": 0.9, "pale_malt": 0.7, "crystal_60": 0.75, "munich_malt": 0.6, "east_kent_goldings": 0.85, "fuggle": 0.8, "cascade": 0.4, "s04_english_ale": 0.9, "us05_clean_ale": 0.75, "lactose": 0.7}
ideal_flavor_profile = {"bitterness": 0.4, "sweetness": 0.3, "roastiness": 0.8, "fruitiness": 0.1, "funkiness": 0.0}
```

Do the same for lager (low roastiness, high bitterness, clean), pale_ale (citrus/floral, medium bitterness), wheat_beer (fruity, low bitterness, some funkiness). See design doc for full ingredient catalog to match IDs.

**Step 4: Run test to verify it passes**

Run: `make test`
Expected: PASS.

**Step 5: Commit**

```bash
git add src/scripts/BeerStyle.gd src/data/styles/*.tres src/tests/test_ingredient_model.gd
git commit -m "feat: add preferred_ingredients and ideal_flavor_profile to BeerStyle"
```

---

### Task 5: Create full ingredient catalog as .tres files

**Files:**
- Delete: `src/data/ingredients/malts/pale_malt.tres` (and other old .tres files)
- Delete: `src/data/ingredients/hops/*.tres` (old ones)
- Delete: `src/data/ingredients/yeast/*.tres` (old ones)
- Create: `src/data/ingredients/malts/pilsner_malt.tres` (and 7 more malts)
- Create: `src/data/ingredients/hops/saaz.tres` (and 7 more hops)
- Create: `src/data/ingredients/yeast/us05_clean_ale.tres` (and 5 more yeasts)
- Create: `src/data/ingredients/adjuncts/lactose.tres` (and 3 more adjuncts)
- Test: `src/tests/test_ingredient_model.gd` (append)

**Step 1: Write the failing test**

Append to `src/tests/test_ingredient_model.gd`:

```gdscript
func test_catalog_loads_all_malts():
	var paths := [
		"res://data/ingredients/malts/pilsner_malt.tres",
		"res://data/ingredients/malts/pale_malt.tres",
		"res://data/ingredients/malts/maris_otter.tres",
		"res://data/ingredients/malts/munich_malt.tres",
		"res://data/ingredients/malts/crystal_60.tres",
		"res://data/ingredients/malts/chocolate_malt.tres",
		"res://data/ingredients/malts/roasted_barley.tres",
		"res://data/ingredients/malts/wheat_malt.tres",
	]
	for path in paths:
		var m = load(path)
		assert_not_null(m, "Should load malt at %s" % path)
		assert_true(m is Malt, "%s should be a Malt" % path)
	# Verify SRM range
	var pilsner = load(paths[0]) as Malt
	var roasted = load(paths[6]) as Malt
	assert_lt(pilsner.color_srm, 5.0, "Pilsner SRM should be < 5")
	assert_gt(roasted.color_srm, 400.0, "Roasted Barley SRM should be > 400")

func test_catalog_loads_all_hops():
	var paths := [
		"res://data/ingredients/hops/saaz.tres",
		"res://data/ingredients/hops/hallertau.tres",
		"res://data/ingredients/hops/east_kent_goldings.tres",
		"res://data/ingredients/hops/fuggle.tres",
		"res://data/ingredients/hops/cascade.tres",
		"res://data/ingredients/hops/centennial.tres",
		"res://data/ingredients/hops/citra.tres",
		"res://data/ingredients/hops/simcoe.tres",
	]
	for path in paths:
		var h = load(path)
		assert_not_null(h, "Should load hop at %s" % path)
		assert_true(h is Hop, "%s should be a Hop" % path)
	var saaz = load(paths[0]) as Hop
	var citra = load(paths[6]) as Hop
	assert_lt(saaz.alpha_acid_pct, 5.0, "Saaz alpha should be < 5")
	assert_gt(citra.alpha_acid_pct, 12.0 - 0.01, "Citra alpha should be >= 12")

func test_catalog_loads_all_yeasts():
	var paths := [
		"res://data/ingredients/yeast/us05_clean_ale.tres",
		"res://data/ingredients/yeast/s04_english_ale.tres",
		"res://data/ingredients/yeast/w3470_lager.tres",
		"res://data/ingredients/yeast/wb06_wheat.tres",
		"res://data/ingredients/yeast/belle_saison.tres",
		"res://data/ingredients/yeast/kveik_voss.tres",
	]
	for path in paths:
		var y = load(path)
		assert_not_null(y, "Should load yeast at %s" % path)
		assert_true(y is Yeast, "%s should be a Yeast" % path)

func test_catalog_loads_all_adjuncts():
	var paths := [
		"res://data/ingredients/adjuncts/lactose.tres",
		"res://data/ingredients/adjuncts/brewing_sugar.tres",
		"res://data/ingredients/adjuncts/irish_moss.tres",
		"res://data/ingredients/adjuncts/flaked_oats.tres",
	]
	for path in paths:
		var a = load(path)
		assert_not_null(a, "Should load adjunct at %s" % path)
		assert_true(a is Adjunct, "%s should be an Adjunct" % path)
	var lactose = load(paths[0]) as Adjunct
	assert_false(lactose.fermentable, "Lactose should not be fermentable")
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — new .tres files don't exist yet.

**Step 3: Write all .tres files**

Delete old .tres files in `src/data/ingredients/malts/`, `hops/`, `yeast/`.

Create new `.tres` files for each ingredient. Each `.tres` file follows this pattern — CRITICAL: use `type="Resource"` never custom class name. The script path points to the subclass (e.g., `res://scripts/Malt.gd`).

Example — `src/data/ingredients/malts/pilsner_malt.tres`:

```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/Malt.gd" id="1_malt"]

[resource]
script = ExtResource("1_malt")
ingredient_id = "pilsner_malt"
ingredient_name = "Pilsner Malt"
description = "Very light base malt. Clean, delicate, bready flavor. The foundation of lagers and pilsners."
category = 0
cost = 15
flavor_tags = ["light", "clean", "bready"]
flavor_profile = {"bitterness": 0.0, "sweetness": 0.2, "roastiness": 0.0, "fruitiness": 0.0, "funkiness": 0.0}
unlocked = true
color_srm = 2.0
body_contribution = 0.3
sweetness = 0.2
fermentability = 0.9
is_base_malt = true
```

Create all 26 .tres files following the catalog tables in the design doc. Create `src/data/ingredients/adjuncts/` directory. Set `unlocked = true` for starting ingredients (first 5 malts, first 4 hops, first 3 yeasts, 0 adjuncts) and `unlocked = false` for the rest.

**Initial unlock state:**
- Malts: Pilsner, Pale, Maris Otter, Munich, Wheat = unlocked; Crystal 60, Chocolate, Roasted Barley = locked
- Hops: Saaz, Hallertau, EKG, Fuggle = unlocked; Cascade, Centennial, Citra, Simcoe = locked
- Yeast: US-05, S-04, W-34/70 = unlocked; WB-06, Belle Saison, Kveik = locked
- Adjuncts: all locked

**Step 4: Run test to verify it passes**

Run: `make test`
Expected: PASS.

**Step 5: Commit**

```bash
git add src/data/ingredients/ src/tests/test_ingredient_model.gd
git commit -m "feat: create 26-item ingredient catalog (8 malts, 8 hops, 6 yeasts, 4 adjuncts)"
```

---

### Task 6: Update QualityCalculator ingredient scoring

**Files:**
- Modify: `src/autoloads/QualityCalculator.gd`
- Modify: `src/tests/test_quality_calculator.gd`

**Step 1: Write the failing tests**

Add new tests and update helpers in `src/tests/test_quality_calculator.gd`. The key change: recipe now uses arrays per category, and scoring uses BeerStyle's `preferred_ingredients` + `ideal_flavor_profile` instead of `Ingredient.style_compatibility`.

Replace the `_make_ingredient` helper and add new tests:

```gdscript
# Updated helper — creates a Malt (or generic Ingredient) with flavor_profile
func _make_malt(id: String, flavor_profile: Dictionary) -> Malt:
	var m := Malt.new()
	m.ingredient_id = id
	m.ingredient_name = id
	m.category = Ingredient.Category.MALT
	m.cost = 20
	m.flavor_profile = flavor_profile
	m.is_base_malt = true
	return m

func _make_hop(id: String, flavor_profile: Dictionary) -> Hop:
	var h := Hop.new()
	h.ingredient_id = id
	h.ingredient_name = id
	h.category = Ingredient.Category.HOP
	h.cost = 25
	h.flavor_profile = flavor_profile
	return h

func _make_yeast_res(id: String, flavor_profile: Dictionary) -> Yeast:
	var y := Yeast.new()
	y.ingredient_id = id
	y.ingredient_name = id
	y.category = Ingredient.Category.YEAST
	y.cost = 15
	y.flavor_profile = flavor_profile
	return y

func _make_style_with_profile(style_id: String, ideal_ratio: float, preferred: Dictionary, ideal_fp: Dictionary) -> BeerStyle:
	var s := BeerStyle.new()
	s.style_id = style_id
	s.style_name = style_id
	s.ideal_flavor_ratio = ideal_ratio
	s.base_price = 200.0
	s.preferred_ingredients = preferred
	s.ideal_flavor_profile = ideal_fp
	return s

# New recipe format: arrays per category
func _make_multi_recipe() -> Dictionary:
	var fp_neutral := {"bitterness": 0.0, "sweetness": 0.0, "roastiness": 0.0, "fruitiness": 0.0, "funkiness": 0.0}
	return {
		"malts": [_make_malt("pale_malt", fp_neutral)],
		"hops": [_make_hop("centennial", fp_neutral)],
		"yeast": _make_yeast_res("us05", fp_neutral),
		"adjuncts": [],
	}

func test_preferred_ingredient_scores_higher():
	var style := _make_style_with_profile("stout", 0.45,
		{"roasted_barley": 0.95, "pale_malt": 0.6},
		{"bitterness": 0.4, "sweetness": 0.3, "roastiness": 0.8, "fruitiness": 0.1, "funkiness": 0.0})
	var fp_roasty := {"bitterness": 0.3, "sweetness": 0.1, "roastiness": 0.9, "fruitiness": 0.0, "funkiness": 0.0}
	var fp_neutral := {"bitterness": 0.0, "sweetness": 0.0, "roastiness": 0.0, "fruitiness": 0.0, "funkiness": 0.0}

	var good_recipe := {
		"malts": [_make_malt("roasted_barley", fp_roasty)],
		"hops": [_make_hop("ekg", fp_neutral)],
		"yeast": _make_yeast_res("s04", fp_neutral),
		"adjuncts": [],
	}
	var bad_recipe := {
		"malts": [_make_malt("unknown_malt", fp_neutral)],
		"hops": [_make_hop("unknown_hop", fp_neutral)],
		"yeast": _make_yeast_res("unknown_yeast", fp_neutral),
		"adjuncts": [],
	}
	var sliders := {"mashing": 50.0, "boiling": 50.0, "fermenting": 50.0}
	var good_result := QualityCalculator.calculate_quality(style, good_recipe, sliders, [])
	var bad_result := QualityCalculator.calculate_quality(style, bad_recipe, sliders, [])
	assert_gt(good_result["ingredient_score"], bad_result["ingredient_score"],
		"Preferred ingredients should score higher")

func test_flavor_profile_match_scores_higher():
	var ideal_fp := {"bitterness": 0.4, "sweetness": 0.3, "roastiness": 0.8, "fruitiness": 0.1, "funkiness": 0.0}
	var style := _make_style_with_profile("stout", 0.45, {}, ideal_fp)
	var matching_fp := {"bitterness": 0.4, "sweetness": 0.3, "roastiness": 0.8, "fruitiness": 0.1, "funkiness": 0.0}
	var mismatched_fp := {"bitterness": 0.0, "sweetness": 0.0, "roastiness": 0.0, "fruitiness": 0.9, "funkiness": 0.8}

	var good_recipe := {
		"malts": [_make_malt("m1", matching_fp)],
		"hops": [_make_hop("h1", matching_fp)],
		"yeast": _make_yeast_res("y1", matching_fp),
		"adjuncts": [],
	}
	var bad_recipe := {
		"malts": [_make_malt("m2", mismatched_fp)],
		"hops": [_make_hop("h2", mismatched_fp)],
		"yeast": _make_yeast_res("y2", mismatched_fp),
		"adjuncts": [],
	}
	var sliders := {"mashing": 50.0, "boiling": 50.0, "fermenting": 50.0}
	var good_result := QualityCalculator.calculate_quality(style, good_recipe, sliders, [])
	var bad_result := QualityCalculator.calculate_quality(style, bad_recipe, sliders, [])
	assert_gt(good_result["ingredient_score"], bad_result["ingredient_score"],
		"Matching flavor profile should score higher")
```

Also update existing tests — change `_make_neutral_recipe` to return the new format and update all `_make_ingredient` calls to use the new helpers (or keep old helper as backward compat shim during transition).

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — QualityCalculator still expects old recipe format.

**Step 3: Write minimal implementation**

Update `src/autoloads/QualityCalculator.gd`:

- Change `_compute_ingredient_score` to accept new recipe format (arrays per category).
- Split into two sub-scores: `_compute_compatibility_score` (checks ingredient IDs against `style.preferred_ingredients`) and `_compute_flavor_match_score` (computes combined flavor profile, measures Euclidean distance to `style.ideal_flavor_profile`).
- Combine: `ingredient_score = compatibility_score * 0.5 + flavor_match_score * 0.5`.
- Update `_compute_novelty_modifier` to extract IDs from arrays.

Key implementation of new ingredient scoring:

```gdscript
func _compute_ingredient_score(style: BeerStyle, recipe: Dictionary) -> float:
	var compat := _compute_compatibility_score(style, recipe)
	var flavor := _compute_flavor_match_score(style, recipe)
	return compat * 0.5 + flavor * 0.5

func _compute_compatibility_score(style: BeerStyle, recipe: Dictionary) -> float:
	var total_compat := 0.0
	var count := 0
	for malt in recipe.get("malts", []):
		total_compat += style.get_ingredient_compatibility(malt.ingredient_id)
		count += 1
	for hop in recipe.get("hops", []):
		total_compat += style.get_ingredient_compatibility(hop.ingredient_id)
		count += 1
	var yeast: Ingredient = recipe.get("yeast", null)
	if yeast:
		total_compat += style.get_ingredient_compatibility(yeast.ingredient_id)
		count += 1
	for adj in recipe.get("adjuncts", []):
		total_compat += style.get_ingredient_compatibility(adj.ingredient_id)
		count += 1
	if count == 0:
		return 50.0
	return (total_compat / float(count)) * 100.0

func _compute_flavor_match_score(style: BeerStyle, recipe: Dictionary) -> float:
	var combined := _combine_flavor_profiles(recipe)
	var ideal: Dictionary = style.ideal_flavor_profile
	# Euclidean distance across 5 axes, normalized to 0-100
	var sum_sq := 0.0
	for axis in ["bitterness", "sweetness", "roastiness", "fruitiness", "funkiness"]:
		var diff: float = combined.get(axis, 0.0) - ideal.get(axis, 0.0)
		sum_sq += diff * diff
	var distance: float = sqrt(sum_sq)
	# Max possible distance = sqrt(5) ≈ 2.236 (all axes differ by 1.0)
	var max_dist: float = sqrt(5.0)
	return clampf((1.0 - distance / max_dist) * 100.0, 0.0, 100.0)

func _combine_flavor_profiles(recipe: Dictionary) -> Dictionary:
	var axes := ["bitterness", "sweetness", "roastiness", "fruitiness", "funkiness"]
	var totals := {}
	for axis in axes:
		totals[axis] = 0.0
	var count := 0
	for malt in recipe.get("malts", []):
		for axis in axes:
			totals[axis] += malt.flavor_profile.get(axis, 0.0)
		count += 1
	for hop in recipe.get("hops", []):
		for axis in axes:
			totals[axis] += hop.flavor_profile.get(axis, 0.0)
		count += 1
	var yeast: Ingredient = recipe.get("yeast", null)
	if yeast:
		for axis in axes:
			totals[axis] += yeast.flavor_profile.get(axis, 0.0)
		count += 1
	for adj in recipe.get("adjuncts", []):
		for axis in axes:
			totals[axis] += adj.flavor_profile.get(axis, 0.0)
		count += 1
	if count > 0:
		for axis in axes:
			totals[axis] /= float(count)
	return totals
```

Update `_compute_novelty_modifier` to work with arrays:

```gdscript
func _compute_novelty_modifier(style: BeerStyle, recipe: Dictionary, history: Array) -> float:
	var style_id: String = style.style_id if style else ""
	var malt_ids: Array = []
	for m in recipe.get("malts", []):
		malt_ids.append(m.ingredient_id)
	malt_ids.sort()
	var hop_ids: Array = []
	for h in recipe.get("hops", []):
		hop_ids.append(h.ingredient_id)
	hop_ids.sort()
	var yeast_id: String = recipe.get("yeast").ingredient_id if recipe.get("yeast") else ""
	var adjunct_ids: Array = []
	for a in recipe.get("adjuncts", []):
		adjunct_ids.append(a.ingredient_id)
	adjunct_ids.sort()

	var repeat_count := 0
	for entry in history:
		if (entry.get("style_id", "") == style_id and
			entry.get("malt_ids", []) == malt_ids and
			entry.get("hop_ids", []) == hop_ids and
			entry.get("yeast_id", "") == yeast_id and
			entry.get("adjunct_ids", []) == adjunct_ids):
			repeat_count += 1

	return maxf(1.0 - (repeat_count * NOVELTY_PENALTY_PER_REPEAT), NOVELTY_FLOOR)
```

**Step 4: Run test to verify it passes**

Run: `make test`
Expected: PASS (update all existing test helpers to new recipe format too).

**Step 5: Commit**

```bash
git add src/autoloads/QualityCalculator.gd src/tests/test_quality_calculator.gd
git commit -m "refactor: rewrite ingredient scoring with flavor profiles + preferred ingredients"
```

---

### Task 7: Update GameState for dynamic ingredient costs and new recipe format

**Files:**
- Modify: `src/autoloads/GameState.gd`
- Modify: `src/tests/test_economy.gd`

**Step 1: Write the failing tests**

Update `src/tests/test_economy.gd`:

```gdscript
func test_deduct_recipe_cost_sums_ingredients():
	GameState.balance = 500.0
	var m := Malt.new()
	m.cost = 20
	m.is_base_malt = true
	var h := Hop.new()
	h.cost = 25
	var y := Yeast.new()
	y.cost = 15
	var recipe := {"malts": [m], "hops": [h], "yeast": y, "adjuncts": []}
	GameState.set_recipe(recipe)
	var ok := GameState.deduct_ingredient_cost()
	assert_true(ok)
	assert_eq(GameState.balance, 440.0)  # 500 - (20+25+15)

func test_deduct_recipe_cost_with_multiple_malts():
	GameState.balance = 500.0
	var m1 := Malt.new()
	m1.cost = 20
	m1.is_base_malt = true
	var m2 := Malt.new()
	m2.cost = 25
	var h := Hop.new()
	h.cost = 25
	var y := Yeast.new()
	y.cost = 15
	var recipe := {"malts": [m1, m2], "hops": [h], "yeast": y, "adjuncts": []}
	GameState.set_recipe(recipe)
	var ok := GameState.deduct_ingredient_cost()
	assert_true(ok)
	assert_eq(GameState.balance, 415.0)  # 500 - (20+25+25+15)

func test_deduct_recipe_cost_fails_insufficient_balance():
	GameState.balance = 30.0
	var m := Malt.new()
	m.cost = 20
	m.is_base_malt = true
	var h := Hop.new()
	h.cost = 25
	var y := Yeast.new()
	y.cost = 15
	var recipe := {"malts": [m], "hops": [h], "yeast": y, "adjuncts": []}
	GameState.set_recipe(recipe)
	var ok := GameState.deduct_ingredient_cost()
	assert_false(ok)
	assert_eq(GameState.balance, 30.0)  # unchanged

func test_get_recipe_cost():
	var m := Malt.new()
	m.cost = 20
	var h := Hop.new()
	h.cost = 25
	var y := Yeast.new()
	y.cost = 15
	var a := Adjunct.new()
	a.cost = 10
	var recipe := {"malts": [m], "hops": [h], "yeast": y, "adjuncts": [a]}
	assert_eq(GameState.get_recipe_cost(recipe), 70)

func test_loss_condition_uses_minimum_recipe_cost():
	# Minimum recipe cost should be data-driven, not flat constant
	GameState.balance = 40.0
	# If min recipe cost is ~50 (15+20+15), 40 < 50 → loss
	assert_true(GameState.check_loss_condition())
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — `get_recipe_cost` doesn't exist, `deduct_ingredient_cost` uses flat constant.

**Step 3: Write minimal implementation**

Update `src/autoloads/GameState.gd`:

- Remove `INGREDIENT_COST` constant.
- Add `get_recipe_cost(recipe: Dictionary) -> int` that sums all ingredient costs.
- Update `deduct_ingredient_cost()` to use `get_recipe_cost(current_recipe)`.
- Add `get_minimum_recipe_cost() -> int` that returns the cheapest valid recipe (cheapest base malt + cheapest hop + cheapest yeast). This can be hardcoded to 50 initially or computed from loaded data.
- Update `check_loss_condition()` to use `get_minimum_recipe_cost()`.
- Update `record_brew()` to store arrays of IDs.
- Update `current_recipe` type documentation.

```gdscript
const MINIMUM_RECIPE_COST: int = 50  # Cheapest base malt (15) + cheapest hop (20) + cheapest yeast (15)

static func get_recipe_cost(recipe: Dictionary) -> int:
	var total := 0
	for malt in recipe.get("malts", []):
		total += malt.cost
	for hop in recipe.get("hops", []):
		total += hop.cost
	var yeast: Resource = recipe.get("yeast", null)
	if yeast:
		total += yeast.cost
	for adj in recipe.get("adjuncts", []):
		total += adj.cost
	return total

func deduct_ingredient_cost() -> bool:
	var cost := get_recipe_cost(current_recipe)
	if balance < cost:
		return false
	balance -= cost
	balance_changed.emit(balance)
	return true

func check_loss_condition() -> bool:
	return balance <= 0.0 or balance < MINIMUM_RECIPE_COST

func record_brew(quality: float) -> void:
	if quality > best_quality:
		best_quality = quality
	var malt_ids: Array = []
	for m in current_recipe.get("malts", []):
		malt_ids.append(m.ingredient_id)
	malt_ids.sort()
	var hop_ids: Array = []
	for h in current_recipe.get("hops", []):
		hop_ids.append(h.ingredient_id)
	hop_ids.sort()
	var yeast_id: String = current_recipe.get("yeast").ingredient_id if current_recipe.get("yeast") else ""
	var adjunct_ids: Array = []
	for a in current_recipe.get("adjuncts", []):
		adjunct_ids.append(a.ingredient_id)
	adjunct_ids.sort()
	recipe_history.append({
		"style_id": current_style.style_id if current_style else "",
		"malt_ids": malt_ids,
		"hop_ids": hop_ids,
		"yeast_id": yeast_id,
		"adjunct_ids": adjunct_ids,
	})
```

**Step 4: Run test to verify it passes**

Run: `make test`
Expected: PASS. Some old economy tests may need updating (remove references to `INGREDIENT_COST`).

**Step 5: Commit**

```bash
git add src/autoloads/GameState.gd src/tests/test_economy.gd
git commit -m "refactor: dynamic ingredient costs, multi-ingredient recipe format in GameState"
```

---

### Task 8: Update RecipeDesigner UI for multi-select

**Files:**
- Modify: `src/ui/RecipeDesigner.gd`
- Modify: `src/ui/RecipeDesigner.tscn`

**Step 1: No unit test for UI** — this is a UI-only change. Verify manually and rely on integration tests.

**Step 2: Update the .tscn**

Add a 4th column (AdjunctPanel) to the HBox. Update category titles to include counter badges. Add a SummaryPanel with flavor bars, color swatch, and cost display. Add a warning label for "No base malt selected."

Key .tscn changes:
- Add `AdjunctPanel` VBoxContainer as 4th child of HBox (same structure as other panels).
- Replace `SummaryPanel/Summary` single label with a VBox containing: FlavorBars (HBoxContainer with 5 ProgressBar nodes), ColorSwatch (ColorRect 24x24), CostLabel, WarningLabel.

**Step 3: Update RecipeDesigner.gd**

Major changes:
- Load all ingredients by scanning `res://data/ingredients/` directories (or use explicit path arrays for the 26 items).
- Change `_selected` from `{malt: null, hop: null, yeast: null}` to `{malts: [], hops: [], yeast: null, adjuncts: []}`.
- Selection limits: `{malts: 3, hops: 2, adjuncts: 2}` (yeast is always exactly 1).
- `_on_ingredient_pressed` toggles selection (add/remove from array) instead of radio-select.
- Counter badges update: "MALTS (2/3)" with accent color.
- Locked ingredients appear dimmed with "Locked" text, not clickable.
- `_check_brew_enabled`: requires 1+ malt with `is_base_malt`, 1+ hop, 1 yeast.
- `_update_summary`: compute combined flavor profile, show bars + color + cost.
- Emit new recipe format: `{malts: [...], hops: [...], yeast: ..., adjuncts: [...]}`.
- Show per-button cost as caption text (right-aligned).

```gdscript
const SELECTION_LIMITS := {"malts": 3, "hops": 2, "adjuncts": 2}

var _selected := {"malts": [], "hops": [], "yeast": null, "adjuncts": []}

func _on_ingredient_pressed(slot: String, ing: Resource, btn: Button) -> void:
	if not ing.unlocked:
		return
	if slot == "yeast":
		# Radio-style for yeast (exactly 1)
		_selected["yeast"] = ing
		_deselect_siblings(btn)
		btn.button_pressed = true
	else:
		# Toggle for multi-select categories
		if ing in _selected[slot]:
			_selected[slot].erase(ing)
			btn.button_pressed = false
		elif _selected[slot].size() < SELECTION_LIMITS[slot]:
			_selected[slot].append(ing)
			btn.button_pressed = true
	_update_counter_badges()
	_update_summary()
	_check_brew_enabled()

func _check_brew_enabled() -> void:
	var has_base_malt := false
	for m in _selected["malts"]:
		if m is Malt and m.is_base_malt:
			has_base_malt = true
			break
	brew_button.disabled = not (has_base_malt and
		_selected["hops"].size() >= 1 and
		_selected["yeast"] != null)
	# Show warning if malts selected but no base malt
	if _selected["malts"].size() > 0 and not has_base_malt:
		warning_label.text = "Recipe requires at least one base malt"
		warning_label.visible = true
	else:
		warning_label.visible = false
```

**Step 4: Run the game manually** to verify the UI works: 4 columns, toggle selection, counter badges, cost display, flavor bars update, locked items dimmed, warning shows when no base malt.

**Step 5: Commit**

```bash
git add src/ui/RecipeDesigner.gd src/ui/RecipeDesigner.tscn
git commit -m "feat: multi-select recipe designer with 4 categories, counters, flavor bars, costs"
```

---

### Task 9: Update integration tests and Game.gd

**Files:**
- Modify: `src/tests/test_integration.gd`
- Modify: `src/scenes/Game.gd` (update ingredient paths if Game.gd loads them)

**Step 1: Update integration tests**

The integration tests likely create recipes in old format. Update them to use the new `{malts: [...], hops: [...], yeast: ..., adjuncts: []}` format. Verify the full brew cycle works end-to-end with the new system.

**Step 2: Update Game.gd**

If `Game.gd` loads ingredient paths directly (it loads style paths), update any references. The RecipeDesigner now handles its own ingredient loading, so Game.gd may not need changes beyond ensuring it passes through the new recipe format correctly to GameState.

**Step 3: Run all tests**

Run: `make test`
Expected: ALL tests pass (54+ existing + new ingredient model tests).

**Step 4: Commit**

```bash
git add src/tests/test_integration.gd src/scenes/Game.gd
git commit -m "fix: update integration tests and Game.gd for new recipe format"
```

---

### Task 10: Final cleanup — remove dead code

**Files:**
- Modify: `src/scripts/Ingredient.gd` (if `get_compatibility` still exists, remove it)
- Verify: no remaining references to `style_compatibility`, `flavor_bonus`, `technique_bonus`, or `INGREDIENT_COST`

**Step 1: Search for dead references**

Search for: `style_compatibility`, `flavor_bonus`, `technique_bonus`, `INGREDIENT_COST`, `get_compatibility` across all `.gd` files. Remove any remaining references.

**Step 2: Run all tests**

Run: `make test`
Expected: ALL tests pass.

**Step 3: Commit**

```bash
git add -u
git commit -m "chore: remove dead ingredient fields (flavor_bonus, technique_bonus, style_compatibility)"
```
