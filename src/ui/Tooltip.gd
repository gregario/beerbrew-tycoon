extends PanelContainer
## Tooltip popup — show near mouse, clamp to viewport.

@onready var label: Label = $Label

const MAX_WIDTH := 250
const OFFSET := Vector2(16, 16)

func _ready() -> void:
	visible = false
	custom_minimum_size.x = 0
	size = Vector2.ZERO

func show_at(text: String, pos: Vector2) -> void:
	label.text = text
	custom_minimum_size.x = min(label.get_minimum_size().x + 32, MAX_WIDTH)
	visible = true
	var vp_size := get_viewport_rect().size
	var tip_pos := pos + OFFSET
	if tip_pos.x + size.x > vp_size.x:
		tip_pos.x = pos.x - size.x - OFFSET.x
	if tip_pos.y + size.y > vp_size.y:
		tip_pos.y = pos.y - size.y - OFFSET.y
	position = tip_pos

func hide_tooltip() -> void:
	visible = false
