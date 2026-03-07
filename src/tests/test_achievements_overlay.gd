extends GutTest

var overlay: CanvasLayer
var meta_mgr: Node

func before_each() -> void:
	meta_mgr = preload("res://autoloads/MetaProgressionManager.gd").new()
	add_child_autofree(meta_mgr)
	overlay = preload("res://ui/AchievementsOverlay.gd").new()
	add_child_autofree(overlay)

func test_overlay_starts_hidden() -> void:
	assert_false(overlay.visible)

func test_overlay_has_closed_signal() -> void:
	assert_true(overlay.has_signal("closed"))

func test_show_displays_six_achievements() -> void:
	overlay.show_achievements(meta_mgr)
	assert_true(overlay.visible)
	assert_eq(overlay._achievement_rows.size(), 6)

func test_completed_achievement_shows_completed() -> void:
	meta_mgr.complete_achievement("first_victory")
	overlay.show_achievements(meta_mgr)
	assert_true(overlay._achievement_rows[0]["completed"])

func test_incomplete_achievement_not_completed() -> void:
	overlay.show_achievements(meta_mgr)
	assert_false(overlay._achievement_rows[0]["completed"])
