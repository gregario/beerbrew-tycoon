extends GutTest

func before_each():
	GameState.reset()
	ResearchManager.reset()

# --- Catalog tests ---

func test_all_new_nodes_exist_in_catalog():
	var new_ids := [
		"water_basics", "mineral_adjustment", "ph_management", "advanced_water",
		"biotransformation", "hop_blending",
		"yeast_health", "temp_profiling", "diacetyl_rest",
	]
	for node_id in new_ids:
		assert_not_null(ResearchManager.get_node_by_id(node_id), "Node '%s' should exist in catalog" % node_id)

func test_total_catalog_size_is_31():
	assert_eq(ResearchManager.get_catalog_size(), 31)

# --- Water Science branch prereqs ---

func test_water_basics_has_prereq_mash_basics():
	var node := ResearchManager.get_node_by_id("water_basics")
	assert_has(node.prerequisites, "mash_basics")

func test_mineral_adjustment_has_prereq_water_basics():
	var node := ResearchManager.get_node_by_id("mineral_adjustment")
	assert_has(node.prerequisites, "water_basics")

func test_ph_management_has_prereq_mineral_adjustment():
	var node := ResearchManager.get_node_by_id("ph_management")
	assert_has(node.prerequisites, "mineral_adjustment")

func test_advanced_water_has_prereq_ph_management():
	var node := ResearchManager.get_node_by_id("advanced_water")
	assert_has(node.prerequisites, "ph_management")

# --- Hop Mastery branch prereqs ---

func test_biotransformation_has_prereq_dry_hopping():
	var node := ResearchManager.get_node_by_id("biotransformation")
	assert_has(node.prerequisites, "dry_hopping")

func test_hop_blending_has_prereq_biotransformation():
	var node := ResearchManager.get_node_by_id("hop_blending")
	assert_has(node.prerequisites, "biotransformation")

# --- Fermentation Science branch prereqs ---

func test_yeast_health_has_prereq_mash_basics():
	var node := ResearchManager.get_node_by_id("yeast_health")
	assert_has(node.prerequisites, "mash_basics")

func test_diacetyl_rest_has_prereq_temp_profiling():
	var node := ResearchManager.get_node_by_id("diacetyl_rest")
	assert_has(node.prerequisites, "temp_profiling")

# --- Unlock chain tests ---

func test_can_unlock_water_basics_after_mash_basics():
	# mash_basics is a root node, auto-unlocked
	ResearchManager.add_rp(15)
	assert_true(ResearchManager.can_unlock("water_basics"))

func test_cannot_unlock_mineral_adjustment_without_water_basics():
	ResearchManager.add_rp(100)
	assert_false(ResearchManager.can_unlock("mineral_adjustment"))

func test_full_water_chain_unlock():
	ResearchManager.add_rp(200)
	assert_true(ResearchManager.unlock("water_basics"))
	assert_true(ResearchManager.unlock("mineral_adjustment"))
	assert_true(ResearchManager.unlock("ph_management"))
	assert_true(ResearchManager.unlock("advanced_water"))
	assert_true(ResearchManager.is_unlocked("advanced_water"))

func test_hop_mastery_chain_unlock():
	# hop_timing is root, dry_hopping prereqs hop_timing
	ResearchManager.add_rp(200)
	ResearchManager.unlock("dry_hopping")
	assert_true(ResearchManager.unlock("biotransformation"))
	assert_true(ResearchManager.unlock("hop_blending"))
	assert_true(ResearchManager.is_unlocked("hop_blending"))

func test_fermentation_science_chain_unlock():
	ResearchManager.add_rp(200)
	assert_true(ResearchManager.unlock("yeast_health"))
	assert_true(ResearchManager.unlock("temp_profiling"))
	assert_true(ResearchManager.unlock("diacetyl_rest"))
	assert_true(ResearchManager.is_unlocked("diacetyl_rest"))

# --- Bonus application tests ---

func test_water_basics_applies_water_awareness_bonus():
	ResearchManager.add_rp(15)
	ResearchManager.unlock("water_basics")
	assert_almost_eq(ResearchManager.bonuses.get("water_awareness", 0.0), 0.1, 0.001)

func test_biotransformation_applies_bonus():
	ResearchManager.add_rp(200)
	ResearchManager.unlock("dry_hopping")
	ResearchManager.unlock("biotransformation")
	assert_almost_eq(ResearchManager.bonuses.get("biotransformation", 0.0), 0.15, 0.001)

func test_diacetyl_rest_applies_bonus():
	ResearchManager.add_rp(200)
	ResearchManager.unlock("yeast_health")
	ResearchManager.unlock("temp_profiling")
	ResearchManager.unlock("diacetyl_rest")
	assert_almost_eq(ResearchManager.bonuses.get("diacetyl_rest", 0.0), 0.2, 0.001)

func test_advanced_water_applies_water_mastery_bonus():
	ResearchManager.add_rp(200)
	ResearchManager.unlock("water_basics")
	ResearchManager.unlock("mineral_adjustment")
	ResearchManager.unlock("ph_management")
	ResearchManager.unlock("advanced_water")
	assert_almost_eq(ResearchManager.bonuses.get("water_mastery", 0.0), 0.2, 0.001)

# --- Category tests ---

func test_all_new_nodes_are_techniques_category():
	var new_ids := [
		"water_basics", "mineral_adjustment", "ph_management", "advanced_water",
		"biotransformation", "hop_blending",
		"yeast_health", "temp_profiling", "diacetyl_rest",
	]
	for node_id in new_ids:
		var node := ResearchManager.get_node_by_id(node_id)
		assert_eq(node.category, ResearchNode.Category.TECHNIQUES, "Node '%s' should be TECHNIQUES category" % node_id)
