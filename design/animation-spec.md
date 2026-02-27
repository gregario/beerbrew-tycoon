# Animation & Transition Specification

## Screen Transitions

| Transition | Property | From > To | Duration | Easing |
|-----------|----------|-----------|----------|--------|
| Card appear | modulate:a | 0 > 1 | 0.2s | EASE_OUT |
| Card disappear | modulate:a | 1 > 0 | 0.15s | EASE_IN |
| Dim overlay appear | color:a | 0 > 0.6 | 0.2s | EASE_OUT |
| Dim overlay disappear | color:a | 0.6 > 0 | 0.15s | EASE_IN |

## Implementation Pattern

```gdscript
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
| Toast auto-dismiss | Wait then fade out | 3.0s hold + 0.2s | EASE_IN |
| Failure panel appear | Fade in (with results) | 0.2s | EASE_OUT |
| Tooltip appear | Instant | 0s | — |

## Principles

- Transitions should feel snappy, never sluggish
- Never exceed 0.3s for any UI animation
- Input feedback (buttons, sliders) is always instant
- Screen transitions are the only animated elements in MVP
- Brewery scene animations are managed by AnimationPlayer (separate concern)
