# Design System Pass — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fill all design stack gaps: document component patterns, states, typography, animation, and information hierarchy. Build toast/notification and tooltip components. Source game-specific icons.

**Architecture:** Design documentation goes in `design/`. Toast and Tooltip are new scenes in `src/ui/`. ToastManager is a new autoload. Animations use Godot Tweens. Icons sourced from Kenney free packs or created as simple colored shapes.

**Tech Stack:** Godot 4.6, GDScript, GUT testing framework

**Design doc:** `docs/plans/2026-02-27-ui-design-overhaul.md` §5

---

## Task 1: Write Component Pattern Library

**Files:**
- Create: `design/component-patterns.md`

**Step 1: Write the component patterns doc**

```markdown
# Component Pattern Library

Reusable UI patterns for BeerBrew Tycoon. All screens must use these patterns.

## Card

- 900x550 PanelContainer, centered in viewport
- Background: surface (#0B1220) at 95% opacity
- Border: 2px muted (#8A9BB1), 4px corner radius
- Inner padding: 32px (lg spacing token)
- Always paired with DimOverlay (full-screen ColorRect, background #0F1724 at 60%)

## Header Bar

- HBoxContainer as first child of card VBox
- Left: title Label (lg/32px, Display-Bold)
- Right: contextual info Label (md/24px, right-aligned, size_flags_horizontal=EXPAND_FILL)
- Followed by HSeparator

## Footer Bar

- HBoxContainer as last child of card VBox
- alignment=END (right-aligned) for single CTA, CENTER for multiple buttons
- Buttons: custom_minimum_size 150x44 or 200x44

## Badge

- Label with theme_override_colors/font_color
- Accent (#FFC857) for demand/highlights
- Success (#5EE8A4) for positive indicators
- Danger (#FF7B7B) for warnings
- Inline within parent container, no wrapper needed

## Stat Row

- GridContainer, columns=2
- h_separation=32, v_separation=8
- Left: key Label (sm/20px)
- Right: value Label (sm/20px, horizontal_alignment=RIGHT)

## Alert Bar

- Label with danger (#FF7B7B) font_color override
- Full-width within card VBox
- Text prefixed with warning context

## Inner Panel

- PanelContainer using Panel stylebox (lighter bg, 1px border, 16px padding)
- Use for: summary bars, score panels, preview sections

## Star Rating

- HBoxContainer, alignment=CENTER, separation=4
- 5 TextureRect nodes, 28x28, STRETCH_KEEP_ASPECT_CENTERED
- Filled: res://assets/ui/kenney/Green/Default/star.png
- Empty: res://assets/ui/kenney/Green/Default/star_outline_depth.png
- filled_count = int(round(score / 20.0))
```

**Step 2: Commit**

```bash
git add design/component-patterns.md
git commit -m "docs: add component pattern library"
```

---

## Task 2: Write Interactive States Spec

**Files:**
- Create: `design/interactive-states.md`

**Step 1: Write the interactive states doc**

```markdown
# Interactive States Specification

## Button States

| State | Kenney Asset | When |
|-------|-------------|------|
| Normal | button_rectangle_depth_line.png (Green) | Default resting state |
| Hover | button_rectangle_gloss.png (Green) | Mouse enters button |
| Pressed | button_rectangle_flat.png (Green) | Mouse down |
| Disabled | button_rectangle_border.png (Grey) | Action not available |

## Selection States

| State | Treatment | When |
|-------|-----------|------|
| Unselected | Default button normal style | No choice made |
| Selected | 2px primary (#5AA9FF) border via add_theme_stylebox_override | Item chosen |
| Focused | Same as hover + outline | Keyboard navigation |

## Slider States

| Part | Style | Color |
|------|-------|-------|
| Track (unfilled) | StyleBoxFlat, 4px radius | Grey (0.3, 0.3, 0.4) |
| Track (filled) | StyleBoxFlat, 4px radius | Success (#5EE8A4) |
| Grabber | Default, grabber_offset=8 | Theme default |

## Checkbox/Radio (future)

| State | Asset |
|-------|-------|
| Unchecked | check_round_grey.png (Green) |
| Checked | check_round_color.png (Green) |

## State Transitions

All state changes are instant (no animation). Stylebox swaps happen on input events.
```

**Step 2: Commit**

```bash
git add design/interactive-states.md
git commit -m "docs: add interactive states specification"
```

---

## Task 3: Write Typography & Information Hierarchy Docs

**Files:**
- Create: `design/typography-hierarchy.md`

**Step 1: Write the typography and hierarchy doc**

```markdown
# Typography & Information Hierarchy

## Type Scale

| Role | Token | Size | Font | Usage |
|------|-------|------|------|-------|
| Hero | xl | 40px | Display-Bold | Score displays, game over titles. One per screen max. |
| Page Title | lg | 32px | Display-Bold | Screen title in header bar. Exactly one per card. |
| Section Header | md | 24px | Inter-Regular | Category labels, phase names, money amounts. |
| Body | sm | 20px | Inter-Regular | Descriptions, stats, summaries. Theme default — no override. |
| Caption | xs | 16px | Inter-Regular | Slider values, minor labels, hints. |

## Rules

- Never skip levels (hero → caption with nothing between is wrong)
- Display-Bold only for hero and page title
- One hero element per screen maximum
- Page title is always first in header bar
- Body text (20px) is the theme default — do not add font_size overrides for it

## Information Hierarchy

Three levels of visual emphasis:

| Level | Treatment | Examples |
|-------|-----------|---------|
| Primary | Hero/lg size, bold font, centered or top | Quality score, game over title, screen title |
| Secondary | md size, standard font, supporting position | Revenue, style name, category headers |
| Tertiary | sm/xs size, muted color optional, grid/bottom | Breakdown stats, hints, slider values |

## Per-Screen Hierarchy

| Screen | Primary | Secondary | Tertiary |
|--------|---------|-----------|----------|
| StylePicker | Screen title | Balance, style names | Demand badges, descriptions |
| RecipeDesigner | Screen title | Category headers | Ingredient names, summary |
| BrewingPhases | Screen title | Phase names | Hint, slider values, preview |
| ResultsOverlay | Quality score | Revenue/balance, style | Breakdown, recipe, rent warning |
| GameOverScreen | Win/loss title | Message | Stats grid |
```

**Step 2: Commit**

```bash
git add design/typography-hierarchy.md
git commit -m "docs: add typography and information hierarchy spec"
```

---

## Task 4: Write Animation Spec

**Files:**
- Create: `design/animation-spec.md`

**Step 1: Write the animation spec**

```markdown
# Animation & Transition Specification

## Screen Transitions

| Transition | Property | From → To | Duration | Easing |
|-----------|----------|-----------|----------|--------|
| Card appear | modulate:a | 0 → 1 | 0.2s | EASE_OUT |
| Card disappear | modulate:a | 1 → 0 | 0.15s | EASE_IN |
| Dim overlay appear | color:a | 0 → 0.6 | 0.2s | EASE_OUT |
| Dim overlay disappear | color:a | 0.6 → 0 | 0.15s | EASE_IN |

## Implementation Pattern

```gdscript
# In each UI screen's show method or when visible changes:
func _show_animated() -> void:
    modulate.a = 0.0
    visible = true
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
```

## Component Animations

| Component | Animation | Duration | Easing |
|-----------|-----------|----------|--------|
| Button hover/press | Instant stylebox swap | 0s | — |
| Slider drag | Immediate value update | 0s | — |
| Star rating | Sequential fade-in per star | 0.1s each | EASE_OUT |
| Toast appear | Slide in from right | 0.3s | EASE_OUT |
| Toast dismiss | Fade out | 0.2s | EASE_IN |
| Tooltip appear | Instant (no delay animation) | 0s | — |

## Principles

- Transitions should feel snappy, never sluggish
- Never exceed 0.3s for any UI animation
- Input feedback (buttons, sliders) is always instant
- Screen transitions are the only animated elements in MVP
- Brewery scene animations are managed by AnimationPlayer (separate concern)
```

**Step 2: Commit**

```bash
git add design/animation-spec.md
git commit -m "docs: add animation and transition specification"
```

---

## Task 5: Implement Screen Transition Animations

**Files:**
- Modify: `src/scenes/Game.gd`

**Step 1: Write failing test**

Create `src/tests/test_ui_transitions.gd`:

```gdscript
extends GutTest

## Tests that UI screens have transition animation support.

func test_style_picker_starts_invisible() -> void:
    # Screens start with modulate.a = 0 when hidden
    var picker := preload("res://ui/StylePicker.tscn").instantiate()
    picker.visible = false
    add_child_autofree(picker)
    # When not visible, modulate can be anything — just verify the scene loads
    assert_not_null(picker, "StylePicker should instantiate")

func test_card_panel_exists_on_screens() -> void:
    # All redesigned screens should have a CardPanel node
    var scenes := [
        preload("res://ui/StylePicker.tscn"),
        preload("res://ui/RecipeDesigner.tscn"),
        preload("res://ui/BrewingPhases.tscn"),
        preload("res://ui/ResultsOverlay.tscn"),
        preload("res://ui/GameOverScreen.tscn"),
    ]
    for scene in scenes:
        var instance := scene.instantiate()
        add_child_autofree(instance)
        assert_not_null(instance.find_child("CardPanel"), "%s should have CardPanel" % instance.name)
        assert_not_null(instance.find_child("DimOverlay"), "%s should have DimOverlay" % instance.name)
```

**Step 2: Run test to verify it passes (structural test)**

Run: `make test`
Expected: PASS

**Step 3: Add transition helper to Game.gd**

Add these methods to `src/scenes/Game.gd`:

```gdscript
func _show_overlay(overlay: Control) -> void:
    overlay.modulate.a = 0.0
    overlay.visible = true
    var tween := create_tween()
    tween.tween_property(overlay, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)

func _hide_all_overlays() -> void:
    for overlay in _all_overlays:
        if overlay and overlay.visible:
            overlay.visible = false
            overlay.modulate.a = 0.0
```

**Step 4: Update _on_state_changed to use _show_overlay**

Replace all `overlay.visible = true` calls with `_show_overlay(overlay)`:

```gdscript
# STYLE_SELECT:
_show_overlay(style_picker)

# RECIPE_DESIGN:
_show_overlay(recipe_designer)

# BREWING_PHASES:
_show_overlay(brewing_phases)

# RESULTS:
_show_overlay(results_overlay)

# GAME_OVER:
_show_overlay(game_over_screen)
```

And in MARKET_CHECK, use `_show_overlay(style_picker)` instead of `style_picker.visible = true`.

**Step 5: Run tests**

Run: `make test`
Expected: All pass

**Step 6: Commit**

```bash
git add src/scenes/Game.gd src/tests/test_ui_transitions.gd
git commit -m "feat: add screen transition fade animations"
```

---

## Task 6: Source Game-Specific Icons

**Files:**
- Create: `src/assets/ui/icons/` directory
- Create icon placeholder files

**Step 1: Check Kenney for game icon packs**

Kenney offers free "Game Icons" and "Board Game Icons" packs. However, for MVP we'll create simple colored-shape placeholder icons using Godot's built-in drawing or source from Kenney's other free packs.

For now, create a placeholder system: simple Label-based icons using Unicode characters that match our theme:

| Concept | Unicode | Fallback |
|---------|---------|----------|
| Beer/mug | 🍺 | Label "B" |
| Grain/malt | 🌾 | Label "M" |
| Hops | 🌿 | Label "H" |
| Yeast | 🧫 | Label "Y" |
| Money | 💰 | Label "$" |
| Quality | ⭐ | Kenney star.png |
| Turns | 🕐 | Label "#" |

Create `src/ui/Icons.gd` autoload:

```gdscript
extends Node
## Simple icon reference for game concepts.
## Replace Unicode with TextureRect when real pixel art icons are sourced.

const ICONS := {
    "beer": "🍺",
    "malt": "🌾",
    "hops": "🌿",
    "yeast": "🧫",
    "money": "$",
    "quality": "⭐",
    "turns": "#",
}

static func get_icon(key: String) -> String:
    return ICONS.get(key, "?")
```

Note: This is a placeholder. Real pixel-art icons should be sourced in a future art pass. The Unicode approach works for MVP and establishes the API.

**Step 2: Commit**

```bash
git add src/ui/Icons.gd
git commit -m "feat: add placeholder icon system for game concepts"
```

---

## Task 7: Build Toast/Notification Component

**Files:**
- Create: `src/ui/Toast.tscn`
- Create: `src/ui/Toast.gd`
- Create: `src/autoloads/ToastManager.gd`
- Create: `src/tests/test_toast.gd`
- Modify: `src/project.godot` (add autoload)

**Step 1: Write failing test**

Create `src/tests/test_toast.gd`:

```gdscript
extends GutTest

var _manager: Node

func before_each() -> void:
    _manager = preload("res://autoloads/ToastManager.gd").new()
    add_child_autofree(_manager)

func test_show_toast_adds_child() -> void:
    _manager.show_toast("Test message")
    assert_eq(_manager.get_child_count(), 1, "Should have one toast child")

func test_toast_has_correct_text() -> void:
    _manager.show_toast("Hello World")
    var toast := _manager.get_child(0)
    var label := toast.find_child("Label") as Label
    assert_not_null(label, "Toast should have a Label")
    assert_eq(label.text, "Hello World")

func test_multiple_toasts_stack() -> void:
    _manager.show_toast("First")
    _manager.show_toast("Second")
    assert_eq(_manager.get_child_count(), 2, "Should have two toasts")
```

**Step 2: Run test — should fail**

Run: `make test`
Expected: FAIL (ToastManager.gd doesn't exist)

**Step 3: Create Toast.gd**

```gdscript
extends PanelContainer
## A single toast notification that auto-dismisses.

@onready var label: Label = $Label
@onready var timer: Timer = $Timer

const DISMISS_TIME := 3.0
const SLIDE_DURATION := 0.3

func setup(message: String) -> void:
    if label:
        label.text = message
    else:
        # Called before _ready, store for later
        set_meta("_pending_text", message)

func _ready() -> void:
    if has_meta("_pending_text"):
        label.text = get_meta("_pending_text")
    timer.wait_time = DISMISS_TIME
    timer.one_shot = true
    timer.timeout.connect(_dismiss)
    timer.start()
    _animate_in()

func _animate_in() -> void:
    var target_x := position.x
    position.x += 320
    var tween := create_tween()
    tween.tween_property(self, "position:x", target_x, SLIDE_DURATION).set_ease(Tween.EASE_OUT)

func _dismiss() -> void:
    var tween := create_tween()
    tween.tween_property(self, "modulate:a", 0.0, 0.2).set_ease(Tween.EASE_IN)
    tween.tween_callback(queue_free)
```

**Step 4: Create Toast.tscn**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://ui/Toast.gd" id="1_toast"]

[node name="Toast" type="PanelContainer"]
custom_minimum_size = Vector2(300, 50)
script = ExtResource("1_toast")

[node name="Label" type="Label" parent="."]
horizontal_alignment = 1
vertical_alignment = 1

[node name="Timer" type="Timer" parent="."]
```

**Step 5: Create ToastManager.gd**

```gdscript
extends CanvasLayer
## Global toast notification manager.
## Usage: ToastManager.show_toast("Message here")

const TOAST_SCENE := preload("res://ui/Toast.tscn")
const TOAST_MARGIN := 16
const TOAST_SPACING := 8

func show_toast(message: String) -> void:
    var toast := TOAST_SCENE.instantiate()
    toast.setup(message)
    add_child(toast)
    _reposition_toasts()

func _reposition_toasts() -> void:
    var y_offset := TOAST_MARGIN
    for i in range(get_child_count() - 1, -1, -1):
        var child := get_child(i)
        child.position = Vector2(1280 - 300 - TOAST_MARGIN, y_offset)
        y_offset += 58 + TOAST_SPACING
```

**Step 6: Register autoload in project.godot**

Add to [autoload] section:
```ini
ToastManager="*res://autoloads/ToastManager.gd"
```

**Step 7: Run tests**

Run: `make test`
Expected: All pass

**Step 8: Commit**

```bash
git add src/ui/Toast.tscn src/ui/Toast.gd src/autoloads/ToastManager.gd src/tests/test_toast.gd src/project.godot
git commit -m "feat: add toast notification system with auto-dismiss"
```

---

## Task 8: Build Tooltip Component

**Files:**
- Create: `src/ui/Tooltip.tscn`
- Create: `src/ui/Tooltip.gd`
- Create: `src/tests/test_tooltip.gd`

**Step 1: Write failing test**

Create `src/tests/test_tooltip.gd`:

```gdscript
extends GutTest

var _tooltip: Control

func before_each() -> void:
    _tooltip = preload("res://ui/Tooltip.tscn").instantiate()
    add_child_autofree(_tooltip)

func test_tooltip_starts_hidden() -> void:
    assert_false(_tooltip.visible, "Tooltip should start hidden")

func test_show_sets_text_and_visibility() -> void:
    _tooltip.show_at("Test tooltip text", Vector2(100, 100))
    assert_true(_tooltip.visible)
    var label := _tooltip.find_child("Label") as Label
    assert_eq(label.text, "Test tooltip text")

func test_hide_tooltip() -> void:
    _tooltip.show_at("Text", Vector2(100, 100))
    _tooltip.hide_tooltip()
    assert_false(_tooltip.visible)
```

**Step 2: Create Tooltip.gd**

```gdscript
extends PanelContainer
## Tooltip popup — show near mouse, clamp to viewport.

@onready var label: Label = $Label

const MAX_WIDTH := 250
const OFFSET := Vector2(16, 16)

func _ready() -> void:
    visible = false
    custom_minimum_size.x = 0
    size = Vector2.ZERO

func show_at(text: String, pos: Vector2) -> void:
    label.text = text
    custom_minimum_size.x = min(label.get_minimum_size().x + 32, MAX_WIDTH)
    visible = true
    # Clamp position to viewport
    var vp_size := get_viewport_rect().size
    var tip_pos := pos + OFFSET
    if tip_pos.x + size.x > vp_size.x:
        tip_pos.x = pos.x - size.x - OFFSET.x
    if tip_pos.y + size.y > vp_size.y:
        tip_pos.y = pos.y - size.y - OFFSET.y
    position = tip_pos

func hide_tooltip() -> void:
    visible = false
```

**Step 3: Create Tooltip.tscn**

```
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://ui/Tooltip.gd" id="1_tooltip"]

[node name="Tooltip" type="PanelContainer"]
visible = false
custom_minimum_size = Vector2(0, 0)
script = ExtResource("1_tooltip")

[node name="Label" type="Label" parent="."]
theme_override_font_sizes/font_size = 16
autowrap_mode = 2
```

**Step 4: Run tests**

Run: `make test`
Expected: All pass

**Step 5: Commit**

```bash
git add src/ui/Tooltip.tscn src/ui/Tooltip.gd src/tests/test_tooltip.gd
git commit -m "feat: add tooltip component with viewport clamping"
```

---

## Dependency Order

```
Tasks 1-4 (docs) — independent, can run in parallel
Task 5 (animations) — independent
Task 6 (icons) — independent
Task 7 (toast) — independent
Task 8 (tooltip) — independent
All tasks are independent and can run in any order.
```
