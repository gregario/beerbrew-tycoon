extends Control

## ResearchTree — node graph overlay for browsing and unlocking research.
## Built entirely in code (no .tscn needed).

signal closed()

const CATEGORY_LABELS: Array[String] = ["Techniques", "Ingredients", "Equipment", "Styles"]
const CATEGORY_MAP: Dictionary = {
	0: ResearchNode.Category.TECHNIQUES,
	1: ResearchNode.Category.INGREDIENTS,
	2: ResearchNode.Category.EQUIPMENT,
	3: ResearchNode.Category.STYLES,
}

const COLOR_SURFACE := Color("#0B1220")
const COLOR_PRIMARY := Color("#5AA9FF")
const COLOR_ACCENT := Color("#FFC857")
const COLOR_SUCCESS := Color("#5EE8A4")
const COLOR_MUTED := Color("#8A9BB1")

const COL_SPACING := 180
const ROW_SPACING := 130
const CARD_SIZE := Vector2(140, 100)
const GRAPH_ORIGIN := Vector2(20, 20)

var _selected_category: int = 0

# UI references
var _dim_bg: ColorRect = null
var _panel: PanelContainer = null
var _rp_label: Label = null
var _tab_buttons: Array[Button] = []
var _scroll: ScrollContainer = null
var _node_graph: Control = null

# Card tracking for drawing connections
var _card_positions: Dictionary = {}  # node_id -> Rect2
var _current_nodes: Array = []


func _ready() -> void:
	_build_ui()
	visible = false


## Open the research tree and refresh the display.
func show_tree() -> void:
	_selected_category = 0
	visible = true
	_refresh()


func _refresh() -> void:
	_rp_label.text = "RP: %d" % ResearchManager.research_points
	_refresh_tabs()
	_build_node_graph()


# ---------------------------------------------------------------------------
# Build UI
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP

	# Dim overlay
	_dim_bg = ColorRect.new()
	_dim_bg.set_anchors_preset(PRESET_FULL_RECT)
	_dim_bg.color = Color(0, 0, 0, 0.6)
	_dim_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim_bg.gui_input.connect(_on_dim_input)
	add_child(_dim_bg)

	# Centered panel
	var center := CenterContainer.new()
	center.set_anchors_preset(PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(900, 600)
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_SURFACE
	panel_style.border_color = COLOR_MUTED
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 16
	panel_style.content_margin_right = 16
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 16
	_panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(_panel)

	var main_vbox := VBoxContainer.new()
	main_vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(main_vbox)

	# Header
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)

	var title := Label.new()
	title.text = "Research Tree"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	header.add_child(title)

	_rp_label = Label.new()
	_rp_label.add_theme_font_size_override("font_size", 24)
	_rp_label.add_theme_color_override("font_color", COLOR_ACCENT)
	header.add_child(_rp_label)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(_on_close_pressed)
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color("#FF7B7B", 0.2)
	close_style.set_corner_radius_all(4)
	close_btn.add_theme_stylebox_override("normal", close_style)
	header.add_child(close_btn)

	main_vbox.add_child(header)

	# Separator
	var sep := HSeparator.new()
	main_vbox.add_child(sep)

	# Category tabs
	var tab_hbox := HBoxContainer.new()
	tab_hbox.add_theme_constant_override("separation", 8)
	for i in range(CATEGORY_LABELS.size()):
		var tab_btn := Button.new()
		tab_btn.text = CATEGORY_LABELS[i]
		tab_btn.custom_minimum_size = Vector2(100, 36)
		tab_btn.add_theme_font_size_override("font_size", 16)
		var idx := i
		tab_btn.pressed.connect(func(): _on_category_pressed(idx))
		tab_hbox.add_child(tab_btn)
		_tab_buttons.append(tab_btn)
	main_vbox.add_child(tab_hbox)

	# Scroll + node graph
	_scroll = ScrollContainer.new()
	_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_node_graph = Control.new()
	_node_graph.custom_minimum_size = Vector2(850, 400)
	_node_graph.draw.connect(_draw_connections)
	_scroll.add_child(_node_graph)

	main_vbox.add_child(_scroll)


# ---------------------------------------------------------------------------
# Tabs
# ---------------------------------------------------------------------------

func _on_category_pressed(index: int) -> void:
	_selected_category = index
	_refresh()


func _refresh_tabs() -> void:
	for i in range(_tab_buttons.size()):
		var btn := _tab_buttons[i]
		var is_active := (i == _selected_category)
		var style := StyleBoxFlat.new()
		if is_active:
			style.bg_color = Color(COLOR_PRIMARY, 0.3)
			style.border_color = Color(COLOR_PRIMARY, 0.8)
			btn.add_theme_color_override("font_color", Color.WHITE)
		else:
			style.bg_color = Color("#0F1724", 0.5)
			style.border_color = Color(COLOR_MUTED, 0.3)
			btn.add_theme_color_override("font_color", COLOR_MUTED)
		style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		btn.add_theme_stylebox_override("normal", style)


# ---------------------------------------------------------------------------
# Node graph
# ---------------------------------------------------------------------------

func _build_node_graph() -> void:
	# Clear old children
	for child in _node_graph.get_children():
		child.queue_free()
	_card_positions.clear()
	_current_nodes.clear()

	await get_tree().process_frame

	var category: ResearchNode.Category = CATEGORY_MAP[_selected_category]
	_current_nodes = ResearchManager.get_nodes_by_category(category)

	if _current_nodes.is_empty():
		_node_graph.queue_redraw()
		return

	# Build a set of in-category node IDs for column computation
	var in_cat_ids: Dictionary = {}
	for n in _current_nodes:
		in_cat_ids[n.node_id] = true

	# Compute columns: nodes with no in-category prereqs → col 0, etc.
	var node_col: Dictionary = {}  # node_id -> int
	var assigned := 0
	var max_iter := 20
	while assigned < _current_nodes.size() and max_iter > 0:
		max_iter -= 1
		for n in _current_nodes:
			if n.node_id in node_col:
				continue
			var max_prereq_col := -1
			var all_resolved := true
			for prereq in n.prerequisites:
				if prereq not in in_cat_ids:
					continue  # cross-category, ignore for layout
				if prereq not in node_col:
					all_resolved = false
					break
				if node_col[prereq] > max_prereq_col:
					max_prereq_col = node_col[prereq]
			if all_resolved:
				node_col[n.node_id] = max_prereq_col + 1
				assigned += 1

	# Group by column for row assignment
	var col_nodes: Dictionary = {}  # col -> Array of ResearchNode
	for n in _current_nodes:
		var col: int = node_col.get(n.node_id, 0)
		if col not in col_nodes:
			col_nodes[col] = []
		col_nodes[col].append(n)

	# Position and create cards
	for col in col_nodes:
		var nodes_in_col: Array = col_nodes[col]
		for row in range(nodes_in_col.size()):
			var n: ResearchNode = nodes_in_col[row]
			var pos := GRAPH_ORIGIN + Vector2(col * COL_SPACING, row * ROW_SPACING)
			var card := _create_card(n, pos)
			_node_graph.add_child(card)
			_card_positions[n.node_id] = Rect2(pos, CARD_SIZE)

	# Update graph minimum size to fit all cards
	var max_x := 0.0
	var max_y := 0.0
	for rect in _card_positions.values():
		var end: Vector2 = rect.position + rect.size
		if end.x > max_x:
			max_x = end.x
		if end.y > max_y:
			max_y = end.y
	_node_graph.custom_minimum_size = Vector2(maxi(850, int(max_x + 40)), maxi(400, int(max_y + 40)))

	_node_graph.queue_redraw()


func _create_card(n: ResearchNode, pos: Vector2) -> PanelContainer:
	var unlocked := ResearchManager.is_unlocked(n.node_id)
	var can_afford := ResearchManager.can_unlock(n.node_id)
	var prereqs_met := _are_prereqs_met(n)

	# Determine border color and state
	var border_color := COLOR_MUTED
	if unlocked:
		border_color = COLOR_SUCCESS
	elif prereqs_met and can_afford:
		border_color = COLOR_PRIMARY
	elif prereqs_met:
		border_color = COLOR_ACCENT

	var card := PanelContainer.new()
	card.position = pos
	card.custom_minimum_size = CARD_SIZE
	card.size = CARD_SIZE

	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_SURFACE
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)

	if not unlocked and not prereqs_met:
		card.modulate.a = 0.5

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	# Name
	var name_label := Label.new()
	name_label.text = n.node_name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(name_label)

	# Cost / status
	var status_label := Label.new()
	status_label.add_theme_font_size_override("font_size", 14)
	if unlocked:
		status_label.text = "Unlocked"
		status_label.add_theme_color_override("font_color", COLOR_SUCCESS)
	else:
		status_label.text = "%d RP" % n.rp_cost
		status_label.add_theme_color_override("font_color", COLOR_ACCENT)
	vbox.add_child(status_label)

	# Cross-category prerequisite hints
	var cross_prereqs := _get_cross_category_prereqs(n)
	if not cross_prereqs.is_empty():
		var hint_label := Label.new()
		hint_label.text = cross_prereqs
		hint_label.add_theme_font_size_override("font_size", 12)
		hint_label.add_theme_color_override("font_color", COLOR_MUTED)
		hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD
		vbox.add_child(hint_label)

	card.add_child(vbox)

	# Click handling
	var node_id := n.node_id
	card.gui_input.connect(func(event: InputEvent): _on_card_input(event, node_id))

	return card


func _are_prereqs_met(n: ResearchNode) -> bool:
	for prereq in n.prerequisites:
		if not ResearchManager.is_unlocked(prereq):
			return false
	return true


func _get_cross_category_prereqs(n: ResearchNode) -> String:
	var in_cat_ids: Dictionary = {}
	for cn in _current_nodes:
		in_cat_ids[cn.node_id] = true

	var hints: Array[String] = []
	for prereq in n.prerequisites:
		if prereq in in_cat_ids:
			continue
		var prereq_node := ResearchManager.get_node_by_id(prereq)
		if prereq_node:
			var cat_name: String = CATEGORY_LABELS[prereq_node.category]
			hints.append("Needs: %s (%s)" % [prereq_node.node_name, cat_name])
	return "\n".join(hints)


# ---------------------------------------------------------------------------
# Connection lines
# ---------------------------------------------------------------------------

func _draw_connections() -> void:
	var in_cat_ids: Dictionary = {}
	for n in _current_nodes:
		in_cat_ids[n.node_id] = true

	for n in _current_nodes:
		if n.node_id not in _card_positions:
			continue
		var target_rect: Rect2 = _card_positions[n.node_id]
		var target_left := Vector2(target_rect.position.x, target_rect.position.y + target_rect.size.y / 2.0)

		for prereq in n.prerequisites:
			if prereq not in in_cat_ids:
				continue
			if prereq not in _card_positions:
				continue
			var source_rect: Rect2 = _card_positions[prereq]
			var source_right := Vector2(source_rect.position.x + source_rect.size.x, source_rect.position.y + source_rect.size.y / 2.0)

			var line_color := COLOR_SUCCESS if ResearchManager.is_unlocked(prereq) else COLOR_MUTED
			_node_graph.draw_line(source_right, target_left, line_color, 2.0)


# ---------------------------------------------------------------------------
# Card interaction
# ---------------------------------------------------------------------------

func _on_card_input(event: InputEvent, node_id: String) -> void:
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return

	var n := ResearchManager.get_node_by_id(node_id)
	if n == null:
		return

	if ResearchManager.is_unlocked(node_id):
		# Show description
		var dlg := AcceptDialog.new()
		dlg.title = n.node_name
		dlg.dialog_text = n.description
		add_child(dlg)
		dlg.popup_centered()
		dlg.confirmed.connect(func(): dlg.queue_free())
		dlg.canceled.connect(func(): dlg.queue_free())
		return

	if ResearchManager.can_unlock(node_id):
		# Confirmation to unlock
		var dlg := ConfirmationDialog.new()
		dlg.title = "Unlock Research"
		dlg.dialog_text = "Unlock %s for %d RP?\n\n%s" % [n.node_name, n.rp_cost, n.description]
		add_child(dlg)
		dlg.popup_centered()
		dlg.confirmed.connect(func():
			ResearchManager.unlock(node_id)
			_refresh()
			dlg.queue_free()
		)
		dlg.canceled.connect(func(): dlg.queue_free())
		return

	# Locked — show what's missing
	var missing_parts: Array[String] = []
	for prereq in n.prerequisites:
		if not ResearchManager.is_unlocked(prereq):
			var prereq_node := ResearchManager.get_node_by_id(prereq)
			if prereq_node:
				missing_parts.append("- %s" % prereq_node.node_name)
	if ResearchManager.research_points < n.rp_cost:
		missing_parts.append("- Not enough RP (need %d, have %d)" % [n.rp_cost, ResearchManager.research_points])

	var dlg := AcceptDialog.new()
	dlg.title = n.node_name
	dlg.dialog_text = "Cannot unlock yet:\n" + "\n".join(missing_parts)
	add_child(dlg)
	dlg.popup_centered()
	dlg.confirmed.connect(func(): dlg.queue_free())
	dlg.canceled.connect(func(): dlg.queue_free())


# ---------------------------------------------------------------------------
# Close / dim
# ---------------------------------------------------------------------------

func _on_close_pressed() -> void:
	visible = false
	closed.emit()


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_close_pressed()
