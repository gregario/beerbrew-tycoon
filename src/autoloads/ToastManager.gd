extends CanvasLayer
## Global toast notification manager.
## Usage: ToastManager.show_toast("Message here")

const TOAST_SCENE := preload("res://ui/Toast.tscn")
const TOAST_MARGIN := 16
const TOAST_SPACING := 8

func show_toast(message: String) -> void:
	var toast := TOAST_SCENE.instantiate()
	toast.setup(message)
	add_child(toast)
	_reposition_toasts()

func _reposition_toasts() -> void:
	var y_offset := TOAST_MARGIN
	for i in range(get_child_count() - 1, -1, -1):
		var child := get_child(i)
		child.position = Vector2(1280 - 300 - TOAST_MARGIN, y_offset)
		y_offset += 58 + TOAST_SPACING
