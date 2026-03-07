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
