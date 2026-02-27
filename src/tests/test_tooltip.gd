extends GutTest

var _tooltip: Control

func before_each() -> void:
	_tooltip = preload("res://ui/Tooltip.tscn").instantiate()
	add_child_autofree(_tooltip)

func test_tooltip_starts_hidden() -> void:
	assert_false(_tooltip.visible, "Tooltip should start hidden")

func test_show_sets_text_and_visibility() -> void:
	_tooltip.show_at("Test tooltip text", Vector2(100, 100))
	assert_true(_tooltip.visible)
	var label := _tooltip.find_child("Label") as Label
	assert_eq(label.text, "Test tooltip text")

func test_hide_tooltip() -> void:
	_tooltip.show_at("Text", Vector2(100, 100))
	_tooltip.hide_tooltip()
	assert_false(_tooltip.visible)
