# Wireframe: Stage 1C — Failure Modes & QA

## QA Checkpoint Toast Notifications

Three checkpoint toasts appear during brewing, using the existing toast system (slide in from right, 0.3s EASE_OUT).

### Pre-Boil Gravity Check (after mashing)

```
┌────────────────────────────────────────┐
│  📊 Pre-Boil Gravity Check             │
│  OG: 1.052  —  Normal efficiency       │
└────────────────────────────────────────┘
```

### Boil Vigor Check (during boiling)

```
┌────────────────────────────────────────┐
│  📊 Boil Vigor Check                   │
│  Good rolling boil  —  DMS driven off  │
└────────────────────────────────────────┘
```

### Final Gravity Check (after fermenting)

```
┌────────────────────────────────────────┐
│  📊 Final Gravity Check                │
│  FG: 1.012  —  Attenuation: 77%       │
└────────────────────────────────────────┘
```

### QA Toast Layout

```
HBoxContainer (separation: 12)
├── ColorRect (4px wide, full height) ← left accent bar
│   Color: primary (#5AA9FF) for normal
│          warning (#FFB347) for low/high readings
│          danger (#FF7B7B) for critical readings
└── VBoxContainer (separation: 4)
    ├── Label: checkpoint name (sm/20px, Display-Bold)
    └── Label: reading + assessment (xs/16px, muted)
```

### QA Reading Assessment Colors

| Assessment | Text Color | Left Bar Color |
|-----------|------------|----------------|
| Normal / Good | muted (#8A9BB1) | primary (#5AA9FF) |
| Low / High | warning (#FFB347) | warning (#FFB347) |
| Critical | danger (#FF7B7B) | danger (#FF7B7B) |

Toast auto-dismisses after 3 seconds (fade out 0.2s EASE_IN).

---

## ResultsOverlay — Failure Mode Updates

### Clean Brew (no failures) — No Change

Existing ResultsOverlay layout unchanged when no failures occur.

### Infected Brew

```
┌─────────────────────────────────────────────────────────┐
│  BREW RESULTS                                           │
│  ─────────────────────────────────────────────────────  │
│                                                         │
│  ★ ☆ ☆ ☆ ☆                                             │
│  Quality Score: 18                                      │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │  ⚠ INFECTION DETECTED                            │  │
│  │  Bacteria contaminated your batch. Your beer      │  │
│  │  tastes sour and unpleasant.                      │  │
│  │                                                   │  │
│  │  Tip: Upgrade your sanitation equipment to        │  │
│  │  reduce infection risk.                           │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
│  Style: IPA          Revenue: $32                       │
│                                                         │
│  ─────────────────────────────────────────────────────  │
│  TASTING NOTES                                          │
│  ─────────────────────────────────────────────────────  │
│                                                         │
│  "Something went wrong here. Sour off-notes."           │
│                                                         │
│                                       [ Continue ]      │
└─────────────────────────────────────────────────────────┘
```

### Off-Flavor Brew

```
┌─────────────────────────────────────────────────────────┐
│  BREW RESULTS                                           │
│  ─────────────────────────────────────────────────────  │
│                                                         │
│  ★ ★ ☆ ☆ ☆                                             │
│  Quality Score: 44                                      │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │  ⚠ OFF-FLAVORS DETECTED                          │  │
│  │  Fusel alcohols — hot, solvent-like character.    │  │
│  │                                                   │  │
│  │  Tip: Better temperature control during           │  │
│  │  fermentation helps avoid off-flavors.            │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
│  Style: Lager          Revenue: $68                     │
│                                                         │
│  ─────────────────────────────────────────────────────  │
│  TASTING NOTES                                          │
│  ─────────────────────────────────────────────────────  │
│                                                         │
│  "Harsh, boozy flavors overpower everything else."      │
│                                                         │
│                                       [ Continue ]      │
└─────────────────────────────────────────────────────────┘
```

### Both Infection + Off-Flavor (stacked)

```
│  ┌───────────────────────────────────────────────────┐  │
│  │  ⚠ INFECTION DETECTED                            │  │
│  │  Bacteria contaminated your batch.               │  │
│  └───────────────────────────────────────────────────┘  │
│  ┌───────────────────────────────────────────────────┐  │
│  │  ⚠ OFF-FLAVORS DETECTED                          │  │
│  │  DMS — cooked corn character from short boil.     │  │
│  └───────────────────────────────────────────────────┘  │
```

When both occur, stack failure panels vertically. Each is independent.

### Failure Panel Layout

```
PanelContainer (Inner Panel pattern, danger variant)
├── StyleBoxFlat
│   ├── bg_color: danger (#FF7B7B) at 10% opacity
│   ├── border_color: danger (#FF7B7B) at 40% opacity
│   ├── border_width_left: 4px (solid danger)
│   └── corner_radius: 4px, content_margin: 16px
└── VBoxContainer (separation: 8)
    ├── Label: failure title (sm/20px, Display-Bold, danger color)
    ├── Label: description (xs/16px, muted, autowrap)
    ├── Spacer (4px)
    └── Label: tip text (xs/16px, primary #5AA9FF, autowrap)
```

### Placement in ResultsOverlay

The failure panel(s) insert between the quality score and the style/revenue row:

```
VBoxContainer (card body)
├── Star Rating
├── Quality Score label
├── [FailurePanel — infection]     ← NEW, conditional
├── [FailurePanel — off-flavor]    ← NEW, conditional
├── HSeparator (if failures shown) ← NEW, conditional
├── Style / Revenue row
├── HSeparator
├── Tasting Notes section
└── Footer (Continue button)
```

---

## Off-Flavor Types

| Off-Flavor | Description | Common Cause |
|-----------|-------------|--------------|
| Esters | Fruity, banana-like character | High fermentation temp |
| Fusel alcohols | Hot, solvent-like, boozy | Very high fermentation temp |
| DMS | Cooked corn, vegetal | Short boil time / weak boil |

Each off-flavor type uses the same panel layout; only text content differs.

---

## Failure Severity Visual Cues

| Severity | Star Impact | Score Color | Panel Treatment |
|----------|-------------|-------------|-----------------|
| Off-flavor only | -1 to -2 stars | warning (#FFB347) | Warning panel |
| Infection only | -2 to -3 stars | danger (#FF7B7B) | Danger panel |
| Both | -3 to -4 stars | danger (#FF7B7B) | Stacked panels |
| Clean brew | Normal | Default | No panel |

---

## No New Scenes Required

All failure mode UI lives within existing scenes:
- QA toasts → existing toast notification system
- Failure panels → inserted into existing ResultsOverlay
- Stats (sanitation, temp_control) → GameState (data only, no UI in 1C)

Equipment UI for upgrading these stats is deferred to Stage 2 (Equipment System).
