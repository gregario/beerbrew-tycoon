extends GutTest

## Integration tests for meta-progression persistence across runs.

func before_each() -> void:
	if is_instance_valid(MetaProgressionManager):
		MetaProgressionManager.reset_meta()
	GameState.reset()

# --- Cross-run persistence ---

func test_end_run_awards_points() -> void:
	var metrics: Dictionary = {
		"turns": 15, "revenue": 6000.0, "best_quality": 75.0,
		"medals": 1, "won": true,
		"equipment_spend": 1500, "channels_unlocked": 2,
		"unique_ingredients": 12,
	}
	var points: int = MetaProgressionManager.end_run(metrics)
	assert_gt(points, 0)
	assert_eq(MetaProgressionManager.available_points, points)
	assert_eq(MetaProgressionManager.total_runs, 1)

func test_points_persist_after_game_reset() -> void:
	MetaProgressionManager.add_points(20)
	GameState.reset()
	# Meta points should NOT be cleared by GameState.reset()
	assert_eq(MetaProgressionManager.available_points, 20)

func test_unlocks_persist_after_game_reset() -> void:
	MetaProgressionManager.add_points(10)
	MetaProgressionManager.unlock_style("lager", 5)
	GameState.reset()
	assert_true(MetaProgressionManager.is_unlocked("styles", "lager"))

func test_achievements_persist_after_game_reset() -> void:
	MetaProgressionManager.complete_achievement("first_victory")
	GameState.reset()
	assert_true(MetaProgressionManager.is_achievement_completed("first_victory"))

func test_meta_unlocked_style_available_in_new_run() -> void:
	MetaProgressionManager.unlocked_styles = ["lager"] as Array[String]
	GameState.reset()
	var lager: Resource = load("res://data/styles/lager.tres")
	assert_true(lager.unlocked)
	# Cleanup
	lager.unlocked = false

func test_save_load_roundtrip() -> void:
	MetaProgressionManager.add_points(30)
	MetaProgressionManager.unlock_style("stout", 8)
	MetaProgressionManager.complete_achievement("perfect_brew")
	MetaProgressionManager.set_active_perks(["nest_egg"] as Array[String])
	var saved: Dictionary = MetaProgressionManager.save_state()

	MetaProgressionManager.reset_meta()
	assert_eq(MetaProgressionManager.available_points, 0)

	MetaProgressionManager.load_state(saved)
	assert_eq(MetaProgressionManager.available_points, 22)
	assert_true(MetaProgressionManager.is_unlocked("styles", "stout"))
	assert_true(MetaProgressionManager.is_achievement_completed("perfect_brew"))
	assert_true(MetaProgressionManager.has_active_perk("nest_egg"))

func test_two_runs_accumulate_points() -> void:
	var metrics1: Dictionary = {
		"turns": 10, "revenue": 4000.0, "best_quality": 60.0,
		"medals": 0, "won": false,
		"equipment_spend": 500, "channels_unlocked": 1,
		"unique_ingredients": 8,
	}
	var pts1: int = MetaProgressionManager.end_run(metrics1)

	GameState.reset()

	var metrics2: Dictionary = {
		"turns": 20, "revenue": 8000.0, "best_quality": 85.0,
		"medals": 2, "won": true,
		"equipment_spend": 2000, "channels_unlocked": 3,
		"unique_ingredients": 15,
	}
	var pts2: int = MetaProgressionManager.end_run(metrics2)

	assert_eq(MetaProgressionManager.lifetime_points, pts1 + pts2)
	assert_eq(MetaProgressionManager.total_runs, 2)
	assert_eq(MetaProgressionManager.run_history.size(), 2)

func test_achievement_unlocks_modifier_for_next_run() -> void:
	# Simulate a winning run to unlock first_victory → tough_market
	var metrics: Dictionary = {
		"turns": 15, "revenue": 10000.0, "best_quality": 80.0,
		"medals": 1, "won": true,
		"equipment_spend": 2000, "channels_unlocked": 2,
		"unique_ingredients": 12,
	}
	MetaProgressionManager.end_run(metrics)
	assert_true(MetaProgressionManager.is_achievement_completed("first_victory"))
	assert_true(MetaProgressionManager.is_modifier_unlocked("tough_market"))

func test_blueprint_discount_applied_after_unlock() -> void:
	MetaProgressionManager.add_points(10)
	MetaProgressionManager.unlock_blueprint("mash_tun", 5)
	if is_instance_valid(ResearchManager):
		var cost: int = ResearchManager._get_effective_rp_cost("semi_pro_equipment")
		assert_eq(cost, 10)  # 20 * 0.5
