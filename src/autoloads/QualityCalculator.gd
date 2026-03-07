extends Node

## QualityCalculator — pure quality scoring logic for BeerBrew Tycoon.
## All methods are stateless. Pass all inputs; receive score + breakdown.

# Phase contribution profiles: [flavor_weight, technique_weight]
# Physical slider values are normalized to 0–100 before multiplying by weights.
const PHASE_PROFILES := {
	"mashing":    [0.3, 0.7],  # Technique-heavy: grain conversion, temperature
	"boiling":    [0.5, 0.5],  # Balanced: hop additions, timing
	"fermenting": [0.7, 0.3],  # Flavor-heavy: yeast character, complexity
}

# Score component weights — 7 components (must sum to 1.0)
const WEIGHT_STYLE: float = 0.25
const WEIGHT_FERMENTATION: float = 0.25
const WEIGHT_SCIENCE: float = 0.15
const WEIGHT_WATER: float = 0.10
const WEIGHT_HOP_SCHEDULE: float = 0.10
const WEIGHT_NOVELTY: float = 0.10
const WEIGHT_CONDITIONING: float = 0.05

# Specialty beer variance
const SPECIALTY_VARIANCE: float = 15.0
const SPECIALTY_CEILING_BOOST: float = 10.0

# Novelty config (also in specs)
const NOVELTY_PENALTY_PER_REPEAT: float = 0.15
const NOVELTY_FLOOR: float = 0.4

# Ratio tolerance: deviation beyond this collapses ratio score to 0
const RATIO_TOLERANCE: float = 0.35

## Main entry point. Returns a Dictionary with:
##   "final_score":           float 0–100
##   "style_match":           float 0–100 (ratio*0.5 + ingredient*0.5)
##   "ratio_score":           float 0–100 (backward compat)
##   "ingredient_score":      float 0–100 (backward compat)
##   "fermentation_score":    float 0–100
##   "science_score":         float 0–100
##   "water_score":           float 0–100
##   "hop_schedule_score":    float 0–100
##   "novelty_score":         float 0–100 (novelty_modifier * 100)
##   "conditioning_score":    float 0–100
##   "base_score":            float 0–100 (backward compat)
##   "total_flavor_points":   float
##   "total_technique_points": float
##   "novelty_modifier":      float 0.4–1.0
##   "brew_attributes":       Array[String]
func calculate_quality(
		style: BeerStyle,
		recipe: Dictionary,
		sliders: Dictionary,
		history: Array,
		water_profile = null,
		hop_allocations: Dictionary = {},
		conditioning_weeks: int = 0
) -> Dictionary:
	# --- 1. Compute raw points from phase sliders ---
	var points := _compute_points(sliders)
	var total_flavor: float = points["flavor"]
	var total_technique: float = points["technique"]
	var total_points: float = total_flavor + total_technique

	# --- 2. Style Match (25%) = ratio*0.5 + ingredient*0.5 ---
	var ratio_score := _compute_ratio_score(style, total_flavor, total_technique)
	var ingredient_score := _compute_ingredient_score(style, recipe)
	var style_match: float = ratio_score * 0.5 + ingredient_score * 0.5

	# --- 3. Fermentation (25%) ---
	var fermentation_score := _compute_fermentation_score(style, recipe, sliders)

	# --- 4. Science (15%) — mash + boil only ---
	var science_score: float = _compute_science_score(style, recipe, sliders)

	# --- 5. Water (10%) ---
	var water_score := _compute_water_score(style, water_profile)

	# --- 6. Hop Schedule (10%) ---
	var hop_schedule_score := _compute_hop_schedule_score(style, hop_allocations)

	# --- 7. Novelty (10%) ---
	var novelty_modifier := _compute_novelty_modifier(style, recipe, history)
	var novelty_score: float = novelty_modifier * 100.0

	# --- 8. Conditioning (5%) ---
	var conditioning_score := _compute_conditioning_score(conditioning_weeks)

	# --- 9. Base effort score (backward compat, not weighted) ---
	var base_score: float = clampf((total_points / 300.0) * 100.0, 0.0, 100.0)

	# --- 10. Weighted final score ---
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

	# --- 10b. Path quality bonus (e.g., Artisan +20%) ---
	if is_instance_valid(PathManager):
		final_score = clampf(final_score * PathManager.get_quality_bonus(), 0.0, 100.0)

	# --- 11. Detect flavor attributes for discovery system ---
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

	return {
		"final_score": final_score,
		"style_match": style_match,
		"ratio_score": ratio_score,
		"ingredient_score": ingredient_score,
		"fermentation_score": fermentation_score,
		"science_score": science_score,
		"water_score": water_score,
		"hop_schedule_score": hop_schedule_score,
		"novelty_score": novelty_score,
		"conditioning_score": conditioning_score,
		"base_score": base_score,
		"total_flavor_points": total_flavor,
		"total_technique_points": total_technique,
		"novelty_modifier": novelty_modifier,
		"brew_attributes": brew_attributes,
	}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

## Normalizes physical slider values to 0–100 for points calculation.
## Mashing: 62–69°C, Boiling: 30–90 min, Fermenting: 15–25°C.
## Values outside physical ranges are clamped to 0–100 after normalization.
static func _normalize_sliders(sliders: Dictionary) -> Dictionary:
	return {
		"mashing": clampf((sliders.get("mashing", 65.0) - 62.0) / 7.0 * 100.0, 0.0, 100.0),
		"boiling": clampf((sliders.get("boiling", 60.0) - 30.0) / 60.0 * 100.0, 0.0, 100.0),
		"fermenting": clampf((sliders.get("fermenting", 20.0) - 15.0) / 10.0 * 100.0, 0.0, 100.0),
	}

## Compute raw Flavor and Technique points from slider values.
## Sliders are in physical units; normalized to 0–100 internally.
func _compute_points(sliders: Dictionary) -> Dictionary:
	var normalized := _normalize_sliders(sliders)
	var flavor := 0.0
	var technique := 0.0
	for phase_name in PHASE_PROFILES:
		var value: float = normalized.get(phase_name, 50.0)
		var profile: Array = PHASE_PROFILES[phase_name]
		flavor += value * profile[0]
		technique += value * profile[1]
	# Apply equipment efficiency bonus
	if is_instance_valid(EquipmentManager):
		var eff_bonus: float = EquipmentManager.active_bonuses.get("efficiency", 0.0)
		if is_instance_valid(ResearchManager):
			eff_bonus += ResearchManager.bonuses.get("efficiency_bonus", 0.0)
		technique *= (1.0 + eff_bonus)
	# Staff + automation bonuses — use whichever is larger per phase
	for phase_name in ["mashing", "boiling", "fermenting"]:
		var staff_bonus: Dictionary = {"flavor": 0.0, "technique": 0.0}
		if is_instance_valid(StaffManager):
			staff_bonus = StaffManager.get_phase_bonus(phase_name)
		var auto_bonus: int = 0
		if is_instance_valid(EquipmentManager):
			match phase_name:
				"mashing":
					auto_bonus = EquipmentManager.get_automation_mash_bonus()
				"boiling":
					auto_bonus = EquipmentManager.get_automation_boil_bonus()
				"fermenting":
					auto_bonus = EquipmentManager.get_automation_ferment_bonus()
		var effective: Dictionary = get_effective_phase_bonus(staff_bonus, auto_bonus)
		flavor += effective["flavor"]
		technique += effective["technique"]
	return {"flavor": flavor, "technique": technique}

## Returns the effective phase bonus: staff or automation, whichever is larger.
## If automation exceeds staff total (flavor+technique), split automation evenly.
func get_effective_phase_bonus(staff_bonus: Dictionary, automation_bonus: int) -> Dictionary:
	var staff_total: float = staff_bonus.get("flavor", 0.0) + staff_bonus.get("technique", 0.0)
	if float(automation_bonus) > staff_total:
		var half: float = float(automation_bonus) / 2.0
		return {"flavor": half, "technique": half}
	return staff_bonus

## Compare player's flavor ratio to style's ideal.
## Returns 0–100: 100 at perfect match, 0 at or beyond RATIO_TOLERANCE deviation.
func _compute_ratio_score(style: BeerStyle, flavor: float, technique: float) -> float:
	var total: float = flavor + technique
	if total == 0.0:
		return 0.0
	var player_ratio: float = flavor / total
	var deviation: float = abs(player_ratio - style.ideal_flavor_ratio)
	var score: float = clampf(1.0 - (deviation / RATIO_TOLERANCE), 0.0, 1.0) * 100.0
	return score

## Ingredient score: 50% compatibility (style prefers ingredient) + 50% flavor match.
## Returns 0–100.
func _compute_ingredient_score(style: BeerStyle, recipe: Dictionary) -> float:
	var compat := _compute_compatibility_score(style, recipe)
	var flavor := _compute_flavor_match_score(style, recipe)
	return compat * 0.5 + flavor * 0.5

## Average ingredient compatibility via style.get_ingredient_compatibility().
## Returns 0–100.
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

## Euclidean distance between combined recipe flavor profile and style ideal.
## Returns 0–100.
func _compute_flavor_match_score(style: BeerStyle, recipe: Dictionary) -> float:
	var combined := _combine_flavor_profiles(recipe)
	var ideal: Dictionary = style.ideal_flavor_profile
	var sum_sq := 0.0
	for axis in ["bitterness", "sweetness", "roastiness", "fruitiness", "funkiness"]:
		var diff: float = combined.get(axis, 0.0) - ideal.get(axis, 0.0)
		sum_sq += diff * diff
	var distance: float = sqrt(sum_sq)
	var max_dist: float = sqrt(5.0)
	return clampf((1.0 - distance / max_dist) * 100.0, 0.0, 100.0)

## Average all ingredients' flavor_profile dictionaries across 5 axes.
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

## Count prior brews of the exact same style+ingredient combo.
## Returns novelty modifier 1.0 -> 0.4 (floored).
## History entries use arrays: malt_ids, hop_ids, adjunct_ids (sorted).
func _compute_novelty_modifier(
		style: BeerStyle,
		recipe: Dictionary,
		history: Array
) -> float:
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

## Compute fermentation score from yeast-temp accuracy, flavor compounds, and stability.
## Returns 0–100.
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

## Scores how well the yeast-temp flavor compounds match what the style expects.
## Returns 0.0–1.0.
func _score_flavor_compounds(compounds: Dictionary, style: BeerStyle) -> float:
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

## Compute brewing science score from mash temp and boil duration.
## Yeast accuracy is now handled by the fermentation component.
## Returns 0–100.
func _compute_science_score(style: BeerStyle, _recipe: Dictionary, sliders: Dictionary) -> float:
	var mash_temp: float = sliders.get("mashing", 65.0)
	var boil_duration: float = sliders.get("boiling", 60.0)
	var mash_score: float = BrewingScience.calc_mash_score(mash_temp, style)
	# Apply research mash bonus
	if is_instance_valid(ResearchManager):
		mash_score = minf(mash_score + ResearchManager.bonuses.get("mash_score_bonus", 0.0), 1.0)
	var boil_score: float = BrewingScience.calc_boil_score(boil_duration, style)
	return (mash_score * 50.0 + boil_score * 50.0)

## Compute water chemistry score. Stub: uses WaterProfile affinity or default 60.
## Returns 0–100.
func _compute_water_score(style: BeerStyle, water_profile) -> float:
	if water_profile == null or not water_profile is WaterProfile:
		return 0.6 * 100.0  # Default tap water = 60/100
	var affinity: float = water_profile.get_affinity(style.style_id)
	return affinity * 100.0

## Compute hop schedule score. Stub: matches allocations to style expectations.
## Returns 0–100.
func _compute_hop_schedule_score(style: BeerStyle, hop_allocations: Dictionary) -> float:
	if hop_allocations.is_empty():
		return 0.5 * 100.0  # Default: no allocations = 50/100
	var expectations: Dictionary = style.hop_schedule_expectations
	if expectations.is_empty():
		return 0.7 * 100.0
	var matches: int = 0
	var total: int = 0
	for hop_id in hop_allocations:
		var slot: String = hop_allocations[hop_id] if hop_allocations[hop_id] is String else ""
		total += 1
		if expectations.has(slot):
			matches += 1
	if total == 0:
		return 0.5 * 100.0
	return (float(matches) / float(total)) * 100.0

## Compute conditioning score. 25 points per week, max 100.
## Returns 0–100.
func _compute_conditioning_score(conditioning_weeks: int) -> float:
	return clampf(float(conditioning_weeks) * 25.0, 0.0, 100.0)

## Apply specialty beer variance: seeded ±15 variance + 10-point ceiling boost.
## Returns clamped 0–100.
func apply_specialty_variance(base_score: float, seed_val: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var variance: float = rng.randf_range(-SPECIALTY_VARIANCE, SPECIALTY_VARIANCE)
	return clampf(base_score + variance + SPECIALTY_CEILING_BOOST, 0.0, 100.0)

## Compute just the raw points for a preview (used by BrewingPhases UI).
func preview_points(sliders: Dictionary) -> Dictionary:
	return _compute_points(sliders)
