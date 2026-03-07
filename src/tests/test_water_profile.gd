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

func test_load_soft_water_profile():
	var wp = load("res://data/water/soft.tres") as WaterProfile
	assert_not_null(wp, "soft.tres should load as WaterProfile")
	assert_eq(wp.profile_id, "soft")
	assert_eq(wp.display_name, "Soft Water")
	assert_true(wp.style_affinities.has("lager"), "Soft water should have lager affinity")

func test_load_all_five_profiles():
	var ids := ["soft", "balanced", "malty", "hoppy", "juicy"]
	for id in ids:
		var wp = load("res://data/water/%s.tres" % id) as WaterProfile
		assert_not_null(wp, "%s.tres should load" % id)
		assert_eq(wp.profile_id, id)
		assert_gt(wp.style_affinities.size(), 0, "%s should have style affinities" % id)
