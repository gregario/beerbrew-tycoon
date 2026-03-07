# Quality Scoring Rebalance Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Refactor QualityCalculator from 5-component to 7-component scoring with fermentation as a dominant lever, water/hop stubs, and conditioning bonus.

**Architecture:** QualityCalculator gets new weight constants, a fermentation component using BrewingScience.calc_yeast_flavors(), water/hop stub components with sensible defaults, and an expanded calculate_quality() signature. Backward compatibility via default parameter values.

**Tech Stack:** Godot 4 / GDScript, GUT tests, `make test`

---

### Task 1: Refactor QualityCalculator weights, signature, and components

This is a single cohesive refactor — weights, signature, fermentation component, water/hop stubs, conditioning, and backward compat must all land together to keep tests passing.

**Files:**
- Modify: `src/autoloads/QualityCalculator.gd`
- Modify: `src/tests/test_quality_calculator.gd`
- Create: `src/tests/test_quality_rebalance.gd`

**Step 1: Update weight constants**

Replace the 5 old weight constants with 7 new ones in QualityCalculator.gd:

```gdscript
# OLD weights — remove these:
# const WEIGHT_RATIO: float = 0.40
# const WEIGHT_INGREDIENTS: float = 0.20
# const WEIGHT_NOVELTY: float = 0.10
# const WEIGHT_BASE: float = 0.10
# const WEIGHT_SCIENCE: float = 0.20

# NEW 7-component weights (sum to 1.0)
const WEIGHT_STYLE: float = 0.25
const WEIGHT_FERMENTATION: float = 0.25
const WEIGHT_SCIENCE: float = 0.15
const WEIGHT_WATER: float = 0.10
const WEIGHT_HOP_SCHEDULE: float = 0.10
const WEIGHT_NOVELTY: float = 0.10
const WEIGHT_CONDITIONING: float = 0.05
```

**Step 2: Update calculate_quality() signature**

Add optional parameters with backward-compatible defaults:

```gdscript
func calculate_quality(
		style: BeerStyle,
		recipe: Dictionary,
		sliders: Dictionary,
		history: Array,
		water_profile = null,        # WaterProfile or null (default tap water)
		hop_allocations: Dictionary = {},  # hop_id -> slot name mapping
		conditioning_weeks: int = 0  # 0-4 weeks
) -> Dictionary:
```

**Step 3: Implement _compute_fermentation_score()**

New private method. Three sub-components averaged:
1. **Yeast-temp accuracy** (40%): From existing `BrewingScience.calc_yeast_accuracy()` — the `quality_bonus` field (0.0-1.0)
2. **Flavor compound desirability** (40%): Uses `BrewingScience.calc_yeast_flavors()` to get compounds, then scores how well they match the style's `yeast_temp_flavors` expectations. If style has no `yeast_temp_flavors`, default 0.7.
3. **Temperature stability** (20%): Based on equipment. If EquipmentManager has a fermentation chamber (check `active_bonuses.get("ferment_temp_control", 0)` > 0), stability = 1.0. Otherwise stability = 0.6.

```gdscript
func _compute_fermentation_score(style: BeerStyle, recipe: Dictionary, sliders: Dictionary) -> float:
	var ferment_temp: float = sliders.get("fermenting", 20.0)
	var yeast: Yeast = recipe.get("yeast", null) as Yeast

	# Sub-component 1: yeast-temp accuracy (40%)
	var accuracy: float = 0.5
	if yeast != null:
		var yeast_result: Dictionary = BrewingScience.calc_yeast_accuracy(ferment_temp, yeast)
		accuracy = yeast_result["quality_bonus"]

	# Sub-component 2: flavor compound desirability (40%)
	var flavor_desirability: float = 0.7  # default if no yeast or no style data
	if yeast != null and not style.yeast_temp_flavors.is_empty():
		var compounds: Dictionary = BrewingScience.calc_yeast_flavors(ferment_temp, yeast)
		flavor_desirability = _score_flavor_compounds(compounds, style)

	# Sub-component 3: temperature stability (20%)
	var stability: float = 0.6
	if is_instance_valid(EquipmentManager):
		var ferment_control: float = EquipmentManager.active_bonuses.get("ferment_temp_control", 0.0)
		if ferment_control > 0:
			stability = 1.0

	return (accuracy * 0.4 + flavor_desirability * 0.4 + stability * 0.2) * 100.0
```

**Step 4: Implement _score_flavor_compounds()**

Scores how well the yeast-temp flavor compounds match what the style expects:

```gdscript
func _score_flavor_compounds(compounds: Dictionary, style: BeerStyle) -> float:
	# style.yeast_temp_flavors maps compound_name -> desired_intensity (0.0-1.0)
	# compounds maps compound_name -> actual_intensity (0.0-1.0)
	# Score: average of (1.0 - abs(desired - actual)) for each desired compound
	var desired: Dictionary = style.yeast_temp_flavors
	if desired.is_empty():
		return 0.7
	var total: float = 0.0
	var count: int = 0
	for compound_name in desired:
		var desired_intensity: float = desired[compound_name]
		var actual_intensity: float = compounds.get(compound_name, 0.0)
		total += 1.0 - absf(desired_intensity - actual_intensity)
		count += 1
	if count == 0:
		return 0.7
	return total / float(count)
```

**Step 5: Implement _compute_water_score()**

Stub that uses WaterProfile.get_affinity() if a profile is provided:

```gdscript
func _compute_water_score(style: BeerStyle, water_profile) -> float:
	if water_profile == null or not water_profile is WaterProfile:
		return 0.6 * 100.0  # Default tap water = 60/100
	var affinity: float = water_profile.get_affinity(style.style_id)
	return affinity * 100.0
```

**Step 6: Implement _compute_hop_schedule_score()**

Stub that compares hop allocations to style expectations:

```gdscript
func _compute_hop_schedule_score(style: BeerStyle, hop_allocations: Dictionary) -> float:
	if hop_allocations.is_empty():
		return 0.5 * 100.0  # Default: no allocations = 50/100
	# If style has no expectations, any allocation is fine
	var expectations: Dictionary = style.hop_schedule_expectations
	if expectations.is_empty():
		return 0.7 * 100.0
	# Count how many allocated hops match expected slots
	var matches: int = 0
	var total: int = 0
	for hop_id in hop_allocations:
		var slot: String = hop_allocations[hop_id] if hop_allocations[hop_id] is String else ""
		total += 1
		# expectations maps slot_name -> weight (e.g., {"bittering": 0.3, "aroma": 0.5, "dry_hop": 0.2})
		if expectations.has(slot):
			matches += 1
	if total == 0:
		return 0.5 * 100.0
	return (float(matches) / float(total)) * 100.0
```

**Step 7: Implement conditioning score**

Simple: +1% per week, max 4%:

```gdscript
func _compute_conditioning_score(conditioning_weeks: int) -> float:
	# 1% per week = 20/100 per week on the 0-100 scale
	return clampf(float(conditioning_weeks) * 20.0, 0.0, 80.0)
```

Wait — the spec says conditioning is 5% weight and +1% per week max 4%. So conditioning_score should be 0-100 scale internally, with each week adding 25 points (so 4 weeks = 100). Then 100 * 0.05 weight = 5% max contribution.

```gdscript
func _compute_conditioning_score(conditioning_weeks: int) -> float:
	return clampf(float(conditioning_weeks) * 25.0, 0.0, 100.0)
```

**Step 8: Refactor the main calculate_quality() body**

Merge the old `ratio_score` and `ingredient_score` into a single `style_match` component. Remove `base_score` (absorbed into other components). Use the new fermentation, water, hop_schedule, and conditioning components.

The style_match component combines:
- Ratio score (50%): existing `_compute_ratio_score()`
- Ingredient score (50%): existing `_compute_ingredient_score()`

```gdscript
# --- Style Match (25%) ---
var ratio_score := _compute_ratio_score(style, total_flavor, total_technique)
var ingredient_score := _compute_ingredient_score(style, recipe)
var style_match: float = ratio_score * 0.5 + ingredient_score * 0.5

# --- Fermentation (25%) ---
var fermentation_score := _compute_fermentation_score(style, recipe, sliders)

# --- Science (15%) --- (existing, with tolerance zones from Group 3)
var science_score := _compute_science_score(style, recipe, sliders)

# --- Water (10%) ---
var water_score := _compute_water_score(style, water_profile)

# --- Hop Schedule (10%) ---
var hop_schedule_score := _compute_hop_schedule_score(style, hop_allocations)

# --- Novelty (10%) ---
var novelty_modifier := _compute_novelty_modifier(style, recipe, history)
var novelty_score: float = novelty_modifier * 100.0

# --- Conditioning (5%) ---
var conditioning_score := _compute_conditioning_score(conditioning_weeks)

# --- Weighted sum ---
var final_score: float = clampf(
	style_match * WEIGHT_STYLE +
	fermentation_score * WEIGHT_FERMENTATION +
	science_score * WEIGHT_SCIENCE +
	water_score * WEIGHT_WATER +
	hop_schedule_score * WEIGHT_HOP_SCHEDULE +
	novelty_score * WEIGHT_NOVELTY +
	conditioning_score * WEIGHT_CONDITIONING,
	0.0, 100.0
)
```

Return dictionary should include all new keys:

```gdscript
return {
	"final_score": final_score,
	"style_match": style_match,
	"ratio_score": ratio_score,          # Keep for backward compat
	"ingredient_score": ingredient_score, # Keep for backward compat
	"fermentation_score": fermentation_score,
	"science_score": science_score,
	"water_score": water_score,
	"hop_schedule_score": hop_schedule_score,
	"novelty_score": novelty_score,
	"conditioning_score": conditioning_score,
	"base_score": base_score,            # Keep for backward compat (compute as before)
	"total_flavor_points": total_flavor,
	"total_technique_points": total_technique,
	"novelty_modifier": novelty_modifier,
	"brew_attributes": brew_attributes,
}
```

**Step 9: Update existing tests in test_quality_calculator.gd**

The weight changes will shift score values. Key updates needed:
- `test_result_has_all_expected_keys()` — add new keys: `style_match`, `fermentation_score`, `water_score`, `hop_schedule_score`, `conditioning_score`
- Score comparisons (gt/lt) should still hold since relative ordering is preserved
- Specific score assertions may need loosening

**Step 10: Write new test file test_quality_rebalance.gd**

Tests for:
1. All 7 component weights sum to 1.0
2. Fermentation component: perfect ferment scores high, bad ferment scores low
3. Flavor compound scoring: matching compounds score higher than mismatched
4. Water component: perfect affinity > default tap water > wrong profile
5. Hop schedule component: matching allocations > empty allocations
6. Conditioning component: more weeks = higher score, capped at 4
7. Backward compatibility: calling without new params produces reasonable scores
8. Style match combines ratio + ingredients correctly
9. Full calculation with all components returns all expected keys

**Step 11: Run tests**

Run: `GODOT="/Users/gregario/Library/Application Support/Steam/steamapps/common/Godot Engine/Godot.app/Contents/MacOS/Godot" make test`
Expected: All tests pass.

**Step 12: Commit**

```bash
git add src/autoloads/QualityCalculator.gd src/tests/test_quality_calculator.gd src/tests/test_quality_rebalance.gd
git commit -m "feat: rebalance quality scoring to 7-component system

Refactor QualityCalculator from 5-component to 7-component scoring:
Style Match 25%, Fermentation 25%, Science 15%, Water 10%,
Hop Schedule 10%, Novelty 10%, Conditioning 5%.

Add fermentation component (yeast-temp accuracy + flavor compounds +
stability). Add water/hop schedule stubs with defaults. Add conditioning
bonus. Backward compatible via default parameters."
```
