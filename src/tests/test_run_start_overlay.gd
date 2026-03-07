extends GutTest

var overlay: CanvasLayer
var meta_mgr: Node

func before_each() -> void:
	meta_mgr = preload("res://autoloads/MetaProgressionManager.gd").new()
	add_child_autofree(meta_mgr)
	overlay = preload("res://ui/RunStartOverlay.gd").new()
	add_child_autofree(overlay)

func test_overlay_starts_hidden() -> void:
	assert_false(overlay.visible)

func test_overlay_has_run_started_signal() -> void:
	assert_true(overlay.has_signal("run_started"))

func test_show_setup_makes_visible() -> void:
	overlay.show_setup(meta_mgr)
	assert_true(overlay.visible)

func test_perk_toggle_max_three() -> void:
	meta_mgr.unlocked_perks = ["nest_egg", "quick_study", "landlords_friend", "style_specialist"] as Array[String]
	overlay.show_setup(meta_mgr)
	overlay._toggle_perk("nest_egg")
	overlay._toggle_perk("quick_study")
	overlay._toggle_perk("landlords_friend")
	assert_eq(overlay._selected_perks.size(), 3)
	overlay._toggle_perk("style_specialist")
	assert_eq(overlay._selected_perks.size(), 3)

func test_modifier_toggle_max_two() -> void:
	meta_mgr.complete_achievement("first_victory")
	meta_mgr.complete_achievement("perfect_brew")
	meta_mgr.complete_achievement("survivor")
	overlay.show_setup(meta_mgr)
	overlay._toggle_modifier("tough_market")
	overlay._toggle_modifier("master_brewer")
	assert_eq(overlay._selected_modifiers.size(), 2)
	overlay._toggle_modifier("lucky_break")
	assert_eq(overlay._selected_modifiers.size(), 2)

func test_perk_toggle_off() -> void:
	meta_mgr.unlocked_perks = ["nest_egg"] as Array[String]
	overlay.show_setup(meta_mgr)
	overlay._toggle_perk("nest_egg")
	assert_eq(overlay._selected_perks.size(), 1)
	overlay._toggle_perk("nest_egg")
	assert_eq(overlay._selected_perks.size(), 0)

func test_start_emits_signal() -> void:
	overlay.show_setup(meta_mgr)
	watch_signals(overlay)
	overlay._on_start_pressed()
	assert_signal_emitted(overlay, "run_started")
