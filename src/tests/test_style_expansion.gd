extends GutTest

func test_ipa_loads():
	var s = load("res://data/styles/ipa.tres") as BeerStyle
	assert_not_null(s)
	assert_eq(s.style_id, "ipa")
	assert_eq(s.family, "ales")
	assert_eq(s.base_price, 280.0)
	assert_false(s.unlocked)
	assert_gt(s.water_affinity["hoppy"], 0.9)
	assert_gt(s.hop_schedule_expectations["dry_hop"], 0.2)

func test_porter_loads():
	var s = load("res://data/styles/porter.tres") as BeerStyle
	assert_not_null(s)
	assert_eq(s.style_id, "porter")
	assert_eq(s.family, "dark")
	assert_eq(s.base_price, 240.0)
	assert_false(s.unlocked)

func test_imperial_stout_loads():
	var s = load("res://data/styles/imperial_stout.tres") as BeerStyle
	assert_not_null(s)
	assert_eq(s.style_id, "imperial_stout")
	assert_eq(s.family, "dark")
	assert_eq(s.base_price, 400.0)
	assert_gt(s.water_affinity["malty"], 0.9)

func test_hefeweizen_loads():
	var s = load("res://data/styles/hefeweizen.tres") as BeerStyle
	assert_not_null(s)
	assert_eq(s.style_id, "hefeweizen")
	assert_eq(s.family, "wheat")
	assert_eq(s.base_price, 220.0)
	assert_true(s.acceptable_off_flavors.has("ester_banana"))
	assert_gt(s.acceptable_off_flavors["ester_banana"], 0.7)
	assert_eq(s.primary_lesson, "yeast_temp_interaction")

func test_czech_pilsner_loads():
	var s = load("res://data/styles/czech_pilsner.tres") as BeerStyle
	assert_not_null(s)
	assert_eq(s.style_id, "czech_pilsner")
	assert_eq(s.family, "lager")
	assert_eq(s.base_price, 260.0)
	assert_gt(s.water_affinity["soft"], 0.9)
	assert_eq(s.primary_lesson, "water_chemistry")

func test_helles_loads():
	var s = load("res://data/styles/helles.tres") as BeerStyle
	assert_not_null(s)
	assert_eq(s.style_id, "helles")
	assert_eq(s.family, "lager")
	assert_eq(s.base_price, 230.0)

func test_marzen_loads():
	var s = load("res://data/styles/marzen.tres") as BeerStyle
	assert_not_null(s)
	assert_eq(s.style_id, "marzen")
	assert_eq(s.family, "lager")
	assert_eq(s.base_price, 250.0)

func test_all_lager_family_locked():
	for id in ["czech_pilsner", "helles", "marzen"]:
		var s = load("res://data/styles/%s.tres" % id) as BeerStyle
		assert_false(s.unlocked, "%s should be locked by default" % id)

func test_saison_loads():
	var s = load("res://data/styles/saison.tres") as BeerStyle
	assert_not_null(s)
	assert_eq(s.style_id, "saison")
	assert_eq(s.family, "belgian")
	assert_eq(s.base_price, 300.0)
	assert_true(s.acceptable_off_flavors.has("phenol_pepper"))
	assert_eq(s.primary_lesson, "high_temp_fermentation")

func test_belgian_dubbel_loads():
	var s = load("res://data/styles/belgian_dubbel.tres") as BeerStyle
	assert_not_null(s)
	assert_eq(s.style_id, "belgian_dubbel")
	assert_eq(s.family, "belgian")
	assert_eq(s.base_price, 350.0)

func test_neipa_loads():
	var s = load("res://data/styles/neipa.tres") as BeerStyle
	assert_not_null(s)
	assert_eq(s.style_id, "neipa")
	assert_eq(s.family, "modern")
	assert_eq(s.base_price, 320.0)
	assert_gt(s.water_affinity["juicy"], 0.9)
	assert_gt(s.hop_schedule_expectations["dry_hop"], 0.3)

func test_all_nine_new_styles_exist():
	var ids := ["ipa", "porter", "imperial_stout", "hefeweizen", "czech_pilsner", "helles", "marzen", "saison", "belgian_dubbel", "neipa"]
	for id in ids:
		var s = load("res://data/styles/%s.tres" % id) as BeerStyle
		assert_not_null(s, "%s.tres should exist" % id)
		assert_ne(s.family, "", "%s should have a family" % id)
		assert_false(s.unlocked, "%s should be locked" % id)

func test_lager_research_unlocks_all_lagers():
	var node = load("res://data/research/styles/lager_brewing.tres") as ResearchNode
	var ids = node.unlock_effect.get("ids", [])
	assert_true("czech_pilsner" in ids, "lager_brewing should unlock czech_pilsner")
	assert_true("helles" in ids, "lager_brewing should unlock helles")
	assert_true("marzen" in ids, "lager_brewing should unlock marzen")

func test_dark_research_unlocks_porter_imperial():
	var node = load("res://data/research/styles/dark_styles.tres") as ResearchNode
	var ids = node.unlock_effect.get("ids", [])
	assert_true("porter" in ids, "dark_styles should unlock porter")
	assert_true("imperial_stout" in ids, "dark_styles should unlock imperial_stout")

func test_wheat_research_unlocks_hefeweizen():
	var node = load("res://data/research/styles/wheat_traditions.tres") as ResearchNode
	var ids = node.unlock_effect.get("ids", [])
	assert_true("hefeweizen" in ids, "wheat_traditions should unlock hefeweizen")

func test_belgian_research_unlocks_saison_dubbel():
	var node = load("res://data/research/styles/belgian_arts.tres") as ResearchNode
	var ids = node.unlock_effect.get("ids", [])
	assert_true("saison" in ids, "belgian_arts should unlock saison")
	assert_true("belgian_dubbel" in ids, "belgian_arts should unlock belgian_dubbel")

func test_modern_techniques_node_exists():
	var node = load("res://data/research/styles/modern_techniques.tres") as ResearchNode
	assert_not_null(node)
	assert_eq(node.node_id, "modern_techniques")
	var ids = node.unlock_effect.get("ids", [])
	assert_true("neipa" in ids)

func test_modern_techniques_in_catalog():
	var node = ResearchManager.get_node_by_id("modern_techniques")
	assert_not_null(node, "modern_techniques should be in ResearchManager catalog")

func test_all_standard_styles_loadable():
	var expected_ids := ["pale_ale", "ipa", "stout", "porter", "imperial_stout",
		"wheat_beer", "hefeweizen", "lager", "czech_pilsner", "helles",
		"marzen", "saison", "belgian_dubbel", "neipa"]
	for id in expected_ids:
		var s = load("res://data/styles/%s.tres" % id) as BeerStyle
		assert_not_null(s, "%s.tres should exist for StylePicker" % id)
