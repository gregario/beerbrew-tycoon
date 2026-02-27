extends PanelContainer
## A single toast notification that auto-dismisses.

@onready var label: Label = $Label
@onready var timer: Timer = $Timer

const DISMISS_TIME := 3.0
const SLIDE_DURATION := 0.3

func setup(message: String) -> void:
	if label:
		label.text = message
	else:
		set_meta("_pending_text", message)

func _ready() -> void:
	if has_meta("_pending_text"):
		label.text = get_meta("_pending_text")
	timer.wait_time = DISMISS_TIME
	timer.one_shot = true
	timer.timeout.connect(_dismiss)
	timer.start()
	_animate_in()

func _animate_in() -> void:
	var target_x := position.x
	position.x += 320
	var tween := create_tween()
	tween.tween_property(self, "position:x", target_x, SLIDE_DURATION).set_ease(Tween.EASE_OUT)

func _dismiss() -> void:
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
