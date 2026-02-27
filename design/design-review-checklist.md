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
- [ ] Body text uses Inter-Regular at 20px (sm) — theme default, no override needed
- [ ] Captions use Inter-Regular at 16px (xs)
- [ ] Hero/score displays use Display-Bold at 40px (xl)
- [ ] No redundant font_size=20 overrides in .tscn files

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
- [ ] Scene references res://assets/ui/theme.tres (or inherits from parent)
- [ ] No inline StyleBox overrides (use theme resource)
