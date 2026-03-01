extends GutTest

func before_each():
	GameState.reset()
	ResearchManager.reset()

func test_catalog_loads_all_nodes():
	assert_eq(ResearchManager.get_catalog_size(), 20)

func test_root_nodes_start_unlocked():
	assert_true(ResearchManager.is_unlocked("mash_basics"))
	assert_true(ResearchManager.is_unlocked("hop_timing"))
	assert_true(ResearchManager.is_unlocked("homebrew_upgrades"))
	assert_true(ResearchManager.is_unlocked("ale_fundamentals"))

func test_non_root_nodes_start_locked():
	assert_false(ResearchManager.is_unlocked("advanced_mashing"))
	assert_false(ResearchManager.is_unlocked("specialty_malts"))
	assert_false(ResearchManager.is_unlocked("semi_pro_equipment"))
	assert_false(ResearchManager.is_unlocked("lager_brewing"))

func test_initial_rp_is_zero():
	assert_eq(ResearchManager.research_points, 0)

func test_add_rp():
	ResearchManager.add_rp(10)
	assert_eq(ResearchManager.research_points, 10)

func test_can_unlock_with_prereqs_met_and_enough_rp():
	ResearchManager.add_rp(15)
	assert_true(ResearchManager.can_unlock("advanced_mashing"))

func test_cannot_unlock_without_enough_rp():
	ResearchManager.add_rp(5)
	assert_false(ResearchManager.can_unlock("advanced_mashing"))

func test_cannot_unlock_without_prereqs():
	ResearchManager.add_rp(100)
	assert_false(ResearchManager.can_unlock("decoction_technique"))

func test_cannot_unlock_already_unlocked():
	assert_false(ResearchManager.can_unlock("mash_basics"))

func test_unlock_deducts_rp():
	ResearchManager.add_rp(20)
	ResearchManager.unlock("advanced_mashing")
	assert_eq(ResearchManager.research_points, 5)

func test_unlock_adds_to_unlocked_nodes():
	ResearchManager.add_rp(15)
	ResearchManager.unlock("advanced_mashing")
	assert_true(ResearchManager.is_unlocked("advanced_mashing"))

func test_unlock_emits_signal():
	watch_signals(ResearchManager)
	ResearchManager.add_rp(15)
	ResearchManager.unlock("advanced_mashing")
	assert_signal_emitted(ResearchManager, "research_unlocked")

func test_get_available_nodes():
	ResearchManager.add_rp(100)
	var available := ResearchManager.get_available_nodes()
	var available_ids := []
	for node in available:
		available_ids.append(node.node_id)
	assert_has(available_ids, "advanced_mashing")
	assert_has(available_ids, "specialty_malts")
	assert_does_not_have(available_ids, "mash_basics")
	assert_does_not_have(available_ids, "decoction_technique")

func test_reset_clears_state():
	ResearchManager.add_rp(50)
	ResearchManager.unlock("advanced_mashing")
	ResearchManager.reset()
	assert_eq(ResearchManager.research_points, 0)
	assert_false(ResearchManager.is_unlocked("advanced_mashing"))
	assert_true(ResearchManager.is_unlocked("mash_basics"))
