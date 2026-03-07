extends CanvasLayer

## ConditioningOverlay — post-brew overlay where the player chooses 0-4 weeks
## of conditioning to reduce off-flavors and gain a small quality bonus.
## Cost: weeks * rent/4. Quality bonus: +1% per week (flat). Off-flavor decay
## applies per-type rates from FailureSystem.DECAY_RATES.

signal conditioning_confirmed(weeks: int)

var _selected_weeks: int = 0

# UI references
var _week_buttons: Array = []  # Array of Button
var _off_flavor_rows: Dictionary = {}  # {type: {current_label, preview_label}}
var _quality_current_label: Label = null
var _quality_preview_label: Label = null
var _cost_label: Label = null
var _confirm_btn: Button = null


func _ready() -> void:
	layer = 10
	visible = false


## Show the conditioning overlay with data from the last brew result.
func show_overlay() -> void:
	_selected_weeks = 0
	_build_ui()
	visible = true


func _build_ui() -> void:
	for child in get_children():
		child.queue_free()
	_week_buttons.clear()
	_off_flavor_rows.clear()

	# Dim background
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	# Center panel
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.custom_minimum_size = Vector2(800, 500)
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("#0B1220")
	panel_style.border_color = Color("#FFC857")
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(4)
	panel_style.set_content_margin_all(32)
	panel.add_theme_stylebox_override("panel", panel_style)
	center.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	# Header
	var header := HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_child(header)
	var title := Label.new()
	title.text = "CONDITIONING"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	# Beer name / style
	var style_name: String = GameState.current_style.style_name if GameState.current_style else "Unknown"
	var style_label := Label.new()
	style_label.text = style_name
	style_label.add_theme_font_size_override("font_size", 20)
	style_label.add_theme_color_override("font_color", Color("#8A9BB1"))
	header.add_child(style_label)

	vbox.add_child(HSeparator.new())

	# Description
	var desc := Label.new()
	desc.text = "Condition your beer to reduce off-flavors and improve quality."
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color("#8A9BB1"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	# Week selector
	var week_row := HBoxContainer.new()
	week_row.mouse_filter = Control.MOUSE_FILTER_PASS
	week_row.add_theme_constant_override("separation", 12)
	week_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(week_row)

	var week_label := Label.new()
	week_label.text = "Weeks: "
	week_label.add_theme_font_size_override("font_size", 20)
	week_label.add_theme_color_override("font_color", Color.WHITE)
	week_row.add_child(week_label)

	for i in range(5):  # 0-4 weeks
		var btn := Button.new()
		btn.text = str(i)
		btn.custom_minimum_size = Vector2(60, 40)
		btn.pressed.connect(_on_week_selected.bind(i))
		_week_buttons.append(btn)
		week_row.add_child(btn)

	_update_week_button_styles()

	# Off-flavor decay preview section
	var intensities: Dictionary = GameState.last_brew_result.get("off_flavor_intensities", {})
	if not intensities.is_empty():
		var flavor_section_label := Label.new()
		flavor_section_label.text = "OFF-FLAVOR DECAY:"
		flavor_section_label.add_theme_font_size_override("font_size", 18)
		flavor_section_label.add_theme_color_override("font_color", Color("#FFB347"))
		vbox.add_child(flavor_section_label)

		var flavor_box := _add_info_box(vbox, Color("#FFB347"))
		for off_flavor_type in intensities:
			var intensity: float = intensities[off_flavor_type]
			if intensity <= 0.0:
				continue
			var row := HBoxContainer.new()
			row.mouse_filter = Control.MOUSE_FILTER_PASS
			row.add_theme_constant_override("separation", 8)
			flavor_box.add_child(row)

			var display_name: String = _get_off_flavor_display_name(off_flavor_type)
			var name_label := Label.new()
			name_label.text = display_name
			name_label.add_theme_font_size_override("font_size", 16)
			name_label.add_theme_color_override("font_color", Color.WHITE)
			name_label.custom_minimum_size = Vector2(140, 0)
			row.add_child(name_label)

			var current_label := Label.new()
			current_label.text = "%.2f" % intensity
			current_label.add_theme_font_size_override("font_size", 16)
			current_label.add_theme_color_override("font_color", _intensity_color(intensity))
			current_label.custom_minimum_size = Vector2(60, 0)
			row.add_child(current_label)

			var arrow := Label.new()
			arrow.text = " -> "
			arrow.add_theme_font_size_override("font_size", 16)
			arrow.add_theme_color_override("font_color", Color("#8A9BB1"))
			row.add_child(arrow)

			var preview_label := Label.new()
			preview_label.text = "%.2f" % intensity
			preview_label.add_theme_font_size_override("font_size", 16)
			preview_label.add_theme_color_override("font_color", _intensity_color(intensity))
			preview_label.custom_minimum_size = Vector2(60, 0)
			row.add_child(preview_label)

			var severity_label := Label.new()
			severity_label.text = "(%s)" % FailureSystem.get_severity_label(intensity)
			severity_label.add_theme_font_size_override("font_size", 14)
			severity_label.add_theme_color_override("font_color", Color("#8A9BB1"))
			row.add_child(severity_label)

			_off_flavor_rows[off_flavor_type] = {
				"current_label": current_label,
				"preview_label": preview_label,
				"severity_label": severity_label,
			}
	else:
		var no_flavors := Label.new()
		no_flavors.text = "No off-flavors detected. Conditioning will only add a quality bonus."
		no_flavors.add_theme_font_size_override("font_size", 16)
		no_flavors.add_theme_color_override("font_color", Color("#5EE8A4"))
		vbox.add_child(no_flavors)

	# Quality bonus preview
	var quality_row := HBoxContainer.new()
	quality_row.mouse_filter = Control.MOUSE_FILTER_PASS
	quality_row.add_theme_constant_override("separation", 12)
	vbox.add_child(quality_row)

	var q_label := Label.new()
	q_label.text = "Quality:"
	q_label.add_theme_font_size_override("font_size", 18)
	q_label.add_theme_color_override("font_color", Color.WHITE)
	quality_row.add_child(q_label)

	var current_score: float = GameState.last_brew_result.get("final_score", 0.0)
	_quality_current_label = Label.new()
	_quality_current_label.text = "%d" % int(current_score)
	_quality_current_label.add_theme_font_size_override("font_size", 18)
	_quality_current_label.add_theme_color_override("font_color", Color.WHITE)
	quality_row.add_child(_quality_current_label)

	var q_arrow := Label.new()
	q_arrow.text = " -> "
	q_arrow.add_theme_font_size_override("font_size", 18)
	q_arrow.add_theme_color_override("font_color", Color("#8A9BB1"))
	quality_row.add_child(q_arrow)

	_quality_preview_label = Label.new()
	_quality_preview_label.text = "%d" % int(current_score)
	_quality_preview_label.add_theme_font_size_override("font_size", 18)
	_quality_preview_label.add_theme_color_override("font_color", Color("#5EE8A4"))
	quality_row.add_child(_quality_preview_label)

	# Cost display
	_cost_label = Label.new()
	_cost_label.text = "Cost: $0"
	_cost_label.add_theme_font_size_override("font_size", 18)
	_cost_label.add_theme_color_override("font_color", Color.WHITE)
	vbox.add_child(_cost_label)

	# Button row
	var btn_row := HBoxContainer.new()
	btn_row.mouse_filter = Control.MOUSE_FILTER_PASS
	btn_row.add_theme_constant_override("separation", 24)
	btn_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(btn_row)

	_confirm_btn = Button.new()
	_confirm_btn.text = "Skip Conditioning"
	_confirm_btn.custom_minimum_size = Vector2(240, 48)
	_confirm_btn.pressed.connect(_on_confirm)
	var confirm_style := StyleBoxFlat.new()
	confirm_style.bg_color = Color("#FFC857")
	confirm_style.set_corner_radius_all(8)
	confirm_style.set_content_margin_all(8)
	_confirm_btn.add_theme_stylebox_override("normal", confirm_style)
	_confirm_btn.add_theme_color_override("font_color", Color("#0F1724"))
	btn_row.add_child(_confirm_btn)

	_update_preview()


func _on_week_selected(weeks: int) -> void:
	_selected_weeks = weeks
	_update_week_button_styles()
	_update_preview()


func _update_week_button_styles() -> void:
	for i in range(_week_buttons.size()):
		var btn: Button = _week_buttons[i]
		if i == _selected_weeks:
			var active_style := StyleBoxFlat.new()
			active_style.bg_color = Color("#FFC857")
			active_style.set_corner_radius_all(4)
			active_style.set_content_margin_all(4)
			btn.add_theme_stylebox_override("normal", active_style)
			btn.add_theme_color_override("font_color", Color("#0F1724"))
		else:
			# Remove overrides to use default style
			btn.remove_theme_stylebox_override("normal")
			btn.remove_theme_color_override("font_color")


func _update_preview() -> void:
	# Update off-flavor decay preview
	var intensities: Dictionary = GameState.last_brew_result.get("off_flavor_intensities", {})
	if not intensities.is_empty():
		var decayed: Dictionary = FailureSystem.apply_conditioning_decay(intensities, _selected_weeks)
		for off_flavor_type in _off_flavor_rows:
			var row_data: Dictionary = _off_flavor_rows[off_flavor_type]
			var new_intensity: float = decayed.get(off_flavor_type, 0.0)
			row_data["preview_label"].text = "%.2f" % new_intensity
			row_data["preview_label"].add_theme_color_override("font_color", _intensity_color(new_intensity))
			row_data["severity_label"].text = "(%s)" % FailureSystem.get_severity_label(new_intensity)

	# Update quality preview
	var current_score: float = GameState.last_brew_result.get("final_score", 0.0)
	var bonus: float = float(_selected_weeks) * 1.0
	var preview_score: float = minf(current_score + bonus, 100.0)
	if _quality_preview_label:
		_quality_preview_label.text = "%d (+%d%%)" % [int(preview_score), int(bonus)] if _selected_weeks > 0 else "%d" % int(current_score)

	# Update cost
	var rent: float = BreweryExpansion.get_rent_amount() if is_instance_valid(BreweryExpansion) else 150.0
	var cost: float = float(_selected_weeks) * (rent / 4.0)
	if _cost_label:
		_cost_label.text = "Cost: $%d" % int(cost)
		if cost > 0:
			_cost_label.add_theme_color_override("font_color", Color("#FFB347"))
		else:
			_cost_label.add_theme_color_override("font_color", Color.WHITE)

	# Update confirm button text
	if _confirm_btn:
		if _selected_weeks == 0:
			_confirm_btn.text = "Skip Conditioning"
		else:
			_confirm_btn.text = "Condition %d Week%s — $%d" % [_selected_weeks, "s" if _selected_weeks > 1 else "", int(cost)]


func _on_confirm() -> void:
	visible = false
	conditioning_confirmed.emit(_selected_weeks)


func _get_off_flavor_display_name(off_flavor_type: String) -> String:
	var info: Dictionary = FailureSystem.OFF_FLAVOR_INFO.get(off_flavor_type, {})
	if info.has("name"):
		return info["name"]
	return off_flavor_type.capitalize().replace("_", " ")


func _intensity_color(intensity: float) -> Color:
	if intensity <= 0.0:
		return Color("#5EE8A4")  # Green — gone
	elif intensity < 0.3:
		return Color("#8A9BB1")  # Gray — subtle
	elif intensity <= 0.6:
		return Color("#FFB347")  # Orange — noticeable
	else:
		return Color("#FF7B7B")  # Red — dominant


func _add_info_box(parent: VBoxContainer, border_color: Color) -> VBoxContainer:
	var pc := PanelContainer.new()
	pc.mouse_filter = Control.MOUSE_FILTER_PASS
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0B1220")
	style.border_color = border_color
	style.border_width_left = 2
	style.set_content_margin_all(12)
	pc.add_theme_stylebox_override("panel", style)
	parent.add_child(pc)
	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_PASS
	vb.add_theme_constant_override("separation", 4)
	pc.add_child(vb)
	return vb
