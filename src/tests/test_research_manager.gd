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

func test_save_state_roundtrip():
	ResearchManager.add_rp(50)
	ResearchManager.unlock("advanced_mashing")
	ResearchManager.unlock("specialty_malts")
	var saved := ResearchManager.save_state()
	ResearchManager.reset()
	assert_false(ResearchManager.is_unlocked("advanced_mashing"))
	ResearchManager.load_state(saved)
	assert_true(ResearchManager.is_unlocked("advanced_mashing"))
	assert_true(ResearchManager.is_unlocked("specialty_malts"))
	assert_eq(ResearchManager.research_points, 25)  # 50 - 15 - 10

func test_save_state_preserves_bonuses():
	ResearchManager.add_rp(15)
	ResearchManager.unlock("advanced_mashing")
	var saved := ResearchManager.save_state()
	ResearchManager.reset()
	ResearchManager.load_state(saved)
	assert_almost_eq(ResearchManager.bonuses.get("mash_score_bonus", 0.0), 0.05, 0.001)

func test_save_state_preserves_equipment_tier():
	ResearchManager.add_rp(20)
	ResearchManager.unlock("semi_pro_equipment")
	var saved := ResearchManager.save_state()
	ResearchManager.reset()
	assert_eq(ResearchManager.unlocked_equipment_tier, 2)
	ResearchManager.load_state(saved)
	assert_eq(ResearchManager.unlocked_equipment_tier, 3)

func test_unlock_style_makes_style_available():
	var lager := load("res://data/styles/lager.tres") as BeerStyle
	assert_false(lager.unlocked, "Lager should start locked")
	ResearchManager.add_rp(15)
	ResearchManager.unlock("lager_brewing")
	assert_true(lager.unlocked, "Lager should be unlocked after research")

func test_reset_relocks_styles():
	var lager := load("res://data/styles/lager.tres") as BeerStyle
	assert_false(lager.unlocked, "Lager should start locked")
	ResearchManager.add_rp(15)
	ResearchManager.unlock("lager_brewing")
	assert_true(lager.unlocked, "Lager should be unlocked after research")
	ResearchManager.reset()
	assert_false(lager.unlocked, "Lager should be re-locked after reset")

func test_rp_formula_low_quality():
	var rp := 2 + int(30.0 / 20.0)
	assert_eq(rp, 3)

func test_rp_formula_high_quality():
	var rp := 2 + int(90.0 / 20.0)
	assert_eq(rp, 6)

func test_rp_formula_perfect_quality():
	var rp := 2 + int(100.0 / 20.0)
	assert_eq(rp, 7)

func test_equipment_tier_default_is_2():
	assert_eq(ResearchManager.unlocked_equipment_tier, 2)

func test_unlock_semi_pro_sets_tier_3():
	ResearchManager.add_rp(20)
	ResearchManager.unlock("semi_pro_equipment")
	assert_eq(ResearchManager.unlocked_equipment_tier, 3)

func test_unlock_pro_sets_tier_4():
	ResearchManager.add_rp(55)
	ResearchManager.unlock("semi_pro_equipment")
	ResearchManager.unlock("pro_equipment")
	assert_eq(ResearchManager.unlocked_equipment_tier, 4)

func test_advanced_mashing_adds_mash_score_bonus():
	ResearchManager.add_rp(15)
	ResearchManager.unlock("advanced_mashing")
	assert_almost_eq(ResearchManager.bonuses.get("mash_score_bonus", 0.0), 0.05, 0.001)

func test_decoction_adds_efficiency_bonus():
	ResearchManager.add_rp(45)
	ResearchManager.unlock("advanced_mashing")
	ResearchManager.unlock("decoction_technique")
	assert_almost_eq(ResearchManager.bonuses.get("efficiency_bonus", 0.0), 0.10, 0.001)

func test_dry_hopping_adds_aroma_bonus():
	ResearchManager.add_rp(20)
	ResearchManager.unlock("dry_hopping")
	assert_almost_eq(ResearchManager.bonuses.get("aroma_bonus", 0.0), 0.15, 0.001)

func test_water_chemistry_adds_noise_reduction():
	ResearchManager.add_rp(40)
	ResearchManager.unlock("advanced_mashing")
	ResearchManager.unlock("water_chemistry")
	assert_almost_eq(ResearchManager.bonuses.get("noise_reduction", 0.0), 0.5, 0.001)

# --- Task 11: Ingredient Unlock Tests ---

func test_unlock_specialty_malts():
	var crystal := load("res://data/ingredients/malts/crystal_60.tres")
	assert_false(crystal.unlocked, "Crystal 60 should start locked")
	ResearchManager.add_rp(10)
	ResearchManager.unlock("specialty_malts")
	assert_true(crystal.unlocked, "Crystal 60 should be unlocked after research")

func test_unlock_american_hops():
	var cascade := load("res://data/ingredients/hops/cascade.tres")
	assert_false(cascade.unlocked, "Cascade should start locked")
	ResearchManager.add_rp(15)
	ResearchManager.unlock("american_hops")
	assert_true(cascade.unlocked, "Cascade should be unlocked after research")

func test_unlock_adjuncts():
	var lactose := load("res://data/ingredients/adjuncts/lactose.tres")
	assert_false(lactose.unlocked, "Lactose should start locked")
	ResearchManager.add_rp(15)
	ResearchManager.unlock("adjunct_brewing")
	assert_true(lactose.unlocked, "Lactose should be unlocked after research")

func test_cross_category_prereq():
	# Dark Styles requires Specialty Malts (Ingredients category)
	ResearchManager.add_rp(100)
	assert_false(ResearchManager.can_unlock("dark_styles"), "Should not unlock without Specialty Malts")
	ResearchManager.unlock("specialty_malts")
	assert_true(ResearchManager.can_unlock("dark_styles"), "Should be unlockable after Specialty Malts")

# --- Task 12: Final Integration Test ---

func test_full_research_flow():
	# Start with no RP
	assert_eq(ResearchManager.research_points, 0)
	assert_eq(ResearchManager.unlocked_nodes.size(), 4)  # 4 root nodes

	# Pre-load resources so cache is primed (same instance used by ResearchManager)
	var crystal := load("res://data/ingredients/malts/crystal_60.tres")
	var stout := load("res://data/styles/stout.tres") as BeerStyle

	# Simulate a few brews worth of RP
	ResearchManager.add_rp(50)

	# Unlock a chain: Specialty Malts (10) → Dark Styles (20) = 30 RP spent
	ResearchManager.unlock("specialty_malts")
	assert_eq(ResearchManager.research_points, 40)
	ResearchManager.unlock("dark_styles")
	assert_eq(ResearchManager.research_points, 20)

	# Verify effects applied
	assert_true(crystal.unlocked)
	assert_true(stout.unlocked)

	# Save, reset, load
	var saved := ResearchManager.save_state()
	ResearchManager.reset()
	assert_false(ResearchManager.is_unlocked("specialty_malts"))
	ResearchManager.load_state(saved)
	assert_true(ResearchManager.is_unlocked("specialty_malts"))
	assert_true(ResearchManager.is_unlocked("dark_styles"))
	assert_eq(ResearchManager.research_points, 20)
