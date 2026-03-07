extends CanvasLayer

## RunSummaryOverlay — shows unlock points earned after a run ends.
## Follows overlay architecture: CanvasLayer layer=10, CenterContainer+PRESET_FULL_RECT.

signal continue_pressed

var _root: CenterContainer
var _total_label: Label
var _lifetime_label: Label
var _grid: GridContainer
var _continue_btn: Button

const META_COLOR: Color = Color("#B88AFF")
const ACCENT_COLOR: Color = Color("#FFC857")
const MUTED_COLOR: Color = Color("#8A9BB1")
const SURFACE_COLOR: Color = Color("#0B1220")
const BG_BORDER_COLOR: Color = Color("#8A9BB1")
const BTN_TEXT_COLOR: Color = Color(0.1, 0.1, 0.1)

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
	title.text = "RUN COMPLETE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(title)

	# Separator
	vbox.add_child(HSeparator.new())

	# Grid for point breakdown
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.mouse_filter = Control.MOUSE_FILTER_PASS
	_grid.add_theme_constant_override("h_separation", 24)
	_grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(_grid)

	# Spacer
	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Separator before total
	vbox.add_child(HSeparator.new())

	# Total label
	_total_label = Label.new()
	_total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_total_label.add_theme_font_size_override("font_size", 24)
	_total_label.add_theme_color_override("font_color", META_COLOR)
	vbox.add_child(_total_label)

	# Lifetime label
	_lifetime_label = Label.new()
	_lifetime_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lifetime_label.add_theme_font_size_override("font_size", 16)
	_lifetime_label.add_theme_color_override("font_color", MUTED_COLOR)
	vbox.add_child(_lifetime_label)

	# Continue button
	_continue_btn = Button.new()
	_continue_btn.text = "Continue to Unlocks"
	_continue_btn.custom_minimum_size = Vector2(240, 48)
	_continue_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = META_COLOR
	btn_style.set_corner_radius_all(4)
	btn_style.set_content_margin_all(8)
	_continue_btn.add_theme_stylebox_override("normal", btn_style)
	_continue_btn.add_theme_color_override("font_color", BTN_TEXT_COLOR)
	_continue_btn.pressed.connect(_on_continue_pressed)
	vbox.add_child(_continue_btn)

	card.add_child(vbox)
	_root.add_child(card)
	add_child(_root)

func show_summary(metrics: Dictionary, points_earned: int) -> void:
	# Clear previous breakdown rows
	for child in _grid.get_children():
		child.queue_free()

	# Calculate component points for display
	var turn_pts: int = mini(metrics.get("turns", 0) / 5, 5)
	var rev_pts: int = mini(int(metrics.get("revenue", 0.0) / 2000.0), 5)
	var qual_pts: int = mini(int(metrics.get("best_quality", 0.0) / 20.0), 5)
	var medal_pts: int = mini(metrics.get("medals", 0), 5)
	var win_pts: int = 5 if metrics.get("won", false) else 0
	var has_challenge: bool = metrics.get("challenge_modifier", false)

	# Add rows
	_add_row("Turns survived (%d)" % metrics.get("turns", 0), "+%d UP" % turn_pts, META_COLOR)
	_add_row("Total revenue ($%d)" % int(metrics.get("revenue", 0.0)), "+%d UP" % rev_pts, META_COLOR)
	_add_row("Best quality (%d)" % int(metrics.get("best_quality", 0.0)), "+%d UP" % qual_pts, META_COLOR)
	_add_row("Competition medals (%d)" % metrics.get("medals", 0), "+%d UP" % medal_pts, META_COLOR)

	if metrics.get("won", false):
		_add_row("Run won", "+5 UP", META_COLOR)

	if has_challenge:
		_add_row("Challenge modifier (1.5x)", "\u00d71.5", ACCENT_COLOR)

	# Total
	_total_label.text = "TOTAL: %d UP" % points_earned

	# Lifetime display — read from MetaProgressionManager if available
	var lifetime: int = 0
	var available: int = 0
	var meta_node: Node = get_node_or_null("/root/MetaProgressionManager")
	if meta_node:
		lifetime = meta_node.lifetime_points
		available = meta_node.available_points
	_lifetime_label.text = "Lifetime: %d | Available: %d" % [lifetime, available]

	visible = true

func _add_row(label_text: String, value_text: String, value_color: Color) -> void:
	var label: Label = Label.new()
	label.text = label_text
	label.add_theme_font_size_override("font_size", 20)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_child(label)

	var value: Label = Label.new()
	value.text = value_text
	value.add_theme_font_size_override("font_size", 20)
	value.add_theme_color_override("font_color", value_color)
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_grid.add_child(value)

func _on_continue_pressed() -> void:
	visible = false
	continue_pressed.emit()
