extends CanvasLayer

## AchievementsOverlay — shows 6 achievements with progress.
## Follows overlay architecture: CanvasLayer layer=10, CenterContainer+PRESET_FULL_RECT.

signal closed

var _root: CenterContainer
var _rows_container: VBoxContainer
var _close_btn: Button
var _meta: Node

var _achievement_rows: Array = []

const META_COLOR: Color = Color("#B88AFF")
const ACCENT_COLOR: Color = Color("#FFC857")
const SUCCESS_COLOR: Color = Color("#5EE8A4")
const MUTED_COLOR: Color = Color("#8A9BB1")
const SURFACE_COLOR: Color = Color("#0B1220")
const BG_BORDER_COLOR: Color = Color("#8A9BB1")
const BTN_TEXT_COLOR: Color = Color(0.1, 0.1, 0.1)
const PRIMARY_COLOR: Color = Color("#5AA9FF")

const ACHIEVEMENT_DEFS: Array = [
	{"id": "first_victory", "name": "First Victory", "description": "Win a run", "unlocks": "Tough Market", "progress_key": ""},
	{"id": "budget_master", "name": "Budget Master", "description": "Win with <$1000 equipment spend", "unlocks": "Budget Brewery", "progress_key": "min_equipment_spend"},
	{"id": "perfect_brew", "name": "Perfect Brew", "description": "Brew a 95+ quality beer", "unlocks": "Master Brewer", "progress_key": "best_quality"},
	{"id": "survivor", "name": "Survivor", "description": "Survive 20 turns", "unlocks": "Lucky Break", "progress_key": "best_turns"},
	{"id": "diversified", "name": "Diversified", "description": "Unlock all 4 distribution channels", "unlocks": "Generous Market", "progress_key": "max_channels"},
	{"id": "scarcity_brewer", "name": "Scarcity Brewer", "description": "Win using ≤10 unique ingredients", "unlocks": "Ingredient Shortage", "progress_key": "min_unique_ingredients"},
]

func _ready() -> void:
	layer = 10
	visible = false
	_build_ui()

func _build_ui() -> void:
	_root = CenterContainer.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_PASS

	# Background dim
	var dim: ColorRect = ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.6)
	dim.mouse_filter = Control.MOUSE_FILTER_PASS
	_root.add_child(dim)

	# Card panel
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(900, 550)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var card_style: StyleBoxFlat = StyleBoxFlat.new()
	card_style.bg_color = SURFACE_COLOR
	card_style.border_color = BG_BORDER_COLOR
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(4)
	card_style.set_content_margin_all(32)
	card.add_theme_stylebox_override("panel", card_style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 16)

	# Title
	var title: Label = Label.new()
	title.text = "ACHIEVEMENTS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	# Separator
	vbox.add_child(HSeparator.new())

	# ScrollContainer for rows
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	_rows_container = VBoxContainer.new()
	_rows_container.mouse_filter = Control.MOUSE_FILTER_PASS
	_rows_container.add_theme_constant_override("separation", 12)
	_rows_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_rows_container)
	vbox.add_child(scroll)

	# Close button
	_close_btn = Button.new()
	_close_btn.text = "Close"
	_close_btn.custom_minimum_size = Vector2(240, 48)
	_close_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = PRIMARY_COLOR
	btn_style.set_corner_radius_all(4)
	btn_style.set_content_margin_all(8)
	_close_btn.add_theme_stylebox_override("normal", btn_style)
	_close_btn.add_theme_color_override("font_color", BTN_TEXT_COLOR)
	_close_btn.pressed.connect(_on_close_pressed)
	vbox.add_child(_close_btn)

	card.add_child(vbox)
	_root.add_child(card)
	add_child(_root)

func show_achievements(meta: Node) -> void:
	_meta = meta
	_rebuild_rows()
	visible = true

func _rebuild_rows() -> void:
	for child in _rows_container.get_children():
		child.queue_free()
	_achievement_rows.clear()

	if not _meta:
		return

	var completed_map: Dictionary = _meta.get_achievements()

	for def in ACHIEVEMENT_DEFS:
		var is_completed: bool = completed_map.get(def["id"], false)
		_achievement_rows.append({"id": def["id"], "completed": is_completed})

		var row: HBoxContainer = HBoxContainer.new()
		row.mouse_filter = Control.MOUSE_FILTER_PASS
		row.add_theme_constant_override("separation", 12)

		# Status icon
		var icon: Label = Label.new()
		if is_completed:
			icon.text = "✓"
			icon.add_theme_color_override("font_color", SUCCESS_COLOR)
		else:
			icon.text = "□"
			icon.add_theme_color_override("font_color", MUTED_COLOR)
		icon.add_theme_font_size_override("font_size", 24)
		icon.custom_minimum_size = Vector2(32, 0)
		row.add_child(icon)

		# Info column
		var info: VBoxContainer = VBoxContainer.new()
		info.mouse_filter = Control.MOUSE_FILTER_PASS
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info.add_theme_constant_override("separation", 2)

		var name_label: Label = Label.new()
		name_label.text = def["name"]
		name_label.add_theme_font_size_override("font_size", 20)
		info.add_child(name_label)

		var desc_label: Label = Label.new()
		desc_label.text = def["description"]
		desc_label.add_theme_font_size_override("font_size", 16)
		desc_label.add_theme_color_override("font_color", MUTED_COLOR)
		info.add_child(desc_label)

		var unlock_label: Label = Label.new()
		unlock_label.text = "Unlocks: %s" % def["unlocks"]
		unlock_label.add_theme_font_size_override("font_size", 16)
		unlock_label.add_theme_color_override("font_color", ACCENT_COLOR)
		info.add_child(unlock_label)

		row.add_child(info)

		# Status text (right-aligned)
		var status_label: Label = Label.new()
		if is_completed:
			status_label.text = "COMPLETED"
			status_label.add_theme_color_override("font_color", SUCCESS_COLOR)
		else:
			status_label.text = _get_progress_hint(def)
			status_label.add_theme_color_override("font_color", MUTED_COLOR)
		status_label.add_theme_font_size_override("font_size", 16)
		status_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		row.add_child(status_label)

		_rows_container.add_child(row)

func _get_progress_hint(def: Dictionary) -> String:
	var progress_key: String = def.get("progress_key", "")
	if progress_key == "" or not _meta:
		return "Not yet"
	var progress: Dictionary = _meta.get_achievement_progress()
	var val: Variant = progress.get(progress_key, 0)
	match progress_key:
		"best_quality":
			return "Best: %d/95" % int(float(val))
		"best_turns":
			return "Best: %d/20" % int(val)
		"max_channels":
			return "Channels: %d/4" % int(val)
		"min_equipment_spend":
			if int(val) >= 999999:
				return "No data"
			return "Best: $%d" % int(val)
		"min_unique_ingredients":
			if int(val) >= 999:
				return "No data"
			return "Best: %d" % int(val)
	return "In progress"

func _on_close_pressed() -> void:
	visible = false
	closed.emit()
