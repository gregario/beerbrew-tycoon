extends CanvasLayer

## ForkChoiceOverlay — presents the artisan vs mass-market fork choice.
## Follows overlay architecture: CanvasLayer layer=10, CenterContainer+PRESET_FULL_RECT.

signal path_selected(path_type: String)

var _root: CenterContainer
var _confirm_dialog: PanelContainer
var _pending_choice: String = ""

func _ready() -> void:
	layer = 10
	visible = false
	_build_ui()

func _build_ui() -> void:
	_root = CenterContainer.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_PASS

	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(700, 500)
	panel.mouse_filter = Control.MOUSE_FILTER_PASS

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 16)

	# Title
	var title := Label.new()
	title.text = "Your Brewery Has Grown — Choose Your Path"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Cards container
	var cards := HBoxContainer.new()
	cards.mouse_filter = Control.MOUSE_FILTER_PASS
	cards.add_theme_constant_override("separation", 24)

	# Artisan card
	var artisan_card := _build_path_card(
		"Artisan Brewery",
		"+20% quality bonus\n50% off competition fees\nRare ingredients access\nRent: $600/cycle",
		"Win: 5 medals + 100 reputation",
		"artisan",
		Color(0.85, 0.65, 0.35)
	)
	cards.add_child(artisan_card)

	# Mass-Market card
	var mass_market_card := _build_path_card(
		"Mass-Market Brewery",
		"2x batch size\n20% ingredient discount\nAutomation equipment\nRent: $800/cycle",
		"Win: $50K revenue + all 4 channels",
		"mass_market",
		Color(0.35, 0.55, 0.75)
	)
	cards.add_child(mass_market_card)

	vbox.add_child(cards)
	panel.add_child(vbox)
	_root.add_child(panel)
	add_child(_root)

	# Confirmation dialog (hidden initially)
	_confirm_dialog = _build_confirm_dialog()
	add_child(_confirm_dialog)

func _build_path_card(title_text: String, benefits: String, win_text: String, path_type: String, accent: Color) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(300, 350)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 12)

	var name_label := Label.new()
	name_label.text = title_text
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", accent)
	vbox.add_child(name_label)

	var sep := HSeparator.new()
	vbox.add_child(sep)

	var benefits_label := Label.new()
	benefits_label.text = benefits
	benefits_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(benefits_label)

	var win_label := Label.new()
	win_label.text = win_text
	win_label.add_theme_color_override("font_color", Color(0.6, 0.8, 0.6))
	vbox.add_child(win_label)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var button := Button.new()
	button.text = "Choose This Path"
	button.pressed.connect(_on_path_button_pressed.bind(path_type))
	vbox.add_child(button)

	card.add_child(vbox)
	return card

func _build_confirm_dialog() -> PanelContainer:
	var dialog := PanelContainer.new()
	dialog.visible = false
	dialog.custom_minimum_size = Vector2(400, 200)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_PASS

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 16)

	var msg := Label.new()
	msg.name = "ConfirmMessage"
	msg.text = "Are you sure? This cannot be undone."
	msg.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(msg)

	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 16)

	var confirm_btn := Button.new()
	confirm_btn.text = "Confirm"
	confirm_btn.pressed.connect(_on_confirm)
	buttons.add_child(confirm_btn)

	var cancel_btn := Button.new()
	cancel_btn.text = "Go Back"
	cancel_btn.pressed.connect(_on_cancel)
	buttons.add_child(cancel_btn)

	vbox.add_child(buttons)
	center.add_child(vbox)
	dialog.add_child(center)
	return dialog

func show_overlay() -> void:
	visible = true

func _on_path_button_pressed(path_type: String) -> void:
	_pending_choice = path_type
	var path_name: String = "Artisan Brewery" if path_type == "artisan" else "Mass-Market Brewery"
	var msg: Label = _confirm_dialog.find_child("ConfirmMessage", true, false)
	if msg:
		msg.text = "Choose %s? This cannot be undone." % path_name
	_confirm_dialog.visible = true

func _on_confirm() -> void:
	_confirm_dialog.visible = false
	visible = false
	path_selected.emit(_pending_choice)

func _on_cancel() -> void:
	_confirm_dialog.visible = false
	_pending_choice = ""
