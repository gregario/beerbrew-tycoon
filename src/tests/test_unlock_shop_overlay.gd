extends GutTest

var overlay: CanvasLayer
var meta_mgr: Node

func before_each() -> void:
	meta_mgr = preload("res://autoloads/MetaProgressionManager.gd").new()
	add_child_autofree(meta_mgr)
	overlay = preload("res://ui/UnlockShopOverlay.gd").new()
	add_child_autofree(overlay)

func test_overlay_starts_hidden() -> void:
	assert_false(overlay.visible)

func test_overlay_has_done_signal() -> void:
	assert_true(overlay.has_signal("done_pressed"))

func test_show_shop_makes_visible() -> void:
	overlay.show_shop(meta_mgr)
	assert_true(overlay.visible)

func test_has_four_tabs() -> void:
	overlay.show_shop(meta_mgr)
	assert_eq(overlay._tab_buttons.size(), 4)

func test_purchase_deducts_points() -> void:
	meta_mgr.add_points(10)
	overlay.show_shop(meta_mgr)
	meta_mgr.unlock_style("lager", 5)
	assert_eq(meta_mgr.available_points, 5)

func test_done_button_hides_overlay() -> void:
	overlay.show_shop(meta_mgr)
	assert_true(overlay.visible)
	overlay._on_done_pressed()
	assert_false(overlay.visible)

func test_points_label_updates() -> void:
	meta_mgr.add_points(15)
	overlay.show_shop(meta_mgr)
	assert_true(overlay._points_label.text.contains("15"))

func test_tab_switch_changes_current_tab() -> void:
	overlay.show_shop(meta_mgr)
	assert_eq(overlay._current_tab, "styles")
	overlay._on_tab_pressed("blueprints")
	assert_eq(overlay._current_tab, "blueprints")

func test_unlock_via_overlay_refreshes_display() -> void:
	meta_mgr.add_points(10)
	overlay.show_shop(meta_mgr)
	overlay._on_unlock_pressed("lager", 5)
	assert_eq(meta_mgr.available_points, 5)
	assert_true(meta_mgr.is_unlocked("styles", "lager"))

func test_insufficient_points_no_unlock() -> void:
	meta_mgr.add_points(2)
	overlay.show_shop(meta_mgr)
	overlay._on_unlock_pressed("stout", 8)
	assert_eq(meta_mgr.available_points, 2)
	assert_false(meta_mgr.is_unlocked("styles", "stout"))
