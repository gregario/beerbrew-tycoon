extends GutTest

var _manager: Node

func before_each() -> void:
	_manager = load("res://autoloads/ToastManager.gd").new()
	add_child_autofree(_manager)

func test_show_toast_adds_child() -> void:
	_manager.show_toast("Test message")
	assert_eq(_manager.get_child_count(), 1, "Should have one toast child")

func test_toast_has_correct_text() -> void:
	_manager.show_toast("Hello World")
	var toast := _manager.get_child(0)
	var label := toast.find_child("Label") as Label
	assert_not_null(label, "Toast should have a Label")
	assert_eq(label.text, "Hello World")

func test_multiple_toasts_stack() -> void:
	_manager.show_toast("First")
	_manager.show_toast("Second")
	assert_eq(_manager.get_child_count(), 2, "Should have two toasts")
