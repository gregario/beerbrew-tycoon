extends SceneTree

## Theme generator — run headlessly:
##   godot --headless --script res://assets/ui/ThemeBuilder.gd --path .
## Reads Kenney assets and design tokens to produce theme.tres.

const KENNEY_GREEN := "res://assets/ui/kenney/Green/Default/"
const KENNEY_GREY := "res://assets/ui/kenney/Grey/Default/"

func _init() -> void:
	var theme := Theme.new()

	# Fonts
	var ui_font := load("res://assets/ui/fonts/Inter-Regular.ttf") as Font
	var display_font := load("res://assets/ui/fonts/Display-Bold.ttf") as Font
	theme.default_font = ui_font
	theme.default_font_size = 20

	# --- Button ---
	var btn_normal := _make_nine_slice(KENNEY_GREEN + "button_rectangle_depth_line.png")
	var btn_hover := _make_nine_slice(KENNEY_GREEN + "button_rectangle_gloss.png")
	var btn_pressed := _make_nine_slice(KENNEY_GREEN + "button_rectangle_flat.png")
	var btn_disabled := _make_nine_slice(KENNEY_GREY + "button_rectangle_border.png")

	theme.set_stylebox("normal", "Button", btn_normal)
	theme.set_stylebox("hover", "Button", btn_hover)
	theme.set_stylebox("pressed", "Button", btn_pressed)
	theme.set_stylebox("disabled", "Button", btn_disabled)
	theme.set_font_size("font_size", "Button", 24)
	theme.set_font("font", "Button", ui_font)
	theme.set_color("font_color", "Button", Color.WHITE)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", Color(0.9, 0.9, 0.9))
	theme.set_color("font_disabled_color", "Button", Color(0.54, 0.61, 0.69))

	# --- Label ---
	theme.set_font_size("font_size", "Label", 20)
	theme.set_font("font", "Label", ui_font)
	theme.set_color("font_color", "Label", Color.WHITE)

	# --- PanelContainer (card background) ---
	var card_bg := StyleBoxFlat.new()
	card_bg.bg_color = Color(0.043, 0.071, 0.125, 0.95)
	card_bg.border_color = Color(0.541, 0.608, 0.694)
	card_bg.set_border_width_all(2)
	card_bg.set_corner_radius_all(4)
	card_bg.set_content_margin_all(32)
	theme.set_stylebox("panel", "PanelContainer", card_bg)

	# --- Panel (inner panels, summary bars) ---
	var inner_panel := StyleBoxFlat.new()
	inner_panel.bg_color = Color(0.059, 0.09, 0.141, 0.8)
	inner_panel.border_color = Color(0.541, 0.608, 0.694, 0.5)
	inner_panel.set_border_width_all(1)
	inner_panel.set_corner_radius_all(4)
	inner_panel.set_content_margin_all(16)
	theme.set_stylebox("panel", "Panel", inner_panel)

	# --- HSlider ---
	var slider_bg := StyleBoxFlat.new()
	slider_bg.bg_color = Color(0.3, 0.3, 0.4, 1.0)
	slider_bg.set_corner_radius_all(4)
	slider_bg.content_margin_top = 12
	slider_bg.content_margin_bottom = 12
	theme.set_stylebox("slider", "HSlider", slider_bg)

	var slider_fill := StyleBoxFlat.new()
	slider_fill.bg_color = Color(0.369, 0.91, 0.643)
	slider_fill.set_corner_radius_all(4)
	slider_fill.content_margin_top = 12
	slider_fill.content_margin_bottom = 12
	theme.set_stylebox("grabber_area", "HSlider", slider_fill)

	theme.set_constant("grabber_offset", "HSlider", 8)
	theme.set_constant("center_grabber", "HSlider", 0)

	# --- Container separation ---
	theme.set_constant("separation", "VBoxContainer", 16)
	theme.set_constant("separation", "HBoxContainer", 16)

	# --- HSeparator ---
	var sep_style := StyleBoxFlat.new()
	sep_style.bg_color = Color(0.541, 0.608, 0.694, 0.5)
	sep_style.content_margin_top = 1
	sep_style.content_margin_bottom = 1
	theme.set_stylebox("separator", "HSeparator", sep_style)
	theme.set_constant("separation", "HSeparator", 8)

	# Save
	var err := ResourceSaver.save(theme, "res://assets/ui/theme.tres")
	if err == OK:
		print("Theme saved to res://assets/ui/theme.tres")
	else:
		print("ERROR saving theme: ", err)

	quit()


func _make_nine_slice(path: String) -> StyleBoxTexture:
	var tex := load(path) as Texture2D
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = 6
	sb.texture_margin_right = 6
	sb.texture_margin_top = 6
	sb.texture_margin_bottom = 6
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb
