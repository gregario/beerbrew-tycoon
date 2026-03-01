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

# Score component weights (must sum to 1.0)
const WEIGHT_RATIO: float = 0.40
const WEIGHT_INGREDIENTS: float = 0.20
const WEIGHT_NOVELTY: float = 0.10
const WEIGHT_BASE: float = 0.10
const WEIGHT_SCIENCE: float = 0.20

# Novelty config (also in specs)
const NOVELTY_PENALTY_PER_REPEAT: float = 0.15
const NOVELTY_FLOOR: float = 0.4

# Ratio tolerance: deviation beyond this collapses ratio score to 0
const RATIO_TOLERANCE: float = 0.35

## Main entry point. Returns a Dictionary with:
##   "final_score":         float 0–100
##   "ratio_score":         float 0–100 (component before weighting)
##   "ingredient_score":    float 0–100
##   "novelty_score":       float 0–100 (novelty_modifier * 100)
##   "base_score":          float 0–100
##   "total_flavor_points": float
##   "total_technique_points": float
##   "novelty_modifier":    float 0.4–1.0
func calculate_quality(
		style: BeerStyle,
		recipe: Dictionary,
		sliders: Dictionary,
		history: Array
) -> Dictionary:
	# --- 1. Compute raw points from phase sliders ---
	var points := _compute_points(sliders)
	var total_flavor: float = points["flavor"]
	var total_technique: float = points["technique"]
	var total_points: float = total_flavor + total_technique

	# --- 2. Ratio match score ---
	var ratio_score := _compute_ratio_score(style, total_flavor, total_technique)

	# --- 3. Ingredient compatibility score ---
	var ingredient_score := _compute_ingredient_score(style, recipe)

	# --- 4. Novelty modifier and score ---
	var novelty_modifier := _compute_novelty_modifier(style, recipe, history)
	var novelty_score: float = novelty_modifier * 100.0

	# --- 5. Base effort score ---
	# Max possible points at 100/100/100: sum of phase weights * 100 each
	# mashing max: 30 + 70 = 100, boiling: 50 + 50 = 100, fermenting: 70 + 30 = 100 → total 300
	var base_score: float = clampf((total_points / 300.0) * 100.0, 0.0, 100.0)

	# --- 6. Brewing science score ---
	var science_score: float = _compute_science_score(style, recipe, sliders)

	# --- 7. Weighted final score ---
	var final_score: float = clampf(
		ratio_score * WEIGHT_RATIO +
		ingredient_score * WEIGHT_INGREDIENTS +
		novelty_score * WEIGHT_NOVELTY +
		base_score * WEIGHT_BASE +
		science_score * WEIGHT_SCIENCE,
		0.0, 100.0
	)

	# --- 8. Detect flavor attributes for discovery system ---
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
		"ratio_score": ratio_score,
		"ingredient_score": ingredient_score,
		"novelty_score": novelty_score,
		"base_score": base_score,
		"science_score": science_score,
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
	return {"flavor": flavor, "technique": technique}

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

## Compute brewing science score from mash temp, boil duration, and ferment temp.
## Returns 0–100.
func _compute_science_score(style: BeerStyle, recipe: Dictionary, sliders: Dictionary) -> float:
	var mash_temp: float = sliders.get("mashing", 65.0)
	var boil_duration: float = sliders.get("boiling", 60.0)
	var ferment_temp: float = sliders.get("fermenting", 20.0)
	var mash_score: float = BrewingScience.calc_mash_score(mash_temp, style)
	# Apply research mash bonus
	if is_instance_valid(ResearchManager):
		mash_score = minf(mash_score + ResearchManager.bonuses.get("mash_score_bonus", 0.0), 1.0)
	var boil_score: float = BrewingScience.calc_boil_score(boil_duration, style)
	var yeast: Yeast = recipe.get("yeast", null) as Yeast
	var yeast_score: float = 0.5
	if yeast != null:
		var yeast_result: Dictionary = BrewingScience.calc_yeast_accuracy(ferment_temp, yeast)
		yeast_score = yeast_result["quality_bonus"]
	return (mash_score * 33.0 + boil_score * 33.0 + yeast_score * 34.0)

## Compute just the raw points for a preview (used by BrewingPhases UI).
func preview_points(sliders: Dictionary) -> Dictionary:
	return _compute_points(sliders)
