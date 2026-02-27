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
