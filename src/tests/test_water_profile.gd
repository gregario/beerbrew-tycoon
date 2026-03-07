extends GutTest

func test_water_profile_properties():
	var wp := WaterProfile.new()
	wp.profile_id = "hoppy"
	wp.display_name = "Hoppy Water"
	wp.mineral_description = "High sulfate, low chloride — crisp hop bitterness"
	wp.style_affinities = {"pale_ale": 0.95, "stout": 0.3}
	assert_eq(wp.profile_id, "hoppy")
	assert_eq(wp.display_name, "Hoppy Water")
	assert_eq(wp.mineral_description, "High sulfate, low chloride — crisp hop bitterness")
	assert_eq(wp.style_affinities["pale_ale"], 0.95)
	assert_eq(wp.style_affinities["stout"], 0.3)

func test_water_profile_default_values():
	var wp := WaterProfile.new()
	assert_eq(wp.profile_id, "")
	assert_eq(wp.display_name, "")
	assert_eq(wp.mineral_description, "")
	assert_eq(wp.style_affinities.size(), 0)

func test_water_profile_get_affinity_with_default():
	var wp := WaterProfile.new()
	wp.style_affinities = {"pale_ale": 0.95}
	assert_eq(wp.get_affinity("pale_ale"), 0.95)
	assert_eq(wp.get_affinity("unknown_style"), 0.6, "Missing style should default to 0.6 (tap water neutral)")
