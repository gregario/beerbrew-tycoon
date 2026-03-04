# Wireframe: Stage 3B — Brewery Expansion

## 1. Expansion Notification Banner (Brewery Hub)

When the player meets expansion thresholds ($5,000 balance + 10 beers brewed), a banner appears at the top of the EQUIPMENT_MANAGE screen.

```
┌──────────────────────────────────────────────────────────────────────┐
│  ┌──────────────────────────────────────────────────────────────┐   │
│  │  ★ Ready to expand! Upgrade to Microbrewery — $3,000        │   │
│  │                                        [ View Details > ]   │   │
│  └──────────────────────────────────────────────────────────────┘   │
│                                                                      │
│  Balance: $6,200                                                     │
│  EQUIPMENT MANAGEMENT                                                │
│                                                                      │
│     ┌─────────────┐    ┌─────────────┐    ┌─────────────┐           │
│     │   Kettle     │    │  Fermenter  │    │   Bottler   │           │
│     │ Basic Kettle │    │ [Empty Slot]│    │ [Empty Slot]│           │
│     └─────────────┘    └─────────────┘    └─────────────┘           │
│                                                                      │
│         [ Start Brewing > ]   [ Research ]   [ Staff ]               │
└──────────────────────────────────────────────────────────────────────┘
```

### Banner Layout
```
PanelContainer "ExpansionBanner" (full width, accent border #FFC857, surface bg)
├── HBoxContainer (padding: 12, separation: 16)
│   ├── Label "★ Ready to expand! Upgrade to Microbrewery — $3,000"
│   │       (sm/20px, accent #FFC857)
│   └── Button "View Details >" (accent bg, dark text, 160x36)
```

- Banner appears with slide-down animation (0.3s ease-out)
- Only visible when threshold met AND not yet expanded
- Dismiss with X button (remembers dismissal for session, reappears next turn)

---

## 2. Expansion Confirmation Screen (Overlay)

Full-screen overlay (same pattern as Staff/Research overlays).

```
┌──────────────────────────────────────────────────────────────────────┐
│ ░░░░░░░░░░░░░░░░░░░░░░░ dim bg (0.6 alpha) ░░░░░░░░░░░░░░░░░░░░░░ │
│ ░░ ┌────────────────────────────────────────────────────────┐ ░░░░░ │
│ ░░ │  EXPAND YOUR BREWERY                              [X] │ ░░░░░ │
│ ░░ │  ─────────────────────────────────────────────────────  │ ░░░░░ │
│ ░░ │                                                         │ ░░░░░ │
│ ░░ │       GARAGE  ──────>  MICROBREWERY                     │ ░░░░░ │
│ ░░ │                                                         │ ░░░░░ │
│ ░░ │  WHAT YOU GET:                                          │ ░░░░░ │
│ ░░ │  ┌─────────────────────────────────────────────────┐   │ ░░░░░ │
│ ░░ │  │  ✦ Station Slots:   3 → 5  (+2 new slots)      │   │ ░░░░░ │
│ ░░ │  │  ✦ Staff Hiring:    Locked → Unlocked (max 2)   │   │ ░░░░░ │
│ ░░ │  │  ✦ Equipment:       T1-T2 → T1-T4 unlocked     │   │ ░░░░░ │
│ ░░ │  │  ✦ Larger Space:    Industrial brewery layout    │   │ ░░░░░ │
│ ░░ │  └─────────────────────────────────────────────────┘   │ ░░░░░ │
│ ░░ │                                                         │ ░░░░░ │
│ ░░ │  COSTS:                                                 │ ░░░░░ │
│ ░░ │  ┌─────────────────────────────────────────────────┐   │ ░░░░░ │
│ ░░ │  │  ● Upgrade Cost:    $3,000 (one-time)           │   │ ░░░░░ │
│ ░░ │  │  ● Rent Increase:   $150 → $400 per period      │   │ ░░░░░ │
│ ░░ │  └─────────────────────────────────────────────────┘   │ ░░░░░ │
│ ░░ │                                                         │ ░░░░░ │
│ ░░ │  Balance after: $3,200                                  │ ░░░░░ │
│ ░░ │                                                         │ ░░░░░ │
│ ░░ │          [ Cancel ]          [ Expand — $3,000 ]        │ ░░░░░ │
│ ░░ └────────────────────────────────────────────────────────┘ ░░░░░ │
└──────────────────────────────────────────────────────────────────────┘
```

### Panel: 900x550 (matches card tokens)
- Background: surface (#0B1220), border: accent (#FFC857), corner_radius: 4

### Layout
```
PanelContainer "ExpansionOverlay" (900x550, centered)
├── VBoxContainer (padding: 32, separation: 16)
│   ├── HBoxContainer (header)
│   │   ├── Label "EXPAND YOUR BREWERY" (lg/32px, white)
│   │   └── Button "X" (close, danger hover)
│   ├── HSeparator
│   ├── HBoxContainer (stage transition visual)
│   │   ├── Label "GARAGE" (md/24px, muted)
│   │   ├── Label "──────>" (md/24px, accent)
│   │   └── Label "MICROBREWERY" (md/24px, accent, bold)
│   ├── Label "WHAT YOU GET:" (sm/20px, success #5EE8A4)
│   ├── PanelContainer (benefits list, surface bg, success border)
│   │   ├── VBoxContainer (separation: 8, padding: 12)
│   │   │   ├── Label "✦ Station Slots: 3 → 5 (+2 new slots)" (sm/20px, white)
│   │   │   ├── Label "✦ Staff Hiring: Locked → Unlocked (max 2)" (sm/20px, white)
│   │   │   ├── Label "✦ Equipment: T1-T2 → T1-T4 unlocked" (sm/20px, white)
│   │   │   └── Label "✦ Larger Space: Industrial brewery layout" (sm/20px, white)
│   ├── Label "COSTS:" (sm/20px, warning #FFB347)
│   ├── PanelContainer (costs list, surface bg, warning border)
│   │   ├── VBoxContainer (separation: 8, padding: 12)
│   │   │   ├── Label "● Upgrade Cost: $3,000 (one-time)" (sm/20px, white)
│   │   │   └── Label "● Rent Increase: $150 → $400 per period" (sm/20px, white)
│   ├── Label "Balance after: $3,200" (sm/20px, muted — danger color if < $200)
│   └── HBoxContainer (buttons, centered, separation: 24)
│       ├── Button "Cancel" (muted, 160x48)
│       └── Button "Expand — $3,000" (accent bg, dark text, 240x48)
```

- "Expand" button disabled if balance < $3,000
- "Balance after" turns danger red if resulting balance < $200

---

## 3. Microbrewery Scene Layout (Post-Expansion)

After expanding, the BreweryScene transitions to a wider layout with 5 station slots.

```
┌──────────────────────────────────────────────────────────────────────┐
│  Balance: $3,200                                                     │
│  MICROBREWERY                              Beers Brewed: 12          │
│                                                                      │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  │
│  │  Kettle  │  │Fermenter│  │ Bottler │  │  Slot 4  │  │  Slot 5  │  │
│  │ Premium  │  │  Basic  │  │ [Empty] │  │ [Empty]  │  │ [Empty]  │  │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘  │
│                                                                      │
│                        ┌─────────────────┐                           │
│                        │ 👤 Lars (Mash)  │                           │
│                        │ 👤 Eva  (Ferm)  │                           │
│                        └─────────────────┘                           │
│                                                                      │
│     [ Start Brewing > ]   [ Research ]   [ Staff ]   [ Shop ]       │
└──────────────────────────────────────────────────────────────────────┘
```

### Key Differences from Garage
- **Title**: "MICROBREWERY" instead of "EQUIPMENT MANAGEMENT"
- **5 station slots** in a row (narrower buttons to fit, 140x80 each)
- **Staff roster mini-display**: small panel showing assigned staff names+phases
- **Beers Brewed counter**: top-right, shows progress toward next expansion threshold
- **Background**: slightly brighter floor color to distinguish from garage

### Slot Button Layout
```
HBoxContainer "StationSlots" (centered, separation: 16)
├── Button slot_0 (140x80, station label + equipment name)
├── Button slot_1 (140x80)
├── Button slot_2 (140x80)
├── Button slot_3 (140x80)  # NEW — unlocked at microbrewery
└── Button slot_4 (140x80)  # NEW — unlocked at microbrewery
```

- New slots (3, 4) initially show "[Empty]" with a subtle pulsing accent border to draw attention
- Slot buttons: same styling as garage but narrower to fit 5

### Staff Mini-Display
```
PanelContainer "StaffMini" (200x80, below slots, surface bg, muted border)
├── VBoxContainer (separation: 2, padding: 8)
│   ├── Label "👤 Name (Phase)" (xs/16px, white) — per assigned staff
│   └── ...
```

- Only shown in microbrewery+ stages
- Clicking opens full Staff Management overlay

---

## 4. Artisan vs Mass-Market Fork Screen

When the player meets the second threshold ($15,000 balance + 25 beers) at microbrewery stage, this choice screen appears.

```
┌──────────────────────────────────────────────────────────────────────┐
│ ░░░░░░░░░░░░░░░░░░░░░░░ dim bg (0.6 alpha) ░░░░░░░░░░░░░░░░░░░░░░ │
│ ░░ ┌────────────────────────────────────────────────────────┐ ░░░░░ │
│ ░░ │  CHOOSE YOUR PATH                                      │ ░░░░░ │
│ ░░ │  This decision is permanent for this run.               │ ░░░░░ │
│ ░░ │  ─────────────────────────────────────────────────────  │ ░░░░░ │
│ ░░ │                                                         │ ░░░░░ │
│ ░░ │  ┌────────────────────┐    ┌────────────────────┐      │ ░░░░░ │
│ ░░ │  │   ARTISAN BREWERY  │    │  MASS-MARKET BREW  │      │ ░░░░░ │
│ ░░ │  │                    │    │                     │      │ ░░░░░ │
│ ░░ │  │  "Quality over     │    │  "Volume over       │      │ ░░░░░ │
│ ░░ │  │   quantity"        │    │   variety"          │      │ ░░░░░ │
│ ░░ │  │                    │    │                     │      │ ░░░░░ │
│ ░░ │  │  ✦ 7 slots         │    │  ✦ 7 slots          │      │ ░░░░░ │
│ ░░ │  │  ✦ Rent: $600      │    │  ✦ Rent: $800       │      │ ░░░░░ │
│ ░░ │  │  ✦ Rare ingredients│    │  ✦ Production lines  │      │ ░░░░░ │
│ ░░ │  │  ✦ On-site pub     │    │  ✦ Marketing events  │      │ ░░░░░ │
│ ░░ │  │  ✦ Max staff: 3    │    │  ✦ Max staff: 4      │      │ ░░░░░ │
│ ░░ │  │                    │    │                     │      │ ░░░░░ │
│ ░░ │  │  Best for:         │    │  Best for:          │      │ ░░░░░ │
│ ░░ │  │  Experimentation,  │    │  Consistency,       │      │ ░░░░░ │
│ ░░ │  │  variety, craft    │    │  scale, brand       │      │ ░░░░░ │
│ ░░ │  │                    │    │                     │      │ ░░░░░ │
│ ░░ │  │  [ Choose Artisan ]│    │  [ Choose Mass  ]   │      │ ░░░░░ │
│ ░░ │  └────────────────────┘    └────────────────────┘      │ ░░░░░ │
│ ░░ │                                                         │ ░░░░░ │
│ ░░ │                    [ Go Back ]                          │ ░░░░░ │
│ ░░ └────────────────────────────────────────────────────────┘ ░░░░░ │
└──────────────────────────────────────────────────────────────────────┘
```

### Panel: 900x550 (matches card tokens)
- Background: surface (#0B1220), border: accent (#FFC857), corner_radius: 4

### Layout
```
PanelContainer "ForkOverlay" (900x550, centered)
├── VBoxContainer (padding: 32, separation: 16)
│   ├── Label "CHOOSE YOUR PATH" (lg/32px, accent)
│   ├── Label "This decision is permanent for this run." (sm/20px, danger #FF7B7B)
│   ├── HSeparator
│   ├── HBoxContainer (separation: 24, centered)
│   │   ├── PanelContainer "ArtisanCard" (380x340, primary border #5AA9FF)
│   │   │   ├── VBoxContainer (padding: 16, separation: 8)
│   │   │   │   ├── Label "ARTISAN BREWERY" (md/24px, primary)
│   │   │   │   ├── Label '"Quality over quantity"' (xs/16px, muted, italic)
│   │   │   │   ├── HSeparator
│   │   │   │   ├── Label "✦ 7 station slots" (sm/20px, white)
│   │   │   │   ├── Label "✦ Rent: $600/period" (sm/20px, white)
│   │   │   │   ├── Label "✦ Rare ingredients" (sm/20px, white)
│   │   │   │   ├── Label "✦ On-site pub" (sm/20px, white)
│   │   │   │   ├── Label "✦ Max staff: 3" (sm/20px, white)
│   │   │   │   ├── HSeparator
│   │   │   │   ├── Label "Best for:" (xs/16px, muted)
│   │   │   │   ├── Label "Experimentation, variety, craft" (xs/16px, success)
│   │   │   │   └── Button "Choose Artisan" (primary bg, white text, 200x44)
│   │   └── PanelContainer "MassMarketCard" (380x340, accent border #FFC857)
│   │       ├── VBoxContainer (padding: 16, separation: 8)
│   │       │   ├── Label "MASS-MARKET BREWERY" (md/24px, accent)
│   │       │   ├── Label '"Volume over variety"' (xs/16px, muted, italic)
│   │       │   ├── ... (same structure as Artisan)
│   │       │   └── Button "Choose Mass-Market" (accent bg, dark text, 200x44)
│   ├── Button "Go Back" (muted, centered, 160x40)
```

### Confirmation Dialog (after choosing)
```
┌────────────────────────────────────┐
│  ARE YOU SURE?                     │
│  ─────────────────────             │
│  You've chosen: Artisan Brewery    │
│                                    │
│  This cannot be undone.            │
│  Upgrade cost: $5,000              │
│                                    │
│  [ Cancel ]    [ Confirm ]         │
└────────────────────────────────────┘
```

- Confirmation text in danger color
- Style: small centered dialog (360x220), same as other confirmation dialogs

---

## 5. Gating Indicators

### Staff Button (Garage — Locked)
```
[ Staff 🔒 ]  — button_rectangle_border.png style, muted text
```
- Tooltip: "Upgrade to Microbrewery to hire staff"
- Clicking shows a small toast: "Staff hiring requires Microbrewery"

### Equipment Shop — Tier Gating
```
┌──────────────────────────────────────┐
│  EQUIPMENT SHOP                      │
│  ─────────────────────               │
│  ┌──────────────────┐               │
│  │ Premium Kettle   │  T2 — $800    │ ← available
│  │ [ Buy ]          │               │
│  └──────────────────┘               │
│  ┌──────────────────┐               │
│  │ Pro Kettle       │  T3 — $2,000  │ ← locked
│  │ 🔒 Microbrewery  │               │
│  └──────────────────┘               │
│  ┌──────────────────┐               │
│  │ Industrial Kettle│  T4 — $5,000  │ ← locked
│  │ 🔒 Microbrewery  │               │
│  └──────────────────┘               │
└──────────────────────────────────────┘
```

- T3-T4 equipment: card shown with muted opacity (0.5), lock icon
- Lock label: "Requires Microbrewery" in muted text (xs/16px)
- After expanding, lock disappears and Buy button becomes active

---

## 6. Expansion Toast Notifications

### On Threshold Reached
```
Toast: "★ Your brewery is ready to expand! Check Equipment Management."
```
- Accent color (#FFC857), shown at end of brew results
- Uses existing ToastManager

### On Expansion Complete
```
Toast: "★ Welcome to your Microbrewery! 2 new station slots unlocked."
```
- Success color (#5EE8A4)
- Shown after overlay closes

### On Rent Change
```
Toast: "Rent increased: $150 → $400 per period"
```
- Warning color (#FFB347)
- Shown alongside expansion toast

---

## 7. Stage Indicator (Header)

The brewery hub header reflects the current stage.

### Garage (default)
```
Balance: $2,450
EQUIPMENT MANAGEMENT
```

### Microbrewery
```
Balance: $3,200           Beers: 12/25
MICROBREWERY
```

### Artisan/Mass-Market
```
Balance: $8,500
ARTISAN BREWERY
```

- "Beers: 12/25" progress shown only at microbrewery stage (tracks toward fork threshold)
- Stage name replaces "EQUIPMENT MANAGEMENT" as header

### Layout
```
VBoxContainer (header)
├── HBoxContainer
│   ├── Label "Balance: $N" (sm/20px, white)
│   └── Label "Beers: N/25" (sm/20px, muted — only at microbrewery)
├── Label "MICROBREWERY" (lg/32px, accent)
```

---

## Color Usage Summary

| Element | Color | Token |
|---------|-------|-------|
| Expansion banner/border | #FFC857 | accent |
| Benefits list | #5EE8A4 | success |
| Costs list | #FFB347 | warning |
| Permanent warning text | #FF7B7B | danger |
| Locked items | #8A9BB1 | muted |
| Artisan card border | #5AA9FF | primary |
| Mass-Market card border | #FFC857 | accent |
| Stage header (upgraded) | #FFC857 | accent |
| New slot pulse border | #FFC857 | accent |

No new theme tokens needed — existing palette covers all states.

---

## Interaction Spec

### Expansion Flow
1. Player reaches threshold ($5,000 + 10 beers) → toast notification at end of brew
2. Next EQUIPMENT_MANAGE: expansion banner appears at top with slide-down
3. Player clicks "View Details >" → expansion overlay opens (fade-in 0.2s)
4. Player reviews benefits/costs → clicks "Expand — $3,000"
5. $3,000 deducted from balance
6. Scene transition: brief fade-out (0.3s) → microbrewery layout fades in (0.3s)
7. Success toast + rent warning toast
8. Banner disappears, header changes to "MICROBREWERY"
9. 2 new station slots visible with pulsing accent borders

### Fork Flow (Microbrewery → Artisan/Mass-Market)
1. Player reaches fork threshold ($15,000 + 25 beers) → toast notification
2. Next EQUIPMENT_MANAGE: fork banner appears (same position as expansion banner)
3. Player clicks "View Details >" → fork choice overlay opens
4. Player hovers over cards → subtle glow on hovered card
5. Player clicks "Choose [Path]" → confirmation dialog
6. Confirm → $5,000 deducted, scene transitions to chosen path layout
7. Fork choice saved to GameState (permanent for this run)

### Gating Flow
1. In garage: Staff button shows lock icon, clicking shows toast
2. In garage: Equipment shop shows T3-T4 items locked with "Requires Microbrewery"
3. After expansion: locks removed, full access granted

### Save/Load
- `brewery_stage` persisted in GameState save data
- `fork_choice` persisted (null until chosen)
- Expansion banner state: derived from thresholds vs current stage (not saved)
