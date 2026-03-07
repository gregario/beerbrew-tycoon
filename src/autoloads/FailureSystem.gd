extends Node

## FailureSystem — infection and off-flavor probability calculations.
## All calculation methods are stateless (pass stats in, get results out).
## Roll methods use RNG and modify brew results.


## Off-flavor descriptions for display.
const OFF_FLAVOR_INFO := {
	"esters": {
		"name": "Esters",
		"description": "Fruity, banana-like character.",
		"tip": "Better temperature control during fermentation helps avoid off-flavors.",
	},
	"fusel_alcohols": {
		"name": "Fusel Alcohols",
		"description": "Hot, solvent-like, boozy character.",
		"tip": "Better temperature control during fermentation helps avoid off-flavors.",
	},
	"dms": {
		"name": "DMS",
		"description": "Cooked corn, vegetal character from short boil.",
		"tip": "A longer, more vigorous boil drives off DMS precursors.",
	},
	"diacetyl": {
		"name": "Diacetyl",
		"description": "Buttery, butterscotch flavor from incomplete fermentation.",
		"tip": "Allow fermentation to complete fully. A diacetyl rest helps.",
	},
	"oxidation": {
		"name": "Oxidation",
		"description": "Cardboard, stale, papery character from oxygen exposure.",
		"tip": "Minimize oxygen exposure during transfers. Closed transfer equipment helps.",
	},
	"acetaldehyde": {
		"name": "Acetaldehyde",
		"description": "Green apple, cidery character from premature packaging.",
		"tip": "Allow fermentation to fully complete before packaging.",
	},
}


## Calculates infection probability from sanitation quality.
## Formula: max(0, (100 - sanitation_quality) / 200.0)
func calc_infection_chance(sanitation_quality: int) -> float:
	return maxf(0.0, float(100 - sanitation_quality) / 200.0)


## Applies infection penalty to a quality score.
## Returns {penalized_score: float, infected: bool, message: String}
func apply_infection_penalty(score: float) -> Dictionary:
	var multiplier: float = randf_range(0.4, 0.6)
	return {
		"penalized_score": score * multiplier,
		"infected": true,
		"message": "Bacteria contaminated your batch. Your beer tastes sour and unpleasant.",
	}


## Calculates off-flavor probability from temperature control quality.
## Same formula as infection: max(0, (100 - stat) / 200.0)
func calc_off_flavor_chance(temp_control_quality: int) -> float:
	return maxf(0.0, float(100 - temp_control_quality) / 200.0)


## Applies off-flavor penalty to a quality score.
## Returns {penalized_score: float, off_flavor_tags: Array[String], message: String}
func apply_off_flavor_penalty(score: float) -> Dictionary:
	var multiplier: float = randf_range(0.7, 0.85)
	var types: Array[String] = ["esters", "fusel_alcohols", "dms"]
	var tag: String = types[randi() % types.size()]
	var info: Dictionary = OFF_FLAVOR_INFO[tag]
	return {
		"penalized_score": score * multiplier,
		"off_flavor_tags": [tag] as Array[String],
		"message": "%s — %s" % [info["name"], info["description"]],
	}


## Generates off-flavor intensities based on brewing conditions.
## Returns Dictionary of off_flavor_type → intensity (0.0-1.0).
func generate_off_flavor_intensities(temp_control_quality: int, batch_size_multiplier: float = 1.0) -> Dictionary:
	var intensities: Dictionary = {}
	var base_risk: float = maxf(0.0, float(100 - temp_control_quality) / 100.0)

	# Esters — fermentation temperature issues
	if base_risk > 0.0 and randf() < base_risk * 0.6:
		intensities["esters"] = randf_range(0.1, base_risk)

	# Fusel alcohols — high fermentation temperature
	if base_risk > 0.3 and randf() < base_risk * 0.4:
		intensities["fusel_alcohols"] = randf_range(0.2, base_risk)

	# DMS — from poor boil (not temp_control, but included for compatibility)
	if base_risk > 0.0 and randf() < base_risk * 0.3:
		intensities["dms"] = randf_range(0.1, base_risk * 0.7)

	# Diacetyl — from rushed fermentation
	if base_risk > 0.0 and randf() < base_risk * 0.5:
		intensities["diacetyl"] = randf_range(0.1, base_risk * 0.8)

	# Oxidation — scales with batch size, mitigated by equipment
	var oxidation_risk: float = base_risk * 0.3
	if batch_size_multiplier > 1.0:
		oxidation_risk += (batch_size_multiplier - 1.0) * 0.3
	if randf() < oxidation_risk:
		intensities["oxidation"] = randf_range(0.1, minf(oxidation_risk, 1.0))

	# Acetaldehyde — premature packaging
	if base_risk > 0.2 and randf() < base_risk * 0.3:
		intensities["acetaldehyde"] = randf_range(0.1, base_risk * 0.6)

	return intensities


## Returns severity label for an off-flavor intensity.
func get_severity_label(intensity: float) -> String:
	if intensity < 0.3:
		return "subtle"
	elif intensity <= 0.6:
		return "noticeable"
	else:
		return "dominant"


## Returns context label based on style acceptability.
## "desired" = within acceptable range, "neutral" = borderline, "flaw" = exceeds threshold.
func get_context_label(off_flavor_type: String, intensity: float, style: BeerStyle) -> String:
	var threshold: float = style.acceptable_off_flavors.get(off_flavor_type, 0.0)
	if intensity <= threshold:
		return "desired"
	elif intensity <= threshold + 0.15:
		return "neutral"
	else:
		return "flaw"


## Evaluates off-flavor intensities against a style, returning penalty and context info.
## Returns Array of Dictionaries: [{type, intensity, severity, context, penalty}]
func evaluate_off_flavors(intensities: Dictionary, style: BeerStyle) -> Array:
	var results: Array = []
	for off_flavor_type in intensities:
		var intensity: float = intensities[off_flavor_type]
		if intensity <= 0.0:
			continue
		var threshold: float = style.acceptable_off_flavors.get(off_flavor_type, 0.0)
		var excess: float = maxf(0.0, intensity - threshold)
		var penalty: float = excess * 25.0  # Up to 25 points penalty per off-flavor
		var info: Dictionary = OFF_FLAVOR_INFO.get(off_flavor_type, {"name": off_flavor_type, "description": "", "tip": ""})
		results.append({
			"type": off_flavor_type,
			"display_name": info["name"],
			"description": info["description"],
			"tip": info["tip"],
			"intensity": intensity,
			"severity": get_severity_label(intensity),
			"context": get_context_label(off_flavor_type, intensity, style),
			"penalty": penalty,
		})
	return results


## Roll for all failure modes and apply penalties to the score.
## Returns {final_score, infected, infection_message, off_flavor_tags, off_flavor_message, failure_messages, off_flavor_intensities}
func roll_failures(base_score: float, sanitation_quality: int, temp_control_quality: int, batch_size_multiplier: float = 1.0) -> Dictionary:
	var final_score: float = base_score
	var infected: bool = false
	var infection_message: String = ""
	var off_flavor_tags: Array[String] = []
	var off_flavor_message: String = ""
	var failure_messages: Array[String] = []
	var off_flavor_intensities: Dictionary = {}

	# Roll infection (unchanged)
	var infection_chance: float = calc_infection_chance(sanitation_quality)
	if infection_chance > 0.0 and randf() < infection_chance:
		var infection_result: Dictionary = apply_infection_penalty(final_score)
		final_score = infection_result["penalized_score"]
		infected = true
		infection_message = infection_result["message"]
		failure_messages.append(infection_message)

	# Generate off-flavor intensities
	off_flavor_intensities = generate_off_flavor_intensities(temp_control_quality, batch_size_multiplier)

	# Apply penalties from intensities
	for off_flavor_type in off_flavor_intensities:
		var intensity: float = off_flavor_intensities[off_flavor_type]
		if intensity > 0.0:
			off_flavor_tags.append(off_flavor_type)
			# Penalty proportional to intensity (subtle = small, dominant = severe)
			var penalty_mult: float = 1.0 - (intensity * 0.3)  # max 30% reduction per off-flavor
			final_score *= penalty_mult

	if off_flavor_tags.size() > 0:
		var first_tag: String = off_flavor_tags[0]
		var info: Dictionary = OFF_FLAVOR_INFO.get(first_tag, {"name": first_tag, "description": ""})
		off_flavor_message = "%s — %s" % [info["name"], info["description"]]
		failure_messages.append(off_flavor_message)

	return {
		"final_score": final_score,
		"infected": infected,
		"infection_message": infection_message,
		"off_flavor_tags": off_flavor_tags,
		"off_flavor_message": off_flavor_message,
		"failure_messages": failure_messages,
		"off_flavor_intensities": off_flavor_intensities,
	}


# ---------------------------------------------------------------------------
# QA Checkpoints
# ---------------------------------------------------------------------------

## Pre-boil gravity estimate from mash temperature.
func calc_pre_boil_gravity(mash_temp_c: float) -> Dictionary:
	var og: float = 1.050 + (mash_temp_c - 65.0) * 0.002
	var assessment: String = "normal"
	if og < 1.045:
		assessment = "low"
	elif og > 1.060:
		assessment = "high"
	return {"og": snapped(og, 0.001), "assessment": assessment}


## Boil vigor assessment from boil duration.
func calc_boil_vigor(boil_min: float) -> Dictionary:
	var vigor: String = "good"
	var assessment: String = "normal"
	if boil_min < 45.0:
		vigor = "weak"
		assessment = "low"
	elif boil_min >= 75.0:
		vigor = "strong"
		assessment = "high"
	var dms_note: String = "DMS driven off" if boil_min >= 60.0 else "DMS risk — consider longer boil"
	return {"vigor": vigor, "assessment": assessment, "dms_note": dms_note}


## Final gravity estimate from mash temp and yeast attenuation.
## yeast_attenuation: fraction in range 0.0-1.0 (e.g., 0.75 for 75%)
func calc_final_gravity(mash_temp_c: float, yeast_attenuation: float) -> Dictionary:
	var og: float = 1.050 + (mash_temp_c - 65.0) * 0.002
	var fg: float = og - (og - 1.0) * yeast_attenuation
	var attenuation_pct: float = ((og - fg) / (og - 1.0)) * 100.0
	var assessment: String = "normal"
	if attenuation_pct < 65.0:
		assessment = "low"
	elif attenuation_pct > 85.0:
		assessment = "high"
	return {"fg": snapped(fg, 0.001), "attenuation_pct": snapped(attenuation_pct, 1.0), "assessment": assessment}
