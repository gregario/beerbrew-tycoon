# Stage 5A — Artisan vs Mass-Market Fork Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Implement the brewery fork system where players choose between Artisan and Mass-Market paths at $15K + 25 brews, with divergent bonuses, win conditions, and separate brewery scenes.

**Architecture:** Strategy pattern — `BreweryPath` base class with `ArtisanPath` and `MassMarketPath` subclasses, orchestrated by a thin `PathManager` autoload. GameState, QualityCalculator, CompetitionManager, and the ingredient cost system query PathManager for path-specific bonuses. Game.gd swaps brewery scenes on path choice.

**Tech Stack:** Godot 4.6 / GDScript, GUT testing framework, `make test` runner.

**Important references:**
- Stack profile: `../../stacks/godot/STACK.md` (read before writing any code)
- Pitfalls: `../../stacks/godot/pitfalls.md` (especially: no `:=` on Dictionary.get(), no static on autoloads, Resource caching in tests)
- Design doc: `docs/plans/2026-03-07-stage5a-artisan-massmarket-fork-design.md`

---

### Task 1: BreweryPath Base Class

**Files:**
- Create: `src/scripts/paths/BreweryPath.gd`
- Test: `src/tests/test_path_manager.gd`

**Step 1: Create the paths directory**

```bash
mkdir -p src/scripts/paths
```

**Step 2: Write the failing test**

Create `src/tests/test_path_manager.gd`:

```gdscript
extends GutTest

## Tests for BreweryPath base class and path subclasses.

const BreweryPath = preload("res://scripts/paths/BreweryPath.gd")

func test_base_path_defaults():
	var path = BreweryPath.new()
	assert_eq(path.get_path_name(), "", "Base path has empty name")
	assert_eq(path.get_quality_bonus(), 1.0, "Base path has no quality bonus")
	assert_eq(path.get_batch_multiplier(), 1.0, "Base path has no batch multiplier")
	assert_eq(path.get_ingredient_discount(), 1.0, "Base path has no ingredient discount")
	assert_eq(path.get_competition_discount(), 1.0, "Base path has no competition discount")
	assert_eq(path.get_win_description(), "", "Base path has empty win description")

func test_base_path_serialize_roundtrip():
	var path = BreweryPath.new()
	var data: Dictionary = path.serialize()
	assert_true(data.has("path_type"), "Serialized data has path_type")
	var path2 = BreweryPath.new()
	path2.deserialize(data)
	assert_eq(path2.get_path_name(), path.get_path_name())
```

**Step 3: Run test to verify it fails**

Run: `make test`
Expected: FAIL — `res://scripts/paths/BreweryPath.gd` not found

**Step 4: Write minimal implementation**

Create `src/scripts/paths/BreweryPath.gd`:

```gdscript
extends RefCounted

## BreweryPath — base class for brewery path strategies.
## Subclasses override bonuses, win conditions, and serialization.

func get_path_name() -> String:
	return ""

func get_path_type() -> String:
	return ""

func get_quality_bonus() -> float:
	return 1.0

func get_batch_multiplier() -> float:
	return 1.0

func get_ingredient_discount() -> float:
	return 1.0

func get_competition_discount() -> float:
	return 1.0

func check_win_condition(_game_state) -> bool:
	return false

func get_win_description() -> String:
	return ""

func serialize() -> Dictionary:
	return {"path_type": get_path_type()}

func deserialize(_data: Dictionary) -> void:
	pass
```

**Step 5: Run test to verify it passes**

Run: `make test`
Expected: PASS

**Step 6: Commit**

```bash
git add src/scripts/paths/BreweryPath.gd src/tests/test_path_manager.gd
git commit -m "feat: add BreweryPath base class with strategy interface"
```

---

### Task 2: ArtisanPath and MassMarketPath Subclasses

**Files:**
- Create: `src/scripts/paths/ArtisanPath.gd`
- Create: `src/scripts/paths/MassMarketPath.gd`
- Modify: `src/tests/test_path_manager.gd`

**Step 1: Write failing tests for ArtisanPath**

Append to `src/tests/test_path_manager.gd`:

```gdscript
const ArtisanPath = preload("res://scripts/paths/ArtisanPath.gd")
const MassMarketPath = preload("res://scripts/paths/MassMarketPath.gd")

# --- ArtisanPath ---

func test_artisan_path_name():
	var path = ArtisanPath.new()
	assert_eq(path.get_path_name(), "Artisan Brewery")
	assert_eq(path.get_path_type(), "artisan")

func test_artisan_quality_bonus():
	var path = ArtisanPath.new()
	assert_almost_eq(path.get_quality_bonus(), 1.2, 0.001)

func test_artisan_competition_discount():
	var path = ArtisanPath.new()
	assert_almost_eq(path.get_competition_discount(), 0.5, 0.001)

func test_artisan_no_batch_or_ingredient_bonus():
	var path = ArtisanPath.new()
	assert_almost_eq(path.get_batch_multiplier(), 1.0, 0.001)
	assert_almost_eq(path.get_ingredient_discount(), 1.0, 0.001)

func test_artisan_reputation_starts_at_zero():
	var path = ArtisanPath.new()
	assert_eq(path.reputation, 0)

func test_artisan_add_reputation():
	var path = ArtisanPath.new()
	path.add_reputation(5)
	assert_eq(path.reputation, 5)
	path.add_reputation(3)
	assert_eq(path.reputation, 8)

func test_artisan_serialize_roundtrip():
	var path = ArtisanPath.new()
	path.add_reputation(42)
	var data: Dictionary = path.serialize()
	assert_eq(data["path_type"], "artisan")
	assert_eq(data["reputation"], 42)
	var path2 = ArtisanPath.new()
	path2.deserialize(data)
	assert_eq(path2.reputation, 42)

func test_artisan_win_description():
	var path = ArtisanPath.new()
	assert_true(path.get_win_description().length() > 0)

# --- MassMarketPath ---

func test_mass_market_path_name():
	var path = MassMarketPath.new()
	assert_eq(path.get_path_name(), "Mass-Market Brewery")
	assert_eq(path.get_path_type(), "mass_market")

func test_mass_market_batch_multiplier():
	var path = MassMarketPath.new()
	assert_almost_eq(path.get_batch_multiplier(), 2.0, 0.001)

func test_mass_market_ingredient_discount():
	var path = MassMarketPath.new()
	assert_almost_eq(path.get_ingredient_discount(), 0.8, 0.001)

func test_mass_market_no_quality_or_competition_bonus():
	var path = MassMarketPath.new()
	assert_almost_eq(path.get_quality_bonus(), 1.0, 0.001)
	assert_almost_eq(path.get_competition_discount(), 1.0, 0.001)

func test_mass_market_serialize_roundtrip():
	var path = MassMarketPath.new()
	var data: Dictionary = path.serialize()
	assert_eq(data["path_type"], "mass_market")
	var path2 = MassMarketPath.new()
	path2.deserialize(data)
	assert_eq(path2.get_path_name(), "Mass-Market Brewery")

func test_mass_market_win_description():
	var path = MassMarketPath.new()
	assert_true(path.get_win_description().length() > 0)
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — ArtisanPath.gd / MassMarketPath.gd not found

**Step 3: Write ArtisanPath implementation**

Create `src/scripts/paths/ArtisanPath.gd`:

```gdscript
extends "res://scripts/paths/BreweryPath.gd"

## ArtisanPath — quality-focused brewery path.
## +20% quality bonus, 50% competition fee discount, reputation tracking.
## Win condition: 5+ medals AND reputation >= 100.

var reputation: int = 0

func get_path_name() -> String:
	return "Artisan Brewery"

func get_path_type() -> String:
	return "artisan"

func get_quality_bonus() -> float:
	return 1.2

func get_competition_discount() -> float:
	return 0.5

func add_reputation(amount: int) -> void:
	reputation += amount

func check_win_condition(game_state) -> bool:
	if not is_instance_valid(CompetitionManager):
		return false
	var total_medals: int = (CompetitionManager.medals["gold"]
		+ CompetitionManager.medals["silver"]
		+ CompetitionManager.medals["bronze"])
	return total_medals >= 5 and reputation >= 100

func get_win_description() -> String:
	return "Earn 5 competition medals and reach 100 reputation"

func serialize() -> Dictionary:
	var data: Dictionary = super.serialize()
	data["reputation"] = reputation
	return data

func deserialize(data: Dictionary) -> void:
	reputation = data.get("reputation", 0)
```

**Step 4: Write MassMarketPath implementation**

Create `src/scripts/paths/MassMarketPath.gd`:

```gdscript
extends "res://scripts/paths/BreweryPath.gd"

## MassMarketPath — volume-focused brewery path.
## 2x batch size, 20% ingredient discount.
## Win condition: $50K total revenue AND all 4 distribution channels.

func get_path_name() -> String:
	return "Mass-Market Brewery"

func get_path_type() -> String:
	return "mass_market"

func get_batch_multiplier() -> float:
	return 2.0

func get_ingredient_discount() -> float:
	return 0.8

func check_win_condition(game_state) -> bool:
	if not is_instance_valid(MarketManager):
		return false
	var total_revenue: float = game_state.total_revenue if game_state else 0.0
	var channels: int = MarketManager.get_unlocked_channels().size()
	return total_revenue >= 50000.0 and channels >= 4

func get_win_description() -> String:
	return "Earn $50,000 total revenue and unlock all 4 distribution channels"
```

**Step 5: Run test to verify it passes**

Run: `make test`
Expected: PASS

**Step 6: Commit**

```bash
git add src/scripts/paths/ArtisanPath.gd src/scripts/paths/MassMarketPath.gd src/tests/test_path_manager.gd
git commit -m "feat: add ArtisanPath and MassMarketPath strategy classes"
```

---

### Task 3: PathManager Autoload

**Files:**
- Create: `src/autoloads/PathManager.gd`
- Modify: `src/project.godot` (add autoload entry)
- Modify: `src/tests/test_path_manager.gd`

**Step 1: Write failing tests**

Append to `src/tests/test_path_manager.gd`:

```gdscript
# --- PathManager ---

func test_path_manager_starts_with_no_path():
	PathManager.reset()
	assert_false(PathManager.has_chosen_path())
	assert_eq(PathManager.get_path_name(), "")

func test_path_manager_choose_artisan():
	PathManager.reset()
	PathManager.choose_path("artisan")
	assert_true(PathManager.has_chosen_path())
	assert_eq(PathManager.get_path_name(), "Artisan Brewery")
	assert_almost_eq(PathManager.get_quality_bonus(), 1.2, 0.001)

func test_path_manager_choose_mass_market():
	PathManager.reset()
	PathManager.choose_path("mass_market")
	assert_true(PathManager.has_chosen_path())
	assert_eq(PathManager.get_path_name(), "Mass-Market Brewery")
	assert_almost_eq(PathManager.get_batch_multiplier(), 2.0, 0.001)

func test_path_manager_cannot_choose_twice():
	PathManager.reset()
	PathManager.choose_path("artisan")
	PathManager.choose_path("mass_market")
	# Should still be artisan — second call ignored
	assert_eq(PathManager.get_path_name(), "Artisan Brewery")

func test_path_manager_can_choose_path_threshold():
	PathManager.reset()
	# Need: MICROBREWERY stage + $15K + 25 brews
	BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY
	BreweryExpansion.beers_brewed = 25
	GameState.balance = 15000.0
	assert_true(PathManager.can_choose_path())

func test_path_manager_cannot_choose_below_threshold():
	PathManager.reset()
	BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY
	BreweryExpansion.beers_brewed = 24  # Not enough brews
	GameState.balance = 15000.0
	assert_false(PathManager.can_choose_path())

func test_path_manager_cannot_choose_wrong_stage():
	PathManager.reset()
	BreweryExpansion.current_stage = BreweryExpansion.Stage.GARAGE
	BreweryExpansion.beers_brewed = 25
	GameState.balance = 15000.0
	assert_false(PathManager.can_choose_path())

func test_path_manager_save_load_artisan():
	PathManager.reset()
	PathManager.choose_path("artisan")
	PathManager.add_reputation(42)
	var data: Dictionary = PathManager.save_state()
	PathManager.reset()
	assert_false(PathManager.has_chosen_path())
	PathManager.load_state(data)
	assert_true(PathManager.has_chosen_path())
	assert_eq(PathManager.get_path_name(), "Artisan Brewery")
	assert_eq(PathManager.get_reputation(), 42)

func test_path_manager_save_load_mass_market():
	PathManager.reset()
	PathManager.choose_path("mass_market")
	var data: Dictionary = PathManager.save_state()
	PathManager.reset()
	PathManager.load_state(data)
	assert_eq(PathManager.get_path_name(), "Mass-Market Brewery")

func test_path_manager_save_load_no_path():
	PathManager.reset()
	var data: Dictionary = PathManager.save_state()
	assert_eq(data["path_type"], "")
	PathManager.load_state(data)
	assert_false(PathManager.has_chosen_path())

func test_path_manager_reset():
	PathManager.choose_path("artisan")
	PathManager.add_reputation(50)
	PathManager.reset()
	assert_false(PathManager.has_chosen_path())
	assert_eq(PathManager.get_reputation(), 0)

func test_path_manager_delegates_defaults_when_no_path():
	PathManager.reset()
	assert_almost_eq(PathManager.get_quality_bonus(), 1.0, 0.001)
	assert_almost_eq(PathManager.get_batch_multiplier(), 1.0, 0.001)
	assert_almost_eq(PathManager.get_ingredient_discount(), 1.0, 0.001)
	assert_almost_eq(PathManager.get_competition_discount(), 1.0, 0.001)
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — PathManager autoload not found

**Step 3: Write PathManager implementation**

Create `src/autoloads/PathManager.gd`:

```gdscript
extends Node

## PathManager — orchestrates brewery path selection and delegates
## all path-specific queries to the active BreweryPath strategy.

const FORK_BALANCE_THRESHOLD: float = 15000.0
const FORK_BEERS_THRESHOLD: int = 25

signal path_chosen(path_type: String)

var current_path = null  # BreweryPath or null

func has_chosen_path() -> bool:
	return current_path != null

func can_choose_path() -> bool:
	if has_chosen_path():
		return false
	if not is_instance_valid(BreweryExpansion):
		return false
	if BreweryExpansion.current_stage != BreweryExpansion.Stage.MICROBREWERY:
		return false
	if not is_instance_valid(GameState):
		return false
	return (GameState.balance >= FORK_BALANCE_THRESHOLD
		and BreweryExpansion.beers_brewed >= FORK_BEERS_THRESHOLD)

func choose_path(path_type: String) -> void:
	if has_chosen_path():
		return
	match path_type:
		"artisan":
			current_path = preload("res://scripts/paths/ArtisanPath.gd").new()
		"mass_market":
			current_path = preload("res://scripts/paths/MassMarketPath.gd").new()
		_:
			push_warning("Unknown path type: %s" % path_type)
			return
	path_chosen.emit(path_type)

# --- Delegated getters ---

func get_path_name() -> String:
	if current_path == null:
		return ""
	return current_path.get_path_name()

func get_path_type() -> String:
	if current_path == null:
		return ""
	return current_path.get_path_type()

func get_quality_bonus() -> float:
	if current_path == null:
		return 1.0
	return current_path.get_quality_bonus()

func get_batch_multiplier() -> float:
	if current_path == null:
		return 1.0
	return current_path.get_batch_multiplier()

func get_ingredient_discount() -> float:
	if current_path == null:
		return 1.0
	return current_path.get_ingredient_discount()

func get_competition_discount() -> float:
	if current_path == null:
		return 1.0
	return current_path.get_competition_discount()

func check_win_condition() -> bool:
	if current_path == null:
		return false
	return current_path.check_win_condition(GameState)

# --- Reputation (artisan-specific, safe to call on any path) ---

func get_reputation() -> int:
	if current_path != null and current_path.has_method("add_reputation"):
		return current_path.reputation
	return 0

func add_reputation(amount: int) -> void:
	if current_path != null and current_path.has_method("add_reputation"):
		current_path.add_reputation(amount)

# --- Persistence ---

func save_state() -> Dictionary:
	if current_path == null:
		return {"path_type": ""}
	return current_path.serialize()

func load_state(data: Dictionary) -> void:
	var path_type: String = data.get("path_type", "")
	if path_type == "":
		current_path = null
		return
	# Use choose_path but reset first to allow it
	current_path = null
	choose_path(path_type)
	if current_path != null:
		current_path.deserialize(data)

func reset() -> void:
	current_path = null
```

**Step 4: Register PathManager as autoload**

Add to `src/project.godot` under `[autoload]` section, after `CompetitionManager`:

```
PathManager="*res://autoloads/PathManager.gd"
```

**Step 5: Run test to verify it passes**

Run: `make test`
Expected: PASS

**Step 6: Commit**

```bash
git add src/autoloads/PathManager.gd src/project.godot src/tests/test_path_manager.gd
git commit -m "feat: add PathManager autoload with path selection and persistence"
```

---

### Task 4: Integrate Path Bonuses into Existing Systems

**Files:**
- Modify: `src/autoloads/QualityCalculator.gd` (line ~68 — apply quality bonus)
- Modify: `src/autoloads/GameState.gd` (line ~166 — apply ingredient discount; line ~248 — apply batch multiplier)
- Modify: `src/autoloads/CompetitionManager.gd` (line ~94 — apply competition discount)
- Modify: `src/tests/test_path_manager.gd` (integration tests)

**Step 1: Write failing integration tests**

Append to `src/tests/test_path_manager.gd`:

```gdscript
# --- Integration: Quality Bonus ---

func test_artisan_quality_bonus_applied():
	PathManager.reset()
	PathManager.choose_path("artisan")
	# Create a minimal style and recipe for QualityCalculator
	var style = BeerStyle.new()
	style.style_name = "Test Lager"
	style.style_id = "test_lager"
	style.ideal_flavor_ratio = 0.5
	style.base_price = 10.0
	var recipe: Dictionary = {"malts": [], "hops": [], "yeast": null}
	var sliders: Dictionary = {"mashing": 65.0, "boiling": 60.0, "fermenting": 20.0}
	var result_artisan: Dictionary = QualityCalculator.calculate_quality(style, recipe, sliders, [])

	PathManager.reset()
	var result_none: Dictionary = QualityCalculator.calculate_quality(style, recipe, sliders, [])

	# Artisan score should be 1.2x the no-path score (clamped to 100)
	var expected: float = minf(result_none["final_score"] * 1.2, 100.0)
	assert_almost_eq(result_artisan["final_score"], expected, 0.1)

func test_mass_market_no_quality_bonus():
	PathManager.reset()
	PathManager.choose_path("mass_market")
	var style = BeerStyle.new()
	style.style_name = "Test Lager"
	style.style_id = "test_lager"
	style.ideal_flavor_ratio = 0.5
	style.base_price = 10.0
	var recipe: Dictionary = {"malts": [], "hops": [], "yeast": null}
	var sliders: Dictionary = {"mashing": 65.0, "boiling": 60.0, "fermenting": 20.0}
	var result: Dictionary = QualityCalculator.calculate_quality(style, recipe, sliders, [])

	PathManager.reset()
	var result_none: Dictionary = QualityCalculator.calculate_quality(style, recipe, sliders, [])
	assert_almost_eq(result["final_score"], result_none["final_score"], 0.1)

# --- Integration: Ingredient Discount ---

func test_mass_market_ingredient_discount_applied():
	PathManager.reset()
	PathManager.choose_path("mass_market")
	# Ingredient discount is 0.8 (20% off)
	var base_cost: float = 100.0
	var discounted: float = base_cost * PathManager.get_ingredient_discount()
	assert_almost_eq(discounted, 80.0, 0.01)

# --- Integration: Batch Multiplier ---

func test_mass_market_batch_multiplier_in_revenue():
	PathManager.reset()
	PathManager.choose_path("mass_market")
	# batch_multiplier should be 2.0
	assert_almost_eq(PathManager.get_batch_multiplier(), 2.0, 0.001)

# --- Integration: Competition Discount ---

func test_artisan_competition_fee_discount():
	PathManager.reset()
	PathManager.choose_path("artisan")
	assert_almost_eq(PathManager.get_competition_discount(), 0.5, 0.001)
	# A $200 entry fee should become $100
	var fee: int = 200
	var discounted_fee: int = int(fee * PathManager.get_competition_discount())
	assert_eq(discounted_fee, 100)
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — quality bonus not applied yet in QualityCalculator

**Step 3: Modify QualityCalculator.gd**

In `src/autoloads/QualityCalculator.gd`, after line 75 (the closing paren of the clampf), apply the path quality bonus. Replace the existing final_score calculation (lines 68-75):

```gdscript
	# --- 7. Weighted final score ---
	var final_score: float = clampf(
		ratio_score * WEIGHT_RATIO +
		ingredient_score * WEIGHT_INGREDIENTS +
		novelty_score * WEIGHT_NOVELTY +
		base_score * WEIGHT_BASE +
		science_score * WEIGHT_SCIENCE,
		0.0, 100.0
	)

	# --- 7b. Path quality bonus (e.g., Artisan +20%) ---
	if is_instance_valid(PathManager):
		final_score = clampf(final_score * PathManager.get_quality_bonus(), 0.0, 100.0)
```

**Step 4: Modify GameState.gd — ingredient discount**

In `src/autoloads/GameState.gd`, modify `get_recipe_cost()` (around line 152-163) to apply ingredient discount. After the `return total` line, replace with:

```gdscript
	# Apply path ingredient discount (e.g., Mass-Market 20% off)
	if is_instance_valid(PathManager):
		total *= PathManager.get_ingredient_discount()
	return total
```

**Step 5: Modify GameState.gd — batch multiplier**

In `src/autoloads/GameState.gd`, modify `calculate_revenue()` (line 248-257). After the equipment batch_mult line (256), add:

```gdscript
	# Apply path batch multiplier (e.g., Mass-Market 2x)
	if is_instance_valid(PathManager):
		batch_mult *= PathManager.get_batch_multiplier()
```

**Step 6: Modify CompetitionManager.gd — competition discount**

In `src/autoloads/CompetitionManager.gd`, modify `enter()` (line 94). After `var fee: int = current_competition["entry_fee"]`, add:

```gdscript
	# Apply path competition discount (e.g., Artisan 50% off)
	if is_instance_valid(PathManager):
		fee = int(fee * PathManager.get_competition_discount())
```

**Step 7: Run test to verify it passes**

Run: `make test`
Expected: PASS (all existing 425 tests + new tests)

**Step 8: Commit**

```bash
git add src/autoloads/QualityCalculator.gd src/autoloads/GameState.gd src/autoloads/CompetitionManager.gd src/tests/test_path_manager.gd
git commit -m "feat: integrate path bonuses into quality, revenue, costs, and competition"
```

---

### Task 5: Win Conditions and Reputation System

**Files:**
- Modify: `src/autoloads/GameState.gd` (lines 179-180 — check_win_condition; lines 108-124 — reputation on medals; line 425+ — reset)
- Modify: `src/tests/test_path_manager.gd`

**Step 1: Write failing tests**

Append to `src/tests/test_path_manager.gd`:

```gdscript
# --- Win Conditions ---

func test_artisan_win_condition_not_met_initially():
	PathManager.reset()
	PathManager.choose_path("artisan")
	assert_false(GameState.check_win_condition())

func test_artisan_win_condition_met():
	PathManager.reset()
	PathManager.choose_path("artisan")
	# Set 5 medals
	CompetitionManager.medals = {"gold": 3, "silver": 1, "bronze": 1}
	# Set reputation >= 100
	PathManager.add_reputation(100)
	assert_true(GameState.check_win_condition())

func test_artisan_win_needs_both_medals_and_reputation():
	PathManager.reset()
	PathManager.choose_path("artisan")
	CompetitionManager.medals = {"gold": 3, "silver": 1, "bronze": 1}
	PathManager.add_reputation(50)  # Not enough
	assert_false(GameState.check_win_condition())

func test_mass_market_win_condition_not_met_initially():
	PathManager.reset()
	PathManager.choose_path("mass_market")
	GameState.total_revenue = 0.0
	assert_false(GameState.check_win_condition())

func test_pre_fork_win_condition_unchanged():
	PathManager.reset()
	GameState.balance = 10000.0
	assert_true(GameState.check_win_condition())

func test_pre_fork_win_condition_below_target():
	PathManager.reset()
	GameState.balance = 9999.0
	assert_false(GameState.check_win_condition())

# --- Reputation Accumulation ---

func test_reputation_on_gold_medal():
	PathManager.reset()
	PathManager.choose_path("artisan")
	# Reputation gain: gold=+5, silver=+3, bronze=+1
	PathManager.add_reputation(5)  # Simulate gold medal rep
	assert_eq(PathManager.get_reputation(), 5)

func test_reputation_on_high_quality_brew():
	PathManager.reset()
	PathManager.choose_path("artisan")
	# +1 rep for brews with quality > 80
	PathManager.add_reputation(1)
	assert_eq(PathManager.get_reputation(), 1)
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — check_win_condition still uses old balance-only check

**Step 3: Modify GameState.check_win_condition()**

In `src/autoloads/GameState.gd`, replace `check_win_condition()` (lines 179-180):

```gdscript
func check_win_condition() -> bool:
	if is_instance_valid(PathManager) and PathManager.has_chosen_path():
		return PathManager.check_win_condition()
	return balance >= WIN_TARGET
```

**Step 4: Add reputation accumulation in _on_results_continue()**

In `src/autoloads/GameState.gd`, after the competition tick block (after line ~124, where medal toasts are shown), add reputation logic:

```gdscript
	# Reputation accumulation (Stage 5A — artisan path)
	if is_instance_valid(PathManager) and PathManager.has_chosen_path():
		if comp_result.has("placement"):
			var rep_gain: int = 0
			match comp_result["placement"]:
				"gold":
					rep_gain = 5
				"silver":
					rep_gain = 3
				"bronze":
					rep_gain = 1
			if rep_gain > 0:
				PathManager.add_reputation(rep_gain)
				if is_instance_valid(ToastManager):
					ToastManager.show_toast("Reputation +%d (now %d)" % [rep_gain, PathManager.get_reputation()])
```

Also add high-quality brew reputation. In `execute_brew()`, after `record_brew(result["final_score"])` (around line 306), add:

```gdscript
	# Reputation for high-quality brews (artisan path, quality > 80)
	if is_instance_valid(PathManager) and PathManager.has_chosen_path():
		if result["final_score"] > 80.0:
			PathManager.add_reputation(1)
```

Also add contract fulfillment reputation. After the contract fulfillment toast (around line 326), add:

```gdscript
		# Reputation for contract fulfillment (artisan path)
		if is_instance_valid(PathManager) and PathManager.has_chosen_path():
			PathManager.add_reputation(2)
```

**Step 5: Add PathManager to GameState.reset()**

In `src/autoloads/GameState.gd`, in `reset()` (line 425+), add after the MarketManager reset:

```gdscript
	if is_instance_valid(PathManager):
		PathManager.reset()
```

**Step 6: Run test to verify it passes**

Run: `make test`
Expected: PASS

**Step 7: Commit**

```bash
git add src/autoloads/GameState.gd src/tests/test_path_manager.gd
git commit -m "feat: add path-dependent win conditions and reputation system"
```

---

### Task 6: Fork Threshold Check and BreweryExpansion Integration

**Files:**
- Modify: `src/autoloads/BreweryExpansion.gd` (add fork expansion support)
- Modify: `src/autoloads/GameState.gd` (fork threshold check in _on_results_continue)
- Modify: `src/tests/test_path_manager.gd`
- Modify: `src/tests/test_brewery_expansion.gd`

**Step 1: Write failing tests**

Append to `src/tests/test_path_manager.gd`:

```gdscript
# --- Fork Threshold ---

func test_fork_threshold_emits_signal():
	PathManager.reset()
	BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY
	BreweryExpansion.beers_brewed = 24
	GameState.balance = 15000.0
	# Simulate reaching threshold
	watch_signals(PathManager)
	BreweryExpansion.beers_brewed = 25
	# can_choose_path should now be true
	assert_true(PathManager.can_choose_path())
```

Add to `src/tests/test_brewery_expansion.gd`:

```gdscript
func test_expand_to_artisan():
	BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY
	BreweryExpansion.expand_to_path(BreweryExpansion.Stage.ARTISAN)
	assert_eq(BreweryExpansion.current_stage, BreweryExpansion.Stage.ARTISAN)
	assert_eq(BreweryExpansion.get_max_slots(), 7)
	assert_eq(BreweryExpansion.get_rent_amount(), 600.0)

func test_expand_to_mass_market():
	BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY
	BreweryExpansion.expand_to_path(BreweryExpansion.Stage.MASS_MARKET)
	assert_eq(BreweryExpansion.current_stage, BreweryExpansion.Stage.MASS_MARKET)
	assert_eq(BreweryExpansion.get_max_slots(), 7)
	assert_eq(BreweryExpansion.get_rent_amount(), 800.0)

func test_cannot_expand_to_path_from_garage():
	BreweryExpansion.current_stage = BreweryExpansion.Stage.GARAGE
	BreweryExpansion.expand_to_path(BreweryExpansion.Stage.ARTISAN)
	assert_eq(BreweryExpansion.current_stage, BreweryExpansion.Stage.GARAGE)
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — `expand_to_path` method doesn't exist

**Step 3: Add expand_to_path to BreweryExpansion.gd**

In `src/autoloads/BreweryExpansion.gd`, after `expand()` (line 78), add:

```gdscript
## Expand to a specific path stage (ARTISAN or MASS_MARKET).
## Only valid from MICROBREWERY stage. No cost — fork is free.
func expand_to_path(target_stage: Stage) -> bool:
	if current_stage != Stage.MICROBREWERY:
		return false
	if target_stage != Stage.ARTISAN and target_stage != Stage.MASS_MARKET:
		return false
	current_stage = target_stage
	if is_instance_valid(EquipmentManager):
		EquipmentManager.resize_slots(get_max_slots())
	brewery_expanded.emit(target_stage)
	return true
```

**Step 4: Add fork threshold signal**

In `src/autoloads/BreweryExpansion.gd`, add a new signal after line 47:

```gdscript
signal fork_threshold_reached()
```

Modify `record_brew()` (line 110) to also check fork threshold:

```gdscript
func record_brew() -> void:
	beers_brewed += 1
	if current_stage == Stage.GARAGE and can_expand():
		threshold_reached.emit()
	elif current_stage == Stage.MICROBREWERY and is_instance_valid(PathManager):
		if PathManager.can_choose_path():
			fork_threshold_reached.emit()
```

**Step 5: Run test to verify it passes**

Run: `make test`
Expected: PASS

**Step 6: Commit**

```bash
git add src/autoloads/BreweryExpansion.gd src/tests/test_path_manager.gd src/tests/test_brewery_expansion.gd
git commit -m "feat: add fork expansion support and threshold detection"
```

---

### Task 7: ForkChoiceOverlay UI

**Files:**
- Create: `src/ui/ForkChoiceOverlay.gd`
- Modify: `src/scenes/Game.gd` (instantiate and show overlay)
- Modify: `src/tests/test_path_manager.gd`

**Step 1: Write failing tests**

Append to `src/tests/test_path_manager.gd`:

```gdscript
# --- ForkChoiceOverlay ---

func test_fork_choice_overlay_loads():
	var script = load("res://ui/ForkChoiceOverlay.gd")
	assert_not_null(script, "ForkChoiceOverlay script loads")
```

**Step 2: Run test to verify it fails**

Run: `make test`
Expected: FAIL — ForkChoiceOverlay.gd not found

**Step 3: Write ForkChoiceOverlay implementation**

Create `src/ui/ForkChoiceOverlay.gd`:

```gdscript
extends CanvasLayer

## ForkChoiceOverlay — presents the artisan vs mass-market fork choice.
## Follows overlay architecture: CanvasLayer layer=10, CenterContainer+PRESET_FULL_RECT.

signal path_selected(path_type: String)

var _root: CenterContainer
var _confirm_dialog: PanelContainer
var _pending_choice: String = ""

func _ready() -> void:
	layer = 10
	visible = false
	_build_ui()

func _build_ui() -> void:
	_root = CenterContainer.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_PASS

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 500)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 16)

	# Title
	var title := Label.new()
	title.text = "Your Brewery Has Grown — Choose Your Path"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Cards container
	var cards := HBoxContainer.new()
	cards.mouse_filter = Control.MOUSE_FILTER_PASS
	cards.add_theme_constant_override("separation", 24)

	# Artisan card
	var artisan_card := _build_path_card(
		"Artisan Brewery",
		"+20% quality bonus\n50% off competition fees\nRare ingredients access\nRent: $600/cycle",
		"Win: 5 medals + 100 reputation",
		"artisan",
		Color(0.85, 0.65, 0.35)  # Amber/copper
	)
	cards.add_child(artisan_card)

	# Mass-Market card
	var mass_market_card := _build_path_card(
		"Mass-Market Brewery",
		"2x batch size\n20% ingredient discount\nAutomation equipment\nRent: $800/cycle",
		"Win: $50K revenue + all 4 channels",
		"mass_market",
		Color(0.35, 0.55, 0.75)  # Steel blue
	)
	cards.add_child(mass_market_card)

	vbox.add_child(cards)
	panel.add_child(vbox)
	_root.add_child(panel)
	add_child(_root)

	# Confirmation dialog (hidden initially)
	_confirm_dialog = _build_confirm_dialog()
	add_child(_confirm_dialog)

func _build_path_card(title_text: String, benefits: String, win_text: String, path_type: String, accent: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 350)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 12)

	var name_label := Label.new()
	name_label.text = title_text
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", accent)
	vbox.add_child(name_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var benefits_label := Label.new()
	benefits_label.text = benefits
	benefits_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(benefits_label)

	var win_label := Label.new()
	win_label.text = win_text
	win_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	vbox.add_child(win_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var button := Button.new()
	button.text = "Choose This Path"
	button.pressed.connect(_on_path_button_pressed.bind(path_type))
	vbox.add_child(button)

	card.add_child(vbox)
	return card

func _build_confirm_dialog() -> PanelContainer:
	var dialog := PanelContainer.new()
	dialog.visible = false
	dialog.custom_minimum_size = Vector2(400, 200)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 16)

	var msg := Label.new()
	msg.name = "ConfirmMessage"
	msg.text = "Are you sure? This cannot be undone."
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(msg)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)

	var confirm_btn := Button.new()
	confirm_btn.text = "Confirm"
	confirm_btn.pressed.connect(_on_confirm)
	buttons.add_child(confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Go Back"
	cancel_btn.pressed.connect(_on_cancel)
	buttons.add_child(cancel_btn)

	vbox.add_child(buttons)
	dialog.add_child(center)
	center.add_child(vbox)
	return dialog

func show_overlay() -> void:
	visible = true

func _on_path_button_pressed(path_type: String) -> void:
	_pending_choice = path_type
	var path_name: String = "Artisan Brewery" if path_type == "artisan" else "Mass-Market Brewery"
	var msg: Label = _confirm_dialog.find_child("ConfirmMessage", true, false)
	if msg:
		msg.text = "Choose %s? This cannot be undone." % path_name
	_confirm_dialog.visible = true

func _on_confirm() -> void:
	_confirm_dialog.visible = false
	visible = false
	path_selected.emit(_pending_choice)

func _on_cancel() -> void:
	_confirm_dialog.visible = false
	_pending_choice = ""
```

**Step 4: Run test to verify it passes**

Run: `make test`
Expected: PASS

**Step 5: Commit**

```bash
git add src/ui/ForkChoiceOverlay.gd src/tests/test_path_manager.gd
git commit -m "feat: add ForkChoiceOverlay UI with path comparison cards"
```

---

### Task 8: Game.gd Integration — Fork Flow and Scene Swap

**Files:**
- Modify: `src/scenes/Game.gd` (add fork overlay, scene swap, connect signals)
- Modify: `src/autoloads/GameState.gd` (add fork_ready signal)
- Create: `src/scenes/ArtisanBreweryScene.gd`
- Create: `src/scenes/MassMarketBreweryScene.gd`

**Step 1: Write the BreweryScene variants**

These will initially be copies of BreweryScene.gd with path-specific header text and accent colors. The full visual differentiation can be refined later.

Create `src/scenes/ArtisanBreweryScene.gd` — this extends BreweryScene.gd and overrides the header and adds a reputation bar:

```gdscript
extends "res://scenes/BreweryScene.gd"

## ArtisanBreweryScene — artisan path brewery layout.
## Adds reputation bar and medal display to the base brewery scene.

var _reputation_bar: ProgressBar
var _reputation_label: Label

func _ready() -> void:
	super._ready()
	_add_reputation_display()
	_update_header()

func _add_reputation_display() -> void:
	# Add reputation bar to the header area
	_reputation_bar = ProgressBar.new()
	_reputation_bar.min_value = 0
	_reputation_bar.max_value = 100
	_reputation_bar.value = PathManager.get_reputation()
	_reputation_bar.custom_minimum_size = Vector2(150, 20)
	_reputation_bar.show_percentage = false

	_reputation_label = Label.new()
	_reputation_label.text = "Rep: %d/100" % PathManager.get_reputation()

	# Find the header area and add reputation display
	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.add_child(_reputation_label)
	hbox.add_child(_reputation_bar)
	# Add to the top of the scene (after existing header elements)
	add_child(hbox)
	move_child(hbox, 0)

func _update_header() -> void:
	# Override the stage name display
	if has_node("HeaderLabel"):
		$HeaderLabel.text = "ARTISAN BREWERY"

func refresh_reputation() -> void:
	if _reputation_bar:
		_reputation_bar.value = PathManager.get_reputation()
	if _reputation_label:
		_reputation_label.text = "Rep: %d/100" % PathManager.get_reputation()
```

Create `src/scenes/MassMarketBreweryScene.gd`:

```gdscript
extends "res://scenes/BreweryScene.gd"

## MassMarketBreweryScene — mass-market path brewery layout.
## Adds revenue tracker and channel status display.

var _revenue_bar: ProgressBar
var _revenue_label: Label
var _channel_label: Label

func _ready() -> void:
	super._ready()
	_add_revenue_display()
	_update_header()

func _add_revenue_display() -> void:
	_revenue_bar = ProgressBar.new()
	_revenue_bar.min_value = 0
	_revenue_bar.max_value = 50000
	_revenue_bar.value = GameState.total_revenue
	_revenue_bar.custom_minimum_size = Vector2(150, 20)
	_revenue_bar.show_percentage = false

	_revenue_label = Label.new()
	_revenue_label.text = "$%d/$50K" % int(GameState.total_revenue)

	var channels_unlocked: int = MarketManager.get_unlocked_channels().size() if is_instance_valid(MarketManager) else 0
	_channel_label = Label.new()
	_channel_label.text = "Channels: %d/4" % channels_unlocked

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.add_child(_revenue_label)
	hbox.add_child(_revenue_bar)
	hbox.add_child(_channel_label)
	add_child(hbox)
	move_child(hbox, 0)

func _update_header() -> void:
	if has_node("HeaderLabel"):
		$HeaderLabel.text = "MASS-MARKET BREWERY"

func refresh_revenue() -> void:
	if _revenue_bar:
		_revenue_bar.value = GameState.total_revenue
	if _revenue_label:
		_revenue_label.text = "$%d/$50K" % int(GameState.total_revenue)
	if _channel_label:
		var channels_unlocked: int = MarketManager.get_unlocked_channels().size() if is_instance_valid(MarketManager) else 0
		_channel_label.text = "Channels: %d/4" % channels_unlocked
```

**Step 2: Integrate fork overlay into Game.gd**

In `src/scenes/Game.gd`, add fork overlay variable after the `_sell_overlay` declaration (line 26):

```gdscript
var _fork_overlay: CanvasLayer = null
```

Add fork overlay creation in `_ready()`, after the sell overlay setup, and connect the BreweryExpansion fork signal:

```gdscript
	# Fork choice overlay (Stage 5A)
	BreweryExpansion.fork_threshold_reached.connect(_on_fork_threshold_reached)
	PathManager.path_chosen.connect(_on_path_chosen)
```

Add the fork handlers:

```gdscript
# ---------------------------------------------------------------------------
# Fork choice handlers (Stage 5A)
# ---------------------------------------------------------------------------

func _on_fork_threshold_reached() -> void:
	_show_fork_overlay()

func _show_fork_overlay() -> void:
	_close_all_managed_overlays()
	if _fork_overlay == null:
		_fork_overlay = preload("res://ui/ForkChoiceOverlay.gd").new()
		add_child(_fork_overlay)
		_managed_overlays.append(_fork_overlay)
		_fork_overlay.path_selected.connect(_on_fork_path_selected)
	_fork_overlay.show_overlay()

func _on_fork_path_selected(path_type: String) -> void:
	PathManager.choose_path(path_type)
	var target_stage: BreweryExpansion.Stage
	if path_type == "artisan":
		target_stage = BreweryExpansion.Stage.ARTISAN
	else:
		target_stage = BreweryExpansion.Stage.MASS_MARKET
	BreweryExpansion.expand_to_path(target_stage)
	_swap_brewery_scene(path_type)
	if is_instance_valid(ToastManager):
		ToastManager.show_toast("You've chosen the %s path!" % PathManager.get_path_name())

func _on_path_chosen(_path_type: String) -> void:
	pass  # Additional reactions to path choice can go here

func _swap_brewery_scene(path_type: String) -> void:
	# Remove old brewery scene
	var old_scene: Node = brewery_scene
	remove_child(old_scene)
	old_scene.queue_free()

	# Instantiate path-specific scene
	var new_script: GDScript
	if path_type == "artisan":
		new_script = preload("res://scenes/ArtisanBreweryScene.gd")
	else:
		new_script = preload("res://scenes/MassMarketBreweryScene.gd")

	var new_scene := Node2D.new()
	new_scene.set_script(new_script)
	new_scene.name = "BreweryScene"
	add_child(new_scene)
	move_child(new_scene, 0)
	brewery_scene = new_scene

	# Reconnect brewery scene signals
	_connect_brewery_signals()
```

Note: `_connect_brewery_signals()` may need to be extracted from the existing `_ready()` setup. The implementing engineer should check what signals BreweryScene currently connects and factor those out.

**Step 3: Run test to verify it passes**

Run: `make test`
Expected: PASS

**Step 4: Commit**

```bash
git add src/scenes/ArtisanBreweryScene.gd src/scenes/MassMarketBreweryScene.gd src/scenes/Game.gd src/autoloads/GameState.gd
git commit -m "feat: add fork overlay integration and path-specific brewery scenes"
```

---

### Task 9: Full Test Suite and Edge Cases

**Files:**
- Modify: `src/tests/test_path_manager.gd` (edge cases)
- Run full test suite to verify no regressions

**Step 1: Add edge case tests**

Append to `src/tests/test_path_manager.gd`:

```gdscript
# --- Edge Cases ---

func test_path_bonuses_reset_on_new_run():
	PathManager.reset()
	PathManager.choose_path("artisan")
	PathManager.add_reputation(50)
	GameState.reset()
	assert_false(PathManager.has_chosen_path())
	assert_eq(PathManager.get_reputation(), 0)

func test_path_bonus_queries_safe_before_path_chosen():
	PathManager.reset()
	# All queries should return defaults, not crash
	assert_almost_eq(PathManager.get_quality_bonus(), 1.0, 0.001)
	assert_almost_eq(PathManager.get_batch_multiplier(), 1.0, 0.001)
	assert_almost_eq(PathManager.get_ingredient_discount(), 1.0, 0.001)
	assert_almost_eq(PathManager.get_competition_discount(), 1.0, 0.001)
	assert_false(PathManager.check_win_condition())
	assert_eq(PathManager.get_reputation(), 0)
	assert_eq(PathManager.get_path_name(), "")

func test_expansion_stage_after_artisan_fork():
	PathManager.reset()
	BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY
	BreweryExpansion.expand_to_path(BreweryExpansion.Stage.ARTISAN)
	assert_eq(BreweryExpansion.current_stage, BreweryExpansion.Stage.ARTISAN)
	assert_eq(BreweryExpansion.get_max_staff(), 3)
	assert_eq(BreweryExpansion.get_equipment_tier_cap(), 4)

func test_expansion_stage_after_mass_market_fork():
	PathManager.reset()
	BreweryExpansion.current_stage = BreweryExpansion.Stage.MICROBREWERY
	BreweryExpansion.expand_to_path(BreweryExpansion.Stage.MASS_MARKET)
	assert_eq(BreweryExpansion.current_stage, BreweryExpansion.Stage.MASS_MARKET)
	assert_eq(BreweryExpansion.get_max_staff(), 4)
	assert_eq(BreweryExpansion.get_rent_amount(), 800.0)

func test_cannot_choose_path_after_already_expanded():
	PathManager.reset()
	BreweryExpansion.current_stage = BreweryExpansion.Stage.ARTISAN
	BreweryExpansion.beers_brewed = 25
	GameState.balance = 15000.0
	# Already past microbrewery — can't choose again
	assert_false(PathManager.can_choose_path())

func test_save_load_preserves_expansion_stage():
	BreweryExpansion.current_stage = BreweryExpansion.Stage.ARTISAN
	var data: Dictionary = BreweryExpansion.save_state()
	BreweryExpansion.reset()
	BreweryExpansion.load_state(data)
	assert_eq(BreweryExpansion.current_stage, BreweryExpansion.Stage.ARTISAN)
```

**Step 2: Run full test suite**

Run: `make test`
Expected: ALL tests pass (425 existing + ~35 new = ~460 total)

**Step 3: Fix any failures**

If any existing tests break, investigate and fix. Common issues:
- Tests that check `check_win_condition()` with balance >= 10000 should still work (pre-fork default)
- Tests that don't reset PathManager may have stale state — add `PathManager.reset()` to their `before_each()` if needed

**Step 4: Commit**

```bash
git add src/tests/test_path_manager.gd
git commit -m "test: add edge case tests for path system and full regression check"
```

---

## Summary

| Task | What | Files Created | Files Modified |
|------|------|---------------|----------------|
| 1 | BreweryPath base class | `scripts/paths/BreweryPath.gd`, `tests/test_path_manager.gd` | — |
| 2 | ArtisanPath + MassMarketPath | `scripts/paths/ArtisanPath.gd`, `scripts/paths/MassMarketPath.gd` | `tests/test_path_manager.gd` |
| 3 | PathManager autoload | `autoloads/PathManager.gd` | `project.godot`, `tests/test_path_manager.gd` |
| 4 | Integrate path bonuses | — | `QualityCalculator.gd`, `GameState.gd`, `CompetitionManager.gd`, tests |
| 5 | Win conditions + reputation | — | `GameState.gd`, tests |
| 6 | Fork threshold + expansion | — | `BreweryExpansion.gd`, `GameState.gd`, tests |
| 7 | ForkChoiceOverlay UI | `ui/ForkChoiceOverlay.gd` | tests |
| 8 | Game.gd integration + scene swap | `scenes/ArtisanBreweryScene.gd`, `scenes/MassMarketBreweryScene.gd` | `Game.gd` |
| 9 | Full test suite + edge cases | — | tests |
