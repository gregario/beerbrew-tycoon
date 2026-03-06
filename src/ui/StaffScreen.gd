extends CanvasLayer

## StaffScreen — full-screen overlay UI for staff management.
## Built entirely in code (no .tscn needed).
## Follows the same pattern as ResearchTree.gd.

signal closed()

const COLOR_SURFACE := Color("#0B1220")
const COLOR_PRIMARY := Color("#5AA9FF")
const COLOR_ACCENT := Color("#FFC857")
const COLOR_SUCCESS := Color("#5EE8A4")
const COLOR_MUTED := Color("#8A9BB1")
const COLOR_WARNING := Color("#FFB347")
const COLOR_DANGER := Color("#FF7B7B")

# UI references
var _dim_bg: ColorRect = null
var _panel: PanelContainer = null
var _staff_count_label: Label = null
var _roster_container: VBoxContainer = null
var _candidates_container: HBoxContainer = null


func _ready() -> void:
	layer = 10
	_build_ui()
	visible = false


## Open the staff screen and refresh the display.
func show_screen() -> void:
	visible = true
	_refresh()


func _refresh() -> void:
	# Update staff count
	var current: int = StaffManager.staff_roster.size()
	var max_staff: int = StaffManager.get_max_staff()
	_staff_count_label.text = "Staff: %d/%d" % [current, max_staff]

	# Clear and rebuild roster
	for child in _roster_container.get_children():
		child.queue_free()

	# Wait a frame so queue_free completes before adding new children
	await get_tree().process_frame

	for staff in StaffManager.staff_roster:
		var card := _build_roster_card(staff)
		_roster_container.add_child(card)

	if StaffManager.staff_roster.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No staff hired yet."
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.add_theme_color_override("font_color", COLOR_MUTED)
		_roster_container.add_child(empty_label)

	# Clear and rebuild candidates
	for child in _candidates_container.get_children():
		child.queue_free()

	await get_tree().process_frame

	for candidate in StaffManager.candidates:
		var card := _build_candidate_card(candidate)
		_candidates_container.add_child(card)

	if StaffManager.candidates.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No candidates available."
		empty_label.add_theme_font_size_override("font_size", 16)
		empty_label.add_theme_color_override("font_color", COLOR_MUTED)
		_candidates_container.add_child(empty_label)


# ---------------------------------------------------------------------------
# Build UI
# ---------------------------------------------------------------------------

func _build_ui() -> void:
	# Dim overlay
	_dim_bg = ColorRect.new()
	_dim_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim_bg.color = Color(0, 0, 0, 0.6)
	_dim_bg.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim_bg.gui_input.connect(_on_dim_input)
	add_child(_dim_bg)

	# Centered panel
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(900, 550)
	_panel.mouse_filter = Control.MOUSE_FILTER_PASS
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
	main_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	main_vbox.add_theme_constant_override("separation", 12)
	_panel.add_child(main_vbox)

	# Header row
	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_PASS
	header.add_theme_constant_override("separation", 16)

	var title := Label.new()
	title.text = "STAFF MANAGEMENT"
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	header.add_child(title)

	_staff_count_label = Label.new()
	_staff_count_label.add_theme_font_size_override("font_size", 20)
	_staff_count_label.add_theme_color_override("font_color", COLOR_MUTED)
	header.add_child(_staff_count_label)

	var close_btn := Button.new()
	close_btn.text = "X"
	close_btn.custom_minimum_size = Vector2(36, 36)
	close_btn.add_theme_font_size_override("font_size", 20)
	close_btn.pressed.connect(_on_close_pressed)
	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color(COLOR_DANGER, 0.2)
	close_style.set_corner_radius_all(4)
	close_btn.add_theme_stylebox_override("normal", close_style)
	header.add_child(close_btn)

	main_vbox.add_child(header)

	# Separator
	var sep := HSeparator.new()
	main_vbox.add_child(sep)

	# YOUR STAFF section
	var roster_header := Label.new()
	roster_header.text = "YOUR STAFF"
	roster_header.add_theme_font_size_override("font_size", 20)
	roster_header.add_theme_color_override("font_color", COLOR_PRIMARY)
	main_vbox.add_child(roster_header)

	var roster_scroll := ScrollContainer.new()
	roster_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	roster_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_roster_container = VBoxContainer.new()
	_roster_container.mouse_filter = Control.MOUSE_FILTER_PASS
	_roster_container.add_theme_constant_override("separation", 8)
	_roster_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	roster_scroll.add_child(_roster_container)

	main_vbox.add_child(roster_scroll)

	# Separator
	var sep2 := HSeparator.new()
	main_vbox.add_child(sep2)

	# CANDIDATES section
	var candidates_header := Label.new()
	candidates_header.text = "CANDIDATES"
	candidates_header.add_theme_font_size_override("font_size", 20)
	candidates_header.add_theme_color_override("font_color", COLOR_SUCCESS)
	main_vbox.add_child(candidates_header)

	_candidates_container = HBoxContainer.new()
	_candidates_container.mouse_filter = Control.MOUSE_FILTER_PASS
	_candidates_container.add_theme_constant_override("separation", 8)
	main_vbox.add_child(_candidates_container)


# ---------------------------------------------------------------------------
# Roster card
# ---------------------------------------------------------------------------

func _build_roster_card(staff: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_SURFACE
	style.border_color = COLOR_PRIMARY
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 4)

	# Header: Name | Lv.N | Salary (right-aligned)
	var header_row := HBoxContainer.new()
	header_row.mouse_filter = Control.MOUSE_FILTER_PASS
	header_row.add_theme_constant_override("separation", 12)

	var name_label := Label.new()
	var staff_name: String = staff.get("staff_name", "Unknown")
	name_label.text = staff_name
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	header_row.add_child(name_label)

	var level_label := Label.new()
	var level: int = staff.get("level", 1)
	level_label.text = "Lv.%d" % level
	level_label.add_theme_font_size_override("font_size", 20)
	level_label.add_theme_color_override("font_color", COLOR_ACCENT)
	header_row.add_child(level_label)

	var salary_spacer := Control.new()
	salary_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(salary_spacer)

	var salary_label := Label.new()
	var salary: int = staff.get("salary_per_turn", 0)
	salary_label.text = "Salary: $%d/turn" % salary
	salary_label.add_theme_font_size_override("font_size", 20)
	salary_label.add_theme_color_override("font_color", COLOR_MUTED)
	header_row.add_child(salary_label)

	vbox.add_child(header_row)

	# Creativity bar
	var creativity_val: int = staff.get("creativity", 0)
	var creativity_row := _build_stat_bar("Creativity:", creativity_val, COLOR_ACCENT)
	vbox.add_child(creativity_row)

	# Precision bar
	var precision_val: int = staff.get("precision", 0)
	var precision_row := _build_stat_bar("Precision:", precision_val, COLOR_PRIMARY)
	vbox.add_child(precision_row)

	# Status row
	var status_row := HBoxContainer.new()
	status_row.mouse_filter = Control.MOUSE_FILTER_PASS
	status_row.add_theme_constant_override("separation", 16)

	var assigned_phase: String = staff.get("assigned_phase", "")
	var assigned_label := Label.new()
	assigned_label.add_theme_font_size_override("font_size", 16)
	if assigned_phase != "":
		assigned_label.text = "Assigned: %s" % assigned_phase.capitalize()
		assigned_label.add_theme_color_override("font_color", COLOR_SUCCESS)
	else:
		assigned_label.text = "Unassigned"
		assigned_label.add_theme_color_override("font_color", COLOR_MUTED)
	status_row.add_child(assigned_label)

	var specialization: String = staff.get("specialization", "none")
	var spec_label := Label.new()
	spec_label.add_theme_font_size_override("font_size", 16)
	if specialization != "none":
		spec_label.text = "Spec: %s" % specialization.capitalize()
		spec_label.add_theme_color_override("font_color", COLOR_ACCENT)
	else:
		spec_label.text = "Spec: None"
		spec_label.add_theme_color_override("font_color", COLOR_MUTED)
	status_row.add_child(spec_label)

	vbox.add_child(status_row)

	# Training status
	var is_training: bool = staff.get("is_training", false)
	if is_training:
		var train_remaining: int = staff.get("training_turns_remaining", 0)
		var training_label := Label.new()
		training_label.text = "Training... (%d turn)" % train_remaining
		training_label.add_theme_font_size_override("font_size", 16)
		training_label.add_theme_color_override("font_color", COLOR_WARNING)
		vbox.add_child(training_label)

	# Action buttons
	var actions_row := HBoxContainer.new()
	actions_row.mouse_filter = Control.MOUSE_FILTER_PASS
	actions_row.add_theme_constant_override("separation", 8)

	var staff_id: String = staff.get("staff_id", "")

	var assign_btn := _make_button("Assign", COLOR_PRIMARY)
	assign_btn.pressed.connect(func(): _show_assign_dialog(staff_id))
	if is_training:
		assign_btn.disabled = true
	actions_row.add_child(assign_btn)

	if level >= StaffManager.SPECIALIZATION_LEVEL and specialization == "none":
		var spec_btn := _make_button("Specialize!", COLOR_ACCENT)
		spec_btn.pressed.connect(func(): _show_specialization_dialog(staff_id))
		if is_training:
			spec_btn.disabled = true
		actions_row.add_child(spec_btn)
	else:
		var train_btn := _make_button("Train", COLOR_ACCENT)
		train_btn.pressed.connect(func(): _show_training_dialog(staff_id))
		if is_training:
			train_btn.disabled = true
		actions_row.add_child(train_btn)

	var fire_btn := _make_button("Fire", COLOR_DANGER)
	fire_btn.pressed.connect(func(): _on_fire_pressed(staff_id))
	actions_row.add_child(fire_btn)

	vbox.add_child(actions_row)

	card.add_child(vbox)
	return card


# ---------------------------------------------------------------------------
# Candidate card
# ---------------------------------------------------------------------------

func _build_candidate_card(candidate: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.custom_minimum_size = Vector2(200, 0)
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_SURFACE
	style.border_color = COLOR_MUTED
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	card.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 4)

	var name_label := Label.new()
	var cand_name: String = candidate.get("staff_name", "Unknown")
	name_label.text = cand_name
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(name_label)

	var creativity_val: int = candidate.get("creativity", 0)
	var creativity_label := Label.new()
	creativity_label.text = "Creativity: %d" % creativity_val
	creativity_label.add_theme_font_size_override("font_size", 16)
	creativity_label.add_theme_color_override("font_color", COLOR_ACCENT)
	vbox.add_child(creativity_label)

	var precision_val: int = candidate.get("precision", 0)
	var precision_label := Label.new()
	precision_label.text = "Precision: %d" % precision_val
	precision_label.add_theme_font_size_override("font_size", 16)
	precision_label.add_theme_color_override("font_color", COLOR_PRIMARY)
	vbox.add_child(precision_label)

	var salary_val: int = candidate.get("salary_per_turn", 0)
	var salary_label := Label.new()
	salary_label.text = "Salary: $%d/turn" % salary_val
	salary_label.add_theme_font_size_override("font_size", 16)
	salary_label.add_theme_color_override("font_color", COLOR_MUTED)
	vbox.add_child(salary_label)

	var candidate_id: String = candidate.get("staff_id", "")
	var hire_btn := _make_button("Hire", COLOR_SUCCESS)
	hire_btn.pressed.connect(func(): _on_hire_pressed(candidate_id))
	var roster_full: bool = StaffManager.staff_roster.size() >= StaffManager.get_max_staff()
	if roster_full:
		hire_btn.disabled = true
	vbox.add_child(hire_btn)

	card.add_child(vbox)
	return card


# ---------------------------------------------------------------------------
# Stat bar helper
# ---------------------------------------------------------------------------

func _build_stat_bar(label_text: String, value: int, fill_color: Color) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.custom_minimum_size = Vector2(80, 0)
	lbl.add_theme_font_size_override("font_size", 16)
	lbl.add_theme_color_override("font_color", COLOR_MUTED)
	row.add_child(lbl)

	var bar := ProgressBar.new()
	bar.min_value = 0
	bar.max_value = 100
	bar.value = value
	bar.custom_minimum_size = Vector2(120, 16)
	bar.show_percentage = false

	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = fill_color
	fill_style.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(fill_color, 0.15)
	bg_style.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", bg_style)

	row.add_child(bar)

	var val_label := Label.new()
	val_label.text = str(value)
	val_label.add_theme_font_size_override("font_size", 16)
	val_label.add_theme_color_override("font_color", fill_color)
	row.add_child(val_label)

	return row


# ---------------------------------------------------------------------------
# Button helper
# ---------------------------------------------------------------------------

func _make_button(text: String, color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(80, 32)
	btn.add_theme_font_size_override("font_size", 14)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(color, 0.2)
	style.border_color = Color(color, 0.6)
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_color_override("font_color", color)
	return btn


# ---------------------------------------------------------------------------
# Assign Phase Dialog
# ---------------------------------------------------------------------------

func _show_assign_dialog(staff_id: String) -> void:
	var overlay := _create_dialog_overlay()
	var parts: Array = _create_dialog_panel(Vector2(280, 250))
	var center: CenterContainer = parts[0]
	var panel: PanelContainer = parts[1]

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 8)

	var header := Label.new()
	header.text = "ASSIGN TO PHASE"
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color.WHITE)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	var phases: Array[String] = ["mashing", "boiling", "fermenting"]
	for phase in phases:
		var phase_btn := _make_button(phase.capitalize(), COLOR_PRIMARY)
		phase_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var current_assignee: Dictionary = StaffManager.get_staff_assigned_to(phase)
		if not current_assignee.is_empty():
			var assignee_name: String = current_assignee.get("staff_name", "")
			var assignee_id: String = current_assignee.get("staff_id", "")
			if assignee_id != staff_id:
				phase_btn.text = "%s (current: %s)" % [phase.capitalize(), assignee_name]
		phase_btn.pressed.connect(func():
			StaffManager.assign_to_phase(staff_id, phase)
			overlay.queue_free()
			_refresh()
		)
		vbox.add_child(phase_btn)

	var unassign_btn := _make_button("Unassign", COLOR_MUTED)
	unassign_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	unassign_btn.pressed.connect(func():
		StaffManager.assign_to_phase(staff_id, "")
		overlay.queue_free()
		_refresh()
	)
	vbox.add_child(unassign_btn)

	var cancel_btn := _make_button("Cancel", COLOR_MUTED)
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.pressed.connect(func(): overlay.queue_free())
	vbox.add_child(cancel_btn)

	panel.add_child(vbox)
	overlay.add_child(center)
	add_child(overlay)


# ---------------------------------------------------------------------------
# Training Dialog
# ---------------------------------------------------------------------------

func _show_training_dialog(staff_id: String) -> void:
	var staff: Dictionary = StaffManager._find_staff(staff_id)
	if staff.is_empty():
		return

	var overlay := _create_dialog_overlay()
	var parts: Array = _create_dialog_panel(Vector2(360, 300))
	var center: CenterContainer = parts[0]
	var panel: PanelContainer = parts[1]

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 8)

	var staff_name: String = staff.get("staff_name", "Unknown")
	var header := Label.new()
	header.text = "TRAIN STAFF: %s" % staff_name
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color.WHITE)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	var creativity_btn := _make_button("Creativity Training $%d" % StaffManager.TRAINING_COST, COLOR_ACCENT)
	creativity_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	creativity_btn.pressed.connect(func():
		StaffManager.start_training(staff_id, "creativity")
		overlay.queue_free()
		_refresh()
	)
	vbox.add_child(creativity_btn)

	var creativity_caption := Label.new()
	creativity_caption.text = "+%d-%d creativity points" % [StaffManager.TRAINING_STAT_GAIN_MIN, StaffManager.TRAINING_STAT_GAIN_MAX]
	creativity_caption.add_theme_font_size_override("font_size", 14)
	creativity_caption.add_theme_color_override("font_color", COLOR_MUTED)
	creativity_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(creativity_caption)

	var precision_btn := _make_button("Precision Training $%d" % StaffManager.TRAINING_COST, COLOR_PRIMARY)
	precision_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	precision_btn.pressed.connect(func():
		StaffManager.start_training(staff_id, "precision")
		overlay.queue_free()
		_refresh()
	)
	vbox.add_child(precision_btn)

	var precision_caption := Label.new()
	precision_caption.text = "+%d-%d precision points" % [StaffManager.TRAINING_STAT_GAIN_MIN, StaffManager.TRAINING_STAT_GAIN_MAX]
	precision_caption.add_theme_font_size_override("font_size", 14)
	precision_caption.add_theme_color_override("font_color", COLOR_MUTED)
	precision_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(precision_caption)

	var warning := Label.new()
	warning.text = "Staff unavailable for 1 turn."
	warning.add_theme_font_size_override("font_size", 14)
	warning.add_theme_color_override("font_color", COLOR_WARNING)
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(warning)

	var cancel_btn := _make_button("Cancel", COLOR_MUTED)
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.pressed.connect(func(): overlay.queue_free())
	vbox.add_child(cancel_btn)

	panel.add_child(vbox)
	overlay.add_child(center)
	add_child(overlay)


# ---------------------------------------------------------------------------
# Specialization Dialog
# ---------------------------------------------------------------------------

func _show_specialization_dialog(staff_id: String) -> void:
	var staff: Dictionary = StaffManager._find_staff(staff_id)
	if staff.is_empty():
		return

	var overlay := _create_dialog_overlay()
	var parts: Array = _create_dialog_panel(Vector2(360, 350))
	var center: CenterContainer = parts[0]
	var panel: PanelContainer = parts[1]

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 8)

	var staff_name: String = staff.get("staff_name", "Unknown")
	var header := Label.new()
	header.text = "SPECIALIZE: %s (Level 5!)" % staff_name
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", Color.WHITE)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(header)

	var desc := Label.new()
	desc.text = "2x bonus in chosen phase, 0.5x in others."
	desc.add_theme_font_size_override("font_size", 14)
	desc.add_theme_color_override("font_color", COLOR_MUTED)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(desc)

	var phases: Dictionary = {
		"mashing": "Mashing Specialist",
		"boiling": "Boiling Specialist",
		"fermenting": "Fermenting Specialist",
	}
	for phase_key in phases:
		var phase_label: String = phases[phase_key]
		var phase_btn := _make_button(phase_label, COLOR_ACCENT)
		phase_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		phase_btn.pressed.connect(func():
			_show_specialization_confirm(staff_id, phase_key, phase_label, overlay)
		)
		vbox.add_child(phase_btn)

	var danger_label := Label.new()
	danger_label.text = "This cannot be undone!"
	danger_label.add_theme_font_size_override("font_size", 14)
	danger_label.add_theme_color_override("font_color", COLOR_DANGER)
	danger_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(danger_label)

	var cancel_btn := _make_button("Cancel", COLOR_MUTED)
	cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_btn.pressed.connect(func(): overlay.queue_free())
	vbox.add_child(cancel_btn)

	panel.add_child(vbox)
	overlay.add_child(center)
	add_child(overlay)


func _show_specialization_confirm(staff_id: String, phase: String, phase_label: String, parent_overlay: Control) -> void:
	var dlg := ConfirmationDialog.new()
	dlg.title = "Confirm Specialization"
	dlg.dialog_text = "Are you sure? This is permanent.\n\nSpecialize as %s?" % phase_label
	add_child(dlg)
	dlg.popup_centered()
	dlg.confirmed.connect(func():
		StaffManager.specialize(staff_id, phase)
		dlg.queue_free()
		parent_overlay.queue_free()
		_refresh()
	)
	dlg.canceled.connect(func(): dlg.queue_free())


# ---------------------------------------------------------------------------
# Hire / Fire
# ---------------------------------------------------------------------------

func _on_hire_pressed(candidate_id: String) -> void:
	StaffManager.hire(candidate_id)
	_refresh()


func _on_fire_pressed(staff_id: String) -> void:
	var staff: Dictionary = StaffManager._find_staff(staff_id)
	var staff_name: String = staff.get("staff_name", "Unknown")

	var dlg := ConfirmationDialog.new()
	dlg.title = "Fire Staff"
	dlg.dialog_text = "Fire %s? This cannot be undone." % staff_name
	add_child(dlg)
	dlg.popup_centered()
	dlg.confirmed.connect(func():
		StaffManager.fire(staff_id)
		dlg.queue_free()
		_refresh()
	)
	dlg.canceled.connect(func(): dlg.queue_free())


# ---------------------------------------------------------------------------
# Dialog helpers
# ---------------------------------------------------------------------------

func _create_dialog_overlay() -> ColorRect:
	var overlay := ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.5)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	return overlay


## Returns [CenterContainer, PanelContainer] — add the center to the overlay,
## add content children to the panel.
func _create_dialog_panel(size: Vector2) -> Array:
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var panel := PanelContainer.new()
	panel.custom_minimum_size = size
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_SURFACE
	style.border_color = COLOR_PRIMARY
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)

	return [center, panel]


# ---------------------------------------------------------------------------
# Close / dim
# ---------------------------------------------------------------------------

func _on_close_pressed() -> void:
	visible = false
	closed.emit()


func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_on_close_pressed()
