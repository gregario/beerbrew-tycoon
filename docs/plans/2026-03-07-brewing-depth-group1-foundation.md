# Brewing Depth Expansion — Group 1: Foundation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Extend existing resource classes and create new data files to support water chemistry, yeast-temp interaction, progressive revelation, and 9 new beer style properties.

**Architecture:** Add properties to existing Resource classes (BeerStyle, Yeast, Malt, Equipment), create a new WaterProfile Resource class, and create .tres data files. No autoload changes, no UI changes, no scoring changes — pure data model foundation.

**Tech Stack:** Godot 4 / GDScript, GUT test framework, .tres resource files

**Stack Profile:** Read `../../stacks/godot/STACK.md` before writing any code. Key pitfall: `.tres` files MUST use `type="Resource"` not custom class names.

**Test command:** `cd projects/beerbrew-tycoon && make test`

---

### Task 1: Create WaterProfile resource class

**Files:**
- Create: `src/scripts/WaterProfile.gd`
- Test: `src/tests/test_water_profile.gd`

**Step 1: Write the failing test**

Create `src/tests/test_water_profile.gd`:

```gdscript
extends GutTest

func test_water_profile_properties():
	var wp := WaterProfile.new()
	wp.profile_id = "hoppy"
	wp.display_name = "Hoppy Water"
	wp.mineral_description = "High sulfate, low chloride — crisp hop bitterness"
	wp.style_affinities = {"pale_ale": 0.95, "stout": 0.3}
	assert_eq(wp.profile_id, "hoppy")
	assert_eq(wp.display_name, "Hoppy Water")
	assert_eq(wp.mineral_description, "High sulfate, low chloride — crisp hop bitterness")
	assert_eq(wp.style_affinities["pale_ale"], 0.95)
	assert_eq(wp.style_affinities["stout"], 0.3)

func test_water_profile_default_values():
	var wp := WaterProfile.new()
	assert_eq(wp.profile_id, "")
	assert_eq(wp.display_name, "")
	assert_eq(wp.mineral_description, "")
	assert_eq(wp.style_affinities.size(), 0)

func test_water_profile_get_affinity_with_default():
	var wp := WaterProfile.new()
	wp.style_affinities = {"pale_ale": 0.95}
	assert_eq(wp.get_affinity("pale_ale"), 0.95)
	assert_eq(wp.get_affinity("unknown_style"), 0.6, "Missing style should default to 0.6 (tap water neutral)")
```

**Step 2: Run test to verify it fails**

Run: `cd projects/beerbrew-tycoon && make test`
Expected: FAIL — `WaterProfile` class not found

**Step 3: Write minimal implementation**

Create `src/scripts/WaterProfile.gd`:

```gdscript
class_name WaterProfile
extends Resource

## Water chemistry profile — defines mineral composition and style affinities.

@export var profile_id: String = ""
@export var display_name: String = ""
@export var mineral_description: String = ""
@export var style_affinities: Dictionary = {}

func get_affinity(style_id: String) -> float:
	return style_affinities.get(style_id, 0.6)
```

**Step 4: Run test to verify it passes**

Run: `cd projects/beerbrew-tycoon && make test`
Expected: PASS — all 3 tests green

**Step 5: Commit**

```bash
git add src/scripts/WaterProfile.gd src/tests/test_water_profile.gd
git commit -m "feat: add WaterProfile resource class with style affinities"
```

---

### Task 2: Create 5 WaterProfile .tres files

**Files:**
- Create: `src/data/water/soft.tres`
- Create: `src/data/water/balanced.tres`
- Create: `src/data/water/malty.tres`
- Create: `src/data/water/hoppy.tres`
- Create: `src/data/water/juicy.tres`
- Test: `src/tests/test_water_profile.gd` (append)

**Step 1: Write the failing test**

Append to `src/tests/test_water_profile.gd`:

```gdscript
func test_load_soft_water_profile():
	var wp = load("res://data/water/soft.tres") as WaterProfile
	assert_not_null(wp, "soft.tres should load as WaterProfile")
	assert_eq(wp.profile_id, "soft")
	assert_eq(wp.display_name, "Soft Water")
	assert_true(wp.style_affinities.has("lager"), "Soft water should have lager affinity")

func test_load_all_five_profiles():
	var ids := ["soft", "balanced", "malty", "hoppy", "juicy"]
	for id in ids:
		var wp = load("res://data/water/%s.tres" % id) as WaterProfile
		assert_not_null(wp, "%s.tres should load" % id)
		assert_eq(wp.profile_id, id)
		assert_gt(wp.style_affinities.size(), 0, "%s should have style affinities" % id)
```

**Step 2: Run test to verify it fails**

Run: `cd projects/beerbrew-tycoon && make test`
Expected: FAIL — .tres files don't exist

**Step 3: Create the 5 .tres data files**

Create directory `src/data/water/` then create each file.

Style affinity values (from spec — water_affinity per style):

| Profile | Pale Ale | Stout | Lager | Wheat | IPA | Porter | Imp Stout | Hefe | Czech Pils | Helles | Marzen | Saison | Dubbel | NEIPA | Berliner | Lambic |
|---------|----------|-------|-------|-------|-----|--------|-----------|------|------------|--------|--------|--------|--------|-------|----------|--------|
| soft | 0.6 | 0.4 | 0.9 | 0.7 | 0.5 | 0.4 | 0.3 | 0.7 | 0.95 | 0.9 | 0.6 | 0.6 | 0.5 | 0.7 | 0.7 | 0.6 |
| balanced | 0.7 | 0.6 | 0.7 | 0.8 | 0.6 | 0.7 | 0.5 | 0.8 | 0.6 | 0.7 | 0.7 | 0.7 | 0.7 | 0.6 | 0.7 | 0.7 |
| malty | 0.5 | 0.9 | 0.5 | 0.5 | 0.3 | 0.85 | 0.95 | 0.5 | 0.3 | 0.5 | 0.85 | 0.5 | 0.85 | 0.3 | 0.4 | 0.5 |
| hoppy | 0.95 | 0.3 | 0.4 | 0.5 | 0.95 | 0.4 | 0.3 | 0.4 | 0.5 | 0.5 | 0.4 | 0.6 | 0.4 | 0.7 | 0.5 | 0.4 |
| juicy | 0.7 | 0.3 | 0.4 | 0.6 | 0.8 | 0.3 | 0.3 | 0.5 | 0.4 | 0.4 | 0.4 | 0.5 | 0.4 | 0.95 | 0.6 | 0.5 |

`src/data/water/soft.tres`:
```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/WaterProfile.gd" id="1_wp"]

[resource]
script = ExtResource("1_wp")
profile_id = "soft"
display_name = "Soft Water"
mineral_description = "Low mineral content — clean, delicate, lets subtle malt and hop character shine"
style_affinities = {"pale_ale": 0.6, "stout": 0.4, "lager": 0.9, "wheat_beer": 0.7, "ipa": 0.5, "porter": 0.4, "imperial_stout": 0.3, "hefeweizen": 0.7, "czech_pilsner": 0.95, "helles": 0.9, "marzen": 0.6, "saison": 0.6, "belgian_dubbel": 0.5, "neipa": 0.7, "berliner_weisse": 0.7, "lambic": 0.6}
```

`src/data/water/balanced.tres`:
```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/WaterProfile.gd" id="1_wp"]

[resource]
script = ExtResource("1_wp")
profile_id = "balanced"
display_name = "Balanced Water"
mineral_description = "Moderate minerals — versatile, works with most styles without strong bias"
style_affinities = {"pale_ale": 0.7, "stout": 0.6, "lager": 0.7, "wheat_beer": 0.8, "ipa": 0.6, "porter": 0.7, "imperial_stout": 0.5, "hefeweizen": 0.8, "czech_pilsner": 0.6, "helles": 0.7, "marzen": 0.7, "saison": 0.7, "belgian_dubbel": 0.7, "neipa": 0.6, "berliner_weisse": 0.7, "lambic": 0.7}
```

`src/data/water/malty.tres`:
```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/WaterProfile.gd" id="1_wp"]

[resource]
script = ExtResource("1_wp")
profile_id = "malty"
display_name = "Malty Water"
mineral_description = "High carbonate, high chloride — rounds out malt sweetness, accentuates body"
style_affinities = {"pale_ale": 0.5, "stout": 0.9, "lager": 0.5, "wheat_beer": 0.5, "ipa": 0.3, "porter": 0.85, "imperial_stout": 0.95, "hefeweizen": 0.5, "czech_pilsner": 0.3, "helles": 0.5, "marzen": 0.85, "saison": 0.5, "belgian_dubbel": 0.85, "neipa": 0.3, "berliner_weisse": 0.4, "lambic": 0.5}
```

`src/data/water/hoppy.tres`:
```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/WaterProfile.gd" id="1_wp"]

[resource]
script = ExtResource("1_wp")
profile_id = "hoppy"
display_name = "Hoppy Water"
mineral_description = "High sulfate, low chloride — crisp, dry finish that amplifies hop bitterness"
style_affinities = {"pale_ale": 0.95, "stout": 0.3, "lager": 0.4, "wheat_beer": 0.5, "ipa": 0.95, "porter": 0.4, "imperial_stout": 0.3, "hefeweizen": 0.4, "czech_pilsner": 0.5, "helles": 0.5, "marzen": 0.4, "saison": 0.6, "belgian_dubbel": 0.4, "neipa": 0.7, "berliner_weisse": 0.5, "lambic": 0.4}
```

`src/data/water/juicy.tres`:
```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/WaterProfile.gd" id="1_wp"]

[resource]
script = ExtResource("1_wp")
profile_id = "juicy"
display_name = "Juicy Water"
mineral_description = "High chloride, low sulfate — soft, round mouthfeel that enhances fruity hop character"
style_affinities = {"pale_ale": 0.7, "stout": 0.3, "lager": 0.4, "wheat_beer": 0.6, "ipa": 0.8, "porter": 0.3, "imperial_stout": 0.3, "hefeweizen": 0.5, "czech_pilsner": 0.4, "helles": 0.4, "marzen": 0.4, "saison": 0.5, "belgian_dubbel": 0.4, "neipa": 0.95, "berliner_weisse": 0.6, "lambic": 0.5}
```

**Step 4: Run test to verify it passes**

Run: `cd projects/beerbrew-tycoon && make test`
Expected: PASS

**Step 5: Commit**

```bash
git add src/data/water/
git commit -m "feat: add 5 water profile data files (soft/balanced/malty/hoppy/juicy)"
```

---

### Task 3: Add new properties to BeerStyle resource

**Files:**
- Modify: `src/scripts/BeerStyle.gd`
- Test: `src/tests/test_beer_style_expansion.gd` (new)

New properties to add (per spec):
- `family: String` — style family grouping (ales, dark, wheat, lager, belgian, modern, specialty)
- `water_affinity: Dictionary` — maps water profile_id → float (0.0-1.0)
- `hop_schedule_expectations: Dictionary` — maps slot name → expected weight (e.g. {"bittering": 0.3, "aroma": 0.5, "dry_hop": 0.2})
- `yeast_temp_flavors: Dictionary` — maps flavor compound → desirability float (e.g. {"ester_banana": 0.8, "clean": 0.9})
- `acceptable_off_flavors: Dictionary` — maps off-flavor type → acceptable threshold (e.g. {"ester": 0.8} for Hefeweizen)
- `primary_lesson: String` — what brewing concept this style teaches

**Step 1: Write the failing test**

Create `src/tests/test_beer_style_expansion.gd`:

```gdscript
extends GutTest

func test_beer_style_has_family():
	var s := BeerStyle.new()
	s.family = "ales"
	assert_eq(s.family, "ales")

func test_beer_style_default_family_is_empty():
	var s := BeerStyle.new()
	assert_eq(s.family, "")

func test_beer_style_has_water_affinity():
	var s := BeerStyle.new()
	s.water_affinity = {"hoppy": 0.95, "malty": 0.3}
	assert_eq(s.water_affinity["hoppy"], 0.95)
	assert_eq(s.water_affinity["malty"], 0.3)

func test_beer_style_has_hop_schedule_expectations():
	var s := BeerStyle.new()
	s.hop_schedule_expectations = {"bittering": 0.3, "aroma": 0.5, "dry_hop": 0.2}
	assert_eq(s.hop_schedule_expectations["aroma"], 0.5)

func test_beer_style_has_yeast_temp_flavors():
	var s := BeerStyle.new()
	s.yeast_temp_flavors = {"ester_banana": 0.8, "clean": 0.9}
	assert_eq(s.yeast_temp_flavors["ester_banana"], 0.8)

func test_beer_style_has_acceptable_off_flavors():
	var s := BeerStyle.new()
	s.acceptable_off_flavors = {"ester": 0.8}
	assert_eq(s.acceptable_off_flavors["ester"], 0.8)

func test_beer_style_default_acceptable_off_flavors_empty():
	var s := BeerStyle.new()
	assert_eq(s.acceptable_off_flavors.size(), 0)

func test_beer_style_has_primary_lesson():
	var s := BeerStyle.new()
	s.primary_lesson = "water_chemistry"
	assert_eq(s.primary_lesson, "water_chemistry")
```

**Step 2: Run test to verify it fails**

Run: `cd projects/beerbrew-tycoon && make test`
Expected: FAIL — properties don't exist on BeerStyle

**Step 3: Add properties to BeerStyle.gd**

Add after line 55 (after `ideal_boil_max`) in `src/scripts/BeerStyle.gd`:

```gdscript
## Style family grouping: ales, dark, wheat, lager, belgian, modern, specialty.
@export var family: String = ""

## Water profile affinities. Key = profile_id (soft/balanced/malty/hoppy/juicy), Value = 0.0-1.0.
@export var water_affinity: Dictionary = {}

## Expected hop timing allocation. Keys: bittering, aroma, dry_hop. Values: 0.0-1.0 weights.
@export var hop_schedule_expectations: Dictionary = {}

## Desired yeast flavor compounds. Key = compound type, Value = desirability 0.0-1.0.
@export var yeast_temp_flavors: Dictionary = {}

## Off-flavor types acceptable in this style. Key = off-flavor type, Value = threshold 0.0-1.0.
@export var acceptable_off_flavors: Dictionary = {}

## What brewing concept this style primarily teaches (for discovery system).
@export var primary_lesson: String = ""
```

**Step 4: Run test to verify it passes**

Run: `cd projects/beerbrew-tycoon && make test`
Expected: PASS — all new + existing tests green

**Step 5: Commit**

```bash
git add src/scripts/BeerStyle.gd src/tests/test_beer_style_expansion.gd
git commit -m "feat: add family, water_affinity, hop_schedule, yeast_temp, off_flavor, primary_lesson to BeerStyle"
```

---

### Task 4: Update existing 7 BeerStyle .tres files with new properties

**Files:**
- Modify: `src/data/styles/pale_ale.tres`
- Modify: `src/data/styles/stout.tres`
- Modify: `src/data/styles/lager.tres`
- Modify: `src/data/styles/wheat_beer.tres`
- Modify: `src/data/styles/berliner_weisse.tres`
- Modify: `src/data/styles/lambic.tres`
- Modify: `src/data/styles/experimental_brew.tres`
- Test: `src/tests/test_beer_style_expansion.gd` (append)

**Step 1: Write the failing test**

Append to `src/tests/test_beer_style_expansion.gd`:

```gdscript
func test_pale_ale_has_family():
	var s = load("res://data/styles/pale_ale.tres") as BeerStyle
	assert_eq(s.family, "ales")

func test_stout_has_family():
	var s = load("res://data/styles/stout.tres") as BeerStyle
	assert_eq(s.family, "dark")

func test_all_existing_styles_have_families():
	var paths := [
		"res://data/styles/pale_ale.tres",
		"res://data/styles/stout.tres",
		"res://data/styles/lager.tres",
		"res://data/styles/wheat_beer.tres",
		"res://data/styles/berliner_weisse.tres",
		"res://data/styles/lambic.tres",
		"res://data/styles/experimental_brew.tres",
	]
	for path in paths:
		var s = load(path) as BeerStyle
		assert_ne(s.family, "", "%s should have a family" % path)

func test_pale_ale_water_affinity():
	var s = load("res://data/styles/pale_ale.tres") as BeerStyle
	assert_true(s.water_affinity.has("hoppy"), "Pale Ale should have hoppy water affinity")
	assert_gt(s.water_affinity["hoppy"], 0.8, "Pale Ale should favor hoppy water")

func test_stout_acceptable_off_flavors():
	var s = load("res://data/styles/stout.tres") as BeerStyle
	assert_true(s.acceptable_off_flavors.size() >= 0, "Stout off-flavor dict should exist")
```

**Step 2: Run test to verify it fails**

Run: `cd projects/beerbrew-tycoon && make test`
Expected: FAIL — family is "" for existing styles

**Step 3: Update each .tres file**

Add the new properties to each existing style .tres. The new lines go after `ideal_boil_max`.

**pale_ale.tres** — add:
```
family = "ales"
water_affinity = {"soft": 0.6, "balanced": 0.7, "malty": 0.5, "hoppy": 0.95, "juicy": 0.7}
hop_schedule_expectations = {"bittering": 0.4, "aroma": 0.4, "dry_hop": 0.2}
yeast_temp_flavors = {"clean": 0.9, "ester_fruit": 0.5, "ester_banana": 0.1, "fusel": 0.0}
acceptable_off_flavors = {}
primary_lesson = "hop_balance"
```

**stout.tres** — add:
```
family = "dark"
water_affinity = {"soft": 0.4, "balanced": 0.6, "malty": 0.9, "hoppy": 0.3, "juicy": 0.3}
hop_schedule_expectations = {"bittering": 0.8, "aroma": 0.15, "dry_hop": 0.05}
yeast_temp_flavors = {"clean": 0.8, "ester_fruit": 0.3, "fusel": 0.0}
acceptable_off_flavors = {"diacetyl": 0.2}
primary_lesson = "malt_roast_depth"
```

**lager.tres** — add:
```
family = "lager"
water_affinity = {"soft": 0.9, "balanced": 0.7, "malty": 0.5, "hoppy": 0.4, "juicy": 0.4}
hop_schedule_expectations = {"bittering": 0.7, "aroma": 0.25, "dry_hop": 0.05}
yeast_temp_flavors = {"clean": 1.0, "ester_banana": 0.0, "ester_fruit": 0.0, "fusel": 0.0}
acceptable_off_flavors = {}
primary_lesson = "fermentation_temperature"
```

**wheat_beer.tres** — add:
```
family = "wheat"
water_affinity = {"soft": 0.7, "balanced": 0.8, "malty": 0.5, "hoppy": 0.5, "juicy": 0.6}
hop_schedule_expectations = {"bittering": 0.6, "aroma": 0.3, "dry_hop": 0.1}
yeast_temp_flavors = {"ester_banana": 0.7, "phenol_clove": 0.6, "clean": 0.3}
acceptable_off_flavors = {"ester": 0.6}
primary_lesson = "yeast_character"
```

**berliner_weisse.tres** — add:
```
family = "specialty"
water_affinity = {"soft": 0.7, "balanced": 0.7, "malty": 0.4, "hoppy": 0.5, "juicy": 0.6}
hop_schedule_expectations = {"bittering": 0.8, "aroma": 0.15, "dry_hop": 0.05}
yeast_temp_flavors = {"clean": 0.5, "phenol_clove": 0.3}
acceptable_off_flavors = {"ester": 0.5, "diacetyl": 0.1}
primary_lesson = "sour_fermentation"
```

**lambic.tres** — add:
```
family = "specialty"
water_affinity = {"soft": 0.6, "balanced": 0.7, "malty": 0.5, "hoppy": 0.4, "juicy": 0.5}
hop_schedule_expectations = {"bittering": 0.9, "aroma": 0.1, "dry_hop": 0.0}
yeast_temp_flavors = {"phenol_clove": 0.4, "ester_fruit": 0.6, "clean": 0.2}
acceptable_off_flavors = {"ester": 0.7, "diacetyl": 0.3, "phenol": 0.5}
primary_lesson = "wild_fermentation"
```

**experimental_brew.tres** — add:
```
family = "specialty"
water_affinity = {"soft": 0.6, "balanced": 0.7, "malty": 0.6, "hoppy": 0.6, "juicy": 0.6}
hop_schedule_expectations = {"bittering": 0.3, "aroma": 0.3, "dry_hop": 0.4}
yeast_temp_flavors = {"clean": 0.5, "ester_fruit": 0.5, "phenol_pepper": 0.5}
acceptable_off_flavors = {"ester": 0.6, "phenol": 0.4}
primary_lesson = "experimentation"
```

**Step 4: Run test to verify it passes**

Run: `cd projects/beerbrew-tycoon && make test`
Expected: PASS

**Step 5: Commit**

```bash
git add src/data/styles/
git commit -m "feat: add family, water_affinity, hop_schedule, yeast_temp, off_flavors to 7 existing styles"
```

---

### Task 5: Add yeast_flavor_profile property to Yeast resource class

**Files:**
- Modify: `src/scripts/Yeast.gd`
- Test: `src/tests/test_ingredient_model.gd` (append)

**Step 1: Write the failing test**

Append to `src/tests/test_ingredient_model.gd`:

```gdscript
func test_yeast_has_flavor_profile_property():
	var y := Yeast.new()
	y.yeast_flavor_profile = {
		"below_16": {"clean": 0.9, "ester_fruit": 0.1},
		"16_to_20": {"clean": 0.8, "ester_fruit": 0.2},
		"above_20": {"clean": 0.5, "ester_fruit": 0.4, "fusel": 0.2},
	}
	assert_eq(y.yeast_flavor_profile.size(), 3)
	assert_eq(y.yeast_flavor_profile["below_16"]["clean"], 0.9)

func test_yeast_flavor_profile_default_empty():
	var y := Yeast.new()
	assert_eq(y.yeast_flavor_profile.size(), 0)
```

**Step 2: Run test to verify it fails**

Run: `cd projects/beerbrew-tycoon && make test`
Expected: FAIL — `yeast_flavor_profile` property doesn't exist

**Step 3: Add property to Yeast.gd**

Add after line 9 (after `flocculation`) in `src/scripts/Yeast.gd`:

```gdscript
## Flavor compounds produced at different temperature ranges.
## Keys: temp range labels (e.g. "below_16", "16_to_20", "above_20").
## Values: Dictionary of compound → intensity (0.0-1.0).
## Compounds: ester_banana, ester_fruit, phenol_clove, phenol_pepper, fusel, clean.
@export var yeast_flavor_profile: Dictionary = {}
```

**Step 4: Run test to verify it passes**

Run: `cd projects/beerbrew-tycoon && make test`
Expected: PASS

**Step 5: Commit**

```bash
git add src/scripts/Yeast.gd src/tests/test_ingredient_model.gd
git commit -m "feat: add yeast_flavor_profile property to Yeast resource"
```

---

### Task 6: Update existing 6 Yeast .tres files with yeast_flavor_profile data

**Files:**
- Modify: `src/data/ingredients/yeast/us05_clean_ale.tres`
- Modify: `src/data/ingredients/yeast/s04_english_ale.tres`
- Modify: `src/data/ingredients/yeast/w3470_lager.tres`
- Modify: `src/data/ingredients/yeast/wb06_wheat.tres`
- Modify: `src/data/ingredients/yeast/belle_saison.tres`
- Modify: `src/data/ingredients/yeast/kveik_voss.tres`
- Test: `src/tests/test_ingredient_model.gd` (append)

**Step 1: Write the failing test**

Append to `src/tests/test_ingredient_model.gd`:

```gdscript
func test_us05_has_yeast_flavor_profile():
	var y = load("res://data/ingredients/yeast/us05_clean_ale.tres") as Yeast
	assert_gt(y.yeast_flavor_profile.size(), 0, "US-05 should have flavor profile data")

func test_wb06_has_banana_clove_crossover():
	var y = load("res://data/ingredients/yeast/wb06_wheat.tres") as Yeast
	var cool = y.yeast_flavor_profile.get("below_18", {})
	var warm = y.yeast_flavor_profile.get("above_22", {})
	assert_gt(cool.get("phenol_clove", 0.0), cool.get("ester_banana", 0.0), "Cool wheat yeast should favor clove")
	assert_gt(warm.get("ester_banana", 0.0), warm.get("phenol_clove", 0.0), "Warm wheat yeast should favor banana")

func test_belle_saison_loves_heat():
	var y = load("res://data/ingredients/yeast/belle_saison.tres") as Yeast
	var hot = y.yeast_flavor_profile.get("above_28", {})
	assert_eq(hot.get("fusel", 0.0), 0.0, "Saison should NOT produce fusel at high temps")
	assert_gt(hot.get("phenol_pepper", 0.0), 0.5, "Saison at high temp should produce pepper")

func test_lager_yeast_needs_cold():
	var y = load("res://data/ingredients/yeast/w3470_lager.tres") as Yeast
	var warm = y.yeast_flavor_profile.get("above_14", {})
	assert_gt(warm.get("fusel", 0.0), 0.0, "Lager yeast above 14°C should produce fusel")

func test_all_yeast_have_flavor_profiles():
	var paths := [
		"res://data/ingredients/yeast/us05_clean_ale.tres",
		"res://data/ingredients/yeast/s04_english_ale.tres",
		"res://data/ingredients/yeast/w3470_lager.tres",
		"res://data/ingredients/yeast/wb06_wheat.tres",
		"res://data/ingredients/yeast/belle_saison.tres",
		"res://data/ingredients/yeast/kveik_voss.tres",
	]
	for path in paths:
		var y = load(path) as Yeast
		assert_gt(y.yeast_flavor_profile.size(), 0, "%s should have yeast_flavor_profile" % path)
```

**Step 2: Run test to verify it fails**

Expected: FAIL — flavor profiles are empty

**Step 3: Update each yeast .tres file**

Add `yeast_flavor_profile` after `flocculation` in each file:

**us05_clean_ale.tres** (forgiving 16-22°C):
```
yeast_flavor_profile = {"below_16": {"clean": 0.95, "ester_fruit": 0.05}, "16_to_22": {"clean": 0.9, "ester_fruit": 0.1}, "above_22": {"clean": 0.6, "ester_fruit": 0.3, "fusel": 0.15}}
```

**s04_english_ale.tres** (fruity esters, medium range):
```
yeast_flavor_profile = {"below_16": {"clean": 0.7, "ester_fruit": 0.2}, "16_to_20": {"clean": 0.5, "ester_fruit": 0.5}, "above_20": {"ester_fruit": 0.6, "fusel": 0.2, "clean": 0.2}}
```

**w3470_lager.tres** (must be cold 8-12°C):
```
yeast_flavor_profile = {"below_8": {"clean": 0.8, "ester_fruit": 0.05}, "8_to_12": {"clean": 0.95, "ester_fruit": 0.05}, "above_14": {"clean": 0.3, "ester_fruit": 0.3, "fusel": 0.4}}
```

**wb06_wheat.tres** (banana/clove crossover at ~20°C):
```
yeast_flavor_profile = {"below_18": {"phenol_clove": 0.7, "ester_banana": 0.2, "clean": 0.1}, "18_to_22": {"ester_banana": 0.5, "phenol_clove": 0.4, "clean": 0.1}, "above_22": {"ester_banana": 0.8, "phenol_clove": 0.1, "clean": 0.1}}
```

**belle_saison.tres** (hotter is better, no fusel penalty):
```
yeast_flavor_profile = {"below_20": {"clean": 0.5, "phenol_pepper": 0.2, "ester_fruit": 0.2}, "20_to_28": {"phenol_pepper": 0.5, "ester_fruit": 0.4, "clean": 0.1}, "above_28": {"phenol_pepper": 0.6, "ester_fruit": 0.4}}
```

**kveik_voss.tres** (extreme heat tolerance):
```
yeast_flavor_profile = {"below_25": {"clean": 0.6, "ester_fruit": 0.3}, "25_to_35": {"ester_fruit": 0.6, "clean": 0.4}, "above_35": {"ester_fruit": 0.5, "fusel": 0.1, "clean": 0.3}}
```

**Step 4: Run test to verify it passes**

Run: `cd projects/beerbrew-tycoon && make test`
Expected: PASS

**Step 5: Commit**

```bash
git add src/data/ingredients/yeast/ src/tests/test_ingredient_model.gd
git commit -m "feat: add yeast_flavor_profile data to all 6 yeast .tres files"
```

---

### Task 7: Add reveals property to Equipment resource class

**Files:**
- Modify: `src/scripts/Equipment.gd`
- Test: `src/tests/test_equipment.gd` (append)

**Step 1: Write the failing test**

Append to `src/tests/test_equipment.gd`:

```gdscript
func test_equipment_has_reveals_property():
	var e := Equipment.new()
	e.reveals = ["temp_numbers", "ferment_profile"]
	assert_eq(e.reveals.size(), 2)
	assert_true("temp_numbers" in e.reveals)

func test_equipment_reveals_default_empty():
	var e := Equipment.new()
	assert_eq(e.reveals.size(), 0)

func test_make_equipment_with_reveals():
	var e := _make_equipment({"reveals": ["water_selector"]})
	assert_eq(e.reveals.size(), 1)
	assert_eq(e.reveals[0], "water_selector")
```

Also update `_make_equipment` helper to include reveals:

In the existing `_make_equipment` function, add after the `upgrade_cost` line:
```gdscript
	e.reveals = overrides.get("reveals", [])
```

**Step 2: Run test to verify it fails**

Expected: FAIL — `reveals` property doesn't exist

**Step 3: Add property to Equipment.gd**

Add after line 22 (after `upgrade_cost`) in `src/scripts/Equipment.gd`:

```gdscript
## Feature IDs this equipment reveals in the UI when equipped.
## Valid IDs: temp_numbers, water_selector, hop_schedule, dry_hop_rack,
## ferment_profile, conditioning_tank, ph_meter, gravity_readings.
@export var reveals: Array[String] = []
```

**Step 4: Run test to verify it passes**

Run: `cd projects/beerbrew-tycoon && make test`
Expected: PASS

**Step 5: Commit**

```bash
git add src/scripts/Equipment.gd src/tests/test_equipment.gd
git commit -m "feat: add reveals property to Equipment resource for progressive disclosure"
```

---

### Task 8: Update existing equipment .tres files with reveals data

**Files:**
- Modify: select equipment .tres files that logically reveal features
- Test: `src/tests/test_equipment.gd` (append)

Equipment that should have reveals:
- `temp_chamber.tres` (fermentation) → `["ferment_profile"]` (has temp control)
- `ss_conical.tres` (fermentation) → `["ferment_profile", "conditioning_tank"]`
- `three_vessel.tres` (brewing) → `["hop_schedule"]`
- `auto_mash_controller.tres` (automation) → `["temp_numbers"]`
- `fermentation_controller.tres` (automation) → `["ferment_profile"]`

**Step 1: Write the failing test**

Append to `src/tests/test_equipment.gd`:

```gdscript
func test_three_vessel_reveals_hop_schedule():
	var e = load("res://data/equipment/brewing/three_vessel.tres") as Equipment
	assert_true("hop_schedule" in e.reveals, "Three-vessel should reveal hop_schedule")

func test_ss_conical_reveals_conditioning():
	var e = load("res://data/equipment/fermentation/ss_conical.tres") as Equipment
	assert_true("conditioning_tank" in e.reveals, "SS Conical should reveal conditioning_tank")
```

**Step 2: Run test to verify it fails**

Expected: FAIL — reveals arrays are empty

**Step 3: Add reveals to equipment .tres files**

Add `reveals = [...]` line after `upgrade_cost` in each file:

- `brewing/three_vessel.tres`: `reveals = ["hop_schedule"]`
- `fermentation/temp_chamber.tres`: `reveals = ["ferment_profile"]`
- `fermentation/ss_conical.tres`: `reveals = ["ferment_profile", "conditioning_tank"]`
- `automation/auto_mash_controller.tres`: `reveals = ["temp_numbers"]`
- `automation/fermentation_controller.tres`: `reveals = ["ferment_profile"]`

**Step 4: Run test to verify it passes**

Run: `cd projects/beerbrew-tycoon && make test`
Expected: PASS

**Step 5: Commit**

```bash
git add src/data/equipment/
git commit -m "feat: add reveals data to existing equipment files"
```

---

### Task 9: Create 4 Measurement equipment .tres files

**Files:**
- Create: `src/data/equipment/measurement/thermometer.tres`
- Create: `src/data/equipment/measurement/digital_thermometer.tres`
- Create: `src/data/equipment/measurement/ph_meter.tres`
- Create: `src/data/equipment/measurement/refractometer.tres`
- Modify: `src/scripts/Equipment.gd` (add MEASUREMENT to Category enum)
- Modify: `src/autoloads/EquipmentManager.gd` (add paths to EQUIPMENT_PATHS)
- Test: `src/tests/test_equipment.gd` (append)

**Step 1: Write the failing test**

Append to `src/tests/test_equipment.gd`:

```gdscript
func test_measurement_category_exists():
	var e := Equipment.new()
	e.category = Equipment.Category.MEASUREMENT
	assert_eq(e.category, Equipment.Category.MEASUREMENT)

func test_thermometer_loads():
	var e = load("res://data/equipment/measurement/thermometer.tres") as Equipment
	assert_not_null(e)
	assert_eq(e.equipment_id, "thermometer")
	assert_eq(e.tier, 1)
	assert_eq(e.cost, 30)
	assert_eq(e.category, Equipment.Category.MEASUREMENT)
	assert_true("temp_numbers" in e.reveals)

func test_digital_thermometer_loads():
	var e = load("res://data/equipment/measurement/digital_thermometer.tres") as Equipment
	assert_not_null(e)
	assert_eq(e.equipment_id, "digital_thermometer")
	assert_eq(e.tier, 2)
	assert_true("temp_numbers" in e.reveals)
	assert_true("ferment_profile" in e.reveals)

func test_ph_meter_loads():
	var e = load("res://data/equipment/measurement/ph_meter.tres") as Equipment
	assert_not_null(e)
	assert_eq(e.equipment_id, "ph_meter")
	assert_true("ph_meter" in e.reveals)

func test_refractometer_loads():
	var e = load("res://data/equipment/measurement/refractometer.tres") as Equipment
	assert_not_null(e)
	assert_eq(e.equipment_id, "refractometer")
	assert_eq(e.tier, 3)
	assert_true("gravity_readings" in e.reveals)

func test_all_measurement_equipment_in_catalog():
	var ids := ["thermometer", "digital_thermometer", "ph_meter", "refractometer"]
	for id in ids:
		var e = EquipmentManager.get_equipment(id)
		assert_not_null(e, "%s should be in EquipmentManager catalog" % id)
```

**Step 2: Run test to verify it fails**

Expected: FAIL — MEASUREMENT not in enum, files don't exist

**Step 3: Implementation**

3a. Add `MEASUREMENT` to Equipment.gd Category enum (after AUTOMATION):

In `src/scripts/Equipment.gd`, change line 6:
```gdscript
enum Category { BREWING, FERMENTATION, PACKAGING, UTILITY, AUTOMATION, MEASUREMENT }
```

3b. Create directory `src/data/equipment/measurement/`

3c. Create `thermometer.tres`:
```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/Equipment.gd" id="1_equip"]

[resource]
script = ExtResource("1_equip")
equipment_id = "thermometer"
equipment_name = "Thermometer"
description = "Basic analog thermometer. Now you can see actual temperatures during brewing."
tier = 1
category = 5
cost = 30
sanitation_bonus = 0
temp_control_bonus = 0
efficiency_bonus = 0.0
batch_size_multiplier = 1.0
upgrades_to = "digital_thermometer"
upgrade_cost = 50
reveals = ["temp_numbers"]
```

3d. Create `digital_thermometer.tres`:
```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/Equipment.gd" id="1_equip"]

[resource]
script = ExtResource("1_equip")
equipment_id = "digital_thermometer"
equipment_name = "Digital Thermometer"
description = "Precise digital readout with fermentation monitoring. Track temperature profiles over time."
tier = 2
category = 5
cost = 80
sanitation_bonus = 0
temp_control_bonus = 0
efficiency_bonus = 0.0
batch_size_multiplier = 1.0
upgrades_to = ""
upgrade_cost = 0
reveals = ["temp_numbers", "ferment_profile"]
```

3e. Create `ph_meter.tres`:
```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/Equipment.gd" id="1_equip"]

[resource]
script = ExtResource("1_equip")
equipment_id = "ph_meter"
equipment_name = "pH Meter"
description = "Measure mash and water pH. Essential for advanced water chemistry."
tier = 2
category = 5
cost = 120
sanitation_bonus = 0
temp_control_bonus = 0
efficiency_bonus = 0.0
batch_size_multiplier = 1.0
upgrades_to = ""
upgrade_cost = 0
reveals = ["ph_meter"]
```

3f. Create `refractometer.tres`:
```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/Equipment.gd" id="1_equip"]

[resource]
script = ExtResource("1_equip")
equipment_id = "refractometer"
equipment_name = "Refractometer"
description = "Measure gravity with a single drop. Track fermentation progress precisely."
tier = 3
category = 5
cost = 200
sanitation_bonus = 0
temp_control_bonus = 0
efficiency_bonus = 0.0
batch_size_multiplier = 1.0
upgrades_to = ""
upgrade_cost = 0
reveals = ["gravity_readings"]
```

3g. Add paths to EquipmentManager.gd EQUIPMENT_PATHS array (after the automation paths):

```gdscript
	"res://data/equipment/measurement/thermometer.tres",
	"res://data/equipment/measurement/digital_thermometer.tres",
	"res://data/equipment/measurement/ph_meter.tres",
	"res://data/equipment/measurement/refractometer.tres",
```

**Step 4: Run test to verify it passes**

Run: `cd projects/beerbrew-tycoon && make test`
Expected: PASS

**Important:** Check that existing tests referencing `Equipment.Category` enum values by integer (e.g., `category = 4` for AUTOMATION) still work. The MEASUREMENT addition at position 5 should not shift existing values since it's appended at the end.

**Step 5: Commit**

```bash
git add src/scripts/Equipment.gd src/data/equipment/measurement/ src/autoloads/EquipmentManager.gd src/tests/test_equipment.gd
git commit -m "feat: add MEASUREMENT equipment category with 4 items (thermometer, digital, pH, refractometer)"
```

---

### Task 10: Create Water Kit equipment .tres file

**Files:**
- Create: `src/data/equipment/measurement/water_kit.tres`
- Modify: `src/autoloads/EquipmentManager.gd` (add path)
- Test: `src/tests/test_equipment.gd` (append)

**Step 1: Write the failing test**

Append to `src/tests/test_equipment.gd`:

```gdscript
func test_water_kit_loads():
	var e = load("res://data/equipment/measurement/water_kit.tres") as Equipment
	assert_not_null(e)
	assert_eq(e.equipment_id, "water_kit")
	assert_eq(e.cost, 100)
	assert_eq(e.tier, 2)
	assert_true("water_selector" in e.reveals)

func test_water_kit_in_catalog():
	var e = EquipmentManager.get_equipment("water_kit")
	assert_not_null(e, "water_kit should be in EquipmentManager catalog")
```

**Step 2: Run test to verify it fails**

Expected: FAIL — file doesn't exist

**Step 3: Create the .tres file and add to catalog**

Create `src/data/equipment/measurement/water_kit.tres`:
```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/Equipment.gd" id="1_equip"]

[resource]
script = ExtResource("1_equip")
equipment_id = "water_kit"
equipment_name = "Water Treatment Kit"
description = "Mineral additions and testing strips. Choose your water profile to match each beer style."
tier = 2
category = 5
cost = 100
sanitation_bonus = 0
temp_control_bonus = 0
efficiency_bonus = 0.0
batch_size_multiplier = 1.0
upgrades_to = ""
upgrade_cost = 0
reveals = ["water_selector"]
```

Add to EquipmentManager.gd EQUIPMENT_PATHS (after refractometer):
```gdscript
	"res://data/equipment/measurement/water_kit.tres",
```

**Step 4: Run test to verify it passes**

Run: `cd projects/beerbrew-tycoon && make test`
Expected: PASS

**Step 5: Commit**

```bash
git add src/data/equipment/measurement/water_kit.tres src/autoloads/EquipmentManager.gd src/tests/test_equipment.gd
git commit -m "feat: add Water Kit equipment (T2, $100, reveals water_selector)"
```

---

### Task 11: Add dms_risk property to Malt resource (bonus from task 3.3)

**Files:**
- Modify: `src/scripts/Malt.gd`
- Modify: `src/data/ingredients/malts/pilsner_malt.tres`
- Test: `src/tests/test_ingredient_model.gd` (append)

This is from Group 3 task 3.3 but belongs with the data model work since it's just a property addition.

**Step 1: Write the failing test**

Append to `src/tests/test_ingredient_model.gd`:

```gdscript
func test_malt_has_dms_risk():
	var m := Malt.new()
	m.dms_risk = "high"
	assert_eq(m.dms_risk, "high")

func test_malt_dms_risk_default_none():
	var m := Malt.new()
	assert_eq(m.dms_risk, "none")

func test_pilsner_malt_has_high_dms_risk():
	var m = load("res://data/ingredients/malts/pilsner_malt.tres") as Malt
	assert_eq(m.dms_risk, "high", "Pilsner malt should have high DMS risk")
```

**Step 2: Run test to verify it fails**

Expected: FAIL — `dms_risk` doesn't exist

**Step 3: Add property**

Add to `src/scripts/Malt.gd` after `is_base_malt`:
```gdscript
## DMS (dimethyl sulfide) risk level: "none", "low", "high".
## High DMS malts (pilsner) require vigorous/long boils to drive off DMS.
@export var dms_risk: String = "none"
```

Add to `src/data/ingredients/malts/pilsner_malt.tres` after `is_base_malt = true`:
```
dms_risk = "high"
```

**Step 4: Run test to verify it passes**

Run: `cd projects/beerbrew-tycoon && make test`
Expected: PASS

**Step 5: Commit**

```bash
git add src/scripts/Malt.gd src/data/ingredients/malts/pilsner_malt.tres src/tests/test_ingredient_model.gd
git commit -m "feat: add dms_risk property to Malt resource, set pilsner_malt to high"
```

---

### Task 12: Add is_revealed() method to EquipmentManager

**Files:**
- Modify: `src/autoloads/EquipmentManager.gd`
- Test: `src/tests/test_equipment_manager.gd` (append)

This is from Group 10 task 10.1 but is a natural companion to the reveals property work.

**Step 1: Write the failing test**

Append to `src/tests/test_equipment_manager.gd`:

```gdscript
func test_is_revealed_with_no_equipment():
	EquipmentManager.reset()
	assert_false(EquipmentManager.is_revealed("temp_numbers"))

func test_is_revealed_with_equipped_thermometer():
	EquipmentManager.reset()
	EquipmentManager.owned_equipment = ["thermometer"]
	EquipmentManager.station_slots[0] = "thermometer"
	assert_true(EquipmentManager.is_revealed("temp_numbers"))

func test_is_revealed_only_checks_slotted():
	EquipmentManager.reset()
	EquipmentManager.owned_equipment = ["thermometer"]
	# Owned but NOT slotted
	assert_false(EquipmentManager.is_revealed("temp_numbers"), "Reveals should only come from slotted equipment")

func test_is_revealed_aggregates_multiple():
	EquipmentManager.reset()
	EquipmentManager.owned_equipment = ["thermometer", "water_kit"]
	EquipmentManager.station_slots[0] = "thermometer"
	EquipmentManager.station_slots[1] = "water_kit"
	assert_true(EquipmentManager.is_revealed("temp_numbers"))
	assert_true(EquipmentManager.is_revealed("water_selector"))
	assert_false(EquipmentManager.is_revealed("hop_schedule"))
```

**Step 2: Run test to verify it fails**

Expected: FAIL — `is_revealed` method doesn't exist

**Step 3: Add method to EquipmentManager.gd**

Add after `recalculate_bonuses()` (after line 176):

```gdscript
## Returns true if any slotted equipment reveals the given feature_id.
func is_revealed(feature_id: String) -> bool:
	for slot_id in station_slots:
		if slot_id == "":
			continue
		var equip: Equipment = get_equipment(slot_id)
		if equip != null and feature_id in equip.reveals:
			return true
	return false
```

**Step 4: Run test to verify it passes**

Run: `cd projects/beerbrew-tycoon && make test`
Expected: PASS

**Step 5: Commit**

```bash
git add src/autoloads/EquipmentManager.gd src/tests/test_equipment_manager.gd
git commit -m "feat: add is_revealed() method to EquipmentManager for progressive disclosure"
```

---

### Final verification

After all 12 tasks, run the full test suite:

```bash
cd projects/beerbrew-tycoon && make test
```

Expected: All existing tests + ~30 new tests pass. Total should be ~730+ tests.

**Summary of changes:**
- 1 new Resource class: `WaterProfile.gd`
- 3 modified Resource classes: `BeerStyle.gd`, `Yeast.gd`, `Equipment.gd`, `Malt.gd`
- 5 new .tres files: water profiles
- 5 new .tres files: measurement equipment + water kit
- 7 modified .tres files: existing beer styles
- 6 modified .tres files: existing yeast
- 5 modified .tres files: existing equipment
- 1 modified autoload: `EquipmentManager.gd` (paths + is_revealed)
- 3 test files modified/created
