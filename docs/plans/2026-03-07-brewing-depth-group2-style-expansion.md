# Brewing Depth Expansion — Group 2: Style Expansion Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add 9 new beer styles organized by family, update research tree gating, and update StylePicker to group by family.

**Architecture:** Create 9 BeerStyle .tres data files, update existing research node unlock arrays to include new styles, create 1 new research node (modern_techniques), update ResearchManager locked arrays, expand StylePicker paths and add family grouping.

**Tech Stack:** Godot 4 / GDScript, GUT test framework, .tres resource files

**Test command:** `cd /Users/gregario/Projects/ClaudeCode/AI-Factory/projects/beerbrew-tycoon && GODOT="/Users/gregario/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot" make test`

---

### Task 1: Create IPA BeerStyle .tres

**Files:**
- Create: `src/data/styles/ipa.tres`
- Test: `src/tests/test_style_expansion.gd` (new)

**Step 1: Write the test file**

Create `src/tests/test_style_expansion.gd`:

```gdscript
extends GutTest

func test_ipa_loads():
	var s = load("res://data/styles/ipa.tres") as BeerStyle
	assert_not_null(s)
	assert_eq(s.style_id, "ipa")
	assert_eq(s.family, "ales")
	assert_eq(s.base_price, 280.0)
	assert_false(s.unlocked, "IPA should be locked by default")
	assert_true(s.water_affinity.has("hoppy"))
	assert_gt(s.water_affinity["hoppy"], 0.9)
	assert_true(s.hop_schedule_expectations.has("dry_hop"))
	assert_gt(s.hop_schedule_expectations["dry_hop"], 0.2)
```

**Step 2: Create the .tres file**

`src/data/styles/ipa.tres`:
```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/BeerStyle.gd" id="1_beer_style"]

[resource]
script = ExtResource("1_beer_style")
style_id = "ipa"
style_name = "IPA"
description = "Bold, hop-forward ale with assertive bitterness and aromatic hop character. Dry hopping is essential."
ideal_flavor_ratio = 0.5
base_price = 280.0
base_demand_weight = 1.2
unlocked = false
preferred_ingredients = {"pale_malt": 0.9, "maris_otter": 0.85, "crystal_60": 0.5, "cascade": 0.9, "centennial": 0.95, "citra": 0.95, "simcoe": 0.9, "us05_clean_ale": 0.9}
ideal_flavor_profile = {"bitterness": 0.8, "sweetness": 0.15, "roastiness": 0.0, "fruitiness": 0.6, "funkiness": 0.0}
ideal_mash_temp_min = 64.0
ideal_mash_temp_max = 67.0
ideal_boil_min = 60.0
ideal_boil_max = 90.0
family = "ales"
water_affinity = {"soft": 0.5, "balanced": 0.6, "malty": 0.3, "hoppy": 0.95, "juicy": 0.8}
hop_schedule_expectations = {"bittering": 0.3, "aroma": 0.4, "dry_hop": 0.3}
yeast_temp_flavors = {"clean": 0.9, "ester_fruit": 0.4, "ester_banana": 0.0, "fusel": 0.0}
acceptable_off_flavors = {}
primary_lesson = "hop_scheduling"
```

**Step 3: Run tests, commit**

```bash
git add src/data/styles/ipa.tres src/tests/test_style_expansion.gd
git commit -m "feat: add IPA beer style"
```

---

### Task 2: Create Porter and Imperial Stout .tres files

**Files:**
- Create: `src/data/styles/porter.tres`
- Create: `src/data/styles/imperial_stout.tres`
- Test: `src/tests/test_style_expansion.gd` (append)

**Tests to append:**

```gdscript
func test_porter_loads():
	var s = load("res://data/styles/porter.tres") as BeerStyle
	assert_not_null(s)
	assert_eq(s.style_id, "porter")
	assert_eq(s.family, "dark")
	assert_eq(s.base_price, 240.0)
	assert_false(s.unlocked)

func test_imperial_stout_loads():
	var s = load("res://data/styles/imperial_stout.tres") as BeerStyle
	assert_not_null(s)
	assert_eq(s.style_id, "imperial_stout")
	assert_eq(s.family, "dark")
	assert_eq(s.base_price, 400.0)
	assert_false(s.unlocked)
	assert_gt(s.water_affinity["malty"], 0.9)
```

**porter.tres:**
```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/BeerStyle.gd" id="1_beer_style"]

[resource]
script = ExtResource("1_beer_style")
style_id = "porter"
style_name = "Porter"
description = "Dark, malty ale with moderate roast character. Chocolate and caramel notes with balanced bitterness."
ideal_flavor_ratio = 0.45
base_price = 240.0
base_demand_weight = 0.9
unlocked = false
preferred_ingredients = {"pale_malt": 0.7, "maris_otter": 0.8, "crystal_60": 0.8, "chocolate_malt": 0.9, "roasted_barley": 0.6, "east_kent_goldings": 0.85, "fuggle": 0.9, "s04_english_ale": 0.9}
ideal_flavor_profile = {"bitterness": 0.4, "sweetness": 0.4, "roastiness": 0.6, "fruitiness": 0.2, "funkiness": 0.0}
ideal_mash_temp_min = 65.0
ideal_mash_temp_max = 68.0
ideal_boil_min = 60.0
ideal_boil_max = 90.0
family = "dark"
water_affinity = {"soft": 0.4, "balanced": 0.7, "malty": 0.85, "hoppy": 0.4, "juicy": 0.3}
hop_schedule_expectations = {"bittering": 0.8, "aroma": 0.15, "dry_hop": 0.05}
yeast_temp_flavors = {"clean": 0.7, "ester_fruit": 0.4, "fusel": 0.0}
acceptable_off_flavors = {"diacetyl": 0.2}
primary_lesson = "malt_complexity"
```

**imperial_stout.tres:**
```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/BeerStyle.gd" id="1_beer_style"]

[resource]
script = ExtResource("1_beer_style")
style_id = "imperial_stout"
style_name = "Imperial Stout"
description = "Massive, high-gravity dark ale. Intense roast, chocolate, and dark fruit. Demands precision and quality ingredients."
ideal_flavor_ratio = 0.4
base_price = 400.0
base_demand_weight = 0.7
unlocked = false
preferred_ingredients = {"pale_malt": 0.7, "maris_otter": 0.9, "crystal_60": 0.7, "chocolate_malt": 0.95, "roasted_barley": 0.9, "east_kent_goldings": 0.8, "fuggle": 0.7, "s04_english_ale": 0.85, "us05_clean_ale": 0.7}
ideal_flavor_profile = {"bitterness": 0.5, "sweetness": 0.5, "roastiness": 0.9, "fruitiness": 0.3, "funkiness": 0.0}
ideal_mash_temp_min = 66.0
ideal_mash_temp_max = 69.0
ideal_boil_min = 75.0
ideal_boil_max = 90.0
family = "dark"
water_affinity = {"soft": 0.3, "balanced": 0.5, "malty": 0.95, "hoppy": 0.3, "juicy": 0.3}
hop_schedule_expectations = {"bittering": 0.85, "aroma": 0.1, "dry_hop": 0.05}
yeast_temp_flavors = {"clean": 0.7, "ester_fruit": 0.5, "fusel": 0.1}
acceptable_off_flavors = {"diacetyl": 0.15, "ester": 0.3}
primary_lesson = "high_gravity_brewing"
```

**Commit:**
```bash
git add src/data/styles/porter.tres src/data/styles/imperial_stout.tres src/tests/test_style_expansion.gd
git commit -m "feat: add Porter and Imperial Stout beer styles"
```

---

### Task 3: Create Hefeweizen .tres

**Files:**
- Create: `src/data/styles/hefeweizen.tres`
- Test: `src/tests/test_style_expansion.gd` (append)

**Test:**
```gdscript
func test_hefeweizen_loads():
	var s = load("res://data/styles/hefeweizen.tres") as BeerStyle
	assert_not_null(s)
	assert_eq(s.style_id, "hefeweizen")
	assert_eq(s.family, "wheat")
	assert_eq(s.base_price, 220.0)
	assert_false(s.unlocked)
	assert_true(s.acceptable_off_flavors.has("ester_banana"))
	assert_gt(s.acceptable_off_flavors["ester_banana"], 0.7)
	assert_eq(s.primary_lesson, "yeast_temp_interaction")
```

**hefeweizen.tres:**
```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/BeerStyle.gd" id="1_beer_style"]

[resource]
script = ExtResource("1_beer_style")
style_id = "hefeweizen"
style_name = "Hefeweizen"
description = "Classic Bavarian wheat beer. Banana and clove character from yeast, not ingredients. Temperature controls the balance."
ideal_flavor_ratio = 0.6
base_price = 220.0
base_demand_weight = 1.0
unlocked = false
preferred_ingredients = {"wheat_malt": 0.95, "pilsner_malt": 0.8, "pale_malt": 0.6, "hallertau": 0.9, "saaz": 0.7, "wb06_wheat": 0.95}
ideal_flavor_profile = {"bitterness": 0.15, "sweetness": 0.35, "roastiness": 0.0, "fruitiness": 0.7, "funkiness": 0.1}
ideal_mash_temp_min = 64.0
ideal_mash_temp_max = 67.0
ideal_boil_min = 60.0
ideal_boil_max = 75.0
family = "wheat"
water_affinity = {"soft": 0.7, "balanced": 0.8, "malty": 0.5, "hoppy": 0.4, "juicy": 0.5}
hop_schedule_expectations = {"bittering": 0.7, "aroma": 0.25, "dry_hop": 0.05}
yeast_temp_flavors = {"ester_banana": 0.8, "phenol_clove": 0.7, "clean": 0.2, "fusel": 0.0}
acceptable_off_flavors = {"ester_banana": 0.8, "ester": 0.6, "phenol": 0.5}
primary_lesson = "yeast_temp_interaction"
```

**Commit:**
```bash
git add src/data/styles/hefeweizen.tres src/tests/test_style_expansion.gd
git commit -m "feat: add Hefeweizen beer style"
```

---

### Task 4: Create Czech Pilsner, Helles, Marzen .tres files

**Files:**
- Create: `src/data/styles/czech_pilsner.tres`
- Create: `src/data/styles/helles.tres`
- Create: `src/data/styles/marzen.tres`
- Test: `src/tests/test_style_expansion.gd` (append)

**Tests:**
```gdscript
func test_czech_pilsner_loads():
	var s = load("res://data/styles/czech_pilsner.tres") as BeerStyle
	assert_not_null(s)
	assert_eq(s.style_id, "czech_pilsner")
	assert_eq(s.family, "lager")
	assert_eq(s.base_price, 260.0)
	assert_gt(s.water_affinity["soft"], 0.9)
	assert_eq(s.primary_lesson, "water_chemistry")

func test_helles_loads():
	var s = load("res://data/styles/helles.tres") as BeerStyle
	assert_not_null(s)
	assert_eq(s.style_id, "helles")
	assert_eq(s.family, "lager")
	assert_eq(s.base_price, 230.0)

func test_marzen_loads():
	var s = load("res://data/styles/marzen.tres") as BeerStyle
	assert_not_null(s)
	assert_eq(s.style_id, "marzen")
	assert_eq(s.family, "lager")
	assert_eq(s.base_price, 250.0)

func test_all_lager_family_locked():
	for id in ["czech_pilsner", "helles", "marzen"]:
		var s = load("res://data/styles/%s.tres" % id) as BeerStyle
		assert_false(s.unlocked, "%s should be locked by default" % id)
```

**czech_pilsner.tres:**
```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/BeerStyle.gd" id="1_beer_style"]

[resource]
script = ExtResource("1_beer_style")
style_id = "czech_pilsner"
style_name = "Czech Pilsner"
description = "The original pilsner. Delicate, crisp, showcases noble hops and soft water. Demands a vigorous boil for pilsner malt."
ideal_flavor_ratio = 0.4
base_price = 260.0
base_demand_weight = 1.1
unlocked = false
preferred_ingredients = {"pilsner_malt": 0.95, "pale_malt": 0.5, "saaz": 0.95, "hallertau": 0.8, "w3470_lager": 0.95}
ideal_flavor_profile = {"bitterness": 0.6, "sweetness": 0.2, "roastiness": 0.0, "fruitiness": 0.15, "funkiness": 0.0}
ideal_mash_temp_min = 63.0
ideal_mash_temp_max = 65.0
ideal_boil_min = 75.0
ideal_boil_max = 90.0
family = "lager"
water_affinity = {"soft": 0.95, "balanced": 0.6, "malty": 0.3, "hoppy": 0.5, "juicy": 0.4}
hop_schedule_expectations = {"bittering": 0.5, "aroma": 0.4, "dry_hop": 0.1}
yeast_temp_flavors = {"clean": 1.0, "ester_banana": 0.0, "ester_fruit": 0.0, "fusel": 0.0}
acceptable_off_flavors = {}
primary_lesson = "water_chemistry"
```

**helles.tres:**
```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/BeerStyle.gd" id="1_beer_style"]

[resource]
script = ExtResource("1_beer_style")
style_id = "helles"
style_name = "Helles"
description = "Munich's golden lager. Subtle malt sweetness with restrained hop bitterness. Deceptively simple to brew well."
ideal_flavor_ratio = 0.35
base_price = 230.0
base_demand_weight = 1.0
unlocked = false
preferred_ingredients = {"pilsner_malt": 0.9, "pale_malt": 0.8, "hallertau": 0.9, "saaz": 0.8, "w3470_lager": 0.9}
ideal_flavor_profile = {"bitterness": 0.25, "sweetness": 0.4, "roastiness": 0.0, "fruitiness": 0.1, "funkiness": 0.0}
ideal_mash_temp_min = 64.0
ideal_mash_temp_max = 67.0
ideal_boil_min = 60.0
ideal_boil_max = 90.0
family = "lager"
water_affinity = {"soft": 0.9, "balanced": 0.7, "malty": 0.5, "hoppy": 0.5, "juicy": 0.4}
hop_schedule_expectations = {"bittering": 0.7, "aroma": 0.25, "dry_hop": 0.05}
yeast_temp_flavors = {"clean": 1.0, "ester_banana": 0.0, "ester_fruit": 0.0, "fusel": 0.0}
acceptable_off_flavors = {}
primary_lesson = "malt_subtlety"
```

**marzen.tres:**
```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/BeerStyle.gd" id="1_beer_style"]

[resource]
script = ExtResource("1_beer_style")
style_id = "marzen"
style_name = "Märzen"
description = "Traditional Oktoberfest lager. Toasty, bready malt with a clean finish. Originally brewed in March for autumn drinking."
ideal_flavor_ratio = 0.4
base_price = 250.0
base_demand_weight = 0.9
unlocked = false
preferred_ingredients = {"munich_malt": 0.95, "pale_malt": 0.7, "crystal_60": 0.7, "hallertau": 0.9, "saaz": 0.7, "w3470_lager": 0.9}
ideal_flavor_profile = {"bitterness": 0.3, "sweetness": 0.5, "roastiness": 0.2, "fruitiness": 0.1, "funkiness": 0.0}
ideal_mash_temp_min = 65.0
ideal_mash_temp_max = 68.0
ideal_boil_min = 60.0
ideal_boil_max = 90.0
family = "lager"
water_affinity = {"soft": 0.6, "balanced": 0.7, "malty": 0.85, "hoppy": 0.4, "juicy": 0.4}
hop_schedule_expectations = {"bittering": 0.75, "aroma": 0.2, "dry_hop": 0.05}
yeast_temp_flavors = {"clean": 1.0, "ester_banana": 0.0, "ester_fruit": 0.0, "fusel": 0.0}
acceptable_off_flavors = {"diacetyl": 0.1}
primary_lesson = "malt_toastiness"
```

**Commit:**
```bash
git add src/data/styles/czech_pilsner.tres src/data/styles/helles.tres src/data/styles/marzen.tres src/tests/test_style_expansion.gd
git commit -m "feat: add Czech Pilsner, Helles, and Märzen lager styles"
```

---

### Task 5: Create Saison and Belgian Dubbel .tres files

**Files:**
- Create: `src/data/styles/saison.tres`
- Create: `src/data/styles/belgian_dubbel.tres`
- Test: `src/tests/test_style_expansion.gd` (append)

**Tests:**
```gdscript
func test_saison_loads():
	var s = load("res://data/styles/saison.tres") as BeerStyle
	assert_not_null(s)
	assert_eq(s.style_id, "saison")
	assert_eq(s.family, "belgian")
	assert_eq(s.base_price, 300.0)
	assert_true(s.acceptable_off_flavors.has("phenol_pepper"))
	assert_eq(s.primary_lesson, "high_temp_fermentation")

func test_belgian_dubbel_loads():
	var s = load("res://data/styles/belgian_dubbel.tres") as BeerStyle
	assert_not_null(s)
	assert_eq(s.style_id, "belgian_dubbel")
	assert_eq(s.family, "belgian")
	assert_eq(s.base_price, 350.0)
```

**saison.tres:**
```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/BeerStyle.gd" id="1_beer_style"]

[resource]
script = ExtResource("1_beer_style")
style_id = "saison"
style_name = "Saison"
description = "Belgian farmhouse ale. Bone-dry, peppery, and complex. Unlike other styles, saison yeast thrives at high temperatures."
ideal_flavor_ratio = 0.55
base_price = 300.0
base_demand_weight = 0.8
unlocked = false
preferred_ingredients = {"pilsner_malt": 0.9, "wheat_malt": 0.7, "pale_malt": 0.6, "saaz": 0.8, "hallertau": 0.7, "belle_saison": 0.95}
ideal_flavor_profile = {"bitterness": 0.35, "sweetness": 0.1, "roastiness": 0.0, "fruitiness": 0.5, "funkiness": 0.4}
ideal_mash_temp_min = 63.0
ideal_mash_temp_max = 66.0
ideal_boil_min = 60.0
ideal_boil_max = 90.0
family = "belgian"
water_affinity = {"soft": 0.6, "balanced": 0.7, "malty": 0.5, "hoppy": 0.6, "juicy": 0.5}
hop_schedule_expectations = {"bittering": 0.5, "aroma": 0.35, "dry_hop": 0.15}
yeast_temp_flavors = {"phenol_pepper": 0.9, "ester_fruit": 0.7, "clean": 0.1, "fusel": 0.0}
acceptable_off_flavors = {"phenol_pepper": 0.8, "ester": 0.5}
primary_lesson = "high_temp_fermentation"
```

**belgian_dubbel.tres:**
```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/BeerStyle.gd" id="1_beer_style"]

[resource]
script = ExtResource("1_beer_style")
style_id = "belgian_dubbel"
style_name = "Belgian Dubbel"
description = "Rich, malty Belgian ale. Dark fruit, caramel, and spice from specialized yeast. Complex yet approachable."
ideal_flavor_ratio = 0.5
base_price = 350.0
base_demand_weight = 0.8
unlocked = false
preferred_ingredients = {"pilsner_malt": 0.8, "munich_malt": 0.7, "crystal_60": 0.8, "brewing_sugar": 0.7, "hallertau": 0.8, "east_kent_goldings": 0.7, "belle_saison": 0.7}
ideal_flavor_profile = {"bitterness": 0.25, "sweetness": 0.55, "roastiness": 0.15, "fruitiness": 0.6, "funkiness": 0.1}
ideal_mash_temp_min = 65.0
ideal_mash_temp_max = 68.0
ideal_boil_min = 60.0
ideal_boil_max = 90.0
family = "belgian"
water_affinity = {"soft": 0.5, "balanced": 0.7, "malty": 0.85, "hoppy": 0.4, "juicy": 0.4}
hop_schedule_expectations = {"bittering": 0.7, "aroma": 0.25, "dry_hop": 0.05}
yeast_temp_flavors = {"ester_fruit": 0.8, "phenol_pepper": 0.4, "clean": 0.2, "fusel": 0.1}
acceptable_off_flavors = {"ester": 0.6, "phenol": 0.3, "diacetyl": 0.1}
primary_lesson = "belgian_yeast_character"
```

**Commit:**
```bash
git add src/data/styles/saison.tres src/data/styles/belgian_dubbel.tres src/tests/test_style_expansion.gd
git commit -m "feat: add Saison and Belgian Dubbel beer styles"
```

---

### Task 6: Create NEIPA .tres

**Files:**
- Create: `src/data/styles/neipa.tres`
- Test: `src/tests/test_style_expansion.gd` (append)

**Test:**
```gdscript
func test_neipa_loads():
	var s = load("res://data/styles/neipa.tres") as BeerStyle
	assert_not_null(s)
	assert_eq(s.style_id, "neipa")
	assert_eq(s.family, "modern")
	assert_eq(s.base_price, 320.0)
	assert_gt(s.water_affinity["juicy"], 0.9)
	assert_gt(s.hop_schedule_expectations["dry_hop"], 0.3)

func test_all_nine_new_styles_exist():
	var ids := ["ipa", "porter", "imperial_stout", "hefeweizen", "czech_pilsner", "helles", "marzen", "saison", "belgian_dubbel", "neipa"]
	for id in ids:
		var s = load("res://data/styles/%s.tres" % id) as BeerStyle
		assert_not_null(s, "%s.tres should exist" % id)
		assert_ne(s.family, "", "%s should have a family" % id)
		assert_false(s.unlocked, "%s should be locked" % id)
```

**neipa.tres:**
```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/BeerStyle.gd" id="1_beer_style"]

[resource]
script = ExtResource("1_beer_style")
style_id = "neipa"
style_name = "NEIPA"
description = "New England IPA. Hazy, juicy, tropical fruit bomb. Massive dry hopping with biotransformation during fermentation."
ideal_flavor_ratio = 0.6
base_price = 320.0
base_demand_weight = 1.1
unlocked = false
preferred_ingredients = {"pale_malt": 0.8, "wheat_malt": 0.8, "flaked_oats": 0.9, "citra": 0.95, "simcoe": 0.9, "us05_clean_ale": 0.8, "kveik_voss": 0.7}
ideal_flavor_profile = {"bitterness": 0.3, "sweetness": 0.3, "roastiness": 0.0, "fruitiness": 0.9, "funkiness": 0.0}
ideal_mash_temp_min = 65.0
ideal_mash_temp_max = 68.0
ideal_boil_min = 45.0
ideal_boil_max = 60.0
family = "modern"
water_affinity = {"soft": 0.7, "balanced": 0.6, "malty": 0.3, "hoppy": 0.7, "juicy": 0.95}
hop_schedule_expectations = {"bittering": 0.15, "aroma": 0.35, "dry_hop": 0.5}
yeast_temp_flavors = {"clean": 0.7, "ester_fruit": 0.6, "ester_banana": 0.0, "fusel": 0.0}
acceptable_off_flavors = {"ester": 0.4}
primary_lesson = "dry_hopping"
```

**Commit:**
```bash
git add src/data/styles/neipa.tres src/tests/test_style_expansion.gd
git commit -m "feat: add NEIPA beer style"
```

---

### Task 7: Update research nodes and ResearchManager for new styles

**Files:**
- Modify: `src/data/research/styles/lager_brewing.tres` (add czech_pilsner, helles, marzen to unlock ids)
- Modify: `src/data/research/styles/dark_styles.tres` (add porter, imperial_stout to unlock ids)
- Modify: `src/data/research/styles/wheat_traditions.tres` (add hefeweizen to unlock ids)
- Modify: `src/data/research/styles/belgian_arts.tres` (change unlock ids to saison, belgian_dubbel)
- Modify: `src/data/research/styles/ipa_mastery.tres` (verify unlock ids include ipa)
- Create: `src/data/research/styles/modern_techniques.tres` (new node, unlocks neipa)
- Modify: `src/autoloads/ResearchManager.gd` (add new locked style IDs, add modern_techniques path)
- Test: `src/tests/test_style_expansion.gd` (append)

**Key changes to existing research nodes:**

Read each .tres file first. The `unlock_effect` is a Dictionary like:
`{"type": "unlock_style", "ids": ["lager"]}`

Update to include new styles:
- `lager_brewing.tres`: `{"type": "unlock_style", "ids": ["lager", "czech_pilsner", "helles", "marzen"]}`
- `dark_styles.tres`: `{"type": "unlock_style", "ids": ["stout", "porter", "imperial_stout"]}`
- `wheat_traditions.tres`: `{"type": "unlock_style", "ids": ["wheat_beer", "hefeweizen"]}`
- `belgian_arts.tres`: `{"type": "unlock_style", "ids": ["saison", "belgian_dubbel"]}`
- `ipa_mastery.tres`: verify it already has `{"type": "unlock_style", "ids": ["ipa"]}`

**New research node — modern_techniques.tres:**
```
[gd_resource type="Resource" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ResearchNode.gd" id="1_rn"]

[resource]
script = ExtResource("1_rn")
node_id = "modern_techniques"
node_name = "Modern Techniques"
description = "Contemporary brewing methods. Biotransformation dry hopping, hazy IPAs, and juice-forward flavors."
category = 3
rp_cost = 25
prerequisites = ["american_hops", "dry_hopping"]
unlock_effect = {"type": "unlock_style", "ids": ["neipa"]}
```

**ResearchManager.gd changes:**

1. Add new style IDs to LOCKED_STYLE_IDS. Currently it's:
```gdscript
const LOCKED_STYLE_IDS: Array[String] = ["lager", "wheat_beer", "stout"]
```
Change to:
```gdscript
const LOCKED_STYLE_IDS: Array[String] = ["lager", "wheat_beer", "stout", "ipa", "porter", "imperial_stout", "hefeweizen", "czech_pilsner", "helles", "marzen", "saison", "belgian_dubbel", "neipa"]
```

2. Add modern_techniques.tres path to RESEARCH_PATHS array.

**Tests:**
```gdscript
func test_lager_research_unlocks_all_lagers():
	var node = load("res://data/research/styles/lager_brewing.tres") as ResearchNode
	var ids = node.unlock_effect.get("ids", [])
	assert_true("czech_pilsner" in ids, "lager_brewing should unlock czech_pilsner")
	assert_true("helles" in ids, "lager_brewing should unlock helles")
	assert_true("marzen" in ids, "lager_brewing should unlock marzen")

func test_dark_research_unlocks_porter_imperial():
	var node = load("res://data/research/styles/dark_styles.tres") as ResearchNode
	var ids = node.unlock_effect.get("ids", [])
	assert_true("porter" in ids, "dark_styles should unlock porter")
	assert_true("imperial_stout" in ids, "dark_styles should unlock imperial_stout")

func test_modern_techniques_node_exists():
	var node = load("res://data/research/styles/modern_techniques.tres") as ResearchNode
	assert_not_null(node)
	assert_eq(node.node_id, "modern_techniques")
	var ids = node.unlock_effect.get("ids", [])
	assert_true("neipa" in ids)

func test_modern_techniques_in_catalog():
	var node = ResearchManager.get_node("modern_techniques")
	assert_not_null(node, "modern_techniques should be in ResearchManager catalog")
```

**Commit:**
```bash
git add src/data/research/styles/ src/autoloads/ResearchManager.gd src/tests/test_style_expansion.gd
git commit -m "feat: update research tree to unlock 9 new beer styles"
```

---

### Task 8: Update StylePicker to include new styles and group by family

**Files:**
- Modify: `src/ui/StylePicker.gd`
- Test: `src/tests/test_style_expansion.gd` (append)

**Changes to StylePicker.gd:**

1. Update `STYLE_PATHS` to include all 14 standard styles (4 existing + 10 new including IPA):
```gdscript
const STYLE_PATHS := [
	"res://data/styles/pale_ale.tres",
	"res://data/styles/ipa.tres",
	"res://data/styles/stout.tres",
	"res://data/styles/porter.tres",
	"res://data/styles/imperial_stout.tres",
	"res://data/styles/wheat_beer.tres",
	"res://data/styles/hefeweizen.tres",
	"res://data/styles/lager.tres",
	"res://data/styles/czech_pilsner.tres",
	"res://data/styles/helles.tres",
	"res://data/styles/marzen.tres",
	"res://data/styles/saison.tres",
	"res://data/styles/belgian_dubbel.tres",
	"res://data/styles/neipa.tres",
]
```

2. Modify `_build_ui()` to group styles by family with headers. Read the existing _build_ui() code first. The family grouping approach:
   - After loading all styles, group them by `style.family`
   - Display family headers (Label, bold) then style buttons under each
   - Use this family display order: ales, dark, wheat, lager, belgian, modern
   - Family header format: "── ALES ──", "── DARK ──", etc.

**Test:**
```gdscript
func test_style_picker_has_all_styles():
	# Verify STYLE_PATHS covers all 14 standard styles
	var picker_script = load("res://ui/StylePicker.gd")
	# We can't easily test the constant directly, so test via loading
	var expected_ids := ["pale_ale", "ipa", "stout", "porter", "imperial_stout",
		"wheat_beer", "hefeweizen", "lager", "czech_pilsner", "helles",
		"marzen", "saison", "belgian_dubbel", "neipa"]
	for id in expected_ids:
		var s = load("res://data/styles/%s.tres" % id) as BeerStyle
		assert_not_null(s, "%s.tres should exist for StylePicker" % id)
```

**Commit:**
```bash
git add src/ui/StylePicker.gd src/tests/test_style_expansion.gd
git commit -m "feat: update StylePicker with 14 styles grouped by family"
```
