extends CanvasLayer

## RunStartOverlay — perk and modifier selection before starting a new run.
## Follows overlay architecture: CanvasLayer layer=10, CenterContainer+PRESET_FULL_RECT.

signal run_started

var _root: CenterContainer
var _perks_container: HBoxContainer
var _perks_label: Label
var _challenge_container: VBoxContainer
var _bonus_container: VBoxContainer
var _modifiers_label: Label
var _start_btn: Button
var _meta: Node

var _selected_perks: Array[String] = []
var _selected_modifiers: Array[String] = []
var _perk_buttons: Dictionary = {}
var _modifier_buttons: Dictionary = {}

const META_COLOR: Color = Color("#B88AFF")
const ACCENT_COLOR: Color = Color("#FFC857")
const SUCCESS_COLOR: Color = Color("#5EE8A4")
const MUTED_COLOR: Color = Color("#8A9BB1")
const SURFACE_COLOR: Color = Color("#0B1220")
const BG_BORDER_COLOR: Color = Color("#8A9BB1")
const DANGER_COLOR: Color = Color("#FF7B7B")
const BTN_TEXT_COLOR: Color = Color(0.1, 0.1, 0.1)

const MAX_PERKS: int = 3
const MAX_MODIFIERS: int = 2

const MODIFIER_DEFS: Dictionary = {
	"tough_market": {"name": "Tough Market", "description": "Demand -20%", "type": "challenge"},
	"budget_brewery": {"name": "Budget Brewery", "description": "Half starting cash", "type": "challenge"},
	"ingredient_shortage": {"name": "Ingredient Shortage", "description": "60% ingredients", "type": "challenge"},
	"master_brewer": {"name": "Master Brewer", "description": "+10% quality", "type": "bonus"},
	"lucky_break": {"name": "Lucky Break", "description": "No infection (5 brews)", "type": "bonus"},
	"generous_market": {"name": "Generous Market", "description": "+20% demand", "type": "bonus"},
}

const PERK_DEFS: Dictionary = {
	"nest_egg": {"name": "Nest Egg", "description": "+5% starting cash ($525)"},
	"quick_study": {"name": "Quick Study", "description": "+1 base RP per brew"},
	"landlords_friend": {"name": "Landlord's Friend", "description": "-10% rent costs"},
	"style_specialist": {"name": "Style Specialist", "description": "+5% quality for one style family"},
}

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
	card.custom_minimum_size = Vector2(900, 600)
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

	# --- Perks Section ---
	_perks_label = Label.new()
	_perks_label.text = "ACTIVE PERKS (0/3)"
	_perks_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_perks_label.add_theme_font_size_override("font_size", 24)
	_perks_label.add_theme_color_override("font_color", META_COLOR)
	vbox.add_child(_perks_label)

	_perks_container = HBoxContainer.new()
	_perks_container.mouse_filter = Control.MOUSE_FILTER_PASS
	_perks_container.add_theme_constant_override("separation", 12)
	vbox.add_child(_perks_container)

	# Separator
	vbox.add_child(HSeparator.new())

	# --- Modifiers Section ---
	_modifiers_label = Label.new()
	_modifiers_label.text = "MODIFIERS (0/2)"
	_modifiers_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_modifiers_label.add_theme_font_size_override("font_size", 24)
	_modifiers_label.add_theme_color_override("font_color", ACCENT_COLOR)
	vbox.add_child(_modifiers_label)

	var mod_columns: HBoxContainer = HBoxContainer.new()
	mod_columns.mouse_filter = Control.MOUSE_FILTER_PASS
	mod_columns.add_theme_constant_override("separation", 24)
	mod_columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Challenge column
	var challenge_panel: PanelContainer = PanelContainer.new()
	challenge_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	challenge_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var challenge_style: StyleBoxFlat = StyleBoxFlat.new()
	challenge_style.bg_color = Color(SURFACE_COLOR, 0.5)
	challenge_style.border_color = DANGER_COLOR
	challenge_style.set_border_width_all(1)
	challenge_style.set_corner_radius_all(4)
	challenge_style.set_content_margin_all(12)
	challenge_panel.add_theme_stylebox_override("panel", challenge_style)

	_challenge_container = VBoxContainer.new()
	_challenge_container.mouse_filter = Control.MOUSE_FILTER_PASS
	_challenge_container.add_theme_constant_override("separation", 8)
	var challenge_title: Label = Label.new()
	challenge_title.text = "Challenge"
	challenge_title.add_theme_font_size_override("font_size", 18)
	challenge_title.add_theme_color_override("font_color", DANGER_COLOR)
	_challenge_container.add_child(challenge_title)
	challenge_panel.add_child(_challenge_container)
	mod_columns.add_child(challenge_panel)

	# Bonus column
	var bonus_panel: PanelContainer = PanelContainer.new()
	bonus_panel.mouse_filter = Control.MOUSE_FILTER_PASS
	bonus_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var bonus_style: StyleBoxFlat = StyleBoxFlat.new()
	bonus_style.bg_color = Color(SURFACE_COLOR, 0.5)
	bonus_style.border_color = SUCCESS_COLOR
	bonus_style.set_border_width_all(1)
	bonus_style.set_corner_radius_all(4)
	bonus_style.set_content_margin_all(12)
	bonus_panel.add_theme_stylebox_override("panel", bonus_style)

	_bonus_container = VBoxContainer.new()
	_bonus_container.mouse_filter = Control.MOUSE_FILTER_PASS
	_bonus_container.add_theme_constant_override("separation", 8)
	var bonus_title: Label = Label.new()
	bonus_title.text = "Bonus"
	bonus_title.add_theme_font_size_override("font_size", 18)
	bonus_title.add_theme_color_override("font_color", SUCCESS_COLOR)
	_bonus_container.add_child(bonus_title)
	bonus_panel.add_child(_bonus_container)
	mod_columns.add_child(bonus_panel)

	vbox.add_child(mod_columns)

	# Spacer
	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Start button
	_start_btn = Button.new()
	_start_btn.text = "Start Brewing!"
	_start_btn.custom_minimum_size = Vector2(240, 48)
	_start_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = ACCENT_COLOR
	btn_style.set_corner_radius_all(4)
	btn_style.set_content_margin_all(8)
	_start_btn.add_theme_stylebox_override("normal", btn_style)
	_start_btn.add_theme_color_override("font_color", BTN_TEXT_COLOR)
	_start_btn.pressed.connect(_on_start_pressed)
	vbox.add_child(_start_btn)

	card.add_child(vbox)
	_root.add_child(card)
	add_child(_root)

func show_setup(meta: Node) -> void:
	_meta = meta
	_selected_perks.clear()
	_selected_modifiers.clear()
	_perk_buttons.clear()
	_modifier_buttons.clear()
	_rebuild_perks()
	_rebuild_modifiers()
	_update_labels()
	visible = true

func _rebuild_perks() -> void:
	for child in _perks_container.get_children():
		child.queue_free()
	_perk_buttons.clear()

	if not _meta:
		return

	var unlocked: Array = _meta.unlocked_perks
	for perk_id in unlocked:
		if not PERK_DEFS.has(perk_id):
			continue
		var def: Dictionary = PERK_DEFS[perk_id]
		var card: PanelContainer = PanelContainer.new()
		card.custom_minimum_size = Vector2(180, 120)
		card.mouse_filter = Control.MOUSE_FILTER_PASS

		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.bg_color = SURFACE_COLOR
		style.border_color = MUTED_COLOR
		style.set_border_width_all(2)
		style.set_corner_radius_all(4)
		style.set_content_margin_all(8)
		card.add_theme_stylebox_override("panel", style)

		var inner: VBoxContainer = VBoxContainer.new()
		inner.mouse_filter = Control.MOUSE_FILTER_PASS
		inner.add_theme_constant_override("separation", 4)

		var name_label: Label = Label.new()
		name_label.text = def["name"]
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inner.add_child(name_label)

		var desc_label: Label = Label.new()
		desc_label.text = def["description"]
		desc_label.add_theme_font_size_override("font_size", 14)
		desc_label.add_theme_color_override("font_color", MUTED_COLOR)
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		inner.add_child(desc_label)

		var toggle_btn: Button = Button.new()
		toggle_btn.text = "OFF"
		toggle_btn.pressed.connect(_toggle_perk.bind(perk_id))
		inner.add_child(toggle_btn)

		card.add_child(inner)
		_perks_container.add_child(card)
		_perk_buttons[perk_id] = {"button": toggle_btn, "style": style}

func _rebuild_modifiers() -> void:
	# Clear existing modifier rows (keep the title labels)
	for child in _challenge_container.get_children():
		if child is Button:
			child.queue_free()
	for child in _bonus_container.get_children():
		if child is Button:
			child.queue_free()
	_modifier_buttons.clear()

	if not _meta:
		return

	for mod_id in MODIFIER_DEFS:
		var def: Dictionary = MODIFIER_DEFS[mod_id]
		var is_unlocked: bool = _meta.is_modifier_unlocked(mod_id)

		var btn: Button = Button.new()
		if is_unlocked:
			btn.text = "%s — %s" % [def["name"], def["description"]]
			btn.pressed.connect(_toggle_modifier.bind(mod_id))
		else:
			btn.text = "%s — LOCKED" % def["name"]
			btn.disabled = true
			btn.add_theme_color_override("font_color", Color(MUTED_COLOR, 0.5))

		if def["type"] == "challenge":
			_challenge_container.add_child(btn)
		else:
			_bonus_container.add_child(btn)

		_modifier_buttons[mod_id] = btn

func _toggle_perk(perk_id: String) -> void:
	if perk_id in _selected_perks:
		_selected_perks.erase(perk_id)
	else:
		if _selected_perks.size() >= MAX_PERKS:
			return
		_selected_perks.append(perk_id)
	_update_perk_visuals()
	_update_labels()

func _toggle_modifier(modifier_id: String) -> void:
	if modifier_id in _selected_modifiers:
		_selected_modifiers.erase(modifier_id)
	else:
		if _selected_modifiers.size() >= MAX_MODIFIERS:
			return
		_selected_modifiers.append(modifier_id)
	_update_modifier_visuals()
	_update_labels()

func _update_labels() -> void:
	_perks_label.text = "ACTIVE PERKS (%d/3)" % _selected_perks.size()
	_modifiers_label.text = "MODIFIERS (%d/2)" % _selected_modifiers.size()

func _update_perk_visuals() -> void:
	for perk_id in _perk_buttons:
		var data: Dictionary = _perk_buttons[perk_id]
		var btn: Button = data["button"]
		var style: StyleBoxFlat = data["style"]
		if perk_id in _selected_perks:
			btn.text = "ON"
			style.border_color = SUCCESS_COLOR
		else:
			btn.text = "OFF"
			style.border_color = MUTED_COLOR

func _update_modifier_visuals() -> void:
	for mod_id in _modifier_buttons:
		var btn: Button = _modifier_buttons[mod_id]
		if btn.disabled:
			continue
		var def: Dictionary = MODIFIER_DEFS[mod_id]
		if mod_id in _selected_modifiers:
			btn.text = "[X] %s — %s" % [def["name"], def["description"]]
		else:
			btn.text = "%s — %s" % [def["name"], def["description"]]

func _on_start_pressed() -> void:
	if _meta:
		var perks_typed: Array[String] = []
		perks_typed.assign(_selected_perks)
		var mods_typed: Array[String] = []
		mods_typed.assign(_selected_modifiers)
		_meta.set_active_perks(perks_typed)
		_meta.set_active_modifiers(mods_typed)
	visible = false
	run_started.emit()
