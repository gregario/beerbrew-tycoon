extends Node

## BrewingScience — pure brewing science calculations.
## All methods are stateless. Converts physical slider values (temp, time)
## into quality-relevant outputs (fermentability, hop utilization, yeast accuracy).


## Calculates fermentability from mash temperature.
## 62°C -> 0.82 (dry/crisp), 69°C -> 0.57 (full/sweet).
func calc_fermentability(mash_temp_c: float) -> float:
	return 0.82 - ((mash_temp_c - 62.0) / 7.0 * 0.25)


## Calculates hop bittering and aroma from boil duration and alpha acid.
func calc_hop_utilization(boil_min: float, alpha_acid_pct: float) -> Dictionary:
	var utilization: float = boil_min / 90.0
	var bittering: float = alpha_acid_pct * utilization
	var aroma: float = alpha_acid_pct * (1.0 - utilization)
	# Apply research aroma bonus
	var aroma_bonus: float = ResearchManager.bonuses.get("aroma_bonus", 0.0)
	aroma *= (1.0 + aroma_bonus)
	return {"bittering": bittering, "aroma": aroma}


## Calculates quality bonus and off-flavors based on fermentation temp vs yeast range.
func calc_yeast_accuracy(ferment_temp_c: float, yeast: Yeast) -> Dictionary:
	var off_flavors: Array[String] = []
	var quality_bonus: float = 1.0

	if ferment_temp_c >= yeast.ideal_temp_min_c and ferment_temp_c <= yeast.ideal_temp_max_c:
		quality_bonus = 1.0
	else:
		var distance: float = 0.0
		if ferment_temp_c > yeast.ideal_temp_max_c:
			distance = ferment_temp_c - yeast.ideal_temp_max_c
		else:
			distance = yeast.ideal_temp_min_c - ferment_temp_c

		if distance <= 2.0:
			quality_bonus = 0.85
		else:
			quality_bonus = 0.6
			if ferment_temp_c > yeast.ideal_temp_max_c:
				if distance >= 5.0:
					off_flavors.append("fusel_alcohols")
				else:
					off_flavors.append("fruity_esters")
			else:
				off_flavors.append("stalled_ferment")

	return {"quality_bonus": quality_bonus, "off_flavors": off_flavors}


## Temperature drift based on equipment quality (0-100).
func calc_temp_drift(temp_control_quality: int) -> float:
	var max_drift: float = float(100 - temp_control_quality) / 25.0
	if max_drift <= 0.0:
		return 0.0
	return randf_range(-max_drift, max_drift)


## Applies +/-5% multiplicative noise. Seeded for reproducibility.
func apply_noise(value: float, brew_seed: int) -> float:
	var rng := RandomNumberGenerator.new()
	rng.seed = brew_seed
	var noise_range := 0.05
	if is_instance_valid(ResearchManager):
		var reduction: float = ResearchManager.bonuses.get("noise_reduction", 0.0)
		noise_range *= (1.0 - reduction)
	return value * rng.randf_range(1.0 - noise_range, 1.0 + noise_range)


## Scores mash temp against style's ideal range. Returns 0.0-1.0.
## ±2°C tolerance zone around ideal range scores 1.0. Penalty ramps beyond.
func calc_mash_score(mash_temp_c: float, style: BeerStyle) -> float:
	var zone_min: float = style.ideal_mash_temp_min - 2.0
	var zone_max: float = style.ideal_mash_temp_max + 2.0
	if mash_temp_c >= zone_min and mash_temp_c <= zone_max:
		return 1.0
	var distance: float = 0.0
	if mash_temp_c < zone_min:
		distance = zone_min - mash_temp_c
	else:
		distance = mash_temp_c - zone_max
	return maxf(0.0, 1.0 - (distance / 5.0))


## Scores boil duration against style's ideal range. Returns 0.0-1.0.
## Non-pilsner malts get a 45-90 min flat zone. High DMS malts use style range.
func calc_boil_score(boil_min: float, style: BeerStyle, has_high_dms_malt: bool = false) -> float:
	var zone_min: float
	var zone_max: float
	if has_high_dms_malt:
		# Pilsner malt needs longer boils — use style's ideal range
		zone_min = style.ideal_boil_min
		zone_max = style.ideal_boil_max
	else:
		# Non-pilsner: 45-90 min all score equally
		zone_min = 45.0
		zone_max = 90.0
	if boil_min >= zone_min and boil_min <= zone_max:
		return 1.0
	var distance: float = 0.0
	if boil_min < zone_min:
		distance = zone_min - boil_min
	else:
		distance = boil_min - zone_max
	return maxf(0.0, 1.0 - (distance / 60.0))


## Determines which flavor attributes are present in this brew's output.
func detect_brew_attributes(
	mash_temp_c: float,
	boil_min: float,
	ferment_temp_c: float,
	yeast: Yeast,
	hops: Array
) -> Array[String]:
	var attributes: Array[String] = []

	# Body from mash temp
	if mash_temp_c <= 63.0:
		attributes.append("dry_body")
	elif mash_temp_c <= 64.0:
		attributes.append("crisp_body")
	elif mash_temp_c <= 66.0:
		attributes.append("medium_body")
	elif mash_temp_c <= 68.0:
		attributes.append("full_body")
	else:
		attributes.append("sweet_body")

	# Bitterness from boil
	if boil_min <= 40.0:
		attributes.append("low_bitter")
	elif boil_min <= 70.0:
		attributes.append("balanced_bitter")
	else:
		attributes.append("assertive_bitter")

	# Aroma from boil + hop variety
	if boil_min <= 50.0:
		for hop in hops:
			if hop is Hop:
				var family: String = hop.variety_family if hop.variety_family != "" else "neutral"
				if family == "american":
					attributes.append("citrus_aroma")
				elif family == "english":
					attributes.append("earthy_aroma")
				elif family == "noble":
					attributes.append("floral_aroma")
				elif family == "pacific":
					attributes.append("piney_aroma")
				else:
					attributes.append("spicy_aroma")

	# Fermentation from yeast accuracy
	var yeast_result: Dictionary = calc_yeast_accuracy(ferment_temp_c, yeast)
	if yeast_result["off_flavors"].size() == 0:
		attributes.append("clean_ferment")
	for off_flavor in yeast_result["off_flavors"]:
		attributes.append(off_flavor)

	return attributes
