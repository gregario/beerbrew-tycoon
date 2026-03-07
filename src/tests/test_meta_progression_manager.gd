extends GutTest

var manager: Node

func before_each() -> void:
	manager = preload("res://autoloads/MetaProgressionManager.gd").new()
	add_child_autofree(manager)

# --- Core state ---

func test_initial_state_has_zero_points() -> void:
	assert_eq(manager.available_points, 0)
	assert_eq(manager.lifetime_points, 0)

func test_initial_state_has_empty_unlocks() -> void:
	assert_eq(manager.unlocked_styles.size(), 0)
	assert_eq(manager.unlocked_blueprints.size(), 0)
	assert_eq(manager.unlocked_ingredients.size(), 0)
	assert_eq(manager.unlocked_perks.size(), 0)

func test_initial_state_has_no_achievements() -> void:
	var achievements: Dictionary = manager.get_achievements()
	for key in achievements:
		assert_false(achievements[key])

func test_initial_run_history_empty() -> void:
	assert_eq(manager.run_history.size(), 0)
	assert_eq(manager.total_runs, 0)

# --- Add points ---

func test_add_points_increases_available_and_lifetime() -> void:
	manager.add_points(10)
	assert_eq(manager.available_points, 10)
	assert_eq(manager.lifetime_points, 10)

func test_add_points_accumulates() -> void:
	manager.add_points(5)
	manager.add_points(7)
	assert_eq(manager.available_points, 12)
	assert_eq(manager.lifetime_points, 12)

# --- Spend points ---

func test_spend_points_reduces_available() -> void:
	manager.add_points(10)
	var success: bool = manager.spend_points(4)
	assert_true(success)
	assert_eq(manager.available_points, 6)
	assert_eq(manager.lifetime_points, 10)

func test_spend_points_fails_if_insufficient() -> void:
	manager.add_points(3)
	var success: bool = manager.spend_points(5)
	assert_false(success)
	assert_eq(manager.available_points, 3)

# --- Unlock methods ---

func test_unlock_style() -> void:
	manager.add_points(10)
	var success: bool = manager.unlock_style("lager", 5)
	assert_true(success)
	assert_true(manager.is_unlocked("styles", "lager"))
	assert_eq(manager.available_points, 5)

func test_unlock_style_fails_if_already_unlocked() -> void:
	manager.add_points(20)
	manager.unlock_style("lager", 5)
	var success: bool = manager.unlock_style("lager", 5)
	assert_false(success)
	assert_eq(manager.available_points, 15)

func test_unlock_blueprint() -> void:
	manager.add_points(10)
	assert_true(manager.unlock_blueprint("mash_tun", 5))
	assert_true(manager.is_unlocked("blueprints", "mash_tun"))

func test_unlock_ingredient() -> void:
	manager.add_points(10)
	assert_true(manager.unlock_ingredient("citra", 6))
	assert_true(manager.is_unlocked("ingredients", "citra"))

func test_unlock_perk() -> void:
	manager.add_points(10)
	assert_true(manager.unlock_perk("nest_egg", 8))
	assert_true(manager.is_unlocked("perks", "nest_egg"))

# --- Perk/modifier selection ---

func test_set_active_perks() -> void:
	manager.set_active_perks(["nest_egg", "quick_study"] as Array[String])
	assert_true(manager.has_active_perk("nest_egg"))
	assert_true(manager.has_active_perk("quick_study"))
	assert_false(manager.has_active_perk("landlords_friend"))

func test_set_active_perks_caps_at_three() -> void:
	manager.set_active_perks(["a", "b", "c", "d"] as Array[String])
	assert_eq(manager.active_perks.size(), 3)

func test_set_active_modifiers() -> void:
	manager.set_active_modifiers(["tough_market"] as Array[String])
	assert_true(manager.has_active_modifier("tough_market"))

func test_set_active_modifiers_caps_at_two() -> void:
	manager.set_active_modifiers(["a", "b", "c"] as Array[String])
	assert_eq(manager.active_modifiers.size(), 2)

func test_has_challenge_modifier() -> void:
	manager.set_active_modifiers(["tough_market"] as Array[String])
	assert_true(manager.has_challenge_modifier())

func test_no_challenge_modifier_with_bonus_only() -> void:
	manager.set_active_modifiers(["master_brewer"] as Array[String])
	assert_false(manager.has_challenge_modifier())

# --- Run history ---

func test_record_run() -> void:
	manager.record_run({"turns": 10, "won": true})
	assert_eq(manager.total_runs, 1)
	assert_eq(manager.run_history.size(), 1)

func test_run_history_caps_at_ten() -> void:
	for i in range(12):
		manager.record_run({"turns": i})
	assert_eq(manager.run_history.size(), 10)
	assert_eq(manager.total_runs, 12)

# --- Save/Load ---

func test_save_returns_dict_with_all_keys() -> void:
	manager.add_points(15)
	var data: Dictionary = manager.save_state()
	assert_true(data.has("available_points"))
	assert_true(data.has("lifetime_points"))
	assert_true(data.has("unlocked_styles"))
	assert_true(data.has("achievements"))
	assert_true(data.has("run_history"))
	assert_true(data.has("active_perks"))
	assert_true(data.has("active_modifiers"))

func test_load_restores_state() -> void:
	manager.add_points(20)
	manager.spend_points(5)
	manager.unlock_style("lager", 0)
	manager.set_active_perks(["nest_egg"] as Array[String])
	var data: Dictionary = manager.save_state()
	var manager2: Node = preload("res://autoloads/MetaProgressionManager.gd").new()
	add_child_autofree(manager2)
	manager2.load_state(data)
	assert_eq(manager2.available_points, 15)
	assert_eq(manager2.lifetime_points, 20)
	assert_true(manager2.is_unlocked("styles", "lager"))
	assert_true(manager2.has_active_perk("nest_egg"))

func test_reset_meta_clears_everything() -> void:
	manager.add_points(10)
	manager.unlock_style("lager", 5)
	manager.record_run({"turns": 10})
	manager.set_active_perks(["nest_egg"] as Array[String])
	manager.reset_meta()
	assert_eq(manager.available_points, 0)
	assert_eq(manager.lifetime_points, 0)
	assert_eq(manager.total_runs, 0)
	assert_eq(manager.unlocked_styles.size(), 0)
	assert_eq(manager.run_history.size(), 0)
	assert_eq(manager.active_perks.size(), 0)

# --- Task 2: Run point calculation ---

func test_calculate_points_zero_for_empty_run() -> void:
	var metrics: Dictionary = {"turns": 0, "revenue": 0.0, "best_quality": 0.0, "medals": 0, "won": false}
	assert_eq(manager.calculate_run_points(metrics), 0)

func test_calculate_points_turns_component() -> void:
	var metrics: Dictionary = {"turns": 12, "revenue": 0.0, "best_quality": 0.0, "medals": 0, "won": false}
	assert_eq(manager.calculate_run_points(metrics), 2)

func test_calculate_points_revenue_component() -> void:
	var metrics: Dictionary = {"turns": 0, "revenue": 8420.0, "best_quality": 0.0, "medals": 0, "won": false}
	assert_eq(manager.calculate_run_points(metrics), 4)

func test_calculate_points_quality_component() -> void:
	var metrics: Dictionary = {"turns": 0, "revenue": 0.0, "best_quality": 87.0, "medals": 0, "won": false}
	assert_eq(manager.calculate_run_points(metrics), 4)

func test_calculate_points_medals_component() -> void:
	var metrics: Dictionary = {"turns": 0, "revenue": 0.0, "best_quality": 0.0, "medals": 3, "won": false}
	assert_eq(manager.calculate_run_points(metrics), 3)

func test_calculate_points_win_bonus() -> void:
	var metrics: Dictionary = {"turns": 0, "revenue": 0.0, "best_quality": 0.0, "medals": 0, "won": true}
	assert_eq(manager.calculate_run_points(metrics), 5)

func test_calculate_points_full_run() -> void:
	var metrics: Dictionary = {"turns": 12, "revenue": 8420.0, "best_quality": 87.0, "medals": 2, "won": true}
	assert_eq(manager.calculate_run_points(metrics), 17)

func test_calculate_points_capped_at_25_base() -> void:
	var metrics: Dictionary = {"turns": 30, "revenue": 50000.0, "best_quality": 100.0, "medals": 10, "won": true}
	assert_eq(manager.calculate_run_points(metrics), 25)

func test_calculate_points_challenge_multiplier() -> void:
	var metrics: Dictionary = {"turns": 12, "revenue": 8420.0, "best_quality": 87.0, "medals": 2, "won": true}
	manager.set_active_modifiers(["tough_market"] as Array[String])
	assert_eq(manager.calculate_run_points(metrics), 25)

func test_end_run_adds_points_and_records() -> void:
	var metrics: Dictionary = {"turns": 10, "revenue": 4000.0, "best_quality": 60.0, "medals": 1, "won": false}
	var points: int = manager.end_run(metrics)
	assert_gt(points, 0)
	assert_eq(manager.available_points, points)
	assert_eq(manager.total_runs, 1)
	assert_eq(manager.run_history.size(), 1)

# --- Task 3: Achievement system ---

func test_achievement_modifier_map_exists() -> void:
	var map: Dictionary = manager.get_achievement_modifier_map()
	assert_eq(map.size(), 6)
	assert_eq(map["first_victory"], "tough_market")
	assert_eq(map["perfect_brew"], "master_brewer")

func test_modifier_locked_until_achievement() -> void:
	assert_false(manager.is_modifier_unlocked("tough_market"))
	manager.complete_achievement("first_victory")
	assert_true(manager.is_modifier_unlocked("tough_market"))

func test_update_progress_tracks_best_quality() -> void:
	manager.update_achievement_progress({"best_quality": 80.0, "turns": 10, "equipment_spend": 2000, "channels_unlocked": 2, "unique_ingredients": 15, "won": false})
	assert_eq(manager.achievement_progress["best_quality"], 80.0)
	manager.update_achievement_progress({"best_quality": 60.0, "turns": 5, "equipment_spend": 3000, "channels_unlocked": 1, "unique_ingredients": 20, "won": false})
	assert_eq(manager.achievement_progress["best_quality"], 80.0)

func test_update_progress_tracks_best_turns() -> void:
	manager.update_achievement_progress({"best_quality": 0.0, "turns": 15, "equipment_spend": 0, "channels_unlocked": 0, "unique_ingredients": 30, "won": false})
	assert_eq(manager.achievement_progress["best_turns"], 15)

func test_check_achievements_completes_first_victory_on_win() -> void:
	manager.update_achievement_progress({"best_quality": 50.0, "turns": 10, "equipment_spend": 2000, "channels_unlocked": 1, "unique_ingredients": 20, "won": true})
	manager.check_achievements()
	assert_true(manager.is_achievement_completed("first_victory"))

func test_check_achievements_completes_perfect_brew() -> void:
	manager.update_achievement_progress({"best_quality": 96.0, "turns": 10, "equipment_spend": 2000, "channels_unlocked": 1, "unique_ingredients": 20, "won": false})
	manager.check_achievements()
	assert_true(manager.is_achievement_completed("perfect_brew"))

func test_check_achievements_completes_survivor() -> void:
	manager.update_achievement_progress({"best_quality": 50.0, "turns": 22, "equipment_spend": 2000, "channels_unlocked": 1, "unique_ingredients": 20, "won": false})
	manager.check_achievements()
	assert_true(manager.is_achievement_completed("survivor"))

func test_check_achievements_completes_budget_master() -> void:
	manager.update_achievement_progress({"best_quality": 50.0, "turns": 10, "equipment_spend": 800, "channels_unlocked": 1, "unique_ingredients": 20, "won": true})
	manager.check_achievements()
	assert_true(manager.is_achievement_completed("budget_master"))

func test_check_achievements_budget_master_requires_win() -> void:
	manager.update_achievement_progress({"best_quality": 50.0, "turns": 10, "equipment_spend": 500, "channels_unlocked": 1, "unique_ingredients": 20, "won": false})
	manager.check_achievements()
	assert_false(manager.is_achievement_completed("budget_master"))

func test_check_achievements_completes_diversified() -> void:
	manager.update_achievement_progress({"best_quality": 50.0, "turns": 10, "equipment_spend": 2000, "channels_unlocked": 4, "unique_ingredients": 20, "won": false})
	manager.check_achievements()
	assert_true(manager.is_achievement_completed("diversified"))

func test_check_achievements_completes_scarcity_brewer() -> void:
	manager.update_achievement_progress({"best_quality": 50.0, "turns": 10, "equipment_spend": 2000, "channels_unlocked": 1, "unique_ingredients": 8, "won": true})
	manager.check_achievements()
	assert_true(manager.is_achievement_completed("scarcity_brewer"))

func test_check_achievements_scarcity_requires_win() -> void:
	manager.update_achievement_progress({"best_quality": 50.0, "turns": 10, "equipment_spend": 2000, "channels_unlocked": 1, "unique_ingredients": 5, "won": false})
	manager.check_achievements()
	assert_false(manager.is_achievement_completed("scarcity_brewer"))

func test_end_run_updates_progress_and_checks_achievements() -> void:
	var metrics: Dictionary = {"turns": 25, "revenue": 10000.0, "best_quality": 96.0, "medals": 3, "won": true, "equipment_spend": 500, "channels_unlocked": 4, "unique_ingredients": 8}
	manager.end_run(metrics)
	assert_true(manager.is_achievement_completed("first_victory"))
	assert_true(manager.is_achievement_completed("perfect_brew"))
	assert_true(manager.is_achievement_completed("survivor"))
	assert_true(manager.is_achievement_completed("budget_master"))
	assert_true(manager.is_achievement_completed("diversified"))
	assert_true(manager.is_achievement_completed("scarcity_brewer"))

# --- Task 4: Unlock catalog ---

func test_get_catalog_has_four_categories() -> void:
	var catalog: Dictionary = manager.get_unlock_catalog()
	assert_true(catalog.has("styles"))
	assert_true(catalog.has("blueprints"))
	assert_true(catalog.has("ingredients"))
	assert_true(catalog.has("perks"))

func test_catalog_styles_has_entries() -> void:
	var styles: Array = manager.get_unlock_catalog()["styles"]
	assert_gt(styles.size(), 0)
	var first: Dictionary = styles[0]
	assert_true(first.has("id"))
	assert_true(first.has("name"))
	assert_true(first.has("cost"))

func test_catalog_perks_has_four_entries() -> void:
	var perks: Array = manager.get_unlock_catalog()["perks"]
	assert_eq(perks.size(), 4)

func test_purchase_style_from_catalog() -> void:
	manager.add_points(10)
	var catalog: Array = manager.get_unlock_catalog()["styles"]
	var first_id: String = catalog[0]["id"]
	var cost: int = catalog[0]["cost"]
	assert_true(manager.unlock_style(first_id, cost))
	assert_true(manager.is_unlocked("styles", first_id))

func test_has_blueprint_discount() -> void:
	manager.add_points(10)
	manager.unlock_blueprint("mash_tun", 5)
	assert_true(manager.has_blueprint_discount("mash_tun"))

func test_no_blueprint_discount_without_purchase() -> void:
	assert_false(manager.has_blueprint_discount("mash_tun"))
