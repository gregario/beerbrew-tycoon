extends CanvasLayer

## MainMenu — title screen with meta-progression stats.
## Follows overlay architecture: CanvasLayer layer=10, CenterContainer+PRESET_FULL_RECT.

signal new_run_pressed
signal unlocks_pressed
signal achievements_pressed
signal quit_pressed

var _root: CenterContainer
var _stats_label: Label
var _meta: Node

const ACCENT_COLOR: Color = Color("#FFC857")
const MUTED_COLOR: Color = Color("#8A9BB1")
const SURFACE_COLOR: Color = Color("#0B1220")
const BG_COLOR: Color = Color("#0F1724")
const DANGER_COLOR: Color = Color("#FF7B7B")
const PRIMARY_COLOR: Color = Color("#5AA9FF")

func _ready() -> void:
	layer = 10
	visible = false
	_build_ui()

func _build_ui() -> void:
	_root = CenterContainer.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_PASS

	# Full-screen background
	var bg: ColorRect = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = BG_COLOR
	bg.mouse_filter = Control.MOUSE_FILTER_PASS
	_root.add_child(bg)

	# Main VBox for vertical centering
	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	main_vbox.add_theme_constant_override("separation", 8)
	main_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	# Title
	var title: Label = Label.new()
	title.text = "BEERBREW TYCOON"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 40)
	title.add_theme_color_override("font_color", ACCENT_COLOR)
	main_vbox.add_child(title)

	# Spacer between title and buttons
	var spacer1: Control = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 32)
	main_vbox.add_child(spacer1)

	# Button column
	var btn_column: VBoxContainer = VBoxContainer.new()
	btn_column.mouse_filter = Control.MOUSE_FILTER_PASS
	btn_column.add_theme_constant_override("separation", 16)
	btn_column.size_flags_horizontal = Control.SIZE_SHRINK_CENTER

	# New Run button (primary CTA)
	var new_run_btn: Button = _make_button("New Run", ACCENT_COLOR, Color(0.1, 0.1, 0.1))
	new_run_btn.pressed.connect(func() -> void: new_run_pressed.emit())
	btn_column.add_child(new_run_btn)

	# Unlocks button
	var unlocks_btn: Button = _make_button("Unlocks", SURFACE_COLOR, Color.WHITE, MUTED_COLOR)
	unlocks_btn.pressed.connect(func() -> void: unlocks_pressed.emit())
	btn_column.add_child(unlocks_btn)

	# Achievements button
	var achievements_btn: Button = _make_button("Achievements", SURFACE_COLOR, Color.WHITE, MUTED_COLOR)
	achievements_btn.pressed.connect(func() -> void: achievements_pressed.emit())
	btn_column.add_child(achievements_btn)

	# Quit button
	var quit_btn: Button = _make_button("Quit", SURFACE_COLOR, Color.WHITE, DANGER_COLOR)
	quit_btn.pressed.connect(func() -> void: quit_pressed.emit())
	btn_column.add_child(quit_btn)

	main_vbox.add_child(btn_column)

	# Spacer before stats
	var spacer2: Control = Control.new()
	spacer2.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_vbox.add_child(spacer2)

	# Stats bar at bottom
	var stats_panel: PanelContainer = PanelContainer.new()
	stats_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	stats_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var stats_style: StyleBoxFlat = StyleBoxFlat.new()
	stats_style.bg_color = SURFACE_COLOR
	stats_style.set_corner_radius_all(4)
	stats_style.set_content_margin_all(12)
	stats_panel.add_theme_stylebox_override("panel", stats_style)

	_stats_label = Label.new()
	_stats_label.text = "Runs: 0 | Best: $0 | Medals: 0 | UP: 0"
	_stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_stats_label.add_theme_font_size_override("font_size", 16)
	_stats_label.add_theme_color_override("font_color", MUTED_COLOR)
	stats_panel.add_child(_stats_label)

	main_vbox.add_child(stats_panel)

	_root.add_child(main_vbox)
	add_child(_root)

func show_menu(meta: Node) -> void:
	_meta = meta
	_update_stats()
	visible = true

func _update_stats() -> void:
	if not _meta:
		return
	var runs: int = _meta.total_runs
	var up: int = _meta.lifetime_points

	# Calculate best revenue and medals from run history
	var best_rev: int = 0
	var total_medals: int = 0
	for run in _meta.run_history:
		var metrics: Dictionary = run.get("metrics", {})
		var rev: int = int(metrics.get("revenue", 0.0))
		if rev > best_rev:
			best_rev = rev
		total_medals += int(metrics.get("medals", 0))

	_stats_label.text = "Runs: %d | Best: $%d | Medals: %d | UP: %d" % [runs, best_rev, total_medals, up]

func _make_button(text: String, bg_color: Color, font_color: Color, border_color: Color = Color.TRANSPARENT) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(240, 48)
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.set_corner_radius_all(4)
	style.set_content_margin_all(8)
	if border_color != Color.TRANSPARENT:
		style.border_color = border_color
		style.set_border_width_all(1)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", font_color)
	return btn
