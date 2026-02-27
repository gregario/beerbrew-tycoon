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
}


## Calculates infection probability from sanitation quality.
## Formula: max(0, (100 - sanitation_quality) / 200.0)
static func calc_infection_chance(sanitation_quality: int) -> float:
	return maxf(0.0, float(100 - sanitation_quality) / 200.0)


## Applies infection penalty to a quality score.
## Returns {penalized_score: float, infected: bool, message: String}
static func apply_infection_penalty(score: float) -> Dictionary:
	var multiplier: float = randf_range(0.4, 0.6)
	return {
		"penalized_score": score * multiplier,
		"infected": true,
		"message": "Bacteria contaminated your batch. Your beer tastes sour and unpleasant.",
	}


## Calculates off-flavor probability from temperature control quality.
## Same formula as infection: max(0, (100 - stat) / 200.0)
static func calc_off_flavor_chance(temp_control_quality: int) -> float:
	return maxf(0.0, float(100 - temp_control_quality) / 200.0)


## Applies off-flavor penalty to a quality score.
## Returns {penalized_score: float, off_flavor_tags: Array[String], message: String}
static func apply_off_flavor_penalty(score: float) -> Dictionary:
	var multiplier: float = randf_range(0.7, 0.85)
	var types: Array[String] = ["esters", "fusel_alcohols", "dms"]
	var tag: String = types[randi() % types.size()]
	var info: Dictionary = OFF_FLAVOR_INFO[tag]
	return {
		"penalized_score": score * multiplier,
		"off_flavor_tags": [tag] as Array[String],
		"message": "%s — %s" % [info["name"], info["description"]],
	}


## Roll for all failure modes and apply penalties to the score.
## Returns {final_score, infected, infection_message, off_flavor_tags, off_flavor_message, failure_messages}
static func roll_failures(base_score: float, sanitation_quality: int, temp_control_quality: int) -> Dictionary:
	var final_score: float = base_score
	var infected: bool = false
	var infection_message: String = ""
	var off_flavor_tags: Array[String] = []
	var off_flavor_message: String = ""
	var failure_messages: Array[String] = []

	# Roll infection
	var infection_chance: float = calc_infection_chance(sanitation_quality)
	if infection_chance > 0.0 and randf() < infection_chance:
		var infection_result: Dictionary = apply_infection_penalty(final_score)
		final_score = infection_result["penalized_score"]
		infected = true
		infection_message = infection_result["message"]
		failure_messages.append(infection_message)

	# Roll off-flavor
	var off_flavor_chance: float = calc_off_flavor_chance(temp_control_quality)
	if off_flavor_chance > 0.0 and randf() < off_flavor_chance:
		var off_flavor_result: Dictionary = apply_off_flavor_penalty(final_score)
		final_score = off_flavor_result["penalized_score"]
		off_flavor_tags = off_flavor_result["off_flavor_tags"]
		off_flavor_message = off_flavor_result["message"]
		failure_messages.append(off_flavor_message)

	return {
		"final_score": final_score,
		"infected": infected,
		"infection_message": infection_message,
		"off_flavor_tags": off_flavor_tags,
		"off_flavor_message": off_flavor_message,
		"failure_messages": failure_messages,
	}


# ---------------------------------------------------------------------------
# QA Checkpoints
# ---------------------------------------------------------------------------

## Pre-boil gravity estimate from mash temperature.
static func calc_pre_boil_gravity(mash_temp_c: float) -> Dictionary:
	var og: float = 1.050 + (mash_temp_c - 65.0) * 0.002
	var assessment: String = "normal"
	if og < 1.045:
		assessment = "low"
	elif og > 1.060:
		assessment = "high"
	return {"og": snapped(og, 0.001), "assessment": assessment}


## Boil vigor assessment from boil duration.
static func calc_boil_vigor(boil_min: float) -> Dictionary:
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
static func calc_final_gravity(mash_temp_c: float, yeast_attenuation: float) -> Dictionary:
	var og: float = 1.050 + (mash_temp_c - 65.0) * 0.002
	var fg: float = og - (og - 1.0) * yeast_attenuation
	var attenuation_pct: float = ((og - fg) / (og - 1.0)) * 100.0
	var assessment: String = "normal"
	if attenuation_pct < 65.0:
		assessment = "low"
	elif attenuation_pct > 85.0:
		assessment = "high"
	return {"fg": snapped(fg, 0.001), "attenuation_pct": snapped(attenuation_pct, 1.0), "assessment": assessment}
