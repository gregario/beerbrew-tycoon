# Stage 2B: Research Tree — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a 20-node research tree that gates progression behind Research Points earned from brewing.

**Architecture:** ResearchManager autoload (mirrors EquipmentManager) manages a catalog of ResearchNode resources, tracks unlocked nodes and RP, and applies unlock effects to existing systems. A node-graph UI lets players browse and purchase research. Existing systems (StylePicker, EquipmentShop, QualityCalculator, BrewingScience) are modified to respect research gates.

**Tech Stack:** Godot 4 / GDScript, GUT testing framework, `.tres` Resource files with `type="Resource"` headers.

**Design doc:** `docs/plans/2026-02-28-stage2b-research-tree-design.md`

**Stack profile:** `stacks/godot/STACK.md` — read before implementing.

---

### Task 1: ResearchNode Resource Class

**Files:**
- Create: `src/scripts/ResearchNode.gd`
- Test: `src/tests/test_research_node.gd`

**Step 1: Write the failing test**

```gdscript
# src/tests/test_research_node.gd
extends GutTest

func test_resource_loads_with_correct_fields():
	var node := ResearchNode.new()
	node.node_id = "test_node"
	node.node_name = "Test Node"
	node.description = "A test research node"
	node.category = ResearchNode.Category.TECHNIQUES
	node.rp_cost = 15
	node.prerequisites = ["prereq_1"]
	node.unlock_effect = {"type": "brewing_bonus", "bonuses": {"mash_score_bonus": 0.05}}

	assert_eq(node.node_id, "test_node")
	assert_eq(node.node_name, "Test Node")
	assert_eq(node.category, ResearchNode.Category.TECHNIQUES)
	assert_eq(node.rp_cost, 15)
	assert_eq(node.prerequisites.size(), 1)
	assert_eq(node.prerequisites[0], "prereq_1")
	assert_eq(node.unlock_effect["type"], "brewing_bonus")

func test_default_values():
	var node := ResearchNode.new()
	assert_eq(node.node_id, "")
	assert_eq(node.rp_cost, 0)
	assert_eq(node.prerequisites.size(), 0)
	assert_true(node.unlock_effect.is_empty())
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — `ResearchNode` class not found.

**Step 3: Write the ResearchNode resource**

```gdscript
# src/scripts/ResearchNode.gd
class_name ResearchNode
extends Resource

enum Category { TECHNIQUES, INGREDIENTS, EQUIPMENT, STYLES }

@export var node_id: String = ""
@export var node_name: String = ""
@export var description: String = ""
@export var category: Category = Category.TECHNIQUES
@export var rp_cost: int = 0
@export var prerequisites: Array[String] = []
@export var unlock_effect: Dictionary = {}
```

**Step 4: Run test to verify it passes**

Run: `make test`
Expected: PASS

**Step 5: Commit**

```bash
git add src/scripts/ResearchNode.gd src/tests/test_research_node.gd
git commit -m "feat(research): add ResearchNode resource class with tests"
```

---

### Task 2: Create 20 ResearchNode .tres Files

**Files:**
- Create: `src/data/research/techniques/mash_basics.tres`
- Create: `src/data/research/techniques/advanced_mashing.tres`
- Create: `src/data/research/techniques/decoction_technique.tres`
- Create: `src/data/research/techniques/hop_timing.tres`
- Create: `src/data/research/techniques/dry_hopping.tres`
- Create: `src/data/research/techniques/water_chemistry.tres`
- Create: `src/data/research/ingredients/specialty_malts.tres`
- Create: `src/data/research/ingredients/american_hops.tres`
- Create: `src/data/research/ingredients/premium_hops.tres`
- Create: `src/data/research/ingredients/specialist_yeast.tres`
- Create: `src/data/research/equipment/homebrew_upgrades.tres`
- Create: `src/data/research/equipment/semi_pro_equipment.tres`
- Create: `src/data/research/equipment/pro_equipment.tres`
- Create: `src/data/research/equipment/adjunct_brewing.tres`
- Create: `src/data/research/styles/ale_fundamentals.tres`
- Create: `src/data/research/styles/lager_brewing.tres`
- Create: `src/data/research/styles/wheat_traditions.tres`
- Create: `src/data/research/styles/dark_styles.tres`
- Create: `src/data/research/styles/ipa_mastery.tres`
- Create: `src/data/research/styles/belgian_arts.tres`

**IMPORTANT:** All `.tres` files MUST use `type="Resource"` in the header, NOT `type="ResearchNode"`. This is a known Godot pitfall — custom class names in .tres type headers cause load failures.

**Step 1: Create directory structure**

```bash
mkdir -p src/data/research/{techniques,ingredients,equipment,styles}
```

**Step 2: Create all .tres files**

Each file follows this template pattern. Here are all 20:

```ini
# src/data/research/techniques/mash_basics.tres
[gd_resource type="Resource" script_class="ResearchNode" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ResearchNode.gd" id="1"]

[resource]
script = ExtResource("1")
node_id = "mash_basics"
node_name = "Mash Basics"
description = "Fundamental mashing knowledge. Your starting point for all-grain brewing."
category = 0
rp_cost = 0
prerequisites = []
unlock_effect = {}
```

```ini
# src/data/research/techniques/advanced_mashing.tres
[gd_resource type="Resource" script_class="ResearchNode" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ResearchNode.gd" id="1"]

[resource]
script = ExtResource("1")
node_id = "advanced_mashing"
node_name = "Advanced Mashing"
description = "Deeper understanding of enzyme activity and mash chemistry."
category = 0
rp_cost = 15
prerequisites = ["mash_basics"]
unlock_effect = {"type": "brewing_bonus", "bonuses": {"mash_score_bonus": 0.05}}
```

```ini
# src/data/research/techniques/decoction_technique.tres
[gd_resource type="Resource" script_class="ResearchNode" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ResearchNode.gd" id="1"]

[resource]
script = ExtResource("1")
node_id = "decoction_technique"
node_name = "Decoction Technique"
description = "Traditional step-mashing for richer malt character and better extraction."
category = 0
rp_cost = 30
prerequisites = ["advanced_mashing"]
unlock_effect = {"type": "brewing_bonus", "bonuses": {"efficiency_bonus": 0.10}}
```

```ini
# src/data/research/techniques/hop_timing.tres
[gd_resource type="Resource" script_class="ResearchNode" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ResearchNode.gd" id="1"]

[resource]
script = ExtResource("1")
node_id = "hop_timing"
node_name = "Hop Timing"
description = "Understanding bittering vs aroma hop additions. Your starting point for hop mastery."
category = 0
rp_cost = 0
prerequisites = []
unlock_effect = {}
```

```ini
# src/data/research/techniques/dry_hopping.tres
[gd_resource type="Resource" script_class="ResearchNode" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ResearchNode.gd" id="1"]

[resource]
script = ExtResource("1")
node_id = "dry_hopping"
node_name = "Dry Hopping"
description = "Post-fermentation hop additions for intense aroma without added bitterness."
category = 0
rp_cost = 20
prerequisites = ["hop_timing"]
unlock_effect = {"type": "brewing_bonus", "bonuses": {"aroma_bonus": 0.15}}
```

```ini
# src/data/research/techniques/water_chemistry.tres
[gd_resource type="Resource" script_class="ResearchNode" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ResearchNode.gd" id="1"]

[resource]
script = ExtResource("1")
node_id = "water_chemistry"
node_name = "Water Chemistry"
description = "Mineral adjustments and pH control for consistent, predictable results."
category = 0
rp_cost = 25
prerequisites = ["advanced_mashing"]
unlock_effect = {"type": "brewing_bonus", "bonuses": {"noise_reduction": 0.5}}
```

```ini
# src/data/research/ingredients/specialty_malts.tres
[gd_resource type="Resource" script_class="ResearchNode" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ResearchNode.gd" id="1"]

[resource]
script = ExtResource("1")
node_id = "specialty_malts"
node_name = "Specialty Malts"
description = "Unlock crystal, chocolate, and roasted malts for richer, more complex beers."
category = 1
rp_cost = 10
prerequisites = []
unlock_effect = {"type": "unlock_ingredients", "ids": ["crystal_60", "chocolate_malt", "roasted_barley"]}
```

```ini
# src/data/research/ingredients/american_hops.tres
[gd_resource type="Resource" script_class="ResearchNode" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ResearchNode.gd" id="1"]

[resource]
script = ExtResource("1")
node_id = "american_hops"
node_name = "American Hops"
description = "Citrusy, piney American hop varieties for bold, modern ales."
category = 1
rp_cost = 15
prerequisites = []
unlock_effect = {"type": "unlock_ingredients", "ids": ["cascade", "centennial"]}
```

```ini
# src/data/research/ingredients/premium_hops.tres
[gd_resource type="Resource" script_class="ResearchNode" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ResearchNode.gd" id="1"]

[resource]
script = ExtResource("1")
node_id = "premium_hops"
node_name = "Premium Hops"
description = "Elite hop varieties with intense tropical and resinous character."
category = 1
rp_cost = 25
prerequisites = ["american_hops"]
unlock_effect = {"type": "unlock_ingredients", "ids": ["citra", "simcoe"]}
```

```ini
# src/data/research/ingredients/specialist_yeast.tres
[gd_resource type="Resource" script_class="ResearchNode" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ResearchNode.gd" id="1"]

[resource]
script = ExtResource("1")
node_id = "specialist_yeast"
node_name = "Specialist Yeast"
description = "Exotic yeast strains for saisons, wheat beers, and farmhouse ales."
category = 1
rp_cost = 20
prerequisites = []
unlock_effect = {"type": "unlock_ingredients", "ids": ["belle_saison", "wb06_wheat", "kveik_voss"]}
```

```ini
# src/data/research/equipment/homebrew_upgrades.tres
[gd_resource type="Resource" script_class="ResearchNode" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ResearchNode.gd" id="1"]

[resource]
script = ExtResource("1")
node_id = "homebrew_upgrades"
node_name = "Homebrew Upgrades"
description = "Basic equipment knowledge. Tier 1-2 gear is available from the start."
category = 2
rp_cost = 0
prerequisites = []
unlock_effect = {}
```

```ini
# src/data/research/equipment/semi_pro_equipment.tres
[gd_resource type="Resource" script_class="ResearchNode" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ResearchNode.gd" id="1"]

[resource]
script = ExtResource("1")
node_id = "semi_pro_equipment"
node_name = "Semi-Pro Equipment"
description = "Unlock Tier 3 semi-professional brewing equipment."
category = 2
rp_cost = 20
prerequisites = ["homebrew_upgrades"]
unlock_effect = {"type": "unlock_equipment_tier", "tier": 3}
```

```ini
# src/data/research/equipment/pro_equipment.tres
[gd_resource type="Resource" script_class="ResearchNode" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ResearchNode.gd" id="1"]

[resource]
script = ExtResource("1")
node_id = "pro_equipment"
node_name = "Pro Equipment"
description = "Unlock Tier 4 professional-grade brewing equipment."
category = 2
rp_cost = 35
prerequisites = ["semi_pro_equipment"]
unlock_effect = {"type": "unlock_equipment_tier", "tier": 4}
```

```ini
# src/data/research/equipment/adjunct_brewing.tres
[gd_resource type="Resource" script_class="ResearchNode" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ResearchNode.gd" id="1"]

[resource]
script = ExtResource("1")
node_id = "adjunct_brewing"
node_name = "Adjunct Brewing"
description = "Unlock brewing sugars, oats, finings, and other adjuncts."
category = 2
rp_cost = 15
prerequisites = ["homebrew_upgrades"]
unlock_effect = {"type": "unlock_ingredients", "ids": ["brewing_sugar", "flaked_oats", "irish_moss", "lactose"]}
```

```ini
# src/data/research/styles/ale_fundamentals.tres
[gd_resource type="Resource" script_class="ResearchNode" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ResearchNode.gd" id="1"]

[resource]
script = ExtResource("1")
node_id = "ale_fundamentals"
node_name = "Ale Fundamentals"
description = "Core ale brewing knowledge. Pale Ale is available from the start."
category = 3
rp_cost = 0
prerequisites = []
unlock_effect = {}
```

```ini
# src/data/research/styles/lager_brewing.tres
[gd_resource type="Resource" script_class="ResearchNode" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ResearchNode.gd" id="1"]

[resource]
script = ExtResource("1")
node_id = "lager_brewing"
node_name = "Lager Brewing"
description = "Cold fermentation techniques for clean, crisp lagers."
category = 3
rp_cost = 15
prerequisites = ["ale_fundamentals"]
unlock_effect = {"type": "unlock_style", "ids": ["lager"]}
```

```ini
# src/data/research/styles/wheat_traditions.tres
[gd_resource type="Resource" script_class="ResearchNode" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ResearchNode.gd" id="1"]

[resource]
script = ExtResource("1")
node_id = "wheat_traditions"
node_name = "Wheat Traditions"
description = "German and Belgian wheat beer brewing methods."
category = 3
rp_cost = 15
prerequisites = ["ale_fundamentals"]
unlock_effect = {"type": "unlock_style", "ids": ["wheat_beer"]}
```

```ini
# src/data/research/styles/dark_styles.tres
[gd_resource type="Resource" script_class="ResearchNode" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ResearchNode.gd" id="1"]

[resource]
script = ExtResource("1")
node_id = "dark_styles"
node_name = "Dark Styles"
description = "Roasty, complex dark beers — stouts, porters, and schwarzbier."
category = 3
rp_cost = 20
prerequisites = ["specialty_malts"]
unlock_effect = {"type": "unlock_style", "ids": ["stout"]}
```

```ini
# src/data/research/styles/ipa_mastery.tres
[gd_resource type="Resource" script_class="ResearchNode" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ResearchNode.gd" id="1"]

[resource]
script = ExtResource("1")
node_id = "ipa_mastery"
node_name = "IPA Mastery"
description = "Hop-forward brewing for India Pale Ales. (Style coming in a future update.)"
category = 3
rp_cost = 25
prerequisites = ["american_hops", "ale_fundamentals"]
unlock_effect = {"type": "unlock_style", "ids": ["ipa"]}
```

```ini
# src/data/research/styles/belgian_arts.tres
[gd_resource type="Resource" script_class="ResearchNode" load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/ResearchNode.gd" id="1"]

[resource]
script = ExtResource("1")
node_id = "belgian_arts"
node_name = "Belgian Arts"
description = "Complex Belgian brewing traditions. (Style coming in a future update.)"
category = 3
rp_cost = 30
prerequisites = ["specialist_yeast", "wheat_traditions"]
unlock_effect = {"type": "unlock_style", "ids": ["belgian"]}
```

**Step 3: Add a test that loads each .tres file**

Add to `src/tests/test_research_node.gd`:

```gdscript
const RESEARCH_PATHS: Array[String] = [
	"res://data/research/techniques/mash_basics.tres",
	"res://data/research/techniques/advanced_mashing.tres",
	"res://data/research/techniques/decoction_technique.tres",
	"res://data/research/techniques/hop_timing.tres",
	"res://data/research/techniques/dry_hopping.tres",
	"res://data/research/techniques/water_chemistry.tres",
	"res://data/research/ingredients/specialty_malts.tres",
	"res://data/research/ingredients/american_hops.tres",
	"res://data/research/ingredients/premium_hops.tres",
	"res://data/research/ingredients/specialist_yeast.tres",
	"res://data/research/equipment/homebrew_upgrades.tres",
	"res://data/research/equipment/semi_pro_equipment.tres",
	"res://data/research/equipment/pro_equipment.tres",
	"res://data/research/equipment/adjunct_brewing.tres",
	"res://data/research/styles/ale_fundamentals.tres",
	"res://data/research/styles/lager_brewing.tres",
	"res://data/research/styles/wheat_traditions.tres",
	"res://data/research/styles/dark_styles.tres",
	"res://data/research/styles/ipa_mastery.tres",
	"res://data/research/styles/belgian_arts.tres",
]

func test_all_tres_files_load():
	for path in RESEARCH_PATHS:
		var res := load(path)
		assert_not_null(res, "Failed to load: %s" % path)
		assert_true(res is ResearchNode, "Not a ResearchNode: %s" % path)

func test_total_node_count():
	assert_eq(RESEARCH_PATHS.size(), 20)

func test_root_nodes_have_zero_cost():
	var root_ids := ["mash_basics", "hop_timing", "homebrew_upgrades", "ale_fundamentals"]
	for path in RESEARCH_PATHS:
		var node := load(path) as ResearchNode
		if node.node_id in root_ids:
			assert_eq(node.rp_cost, 0, "%s should be free" % node.node_id)
			assert_eq(node.prerequisites.size(), 0, "%s should have no prereqs" % node.node_id)
```

**Step 4: Run tests**

Run: `make test`
Expected: PASS — all 20 .tres files load correctly.

**Step 5: Commit**

```bash
git add src/data/research/ src/tests/test_research_node.gd
git commit -m "feat(research): add 20 ResearchNode .tres files with load tests"
```

---

### Task 3: ResearchManager Autoload — Core Logic

**Files:**
- Create: `src/autoloads/ResearchManager.gd`
- Create: `src/tests/test_research_manager.gd`
- Modify: `src/project.godot:33` (add autoload registration)

**Step 1: Write failing tests for core ResearchManager logic**

```gdscript
# src/tests/test_research_manager.gd
extends GutTest

func before_each():
	GameState.reset()
	ResearchManager.reset()

func test_catalog_loads_all_nodes():
	assert_eq(ResearchManager.get_catalog_size(), 20)

func test_root_nodes_start_unlocked():
	assert_true(ResearchManager.is_unlocked("mash_basics"))
	assert_true(ResearchManager.is_unlocked("hop_timing"))
	assert_true(ResearchManager.is_unlocked("homebrew_upgrades"))
	assert_true(ResearchManager.is_unlocked("ale_fundamentals"))

func test_non_root_nodes_start_locked():
	assert_false(ResearchManager.is_unlocked("advanced_mashing"))
	assert_false(ResearchManager.is_unlocked("specialty_malts"))
	assert_false(ResearchManager.is_unlocked("semi_pro_equipment"))
	assert_false(ResearchManager.is_unlocked("lager_brewing"))

func test_initial_rp_is_zero():
	assert_eq(ResearchManager.research_points, 0)

func test_add_rp():
	ResearchManager.add_rp(10)
	assert_eq(ResearchManager.research_points, 10)

func test_can_unlock_with_prereqs_met_and_enough_rp():
	ResearchManager.add_rp(15)
	assert_true(ResearchManager.can_unlock("advanced_mashing"))

func test_cannot_unlock_without_enough_rp():
	ResearchManager.add_rp(5)
	assert_false(ResearchManager.can_unlock("advanced_mashing"))

func test_cannot_unlock_without_prereqs():
	ResearchManager.add_rp(100)
	assert_false(ResearchManager.can_unlock("decoction_technique"))

func test_cannot_unlock_already_unlocked():
	assert_false(ResearchManager.can_unlock("mash_basics"))

func test_unlock_deducts_rp():
	ResearchManager.add_rp(20)
	ResearchManager.unlock("advanced_mashing")
	assert_eq(ResearchManager.research_points, 5)

func test_unlock_adds_to_unlocked_nodes():
	ResearchManager.add_rp(15)
	ResearchManager.unlock("advanced_mashing")
	assert_true(ResearchManager.is_unlocked("advanced_mashing"))

func test_unlock_emits_signal():
	watch_signals(ResearchManager)
	ResearchManager.add_rp(15)
	ResearchManager.unlock("advanced_mashing")
	assert_signal_emitted(ResearchManager, "research_unlocked")

func test_get_available_nodes():
	ResearchManager.add_rp(100)
	var available := ResearchManager.get_available_nodes()
	# Root nodes are already unlocked, so available should be nodes whose prereqs are met but not yet unlocked
	var available_ids := []
	for node in available:
		available_ids.append(node.node_id)
	assert_has(available_ids, "advanced_mashing")
	assert_has(available_ids, "specialty_malts")
	assert_does_not_have(available_ids, "mash_basics")  # already unlocked
	assert_does_not_have(available_ids, "decoction_technique")  # prereq not met

func test_reset_clears_state():
	ResearchManager.add_rp(50)
	ResearchManager.unlock("advanced_mashing")
	ResearchManager.reset()
	assert_eq(ResearchManager.research_points, 0)
	assert_false(ResearchManager.is_unlocked("advanced_mashing"))
	assert_true(ResearchManager.is_unlocked("mash_basics"))  # roots re-unlocked
```

**Step 2: Run tests to verify they fail**

Run: `make test`
Expected: FAIL — `ResearchManager` not found.

**Step 3: Implement ResearchManager**

```gdscript
# src/autoloads/ResearchManager.gd
extends Node

signal research_unlocked(node_id: String)
signal rp_changed(new_amount: int)

const RESEARCH_PATHS: Array[String] = [
	"res://data/research/techniques/mash_basics.tres",
	"res://data/research/techniques/advanced_mashing.tres",
	"res://data/research/techniques/decoction_technique.tres",
	"res://data/research/techniques/hop_timing.tres",
	"res://data/research/techniques/dry_hopping.tres",
	"res://data/research/techniques/water_chemistry.tres",
	"res://data/research/ingredients/specialty_malts.tres",
	"res://data/research/ingredients/american_hops.tres",
	"res://data/research/ingredients/premium_hops.tres",
	"res://data/research/ingredients/specialist_yeast.tres",
	"res://data/research/equipment/homebrew_upgrades.tres",
	"res://data/research/equipment/semi_pro_equipment.tres",
	"res://data/research/equipment/pro_equipment.tres",
	"res://data/research/equipment/adjunct_brewing.tres",
	"res://data/research/styles/ale_fundamentals.tres",
	"res://data/research/styles/lager_brewing.tres",
	"res://data/research/styles/wheat_traditions.tres",
	"res://data/research/styles/dark_styles.tres",
	"res://data/research/styles/ipa_mastery.tres",
	"res://data/research/styles/belgian_arts.tres",
]

var research_points: int = 0
var unlocked_nodes: Array[String] = []
var bonuses: Dictionary = {}
var unlocked_equipment_tier: int = 2

var _catalog: Dictionary = {}

func _ready() -> void:
	_load_catalog()

func _load_catalog() -> void:
	_catalog.clear()
	for path in RESEARCH_PATHS:
		var res := load(path) as ResearchNode
		if res:
			_catalog[res.node_id] = res

func get_catalog_size() -> int:
	return _catalog.size()

func get_node_by_id(node_id: String) -> ResearchNode:
	return _catalog.get(node_id) as ResearchNode

func is_unlocked(node_id: String) -> bool:
	return node_id in unlocked_nodes

func can_unlock(node_id: String) -> bool:
	if is_unlocked(node_id):
		return false
	var node := get_node_by_id(node_id)
	if not node:
		return false
	if research_points < node.rp_cost:
		return false
	for prereq in node.prerequisites:
		if not is_unlocked(prereq):
			return false
	return true

func unlock(node_id: String) -> bool:
	if not can_unlock(node_id):
		return false
	var node := get_node_by_id(node_id)
	research_points -= node.rp_cost
	unlocked_nodes.append(node_id)
	_apply_effect(node)
	research_unlocked.emit(node_id)
	rp_changed.emit(research_points)
	return true

func add_rp(amount: int) -> void:
	research_points += amount
	rp_changed.emit(research_points)

func get_available_nodes() -> Array:
	var available: Array = []
	for node_id in _catalog:
		if is_unlocked(node_id):
			continue
		var node := get_node_by_id(node_id)
		var prereqs_met := true
		for prereq in node.prerequisites:
			if not is_unlocked(prereq):
				prereqs_met = false
				break
		if prereqs_met:
			available.append(node)
	return available

func get_nodes_by_category(category: ResearchNode.Category) -> Array:
	var nodes: Array = []
	for node_id in _catalog:
		var node := get_node_by_id(node_id)
		if node.category == category:
			nodes.append(node)
	return nodes

func _apply_effect(node: ResearchNode) -> void:
	var effect := node.unlock_effect
	if effect.is_empty():
		return
	var effect_type: String = effect.get("type", "")
	match effect_type:
		"unlock_ingredients":
			_unlock_ingredients(effect.get("ids", []))
		"unlock_style":
			_unlock_styles(effect.get("ids", []))
		"unlock_equipment_tier":
			var tier: int = effect.get("tier", 2)
			if tier > unlocked_equipment_tier:
				unlocked_equipment_tier = tier
		"brewing_bonus":
			var bonus_dict: Dictionary = effect.get("bonuses", {})
			for key in bonus_dict:
				bonuses[key] = bonus_dict[key]

func _unlock_ingredients(ids: Array) -> void:
	# Ingredients are loaded via EquipmentManager or RecipeDesigner catalogs.
	# We iterate all known ingredient paths to find and unlock matching ones.
	var ingredient_dirs := [
		"res://data/ingredients/malts/",
		"res://data/ingredients/hops/",
		"res://data/ingredients/yeast/",
		"res://data/ingredients/adjuncts/",
	]
	for dir_path in ingredient_dirs:
		var dir := DirAccess.open(dir_path)
		if not dir:
			continue
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var res := load(dir_path + file_name)
				if res and "ingredient_id" in res and res.ingredient_id in ids:
					res.unlocked = true
			file_name = dir.get_next()

func _unlock_styles(ids: Array) -> void:
	var style_dir := "res://data/styles/"
	var dir := DirAccess.open(style_dir)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load(style_dir + file_name)
			if res and "style_id" in res and res.style_id in ids:
				res.unlocked = true
		file_name = dir.get_next()

func save_state() -> Dictionary:
	return {
		"research_points": research_points,
		"unlocked_nodes": unlocked_nodes.duplicate(),
	}

func load_state(data: Dictionary) -> void:
	research_points = data.get("research_points", 0)
	var saved_nodes: Array = data.get("unlocked_nodes", [])
	# Reset to clean state, then re-unlock saved nodes
	unlocked_nodes = []
	bonuses = {}
	unlocked_equipment_tier = 2
	# First unlock root nodes (free, no prereqs)
	_unlock_root_nodes()
	# Then re-apply effects for all saved non-root nodes
	for node_id in saved_nodes:
		if node_id not in unlocked_nodes:
			unlocked_nodes.append(node_id)
			var node := get_node_by_id(node_id)
			if node:
				_apply_effect(node)

func reset() -> void:
	research_points = 0
	unlocked_nodes = []
	bonuses = {}
	unlocked_equipment_tier = 2
	_unlock_root_nodes()
	# Reset ingredient and style unlock states
	_reset_ingredient_locks()
	_reset_style_locks()

func _unlock_root_nodes() -> void:
	for node_id in _catalog:
		var node := get_node_by_id(node_id)
		if node.rp_cost == 0 and node.prerequisites.is_empty():
			if node_id not in unlocked_nodes:
				unlocked_nodes.append(node_id)

func _reset_ingredient_locks() -> void:
	var ingredient_dirs := [
		"res://data/ingredients/malts/",
		"res://data/ingredients/hops/",
		"res://data/ingredients/yeast/",
		"res://data/ingredients/adjuncts/",
	]
	for dir_path in ingredient_dirs:
		var dir := DirAccess.open(dir_path)
		if not dir:
			continue
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var res := load(dir_path + file_name)
				if res and "unlocked" in res:
					# Restore to the resource's saved default
					# Locked ingredients have unlocked=false in .tres
					pass  # Resources are cached; reset by reloading would be needed
					# For now, the .tres default is the source of truth
			file_name = dir.get_next()
	# Simpler approach: explicitly re-lock the known locked ingredient IDs
	var locked_ids := ["crystal_60", "chocolate_malt", "roasted_barley",
		"cascade", "centennial", "citra", "simcoe",
		"belle_saison", "wb06_wheat", "kveik_voss",
		"brewing_sugar", "flaked_oats", "irish_moss", "lactose"]
	_set_ingredients_locked(locked_ids)

func _set_ingredients_locked(ids: Array) -> void:
	var ingredient_dirs := [
		"res://data/ingredients/malts/",
		"res://data/ingredients/hops/",
		"res://data/ingredients/yeast/",
		"res://data/ingredients/adjuncts/",
	]
	for dir_path in ingredient_dirs:
		var dir := DirAccess.open(dir_path)
		if not dir:
			continue
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var res := load(dir_path + file_name)
				if res and "ingredient_id" in res and res.ingredient_id in ids:
					res.unlocked = false
			file_name = dir.get_next()

func _reset_style_locks() -> void:
	var locked_style_ids := ["lager", "wheat_beer", "stout"]
	var style_dir := "res://data/styles/"
	var dir := DirAccess.open(style_dir)
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var res := load(style_dir + file_name)
			if res and "style_id" in res and res.style_id in locked_style_ids:
				res.unlocked = false
		file_name = dir.get_next()
```

**Step 4: Register autoload in project.godot**

Add after line 33 in `src/project.godot`:
```ini
ResearchManager="*res://autoloads/ResearchManager.gd"
```

**Step 5: Run tests**

Run: `make test`
Expected: PASS

**Step 6: Commit**

```bash
git add src/autoloads/ResearchManager.gd src/tests/test_research_manager.gd src/project.godot
git commit -m "feat(research): add ResearchManager autoload with core unlock logic and tests"
```

---

### Task 4: Save/Load and RP Accumulation Integration

**Files:**
- Modify: `src/autoloads/GameState.gd:18-25` (add RESEARCH_MANAGE state)
- Modify: `src/autoloads/GameState.gd:274` (add RP accumulation after record_brew)
- Modify: `src/autoloads/GameState.gd:337` (add ResearchManager.reset() in reset())
- Test: `src/tests/test_research_manager.gd` (add save/load and RP formula tests)

**Step 1: Write failing tests for save/load and RP formula**

Add to `src/tests/test_research_manager.gd`:

```gdscript
func test_save_state_roundtrip():
	ResearchManager.add_rp(50)
	ResearchManager.unlock("advanced_mashing")
	ResearchManager.unlock("specialty_malts")
	var saved := ResearchManager.save_state()
	ResearchManager.reset()
	assert_false(ResearchManager.is_unlocked("advanced_mashing"))
	ResearchManager.load_state(saved)
	assert_true(ResearchManager.is_unlocked("advanced_mashing"))
	assert_true(ResearchManager.is_unlocked("specialty_malts"))
	assert_eq(ResearchManager.research_points, 25)  # 50 - 15 - 10

func test_save_state_preserves_bonuses():
	ResearchManager.add_rp(15)
	ResearchManager.unlock("advanced_mashing")
	var saved := ResearchManager.save_state()
	ResearchManager.reset()
	ResearchManager.load_state(saved)
	assert_almost_eq(ResearchManager.bonuses.get("mash_score_bonus", 0.0), 0.05, 0.001)

func test_save_state_preserves_equipment_tier():
	ResearchManager.add_rp(20)
	ResearchManager.unlock("semi_pro_equipment")
	var saved := ResearchManager.save_state()
	ResearchManager.reset()
	assert_eq(ResearchManager.unlocked_equipment_tier, 2)
	ResearchManager.load_state(saved)
	assert_eq(ResearchManager.unlocked_equipment_tier, 3)

func test_rp_formula_low_quality():
	# quality_score = 30 → 2 + 30/20 = 2 + 1 = 3
	var rp := 2 + int(30.0 / 20.0)
	assert_eq(rp, 3)

func test_rp_formula_high_quality():
	# quality_score = 90 → 2 + 90/20 = 2 + 4 = 6
	var rp := 2 + int(90.0 / 20.0)
	assert_eq(rp, 6)

func test_rp_formula_perfect_quality():
	# quality_score = 100 → 2 + 100/20 = 2 + 5 = 7
	var rp := 2 + int(100.0 / 20.0)
	assert_eq(rp, 7)
```

**Step 2: Run tests to verify new tests pass (they test pure math, so they should)**

Run: `make test`

**Step 3: Modify GameState.gd**

Add `RESEARCH_MANAGE` to State enum (after `EQUIPMENT_MANAGE` at line 24):
```gdscript
enum State {
	MARKET_CHECK,
	STYLE_SELECT,
	RECIPE_DESIGN,
	BREWING_PHASES,
	RESULTS,
	EQUIPMENT_MANAGE,
	RESEARCH_MANAGE,
	GAME_OVER
}
```

Add RP accumulation in `execute_brew()` after `record_brew(result["final_score"])` (around line 275):
```gdscript
	# Award research points
	var rp_earned: int = 2 + int(result["final_score"] / 20.0)
	ResearchManager.add_rp(rp_earned)
	result["rp_earned"] = rp_earned
```

Add `ResearchManager.reset()` in `reset()` (around line 337, after `EquipmentManager.reset()`):
```gdscript
	ResearchManager.reset()
```

**Step 4: Run all tests**

Run: `make test`
Expected: All existing + new tests PASS.

**Step 5: Commit**

```bash
git add src/autoloads/GameState.gd src/tests/test_research_manager.gd
git commit -m "feat(research): integrate RP accumulation and RESEARCH_MANAGE state"
```

---

### Task 5: BeerStyle Unlocking

**Files:**
- Modify: `src/scripts/BeerStyle.gd:19` (add unlocked field)
- Modify: `src/data/styles/lager.tres` (set unlocked = false)
- Modify: `src/data/styles/wheat_beer.tres` (set unlocked = false)
- Modify: `src/data/styles/stout.tres` (set unlocked = false)
- Modify: `src/ui/StylePicker.gd:44` (filter locked styles)
- Test: `src/tests/test_research_manager.gd` (add style unlock test)

**Step 1: Write failing test**

Add to `src/tests/test_research_manager.gd`:

```gdscript
func test_unlock_style_makes_style_available():
	var lager := load("res://data/styles/lager.tres") as BeerStyle
	assert_false(lager.unlocked, "Lager should start locked")
	ResearchManager.add_rp(15)
	ResearchManager.unlock("lager_brewing")
	assert_true(lager.unlocked, "Lager should be unlocked after research")

func test_reset_relocks_styles():
	ResearchManager.add_rp(15)
	ResearchManager.unlock("lager_brewing")
	var lager := load("res://data/styles/lager.tres") as BeerStyle
	assert_true(lager.unlocked)
	ResearchManager.reset()
	lager = load("res://data/styles/lager.tres") as BeerStyle
	assert_false(lager.unlocked)
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — BeerStyle has no `unlocked` field.

**Step 3: Add unlocked field to BeerStyle.gd**

After `@export var base_price` (line 19), add:
```gdscript
@export var unlocked: bool = true
```

**Step 4: Update .tres files**

Add `unlocked = false` to lager.tres, wheat_beer.tres, stout.tres. Pale_ale.tres keeps `unlocked = true` (or omits it, defaulting to true).

**Step 5: Update StylePicker.gd**

In `_build_ui()` method (around line 44), mirror the RecipeDesigner locked ingredient pattern:

```gdscript
for style in _styles:
	var btn := Button.new()
	if style.unlocked:
		btn.text = style.style_name
	else:
		btn.text = "%s  (Research Required)" % style.style_name
		btn.disabled = true
		btn.modulate.a = 0.5
```

And guard the press handler:
```gdscript
func _on_style_pressed(style: BeerStyle) -> void:
	if not style.unlocked:
		return
```

**Step 6: Run tests**

Run: `make test`
Expected: PASS

**Step 7: Commit**

```bash
git add src/scripts/BeerStyle.gd src/data/styles/ src/ui/StylePicker.gd src/tests/test_research_manager.gd
git commit -m "feat(research): gate beer styles behind research tree unlocks"
```

---

### Task 6: Equipment Tier Gating

**Files:**
- Modify: `src/ui/EquipmentShop.gd:200-205` (filter by tier)
- Test: `src/tests/test_research_manager.gd` (add equipment tier test)

**Step 1: Write failing test**

Add to `src/tests/test_research_manager.gd`:

```gdscript
func test_equipment_tier_default_is_2():
	assert_eq(ResearchManager.unlocked_equipment_tier, 2)

func test_unlock_semi_pro_sets_tier_3():
	ResearchManager.add_rp(20)
	ResearchManager.unlock("semi_pro_equipment")
	assert_eq(ResearchManager.unlocked_equipment_tier, 3)

func test_unlock_pro_sets_tier_4():
	ResearchManager.add_rp(55)
	ResearchManager.unlock("semi_pro_equipment")
	ResearchManager.unlock("pro_equipment")
	assert_eq(ResearchManager.unlocked_equipment_tier, 4)
```

**Step 2: Run tests — these should pass already (logic is in Task 3)**

Run: `make test`
Expected: PASS

**Step 3: Modify EquipmentShop.gd**

In `_build_item_rows()` (around line 201), add tier filtering:

```gdscript
func _build_item_rows(items: Array) -> void:
	for equip in items:
		if not equip is Equipment:
			continue
		var row: PanelContainer
		if equip.tier > ResearchManager.unlocked_equipment_tier:
			row = _create_locked_row(equip)
		else:
			row = _create_shop_row(equip)
		_item_list.add_child(row)
```

Add a `_create_locked_row()` method that shows the equipment name greyed out with "(Research Required)" — similar pattern to the existing `_create_shop_row()` but with `modulate.a = 0.5` and no buy button.

**Step 4: Run tests**

Run: `make test`
Expected: PASS

**Step 5: Commit**

```bash
git add src/ui/EquipmentShop.gd src/tests/test_research_manager.gd
git commit -m "feat(research): gate equipment tiers behind research tree"
```

---

### Task 7: Brewing Bonus Integration

**Files:**
- Modify: `src/autoloads/QualityCalculator.gd:256` (add mash_score_bonus)
- Modify: `src/autoloads/QualityCalculator.gd:128-131` (add research efficiency_bonus)
- Modify: `src/autoloads/BrewingScience.gd:60-63` (apply noise_reduction)
- Modify: `src/autoloads/BrewingScience.gd:15-19` (apply aroma_bonus)
- Test: `src/tests/test_research_manager.gd` (add bonus tests)

**Step 1: Write failing tests**

Add to `src/tests/test_research_manager.gd`:

```gdscript
func test_advanced_mashing_adds_mash_score_bonus():
	ResearchManager.add_rp(15)
	ResearchManager.unlock("advanced_mashing")
	assert_almost_eq(ResearchManager.bonuses.get("mash_score_bonus", 0.0), 0.05, 0.001)

func test_decoction_adds_efficiency_bonus():
	ResearchManager.add_rp(45)
	ResearchManager.unlock("advanced_mashing")
	ResearchManager.unlock("decoction_technique")
	assert_almost_eq(ResearchManager.bonuses.get("efficiency_bonus", 0.0), 0.10, 0.001)

func test_dry_hopping_adds_aroma_bonus():
	ResearchManager.add_rp(20)
	ResearchManager.unlock("dry_hopping")
	assert_almost_eq(ResearchManager.bonuses.get("aroma_bonus", 0.0), 0.15, 0.001)

func test_water_chemistry_adds_noise_reduction():
	ResearchManager.add_rp(40)
	ResearchManager.unlock("advanced_mashing")
	ResearchManager.unlock("water_chemistry")
	assert_almost_eq(ResearchManager.bonuses.get("noise_reduction", 0.0), 0.5, 0.001)
```

**Step 2: Run tests — these should pass already (bonus storage is in Task 3)**

Run: `make test`
Expected: PASS (ResearchManager stores bonuses; now we wire them into the systems)

**Step 3: Modify QualityCalculator.gd**

In `_compute_science_score()` (around line 256), after mash_score is calculated:
```gdscript
	var mash_score: float = BrewingScience.calc_mash_score(mash_temp, style)
	# Apply research bonus
	if is_instance_valid(ResearchManager):
		mash_score = minf(mash_score + ResearchManager.bonuses.get("mash_score_bonus", 0.0), 1.0)
```

In `_compute_points()` (around line 128-131), add research efficiency bonus alongside equipment:
```gdscript
	if is_instance_valid(EquipmentManager):
		var eff_bonus: float = EquipmentManager.active_bonuses.get("efficiency", 0.0)
		if is_instance_valid(ResearchManager):
			eff_bonus += ResearchManager.bonuses.get("efficiency_bonus", 0.0)
		technique *= (1.0 + eff_bonus)
```

**Step 4: Modify BrewingScience.gd**

In `apply_noise()` (line 60-63), apply noise reduction:
```gdscript
static func apply_noise(value: float, brew_seed: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = brew_seed
	var noise_range := 0.05
	if is_instance_valid(ResearchManager):
		var reduction: float = ResearchManager.bonuses.get("noise_reduction", 0.0)
		noise_range *= (1.0 - reduction)
	return value * rng.randf_range(1.0 - noise_range, 1.0 + noise_range)
```

In `calc_hop_utilization()` (line 15-19), apply aroma bonus:
```gdscript
static func calc_hop_utilization(boil_min: float, alpha_acid_pct: float) -> Dictionary:
	var utilization: float = boil_min / 90.0
	var bittering: float = alpha_acid_pct * utilization
	var aroma: float = alpha_acid_pct * (1.0 - utilization)
	if is_instance_valid(ResearchManager):
		aroma *= (1.0 + ResearchManager.bonuses.get("aroma_bonus", 0.0))
	return {"bittering": bittering, "aroma": aroma}
```

**Step 5: Run all tests**

Run: `make test`
Expected: PASS (all existing tests should still pass; research bonuses default to 0 when not researched)

**Step 6: Commit**

```bash
git add src/autoloads/QualityCalculator.gd src/autoloads/BrewingScience.gd src/tests/test_research_manager.gd
git commit -m "feat(research): wire brewing bonuses into QualityCalculator and BrewingScience"
```

---

### Task 8: RP Display in ResultsOverlay

**Files:**
- Modify: `src/ui/ResultsOverlay.gd:80` (add RP earned display)

**Step 1: Modify ResultsOverlay.gd**

In `populate()` method, after the balance_label update (around line 80), add RP display. The `result` dictionary now contains `rp_earned` (added in Task 4).

```gdscript
	# After balance_label.text line:
	if result.has("rp_earned"):
		var rp_label := Label.new()
		rp_label.text = "+%d Research Points" % result["rp_earned"]
		rp_label.add_theme_color_override("font_color", Color("#FFC857"))
		# Add to the results container (find the appropriate VBox parent)
		revenue_label.get_parent().add_child(rp_label)
```

Note: The exact insertion depends on the ResultsOverlay scene structure. The implementing engineer should read ResultsOverlay.gd fully and find the right container to add this label to. Follow the pattern used by `revenue_label` and `balance_label`.

**Step 2: Also add a toast notification**

In `GameState.execute_brew()`, after the RP accumulation lines added in Task 4:
```gdscript
	ToastManager.show_toast("Earned %d Research Points" % rp_earned)
```

**Step 3: Run tests and verify manually**

Run: `make test`
Expected: PASS

**Step 4: Commit**

```bash
git add src/ui/ResultsOverlay.gd src/autoloads/GameState.gd
git commit -m "feat(research): show RP earned in results overlay and toast"
```

---

### Task 9: Research Tree UI — Node Graph

**Files:**
- Create: `src/ui/ResearchTree.gd`

This is the largest task. The UI is code-only (no .tscn), mirrors EquipmentShop.gd pattern.

**Step 1: Implement ResearchTree.gd**

```gdscript
# src/ui/ResearchTree.gd
extends Control

signal closed

# Design tokens
const COLOR_BG := Color("#0F1724")
const COLOR_SURFACE := Color("#0B1220")
const COLOR_PRIMARY := Color("#5AA9FF")
const COLOR_ACCENT := Color("#FFC857")
const COLOR_SUCCESS := Color("#5EE8A4")
const COLOR_MUTED := Color("#8A9BB1")
const COLOR_DANGER := Color("#FF7B7B")

const CARD_SIZE := Vector2(140, 100)
const CARD_SPACING := Vector2(180, 130)

var _dim: ColorRect
var _panel: PanelContainer
var _rp_label: Label
var _node_graph: Control
var _current_category: ResearchNode.Category = ResearchNode.Category.TECHNIQUES
var _card_positions: Dictionary = {}  # node_id -> Vector2
var _node_cards: Dictionary = {}  # node_id -> PanelContainer

func _ready() -> void:
	visible = false
	_build_ui()

func show_tree() -> void:
	_refresh()
	visible = true

func _build_ui() -> void:
	# Dim overlay
	_dim = ColorRect.new()
	_dim.color = Color(0, 0, 0, 0.6)
	_dim.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(_dim)

	# Center container
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	add_child(center)

	# Main panel
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(900, 600)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_SURFACE
	panel_style.border_color = COLOR_MUTED
	panel_style.set_border_width_all(2)
	panel_style.set_content_margin_all(16)
	panel_style.set_corner_radius_all(8)
	_panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(_panel)

	var vbox := VBoxContainer.new()
	_panel.add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	vbox.add_child(header)
	var title := Label.new()
	title.text = "Research Tree"
	title.add_theme_font_size_override("font_size", 32)
	header.add_child(title)
	header.add_child(_create_spacer())
	_rp_label = Label.new()
	_rp_label.add_theme_font_size_override("font_size", 24)
	_rp_label.add_theme_color_override("font_color", COLOR_ACCENT)
	header.add_child(_rp_label)

	# Separator
	var sep := HSeparator.new()
	vbox.add_child(sep)

	# Category tabs
	var tabs := HBoxContainer.new()
	vbox.add_child(tabs)
	var categories := ["Techniques", "Ingredients", "Equipment", "Styles"]
	for i in categories.size():
		var btn := Button.new()
		btn.text = categories[i]
		btn.pressed.connect(_on_category_pressed.bind(i))
		tabs.add_child(btn)

	# Scroll + node graph area
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	_node_graph = Control.new()
	_node_graph.custom_minimum_size = Vector2(850, 400)
	scroll.add_child(_node_graph)

	# Close button
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(footer)
	var close_btn := Button.new()
	close_btn.text = "Close"
	close_btn.pressed.connect(_on_close_pressed)
	footer.add_child(close_btn)

func _on_category_pressed(category_index: int) -> void:
	_current_category = category_index as ResearchNode.Category
	_refresh()

func _on_close_pressed() -> void:
	visible = false
	closed.emit()

func _refresh() -> void:
	_rp_label.text = "RP: %d" % ResearchManager.research_points
	_build_node_graph()

func _build_node_graph() -> void:
	# Clear previous cards
	for child in _node_graph.get_children():
		child.queue_free()
	_card_positions.clear()
	_node_cards.clear()

	var nodes := ResearchManager.get_nodes_by_category(_current_category)
	_compute_positions(nodes)

	# Must wait a frame after queue_free
	await get_tree().process_frame

	# Draw cards
	for node in nodes:
		var card := _create_node_card(node)
		card.position = _card_positions[node.node_id]
		_node_graph.add_child(card)
		_node_cards[node.node_id] = card

	# Update minimum size for scroll
	var max_x := 0.0
	var max_y := 0.0
	for pos in _card_positions.values():
		max_x = maxf(max_x, pos.x + CARD_SIZE.x + 20)
		max_y = maxf(max_y, pos.y + CARD_SIZE.y + 20)
	_node_graph.custom_minimum_size = Vector2(maxf(850, max_x), maxf(400, max_y))

	# Request redraw for connection lines
	_node_graph.queue_redraw()

func _compute_positions(nodes: Array) -> void:
	# Sort nodes into columns by dependency depth
	var depths: Dictionary = {}
	for node in nodes:
		depths[node.node_id] = _get_depth(node, nodes)

	# Group by depth
	var columns: Dictionary = {}
	for node in nodes:
		var depth: int = depths[node.node_id]
		if depth not in columns:
			columns[depth] = []
		columns[depth].append(node)

	# Position: column = depth (left to right), row = index within column
	for depth in columns:
		var col_nodes: Array = columns[depth]
		for i in col_nodes.size():
			var x := 20.0 + depth * CARD_SPACING.x
			var y := 20.0 + i * CARD_SPACING.y
			_card_positions[col_nodes[i].node_id] = Vector2(x, y)

func _get_depth(node: ResearchNode, all_nodes: Array) -> int:
	if node.prerequisites.is_empty():
		return 0
	var max_depth := 0
	for prereq_id in node.prerequisites:
		for other in all_nodes:
			if other.node_id == prereq_id:
				max_depth = maxi(max_depth, _get_depth(other, all_nodes) + 1)
				break
	return max_depth

func _create_node_card(node: ResearchNode) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_SURFACE
	style.set_border_width_all(2)
	style.set_content_margin_all(8)
	style.set_corner_radius_all(4)

	if ResearchManager.is_unlocked(node.node_id):
		style.border_color = COLOR_SUCCESS
	elif ResearchManager.can_unlock(node.node_id):
		style.border_color = COLOR_PRIMARY
	else:
		var prereqs_met := true
		for prereq in node.prerequisites:
			if not ResearchManager.is_unlocked(prereq):
				prereqs_met = false
				break
		if prereqs_met:
			style.border_color = COLOR_ACCENT  # can't afford
		else:
			style.border_color = COLOR_MUTED
			card.modulate.a = 0.5

	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	card.add_child(vbox)

	var name_label := Label.new()
	name_label.text = node.node_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(name_label)

	var cost_label := Label.new()
	if ResearchManager.is_unlocked(node.node_id):
		cost_label.text = "Unlocked"
		cost_label.add_theme_color_override("font_color", COLOR_SUCCESS)
	else:
		cost_label.text = "%d RP" % node.rp_cost
		cost_label.add_theme_color_override("font_color", COLOR_ACCENT)
	cost_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(cost_label)

	# Cross-category prerequisite hint
	for prereq_id in node.prerequisites:
		var prereq_node := ResearchManager.get_node_by_id(prereq_id)
		if prereq_node and prereq_node.category != node.category:
			var hint := Label.new()
			var cat_names := ["Techniques", "Ingredients", "Equipment", "Styles"]
			hint.text = "Needs: %s (%s)" % [prereq_node.node_name, cat_names[prereq_node.category]]
			hint.add_theme_font_size_override("font_size", 12)
			hint.add_theme_color_override("font_color", COLOR_MUTED)
			hint.autowrap_mode = TextServer.AUTOWRAP_WORD
			vbox.add_child(hint)

	# Click handler
	card.gui_input.connect(_on_card_input.bind(node))

	return card

func _on_card_input(event: InputEvent, node: ResearchNode) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if ResearchManager.can_unlock(node.node_id):
			_show_confirm(node)
		elif ResearchManager.is_unlocked(node.node_id):
			_show_info(node, "Already researched.\n%s" % node.description)
		else:
			var missing := []
			for prereq_id in node.prerequisites:
				if not ResearchManager.is_unlocked(prereq_id):
					var prereq := ResearchManager.get_node_by_id(prereq_id)
					if prereq:
						missing.append(prereq.node_name)
			if missing.size() > 0:
				_show_info(node, "Requires: %s" % ", ".join(missing))
			else:
				_show_info(node, "Not enough RP. Need %d, have %d." % [node.rp_cost, ResearchManager.research_points])

func _show_confirm(node: ResearchNode) -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "Research"
	dialog.dialog_text = "Unlock %s for %d RP?\n\n%s" % [node.node_name, node.rp_cost, node.description]
	dialog.confirmed.connect(func():
		ResearchManager.unlock(node.node_id)
		_refresh()
		dialog.queue_free()
	)
	dialog.canceled.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()

func _show_info(node: ResearchNode, text: String) -> void:
	var dialog := AcceptDialog.new()
	dialog.title = node.node_name
	dialog.dialog_text = text
	dialog.confirmed.connect(func(): dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered()

func _create_spacer() -> Control:
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spacer
```

Also add a `_draw()` override on the `_node_graph` control to draw prerequisite lines. Since `_node_graph` is a plain Control, the implementing engineer should subclass it or use `_node_graph.draw.connect(...)`:

```gdscript
# In _build_ui(), after creating _node_graph:
_node_graph.draw.connect(_draw_connections)

# Connection drawing method:
func _draw_connections() -> void:
	var nodes := ResearchManager.get_nodes_by_category(_current_category)
	for node in nodes:
		if node.node_id not in _card_positions:
			continue
		var end_pos: Vector2 = _card_positions[node.node_id] + Vector2(0, CARD_SIZE.y / 2)
		for prereq_id in node.prerequisites:
			if prereq_id not in _card_positions:
				continue  # cross-category prereq, skip line
			var start_pos: Vector2 = _card_positions[prereq_id] + Vector2(CARD_SIZE.x, CARD_SIZE.y / 2)
			var color := COLOR_SUCCESS if ResearchManager.is_unlocked(prereq_id) else COLOR_MUTED
			_node_graph.draw_line(start_pos, end_pos, color, 2.0, true)
```

**Step 2: Run tests**

Run: `make test`
Expected: PASS (no new test file needed for UI; visual verification needed)

**Step 3: Commit**

```bash
git add src/ui/ResearchTree.gd
git commit -m "feat(research): add Research Tree node graph UI"
```

---

### Task 10: Wire Research Tree into Game Flow

**Files:**
- Modify: `src/scenes/Game.gd:36-44` (create ResearchTree, add to overlays)
- Modify: `src/scenes/Game.gd:103-106` (handle RESEARCH_MANAGE state)
- Modify: `src/scenes/BreweryScene.gd:7-8` (add research_requested signal)
- Modify: `src/scenes/BreweryScene.gd:139-161` (add Research button)

**Step 1: Add research_requested signal to BreweryScene.gd**

After `signal start_brewing_pressed()` (line 8):
```gdscript
signal research_requested()
```

**Step 2: Add Research button to BreweryScene.gd**

In `_build_equipment_ui()`, after the "Start Brewing" button block (after line 161), add:

```gdscript
	var research_btn := Button.new()
	research_btn.text = "Research"
	research_btn.position = Vector2(660, 620)  # Position next to Start Brewing
	research_btn.size = Vector2(120, 40)
	research_btn.pressed.connect(func(): research_requested.emit())
	_equipment_ui.add_child(research_btn)
```

**Step 3: Wire ResearchTree in Game.gd**

After EquipmentShop creation (around line 40), add:
```gdscript
	var research_script = preload("res://ui/ResearchTree.gd")
	research_tree = Control.new()
	research_tree.set_script(research_script)
	research_tree.name = "ResearchTree"
	add_child(research_tree)
```

Add `research_tree` to `_all_overlays` (line 44).

Add signal connection (around line 59):
```gdscript
	brewery_scene.research_requested.connect(_on_research_requested)
	research_tree.closed.connect(_on_research_tree_closed)
```

Add handlers:
```gdscript
func _on_research_requested() -> void:
	research_tree.show_tree()

func _on_research_tree_closed() -> void:
	pass  # Stay in EQUIPMENT_MANAGE state, research is an overlay
```

Note: Research Tree opens as an overlay ON TOP of the equipment view, rather than switching to a separate state. This keeps it simpler — the player can open/close research while in equipment mode. The `RESEARCH_MANAGE` state in GameState is available for future use if needed but not required for this implementation.

Declare `var research_tree` at the top of Game.gd alongside the other UI variables.

**Step 4: Run all tests**

Run: `make test`
Expected: PASS

**Step 5: Commit**

```bash
git add src/scenes/Game.gd src/scenes/BreweryScene.gd
git commit -m "feat(research): wire Research Tree UI into game flow"
```

---

### Task 11: Ingredient Unlock Tests

**Files:**
- Test: `src/tests/test_research_manager.gd` (add ingredient unlock tests)

**Step 1: Write tests for ingredient unlocking**

Add to `src/tests/test_research_manager.gd`:

```gdscript
func test_unlock_specialty_malts():
	var crystal := load("res://data/ingredients/malts/crystal_60.tres")
	assert_false(crystal.unlocked, "Crystal 60 should start locked")
	ResearchManager.add_rp(10)
	ResearchManager.unlock("specialty_malts")
	assert_true(crystal.unlocked, "Crystal 60 should be unlocked after research")

func test_unlock_american_hops():
	var cascade := load("res://data/ingredients/hops/cascade.tres")
	assert_false(cascade.unlocked, "Cascade should start locked")
	ResearchManager.add_rp(15)
	ResearchManager.unlock("american_hops")
	assert_true(cascade.unlocked, "Cascade should be unlocked after research")

func test_unlock_adjuncts():
	var lactose := load("res://data/ingredients/adjuncts/lactose.tres")
	assert_false(lactose.unlocked, "Lactose should start locked")
	ResearchManager.add_rp(15)
	ResearchManager.unlock("adjunct_brewing")
	assert_true(lactose.unlocked, "Lactose should be unlocked after research")

func test_cross_category_prereq():
	# Dark Styles requires Specialty Malts (Ingredients category)
	ResearchManager.add_rp(100)
	assert_false(ResearchManager.can_unlock("dark_styles"), "Should not unlock without Specialty Malts")
	ResearchManager.unlock("specialty_malts")
	assert_true(ResearchManager.can_unlock("dark_styles"), "Should be unlockable after Specialty Malts")
```

**Step 2: Run tests**

Run: `make test`
Expected: PASS

**Step 3: Commit**

```bash
git add src/tests/test_research_manager.gd
git commit -m "test(research): add ingredient and cross-category unlock tests"
```

---

### Task 12: Final Integration Test and Cleanup

**Files:**
- Test: `src/tests/test_research_manager.gd` (add integration test)

**Step 1: Write an end-to-end research flow test**

```gdscript
func test_full_research_flow():
	# Start with no RP
	assert_eq(ResearchManager.research_points, 0)
	assert_eq(ResearchManager.unlocked_nodes.size(), 4)  # 4 root nodes

	# Simulate a few brews worth of RP
	ResearchManager.add_rp(50)

	# Unlock a chain: Specialty Malts (10) → Dark Styles (20) = 30 RP spent
	ResearchManager.unlock("specialty_malts")
	assert_eq(ResearchManager.research_points, 40)
	ResearchManager.unlock("dark_styles")
	assert_eq(ResearchManager.research_points, 20)

	# Verify effects applied
	var crystal := load("res://data/ingredients/malts/crystal_60.tres")
	assert_true(crystal.unlocked)
	var stout := load("res://data/styles/stout.tres") as BeerStyle
	assert_true(stout.unlocked)

	# Save, reset, load
	var saved := ResearchManager.save_state()
	ResearchManager.reset()
	assert_false(ResearchManager.is_unlocked("specialty_malts"))
	ResearchManager.load_state(saved)
	assert_true(ResearchManager.is_unlocked("specialty_malts"))
	assert_true(ResearchManager.is_unlocked("dark_styles"))
	assert_eq(ResearchManager.research_points, 20)
```

**Step 2: Run all tests**

Run: `make test`
Expected: ALL PASS

**Step 3: Commit**

```bash
git add src/tests/test_research_manager.gd
git commit -m "test(research): add full integration test for research flow"
```

**Step 4: Run full test suite one final time**

Run: `make test`
Expected: All tests pass (existing 198 + new research tests).
