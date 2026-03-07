extends GutTest

var overlay: CanvasLayer

func before_each() -> void:
	overlay = preload("res://ui/RunSummaryOverlay.gd").new()
	add_child_autofree(overlay)

func test_overlay_starts_hidden() -> void:
	assert_false(overlay.visible)

func test_overlay_has_continue_signal() -> void:
	assert_true(overlay.has_signal("continue_pressed"))

func test_show_summary_makes_visible() -> void:
	var metrics: Dictionary = {"turns": 12, "revenue": 8420.0, "best_quality": 87.0, "medals": 2, "won": true}
	overlay.show_summary(metrics, 17)
	assert_true(overlay.visible)

func test_total_label_shows_points() -> void:
	var metrics: Dictionary = {"turns": 12, "revenue": 8420.0, "best_quality": 87.0, "medals": 2, "won": true}
	overlay.show_summary(metrics, 17)
	assert_true(overlay._total_label.text.contains("17"))

func test_show_summary_without_win() -> void:
	var metrics: Dictionary = {"turns": 10, "revenue": 4000.0, "best_quality": 60.0, "medals": 1, "won": false}
	overlay.show_summary(metrics, 8)
	assert_true(overlay.visible)
	assert_true(overlay._total_label.text.contains("8"))

func test_show_summary_with_challenge_modifier() -> void:
	var metrics: Dictionary = {"turns": 15, "revenue": 6000.0, "best_quality": 80.0, "medals": 3, "won": false, "challenge_modifier": true}
	overlay.show_summary(metrics, 12)
	assert_true(overlay.visible)

func test_continue_button_hides_overlay() -> void:
	var metrics: Dictionary = {"turns": 10, "revenue": 2000.0, "best_quality": 40.0, "medals": 0, "won": false}
	overlay.show_summary(metrics, 3)
	assert_true(overlay.visible)
	overlay._on_continue_pressed()
	assert_false(overlay.visible)

func test_grid_has_rows_after_show() -> void:
	var metrics: Dictionary = {"turns": 10, "revenue": 2000.0, "best_quality": 40.0, "medals": 1, "won": false}
	overlay.show_summary(metrics, 5)
	# 4 rows x 2 columns = 8 children (no win row, no challenge row)
	assert_eq(overlay._grid.get_child_count(), 8)

func test_grid_has_win_row_when_won() -> void:
	var metrics: Dictionary = {"turns": 10, "revenue": 2000.0, "best_quality": 40.0, "medals": 1, "won": true}
	overlay.show_summary(metrics, 10)
	# 5 rows x 2 columns = 10 children (includes win row)
	assert_eq(overlay._grid.get_child_count(), 10)
