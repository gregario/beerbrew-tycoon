extends Node

## QualityCalculator — pure quality scoring logic for BeerBrew Tycoon.
## All methods are stateless. Pass all inputs; receive score + breakdown.

# Phase contribution profiles: [flavor_weight, technique_weight]
# Slider value (0–100) is multiplied by these weights to get raw points.
const PHASE_PROFILES := {
	"mashing":    [0.3, 0.7],  # Technique-heavy: grain conversion, temperature
	"boiling":    [0.5, 0.5],  # Balanced: hop additions, timing
	"fermenting": [0.7, 0.3],  # Flavor-heavy: yeast character, complexity
}

# Score component weights (must sum to 1.0)
const WEIGHT_RATIO: float = 0.50
const WEIGHT_INGREDIENTS: float = 0.25
const WEIGHT_NOVELTY: float = 0.15
const WEIGHT_BASE: float = 0.10

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

	# --- 6. Weighted final score ---
	var final_score: float = (
		ratio_score * WEIGHT_RATIO +
		ingredient_score * WEIGHT_INGREDIENTS +
		novelty_score * WEIGHT_NOVELTY +
		base_score * WEIGHT_BASE
	)
	final_score = clampf(final_score, 0.0, 100.0)

	return {
		"final_score": final_score,
		"ratio_score": ratio_score,
		"ingredient_score": ingredient_score,
		"novelty_score": novelty_score,
		"base_score": base_score,
		"total_flavor_points": total_flavor,
		"total_technique_points": total_technique,
		"novelty_modifier": novelty_modifier,
	}

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

## Compute raw Flavor and Technique points from slider values.
## sliders: {mashing: float, boiling: float, fermenting: float} each 0–100.
func _compute_points(sliders: Dictionary) -> Dictionary:
	var flavor := 0.0
	var technique := 0.0
	for phase_name in PHASE_PROFILES:
		var value: float = sliders.get(phase_name, 50.0)
		var profile: Array = PHASE_PROFILES[phase_name]
		flavor += value * profile[0]
		technique += value * profile[1]
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

## Compute just the raw points for a preview (used by BrewingPhases UI).
func preview_points(sliders: Dictionary) -> Dictionary:
	return _compute_points(sliders)
