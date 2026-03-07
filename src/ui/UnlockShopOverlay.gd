extends CanvasLayer

## UnlockShopOverlay — tabbed shop for spending unlock points.
## Follows overlay architecture: CanvasLayer layer=10, CenterContainer+PRESET_FULL_RECT.

signal done_pressed

var _root: CenterContainer
var _points_label: Label
var _tab_buttons: Array = []
var _content_scroll: ScrollContainer
var _content_grid: GridContainer
var _meta: Node
var _current_tab: String = "styles"

const TAB_NAMES: Array = ["Styles", "Blueprints", "Ingredients", "Perks"]
const TAB_KEYS: Array = ["styles", "blueprints", "ingredients", "perks"]

const META_COLOR: Color = Color("#B88AFF")
const PRIMARY_COLOR: Color = Color("#5AA9FF")
const SUCCESS_COLOR: Color = Color("#5EE8A4")
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

	# Header: title + points
	var header: HBoxContainer = HBoxContainer.new()
	header.mouse_filter = Control.MOUSE_FILTER_PASS

	var title: Label = Label.new()
	title.text = "UNLOCK SHOP"
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_points_label = Label.new()
	_points_label.add_theme_font_size_override("font_size", 24)
	_points_label.add_theme_color_override("font_color", META_COLOR)
	_points_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(_points_label)

	vbox.add_child(header)

	# Tab bar
	var tab_bar: HBoxContainer = HBoxContainer.new()
	tab_bar.mouse_filter = Control.MOUSE_FILTER_PASS
	tab_bar.add_theme_constant_override("separation", 8)

	for i in range(TAB_NAMES.size()):
		var tab_btn: Button = Button.new()
		tab_btn.text = TAB_NAMES[i]
		tab_btn.custom_minimum_size = Vector2(150, 44)
		tab_btn.pressed.connect(_on_tab_pressed.bind(TAB_KEYS[i]))
		_tab_buttons.append(tab_btn)
		tab_bar.add_child(tab_btn)

	vbox.add_child(tab_bar)

	# Content area
	_content_scroll = ScrollContainer.new()
	_content_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	_content_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_content_scroll.custom_minimum_size = Vector2(0, 300)

	_content_grid = GridContainer.new()
	_content_grid.columns = 3
	_content_grid.mouse_filter = Control.MOUSE_FILTER_PASS
	_content_grid.add_theme_constant_override("h_separation", 16)
	_content_grid.add_theme_constant_override("v_separation", 16)

	_content_scroll.add_child(_content_grid)
	vbox.add_child(_content_scroll)

	# Done button
	var done_btn: Button = Button.new()
	done_btn.text = "Done"
	done_btn.custom_minimum_size = Vector2(240, 48)
	done_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var btn_style: StyleBoxFlat = StyleBoxFlat.new()
	btn_style.bg_color = PRIMARY_COLOR
	btn_style.set_corner_radius_all(4)
	btn_style.set_content_margin_all(8)
	done_btn.add_theme_stylebox_override("normal", btn_style)
	done_btn.add_theme_color_override("font_color", BTN_TEXT_COLOR)
	done_btn.pressed.connect(_on_done_pressed)
	vbox.add_child(done_btn)

	card.add_child(vbox)
	_root.add_child(card)
	add_child(_root)

func show_shop(meta: Node) -> void:
	_meta = meta
	_current_tab = "styles"
	_refresh()
	visible = true

func _refresh() -> void:
	if not _meta:
		return
	_points_label.text = "Available: %d UP" % _meta.available_points
	_update_tab_styles()
	_populate_grid()

func _update_tab_styles() -> void:
	for i in range(_tab_buttons.size()):
		var btn: Button = _tab_buttons[i]
		var style: StyleBoxFlat = StyleBoxFlat.new()
		style.set_corner_radius_all(4)
		style.set_content_margin_all(8)
		if TAB_KEYS[i] == _current_tab:
			style.bg_color = PRIMARY_COLOR
			btn.add_theme_color_override("font_color", BTN_TEXT_COLOR)
		else:
			style.bg_color = SURFACE_COLOR
			style.border_color = MUTED_COLOR
			style.set_border_width_all(1)
			btn.add_theme_color_override("font_color", MUTED_COLOR)
		btn.add_theme_stylebox_override("normal", style)

func _populate_grid() -> void:
	# Clear existing cards
	for child in _content_grid.get_children():
		child.queue_free()

	var catalog: Dictionary = _meta.get_unlock_catalog()
	var items: Array = catalog.get(_current_tab, [])

	for item in items:
		var item_card: PanelContainer = _build_item_card(item)
		_content_grid.add_child(item_card)

func _build_item_card(item: Dictionary) -> PanelContainer:
	var card: PanelContainer = PanelContainer.new()
	card.custom_minimum_size = Vector2(250, 220)
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var card_style: StyleBoxFlat = StyleBoxFlat.new()
	card_style.bg_color = SURFACE_COLOR
	card_style.border_color = MUTED_COLOR
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(4)
	card_style.set_content_margin_all(16)
	card.add_theme_stylebox_override("panel", card_style)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 8)

	# Name
	var name_label: Label = Label.new()
	name_label.text = item.get("name", "")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(name_label)

	# Description
	var desc_label: Label = Label.new()
	desc_label.text = item.get("description", "")
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", MUTED_COLOR)
	vbox.add_child(desc_label)

	# Spacer
	var spacer: Control = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	var item_id: String = item.get("id", "")
	var cost: int = item.get("cost", 0)
	var is_unlocked: bool = _meta.is_unlocked(_current_tab, item_id)

	# Cost label
	var cost_label: Label = Label.new()
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cost_label.add_theme_font_size_override("font_size", 20)
	if is_unlocked:
		cost_label.text = "UNLOCKED"
		cost_label.add_theme_color_override("font_color", SUCCESS_COLOR)
	elif cost > _meta.available_points:
		cost_label.text = "%d UP" % cost
		cost_label.add_theme_color_override("font_color", MUTED_COLOR)
	else:
		cost_label.text = "%d UP" % cost
		cost_label.add_theme_color_override("font_color", META_COLOR)
	vbox.add_child(cost_label)

	if not is_unlocked:
		var unlock_btn: Button = Button.new()
		unlock_btn.text = "Unlock"
		unlock_btn.custom_minimum_size = Vector2(150, 44)
		unlock_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		var btn_style: StyleBoxFlat = StyleBoxFlat.new()
		btn_style.set_corner_radius_all(4)
		btn_style.set_content_margin_all(8)
		if cost <= _meta.available_points:
			btn_style.bg_color = PRIMARY_COLOR
			unlock_btn.add_theme_color_override("font_color", BTN_TEXT_COLOR)
		else:
			btn_style.bg_color = MUTED_COLOR
			unlock_btn.disabled = true
		unlock_btn.add_theme_stylebox_override("normal", btn_style)
		unlock_btn.pressed.connect(_on_unlock_pressed.bind(item_id, cost))
		vbox.add_child(unlock_btn)

	card.add_child(vbox)
	return card

func _on_tab_pressed(tab_key: String) -> void:
	_current_tab = tab_key
	_refresh()

func _on_unlock_pressed(item_id: String, cost: int) -> void:
	if not _meta:
		return
	var success: bool = false
	match _current_tab:
		"styles":
			success = _meta.unlock_style(item_id, cost)
		"blueprints":
			success = _meta.unlock_blueprint(item_id, cost)
		"ingredients":
			success = _meta.unlock_ingredient(item_id, cost)
		"perks":
			success = _meta.unlock_perk(item_id, cost)
	if success:
		_refresh()

func _on_done_pressed() -> void:
	visible = false
	done_pressed.emit()
