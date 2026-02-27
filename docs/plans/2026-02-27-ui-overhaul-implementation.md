# UI Design Overhaul — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Overhaul BeerBrew Tycoon from a cramped 320x180 pixel-scaled UI to a polished 1280x720 native UI with Kenney Green theme, centered card layout, and proper design system.

**Architecture:** Change viewport to 1280x720 native with `canvas_items` stretch. Build a Godot Theme resource from design tokens + Kenney Green nine-slice textures. Refactor all 5 UI screens to use a shared card layout pattern (centered panel with dim overlay). Update the brewery background scene to fill the new resolution. All existing GDScript logic and signals remain unchanged — this is a visual-only refactor.

**Tech Stack:** Godot 4.6, GDScript, GUT testing framework, Kenney UI Pack (Green theme)

**Key constraint:** All 45 existing tests must continue passing after every task. Run `make test` after each commit.

**Design doc:** `docs/plans/2026-02-27-ui-design-overhaul.md`

---

## Task 1: Update Viewport Resolution

**Files:**
- Modify: `src/project.godot:30-34`

**Step 1: Update project.godot display settings**

Change the `[display]` section from:
```ini
[display]
window/size/viewport_width=320
window/size/viewport_height=180
window/size/window_width_override=1280
window/size/window_height_override=720
window/stretch/mode="viewport"
```

To:
```ini
[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
```

Remove `window_width_override` and `window_height_override` (no longer needed — native matches display).

**Step 2: Run tests to verify nothing broke**

Run: `make test`
Expected: 45/45 tests pass (resolution change doesn't affect logic tests)

**Step 3: Commit**

```bash
git add src/project.godot
git commit -m "feat: change viewport to 1280x720 native with canvas_items stretch"
```

---

## Task 2: Update design tokens for new resolution

**Files:**
- Modify: `design/theme.json`

**Step 1: Update theme.json with new typography and spacing scales**

Replace full contents with:
```json
{
  "name": "beerbrew_tycoon_theme",
  "palette": {
    "primary": "#5AA9FF",
    "accent": "#FFC857",
    "background": "#0F1724",
    "surface": "#0B1220",
    "muted": "#8A9BB1",
    "success": "#5EE8A4",
    "danger": "#FF7B7B"
  },
  "typography": {
    "ui_font": "res://assets/ui/fonts/Inter-Regular.ttf",
    "display_font": "res://assets/ui/fonts/Display-Bold.ttf",
    "sizes": { "xs": 16, "sm": 20, "md": 24, "lg": 32, "xl": 40 },
    "hierarchy": {
      "page_title": { "size": "lg", "font": "display_font" },
      "section_header": { "size": "md", "font": "ui_font" },
      "body": { "size": "sm", "font": "ui_font" },
      "caption": { "size": "xs", "font": "ui_font" },
      "hero": { "size": "xl", "font": "display_font" }
    }
  },
  "spacing": { "xs": 8, "sm": 16, "md": 24, "lg": 32, "xl": 48 },
  "card": {
    "width": 900,
    "height": 550,
    "padding": 32,
    "corner_radius": 4,
    "border_width": 2,
    "background_opacity": 0.95,
    "dim_overlay_opacity": 0.6
  },
  "button_states": {
    "normal": "button_rectangle_depth_line.png",
    "hover": "button_rectangle_gloss.png",
    "pressed": "button_rectangle_flat.png",
    "disabled": "button_rectangle_border.png"
  }
}
```

**Step 2: Commit**

```bash
git add design/theme.json
git commit -m "feat: update design tokens for 1280x720 resolution"
```

---

## Task 3: Update BreweryScene for 1280x720

**Files:**
- Modify: `src/scenes/BreweryScene.tscn`

**Step 1: Scale all positions and sizes by 4x**

The brewery scene used hardcoded 320x180 positions. Scale everything to 1280x720:

| Node | Old Size | New Size | Old Position | New Position |
|------|----------|----------|-------------|-------------|
| Background | 320x180 | 1280x720 | (0,0) | (0,0) |
| Floor | 320x60 | 1280x240 | (0,120) | (0,480) |
| Kettle | 28x32 | 112x128 | (60,88) | (240,352) |
| KettleLabel | — | — | (52,122) | (208,488) |
| Fermenter | 24x36 | 96x144 | (130,84) | (520,336) |
| FermenterLabel | — | — | (118,122) | (472,488) |
| Bottler | 20x28 | 80x112 | (210,92) | (840,368) |
| BottlerLabel | — | — | (204,122) | (816,488) |
| Character | 12x20 | 48x80 | (148,98) | (592,392) |

Update all label font sizes from 6 to 20.

Update BreweryScene.tscn with new values for every node's `size`, `position`, and `theme_override_font_sizes/font_size`.

**Step 2: Update BreweryScene.gd kettle rest color**

In `src/scenes/BreweryScene.gd`, the `set_brewing(false)` branch sets kettle color — no change needed, color values are resolution-independent.

**Step 3: Run tests**

Run: `make test`
Expected: 45/45 pass

**Step 4: Commit**

```bash
git add src/scenes/BreweryScene.tscn
git commit -m "feat: scale BreweryScene to 1280x720"
```

---

## Task 4: Create Godot Theme Resource

**Files:**
- Create: `src/assets/ui/theme.tres`

**Step 1: Create the Theme resource file**

This is the central theme resource. It must define styles for `Button`, `Panel`, `Label`, `HSlider`, and `VBoxContainer`/`HBoxContainer`.

Create `src/assets/ui/theme.tres`:

```tres
[gd_resource type="Theme" load_steps=9 format=3]

[ext_resource type="FontFile" path="res://assets/ui/fonts/Inter-Regular.ttf" id="1_inter"]
[ext_resource type="FontFile" path="res://assets/ui/fonts/Display-Bold.ttf" id="2_display"]
[ext_resource type="Texture2D" path="res://assets/ui/kenney/Green/Default/button_rectangle_depth_line.png" id="3_btn_normal"]
[ext_resource type="Texture2D" path="res://assets/ui/kenney/Green/Default/button_rectangle_gloss.png" id="4_btn_hover"]
[ext_resource type="Texture2D" path="res://assets/ui/kenney/Green/Default/button_rectangle_flat.png" id="5_btn_pressed"]
[ext_resource type="Texture2D" path="res://assets/ui/kenney/Grey/Default/button_rectangle_border.png" id="6_btn_disabled"]
[ext_resource type="Texture2D" path="res://assets/ui/kenney/Green/Default/slide_horizontal_color_section_wide.png" id="7_slider_fill"]
[ext_resource type="Texture2D" path="res://assets/ui/kenney/Green/Default/slide_horizontal_grey_section_wide.png" id="8_slider_track"]

[resource]
default_font = ExtResource("1_inter")
default_font_size = 20

Button/font_sizes/font_size = 24
Button/fonts/font = ExtResource("1_inter")
Button/colors/font_color = Color(1, 1, 1, 1)
Button/colors/font_hover_color = Color(1, 1, 1, 1)
Button/colors/font_pressed_color = Color(0.9, 0.9, 0.9, 1)
Button/colors/font_disabled_color = Color(0.54, 0.61, 0.69, 1)

Label/font_sizes/font_size = 20
Label/fonts/font = ExtResource("1_inter")
Label/colors/font_color = Color(1, 1, 1, 1)

HSlider/styles/slider = null
HSlider/styles/grabber_area = null
HSlider/icons/grabber = null
```

**Important note:** Godot Theme .tres files for nine-slice StyleBoxTexture are complex to hand-write. The engineer should verify this loads correctly in the Godot editor and adjust as needed. The key properties are:
- Button normal/hover/pressed/disabled StyleBoxTexture using the Kenney PNGs
- Default font = Inter-Regular at 20px
- Label font color = white

If hand-editing the .tres is too fragile, an alternative approach: create a `ThemeBuilder.gd` tool script that programmatically builds the theme at editor time. See Step 2.

**Step 2: Alternative — Create ThemeBuilder tool script**

If the .tres approach is fragile, create `src/assets/ui/ThemeBuilder.gd`:

```gdscript
@tool
extends EditorScript

## Run from Editor > Run Script to generate the game theme.
## Reads Kenney assets and design tokens to produce theme.tres.

const KENNEY_GREEN := "res://assets/ui/kenney/Green/Default/"
const KENNEY_GREY := "res://assets/ui/kenney/Grey/Default/"

func _run() -> void:
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

	# --- Panel (card background) ---
	var card_bg := StyleBoxFlat.new()
	card_bg.bg_color = Color("#0B1220", 0.95)
	card_bg.border_color = Color("#8A9BB1")
	card_bg.set_border_width_all(2)
	card_bg.set_corner_radius_all(4)
	card_bg.set_content_margin_all(32)
	theme.set_stylebox("panel", "PanelContainer", card_bg)

	# --- HSlider ---
	var slider_bg := StyleBoxFlat.new()
	slider_bg.bg_color = Color(0.3, 0.3, 0.4, 1.0)
	slider_bg.set_corner_radius_all(4)
	slider_bg.content_margin_top = 12
	slider_bg.content_margin_bottom = 12
	theme.set_stylebox("slider", "HSlider", slider_bg)

	var slider_fill := StyleBoxFlat.new()
	slider_fill.bg_color = Color("#5EE8A4")
	slider_fill.set_corner_radius_all(4)
	slider_fill.content_margin_top = 12
	slider_fill.content_margin_bottom = 12
	theme.set_stylebox("grabber_area", "HSlider", slider_fill)

	theme.set_constant("grabber_offset", "HSlider", 8)
	theme.set_constant("center_grabber", "HSlider", 0)

	# --- VBoxContainer / HBoxContainer ---
	theme.set_constant("separation", "VBoxContainer", 16)
	theme.set_constant("separation", "HBoxContainer", 16)

	# Save
	var err := ResourceSaver.save(theme, "res://assets/ui/theme.tres")
	if err == OK:
		print("Theme saved to res://assets/ui/theme.tres")
	else:
		print("ERROR saving theme: ", err)


func _make_nine_slice(path: String) -> StyleBoxTexture:
	var tex := load(path) as Texture2D
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	# Kenney button assets: set margins to ~6px for nine-slice
	sb.texture_margin_left = 6
	sb.texture_margin_right = 6
	sb.texture_margin_top = 6
	sb.texture_margin_bottom = 6
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb
```

Run this in the Godot editor via Editor > Run Script to generate `theme.tres`.

**Step 3: Run tests**

Run: `make test`
Expected: 45/45 pass (new files, no behavior change)

**Step 4: Commit**

```bash
git add src/assets/ui/ThemeBuilder.gd src/assets/ui/theme.tres
git commit -m "feat: create Godot Theme resource with Kenney Green assets"
```

---

## Task 5: Create CardContainer reusable scene

**Files:**
- Create: `src/ui/CardContainer.tscn`
- Create: `src/ui/CardContainer.gd`

This is the shared layout used by all 5 UI screens: a full-screen dim overlay + centered card panel.

**Step 1: Create CardContainer.gd**

```gdscript
extends Control
## Reusable centered card with dim overlay background.
## Add children to the inner VBox via get_content_container().

@onready var dim_overlay: ColorRect = $DimOverlay
@onready var card_panel: PanelContainer = $CardPanel
@onready var content_vbox: VBoxContainer = $CardPanel/MarginContainer/VBox

func get_content_container() -> VBoxContainer:
	return content_vbox
```

**Step 2: Create CardContainer.tscn**

```
CardContainer (Control) — full-screen, anchors 0-1 all edges
├── DimOverlay (ColorRect)
│   anchors: full-screen (0-1 all edges)
│   color: Color(0.059, 0.09, 0.141, 0.6)  — background #0F1724 at 60%
├── CardPanel (PanelContainer)
│   anchors: center
│   custom_minimum_size: Vector2(900, 550)
│   offset_left: -450, offset_top: -275, offset_right: 450, offset_bottom: 275
│   theme: ExtResource (res://assets/ui/theme.tres)
│   └── MarginContainer
│       offset_all: 0 (margins come from PanelContainer stylebox)
│       └── VBox (VBoxContainer)
│           theme_override_constants/separation = 16
```

The CardPanel uses the PanelContainer stylebox from the theme (surface color, border, corner radius, 32px content margins).

**Step 3: Run tests**

Run: `make test`
Expected: 45/45 pass

**Step 4: Commit**

```bash
git add src/ui/CardContainer.tscn src/ui/CardContainer.gd
git commit -m "feat: add reusable CardContainer scene with dim overlay"
```

---

## Task 6: Redesign StylePicker

**Files:**
- Modify: `src/ui/StylePicker.tscn` (full rewrite)
- Modify: `src/ui/StylePicker.gd` (update node paths and button creation)

**Step 1: Rewrite StylePicker.tscn**

Replace the current scene with a CardContainer-based layout:

```
StylePicker (Control) — full-screen anchors
├── DimOverlay (ColorRect) — background #0F1724 at 60% opacity, full-screen
├── CardPanel (PanelContainer) — centered, 900x550, theme=theme.tres
│   └── MarginContainer
│       └── VBox (VBoxContainer, separation=16)
│           ├── HeaderRow (HBoxContainer)
│           │   ├── Title (Label) — "CHOOSE A BEER STYLE", font_size=32, Display-Bold
│           │   └── BalanceLabel (Label) — "Balance: $500", font_size=24, h_size_flags=EXPAND_FILL, h_align=RIGHT
│           ├── HSeparator
│           ├── StyleButtons (VBoxContainer, separation=12)
│           │   [dynamically populated]
│           └── FooterRow (HBoxContainer, alignment=END)
│               └── NextButton (Button) — "Design Recipe →", disabled=true, font_size=24
```

Key changes vs old:
- CardPanel replaces the old full-screen Panel
- DimOverlay added for background dimming
- Title + Balance on same row (HeaderRow HBoxContainer)
- Title uses Display-Bold at 32px
- StyleButtons separation increased to 12px
- NextButton in a right-aligned footer row

**Step 2: Update StylePicker.gd node paths**

Update `@onready` references to match new tree:
```gdscript
@onready var style_buttons_container: VBoxContainer = $CardPanel/MarginContainer/VBox/StyleButtons
@onready var next_button: Button = $CardPanel/MarginContainer/VBox/FooterRow/NextButton
@onready var title_label: Label = $CardPanel/MarginContainer/VBox/HeaderRow/Title
@onready var balance_label: Label = $CardPanel/MarginContainer/VBox/HeaderRow/BalanceLabel
```

Update `_build_ui()` to create richer style buttons:
- Each button should show the style name + demand as a label (not just button text)
- Add `custom_minimum_size.y = 60` for larger touch targets
- For HIGH DEMAND, append text in accent color or use a separate label

**Step 3: Run tests**

Run: `make test`
Expected: 45/45 pass (UI structure changed but signals/logic unchanged)

**Step 4: Commit**

```bash
git add src/ui/StylePicker.tscn src/ui/StylePicker.gd
git commit -m "feat: redesign StylePicker with card layout and Kenney theme"
```

---

## Task 7: Redesign RecipeDesigner

**Files:**
- Modify: `src/ui/RecipeDesigner.tscn` (full rewrite)
- Modify: `src/ui/RecipeDesigner.gd` (update node paths)

**Step 1: Rewrite RecipeDesigner.tscn**

```
RecipeDesigner (Control) — full-screen anchors
├── DimOverlay (ColorRect) — background at 60% opacity
├── CardPanel (PanelContainer) — centered 900x550, theme=theme.tres
│   └── MarginContainer
│       └── VBox (VBoxContainer, separation=16)
│           ├── Title (Label) — "DESIGN YOUR RECIPE", font_size=32, Display-Bold
│           ├── HSeparator
│           ├── HBox (HBoxContainer, separation=24)
│           │   ├── MaltPanel (VBoxContainer, h_size_flags=EXPAND_FILL)
│           │   │   ├── MaltTitle (Label) — "MALT", font_size=24
│           │   │   └── VBox (VBoxContainer, separation=8)
│           │   ├── HopPanel (VBoxContainer, h_size_flags=EXPAND_FILL)
│           │   │   ├── HopTitle (Label) — "HOPS", font_size=24
│           │   │   └── VBox (VBoxContainer, separation=8)
│           │   └── YeastPanel (VBoxContainer, h_size_flags=EXPAND_FILL)
│           │       ├── YeastTitle (Label) — "YEAST", font_size=24
│           │       └── VBox (VBoxContainer, separation=8)
│           ├── SummaryPanel (PanelContainer)
│           │   └── Summary (Label) — "Malt: — | Hop: — | Yeast: —", font_size=20, center
│           └── FooterRow (HBoxContainer, alignment=END)
│               └── BrewButton (Button) — "Start Brewing →", disabled=true, font_size=24
```

**Step 2: Update RecipeDesigner.gd node paths**

```gdscript
@onready var malt_container: VBoxContainer = $CardPanel/MarginContainer/VBox/HBox/MaltPanel/VBox
@onready var hop_container: VBoxContainer = $CardPanel/MarginContainer/VBox/HBox/HopPanel/VBox
@onready var yeast_container: VBoxContainer = $CardPanel/MarginContainer/VBox/HBox/YeastPanel/VBox
@onready var summary_label: Label = $CardPanel/MarginContainer/VBox/SummaryPanel/Summary
@onready var brew_button: Button = $CardPanel/MarginContainer/VBox/FooterRow/BrewButton
```

Update `_build_category()` to create buttons with `custom_minimum_size.y = 44` for proper touch targets.

**Step 3: Run tests**

Run: `make test`
Expected: 45/45 pass

**Step 4: Commit**

```bash
git add src/ui/RecipeDesigner.tscn src/ui/RecipeDesigner.gd
git commit -m "feat: redesign RecipeDesigner with card layout and columns"
```

---

## Task 8: Redesign BrewingPhases

**Files:**
- Modify: `src/ui/BrewingPhases.tscn` (full rewrite)
- Modify: `src/ui/BrewingPhases.gd` (update node paths)

**Step 1: Rewrite BrewingPhases.tscn**

```
BrewingPhases (Control) — full-screen anchors
├── DimOverlay (ColorRect) — background at 60% opacity
├── CardPanel (PanelContainer) — centered 900x550, theme=theme.tres
│   └── MarginContainer
│       └── VBox (VBoxContainer, separation=16)
│           ├── Title (Label) — "BREWING PHASES", font_size=32, Display-Bold
│           ├── HSeparator
│           ├── Hint (Label) — "Adjust effort across brewing phases.", font_size=20, autowrap
│           ├── MashingRow (VBoxContainer, separation=4)
│           │   ├── MashingTitle (Label) — "MASHING  (Technique-heavy)", font_size=24
│           │   ├── MashingSlider (HSlider) — min=0, max=100, value=50, custom_minimum_size.y=32
│           │   └── MashingValue (Label) — "50", font_size=16, h_align=CENTER
│           ├── BoilingRow (VBoxContainer, separation=4)
│           │   ├── BoilingTitle (Label) — "BOILING  (Balanced)", font_size=24
│           │   ├── BoilingSlider (HSlider) — min=0, max=100, value=50, custom_minimum_size.y=32
│           │   └── BoilingValue (Label) — "50", font_size=16, h_align=CENTER
│           ├── FermentingRow (VBoxContainer, separation=4)
│           │   ├── FermentingTitle (Label) — "FERMENTING  (Flavor-heavy)", font_size=24
│           │   ├── FermentingSlider (HSlider) — min=0, max=100, value=50, custom_minimum_size.y=32
│           │   └── FermentingValue (Label) — "50", font_size=16, h_align=CENTER
│           ├── PreviewPanel (PanelContainer)
│           │   └── PreviewHBox (HBoxContainer, separation=32)
│           │       ├── FlavorLabel (Label) — "Flavor: 75", font_size=20
│           │       └── TechniqueLabel (Label) — "Technique: 75", font_size=20
│           └── FooterRow (HBoxContainer, alignment=END)
│               └── BrewButton (Button) — "Brew!", font_size=24
```

**Step 2: Update BrewingPhases.gd**

Update node paths:
```gdscript
@onready var mashing_slider: HSlider = $CardPanel/MarginContainer/VBox/MashingRow/MashingSlider
@onready var boiling_slider: HSlider = $CardPanel/MarginContainer/VBox/BoilingRow/BoilingSlider
@onready var fermenting_slider: HSlider = $CardPanel/MarginContainer/VBox/FermentingRow/FermentingSlider
@onready var preview_label: Label = $CardPanel/MarginContainer/VBox/PreviewPanel/PreviewHBox/FlavorLabel
@onready var brew_button: Button = $CardPanel/MarginContainer/VBox/FooterRow/BrewButton
```

Note: The preview now has two separate labels. Update `_update_preview()` to set both:
```gdscript
@onready var flavor_label: Label = $CardPanel/MarginContainer/VBox/PreviewPanel/PreviewHBox/FlavorLabel
@onready var technique_label: Label = $CardPanel/MarginContainer/VBox/PreviewPanel/PreviewHBox/TechniqueLabel

func _update_preview() -> void:
    var pts: Dictionary = QualityCalculator.preview_points(_get_sliders())
    flavor_label.text = "Flavor: %d" % pts["flavor"]
    technique_label.text = "Technique: %d" % pts["technique"]
```

Also update slider value labels on change:
```gdscript
@onready var mashing_value: Label = $CardPanel/MarginContainer/VBox/MashingRow/MashingValue
@onready var boiling_value: Label = $CardPanel/MarginContainer/VBox/BoilingRow/BoilingValue
@onready var fermenting_value: Label = $CardPanel/MarginContainer/VBox/FermentingRow/FermentingValue

func _on_slider_changed() -> void:
    mashing_value.text = str(int(mashing_slider.value))
    boiling_value.text = str(int(boiling_slider.value))
    fermenting_value.text = str(int(fermenting_slider.value))
    _update_preview()
```

**Step 3: Run tests**

Run: `make test`
Expected: 45/45 pass

**Step 4: Commit**

```bash
git add src/ui/BrewingPhases.tscn src/ui/BrewingPhases.gd
git commit -m "feat: redesign BrewingPhases with card layout and larger sliders"
```

---

## Task 9: Redesign ResultsOverlay

**Files:**
- Modify: `src/ui/ResultsOverlay.tscn` (full rewrite)
- Modify: `src/ui/ResultsOverlay.gd` (update node paths and populate logic)

**Step 1: Rewrite ResultsOverlay.tscn**

```
ResultsOverlay (Control) — full-screen anchors
├── DimOverlay (ColorRect) — background at 60% opacity
├── CardPanel (PanelContainer) — centered 900x550, theme=theme.tres
│   └── MarginContainer
│       └── VBox (VBoxContainer, separation=16)
│           ├── Title (Label) — "BREW COMPLETE!", font_size=32, Display-Bold
│           ├── HSeparator
│           ├── StyleLabel (Label) — "Style: —", font_size=24
│           ├── RecipeLabel (Label) — "— · — · —", font_size=20, color=muted
│           ├── ScorePanel (PanelContainer) — centered
│           │   └── ScoreVBox (VBoxContainer, separation=4, alignment=CENTER)
│           │       ├── ScoreLabel (Label) — "78/100", font_size=40, Display-Bold, h_align=CENTER
│           │       └── StarsRow (HBoxContainer, alignment=CENTER)
│           │           [5 TextureRect nodes for star icons — populated in code]
│           ├── BreakdownGrid (GridContainer, columns=2, separation=8)
│           │   ├── RatioLabel (Label) — "Ratio: 18", font_size=20
│           │   ├── IngredientsLabel (Label) — "Ingredients: 22", font_size=20
│           │   ├── NoveltyLabel (Label) — "Novelty: 20", font_size=20
│           │   ├── EffortLabel (Label) — "Effort: 18", font_size=20
│           ├── HSeparator2
│           ├── MoneyRow (HBoxContainer)
│           │   ├── RevenueLabel (Label) — "Revenue: +$145", font_size=24, color=success
│           │   └── BalanceLabel (Label) — "Balance: $645", font_size=24, h_align=RIGHT, h_size_flags=EXPAND_FILL
│           ├── RentLabel (Label) — "", font_size=20, color=danger, visible=false
│           └── FooterRow (HBoxContainer, alignment=END)
│               └── ContinueButton (Button) — "Continue →", font_size=24
```

**Step 2: Update ResultsOverlay.gd**

Update node paths to match new tree. Update `populate()` to:
- Set individual breakdown labels (4 separate labels instead of one combined string)
- Create star TextureRect nodes in StarsRow based on score (score/20 = stars, e.g. 78/100 = 3.9 → 4 filled, 1 empty)
- Set revenue color to success green
- Set rent label color to danger red

```gdscript
@onready var style_label: Label = $CardPanel/MarginContainer/VBox/StyleLabel
@onready var recipe_label: Label = $CardPanel/MarginContainer/VBox/RecipeLabel
@onready var score_label: Label = $CardPanel/MarginContainer/VBox/ScorePanel/ScoreVBox/ScoreLabel
@onready var stars_row: HBoxContainer = $CardPanel/MarginContainer/VBox/ScorePanel/ScoreVBox/StarsRow
@onready var ratio_label: Label = $CardPanel/MarginContainer/VBox/BreakdownGrid/RatioLabel
@onready var ingredients_label: Label = $CardPanel/MarginContainer/VBox/BreakdownGrid/IngredientsLabel
@onready var novelty_label: Label = $CardPanel/MarginContainer/VBox/BreakdownGrid/NoveltyLabel
@onready var effort_label: Label = $CardPanel/MarginContainer/VBox/BreakdownGrid/EffortLabel
@onready var revenue_label: Label = $CardPanel/MarginContainer/VBox/MoneyRow/RevenueLabel
@onready var balance_label: Label = $CardPanel/MarginContainer/VBox/MoneyRow/BalanceLabel
@onready var rent_label: Label = $CardPanel/MarginContainer/VBox/RentLabel
@onready var continue_button: Button = $CardPanel/MarginContainer/VBox/FooterRow/ContinueButton

const STAR_FILLED := preload("res://assets/ui/kenney/Green/Default/star.png")
const STAR_EMPTY := preload("res://assets/ui/kenney/Green/Default/star_outline_depth.png")

func _update_stars(score: float) -> void:
    for child in stars_row.get_children():
        child.queue_free()
    var filled_count: int = int(round(score / 20.0))
    for i in range(5):
        var star := TextureRect.new()
        star.texture = STAR_FILLED if i < filled_count else STAR_EMPTY
        star.custom_minimum_size = Vector2(28, 28)
        star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
        stars_row.add_child(star)
```

**Step 3: Run tests**

Run: `make test`
Expected: 45/45 pass

**Step 4: Commit**

```bash
git add src/ui/ResultsOverlay.tscn src/ui/ResultsOverlay.gd
git commit -m "feat: redesign ResultsOverlay with hero score and star rating"
```

---

## Task 10: Redesign GameOverScreen

**Files:**
- Modify: `src/ui/GameOverScreen.tscn` (full rewrite)
- Modify: `src/ui/GameOverScreen.gd` (update node paths and populate logic)

**Step 1: Rewrite GameOverScreen.tscn**

```
GameOverScreen (Control) — full-screen anchors
├── DimOverlay (ColorRect) — background at 60% opacity
├── CardPanel (PanelContainer) — centered 900x550, theme=theme.tres
│   └── MarginContainer
│       └── VBox (VBoxContainer, separation=16)
│           ├── TitleLabel (Label) — "Game Over", font_size=40, Display-Bold, h_align=CENTER
│           ├── MessageLabel (Label) — "", font_size=20, autowrap=WORD_SMART, h_align=CENTER
│           ├── HSeparator
│           ├── StatsGrid (GridContainer, columns=2, separation=8)
│           │   ├── TurnsKeyLabel (Label) — "Turns Played", font_size=20
│           │   ├── TurnsValueLabel (Label) — "—", font_size=20, h_align=RIGHT
│           │   ├── QualityKeyLabel (Label) — "Best Quality", font_size=20
│           │   ├── QualityValueLabel (Label) — "—", font_size=20, h_align=RIGHT
│           │   ├── RevenueKeyLabel (Label) — "Total Revenue", font_size=20
│           │   ├── RevenueValueLabel (Label) — "—", font_size=20, h_align=RIGHT
│           │   ├── BalanceKeyLabel (Label) — "Final Balance", font_size=20
│           │   ├── BalanceValueLabel (Label) — "—", font_size=20, h_align=RIGHT
│           ├── HSeparator2
│           └── Buttons (HBoxContainer, alignment=CENTER, separation=24)
│               ├── NewRunButton (Button) — "New Run", font_size=24
│               └── QuitButton (Button) — "Quit", font_size=24
```

**Step 2: Update GameOverScreen.gd**

Update node paths. Update `populate()` to:
- Set title color: `success` (#5EE8A4) for win, `danger` (#FF7B7B) for loss
- Set individual stat value labels instead of multi-line string

```gdscript
@onready var title_label: Label = $CardPanel/MarginContainer/VBox/TitleLabel
@onready var message_label: Label = $CardPanel/MarginContainer/VBox/MessageLabel
@onready var turns_value: Label = $CardPanel/MarginContainer/VBox/StatsGrid/TurnsValueLabel
@onready var quality_value: Label = $CardPanel/MarginContainer/VBox/StatsGrid/QualityValueLabel
@onready var revenue_value: Label = $CardPanel/MarginContainer/VBox/StatsGrid/RevenueValueLabel
@onready var balance_value: Label = $CardPanel/MarginContainer/VBox/StatsGrid/BalanceValueLabel
@onready var new_run_button: Button = $CardPanel/MarginContainer/VBox/Buttons/NewRunButton
@onready var quit_button: Button = $CardPanel/MarginContainer/VBox/Buttons/QuitButton

func populate() -> void:
    if GameState.run_won:
        title_label.text = "BREWERY SUCCESS!"
        title_label.add_theme_color_override("font_color", Color("#5EE8A4"))
        message_label.text = "You saved $%d and built a thriving garage brewery!\nTime to upgrade..." % GameState.balance
    else:
        title_label.text = "GAME OVER"
        title_label.add_theme_color_override("font_color", Color("#FF7B7B"))
        message_label.text = "Bankrupt. The bills piled up and you ran out of cash.\nBetter luck next run."

    turns_value.text = str(GameState.turn_counter)
    quality_value.text = str(GameState.best_quality)
    revenue_value.text = "$%d" % GameState.total_revenue
    balance_value.text = "$%d" % GameState.balance
```

**Step 3: Run tests**

Run: `make test`
Expected: 45/45 pass

**Step 4: Commit**

```bash
git add src/ui/GameOverScreen.tscn src/ui/GameOverScreen.gd
git commit -m "feat: redesign GameOverScreen with card layout and structured stats"
```

---

## Task 11: Update Game.tscn and Game.gd for new layout

**Files:**
- Modify: `src/scenes/Game.tscn`
- Modify: `src/scenes/Game.gd` (if node paths changed)

**Step 1: Verify Game.tscn references**

Since each UI scene is instanced as a PackedScene, Game.tscn itself should not need structural changes — the instances load the redesigned scenes automatically. However, verify:
- All 5 UI scenes still load correctly as instances
- BreweryScene is still first in the tree (renders behind overlays)
- No node path references in Game.gd broke (all use direct child names like `$StylePicker`)

Game.gd references nodes by direct child name (`$StylePicker`, `$RecipeDesigner`, etc.) — these haven't changed, so no update needed.

**Step 2: Run tests**

Run: `make test`
Expected: 45/45 pass

**Step 3: Manual smoke test**

Open the game in Godot editor and play through:
1. Verify brewery scene fills 1280x720
2. Verify StylePicker card is centered with dim overlay
3. Verify all buttons are clickable and within screen bounds
4. Verify text is readable at all sizes
5. Verify slider interaction works in BrewingPhases
6. Verify ResultsOverlay shows star rating
7. Play through to GameOver screen

**Step 4: Commit (if any fixes needed)**

```bash
git commit -m "fix: adjust Game scene for UI overhaul compatibility"
```

---

## Task 12: Remove all hardcoded font_size overrides

**Files:**
- Modify: All 5 `.tscn` files in `src/ui/`

**Step 1: Audit remaining hardcoded theme overrides**

After tasks 6-10, some `theme_override_font_sizes/font_size` properties may still exist in scene files. Remove ALL of them — font sizes should come from the theme resource or be set via specific node classes (title nodes use Display-Bold at lg size via code).

For nodes that need non-default sizes (titles at 32px, heroes at 40px), set via GDScript in `_ready()`:
```gdscript
title_label.add_theme_font_size_override("font_size", 32)
title_label.add_theme_font_override("font", preload("res://assets/ui/fonts/Display-Bold.ttf"))
```

This keeps the .tscn files clean and the theme resource as the single source of truth.

**Step 2: Run tests**

Run: `make test`
Expected: 45/45 pass

**Step 3: Commit**

```bash
git add src/ui/*.tscn src/ui/*.gd
git commit -m "refactor: remove hardcoded font overrides, use theme resource"
```

---

## Task 13: Update design/theme.json and add design review checklist

**Files:**
- Modify: `design/theme.json` (already done in Task 2)
- Create: `design/design-review-checklist.md`

**Step 1: Create design review checklist**

Create `design/design-review-checklist.md`:
```markdown
# Design Review Checklist

Use this checklist after implementing any UI screen or component.

## Layout
- [ ] Card is centered in viewport (900x550 or smaller)
- [ ] Dim overlay covers full screen behind card
- [ ] Content does not overflow card bounds
- [ ] All interactive elements are within visible area
- [ ] Minimum touch target size is 44px

## Typography
- [ ] Page titles use Display-Bold at 32px (lg)
- [ ] Section headers use Inter-Regular at 24px (md)
- [ ] Body text uses Inter-Regular at 20px (sm)
- [ ] Captions use Inter-Regular at 16px (xs)
- [ ] Hero/score displays use Display-Bold at 40px (xl)
- [ ] No hardcoded font_size in .tscn files

## Colors
- [ ] Card background is surface (#0B1220) at 95% opacity
- [ ] Text is white on dark backgrounds
- [ ] Interactive elements use primary (#5AA9FF) for selected state
- [ ] Warnings use danger (#FF7B7B)
- [ ] Positive results use success (#5EE8A4)
- [ ] Secondary text uses muted (#8A9BB1)

## Spacing
- [ ] Card inner padding is 32px (lg)
- [ ] VBox separation matches token scale (8/16/24/32/48)
- [ ] No magic numbers — all spacing uses token values

## States
- [ ] Buttons have normal/hover/pressed/disabled styles (from theme)
- [ ] Disabled buttons are visually distinct
- [ ] Selected items have visible highlight

## Theme
- [ ] Scene references res://assets/ui/theme.tres
- [ ] No inline StyleBox overrides (use theme resource)
```

**Step 2: Commit**

```bash
git add design/design-review-checklist.md
git commit -m "docs: add design review checklist"
```

---

## Dependency Order

```
Task 1 (viewport) → Task 3 (brewery scene)
Task 2 (tokens) → Task 4 (theme resource) → Tasks 5-10 (screen redesigns)
Task 5 (CardContainer) → Tasks 6-10 (all screens use it as pattern)
Tasks 6-10 can run in parallel after Task 5
Task 11 (integration check) → after Tasks 6-10
Task 12 (cleanup) → after Task 11
Task 13 (checklist) → independent, can run anytime
```

Critical path: 1 → 2 → 4 → 5 → 6/7/8/9/10 → 11 → 12
