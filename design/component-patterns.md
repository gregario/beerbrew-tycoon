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
