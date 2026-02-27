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

## Average ingredient compatibility across all three selected ingredients.
## Returns 0–100.
func _compute_ingredient_score(style: BeerStyle, recipe: Dictionary) -> float:
	var total_compat := 0.0
	var count := 0
	for slot in ["malt", "hop", "yeast"]:
		var ingredient: Ingredient = recipe.get(slot, null)
		if ingredient != null:
			total_compat += ingredient.get_compatibility(style.style_id)
			count += 1
	if count == 0:
		return 50.0  # Neutral if no ingredients (shouldn't happen)
	return (total_compat / float(count)) * 100.0

## Count prior brews of the exact same style+ingredient combo.
## Returns novelty modifier 1.0 → 0.4 (floored).
func _compute_novelty_modifier(
		style: BeerStyle,
		recipe: Dictionary,
		history: Array
) -> float:
	var style_id: String = style.style_id if style else ""
	var malt_id: String = recipe.get("malt", null).ingredient_id if recipe.get("malt") else ""
	var hop_id: String = recipe.get("hop", null).ingredient_id if recipe.get("hop") else ""
	var yeast_id: String = recipe.get("yeast", null).ingredient_id if recipe.get("yeast") else ""

	var repeat_count := 0
	for entry in history:
		if (entry.get("style_id", "") == style_id and
			entry.get("malt_id", "") == malt_id and
			entry.get("hop_id", "") == hop_id and
			entry.get("yeast_id", "") == yeast_id):
			repeat_count += 1

	var modifier: float = 1.0 - (repeat_count * NOVELTY_PENALTY_PER_REPEAT)
	return maxf(modifier, NOVELTY_FLOOR)

## Compute just the raw points for a preview (used by BrewingPhases UI).
func preview_points(sliders: Dictionary) -> Dictionary:
	return _compute_points(sliders)
