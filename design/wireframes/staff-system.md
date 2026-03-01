# Wireframe: Stage 3A — Staff System UI

## 1. Brewery Hub — Staff Button (Added to EquipmentUI)

The brewery hub (EQUIPMENT_MANAGE state) gains a "Staff" button alongside "Start Brewing" and "Research".

```
┌──────────────────────────────────────────────────────────────────────┐
│  Balance: $2,450                                                     │
│  EQUIPMENT MANAGEMENT                                                │
│                                                                      │
│     ┌─────────────┐    ┌─────────────┐    ┌─────────────┐           │
│     │   Kettle     │    │  Fermenter  │    │   Bottler   │           │
│     │ Basic Kettle │    │ [Empty Slot]│    │ [Empty Slot]│           │
│     └─────────────┘    └─────────────┘    └─────────────┘           │
│                                                                      │
│                                                                      │
│         [ Start Brewing > ]   [ Research ]   [ Staff ]               │
└──────────────────────────────────────────────────────────────────────┘
```

- "Staff" button position: right of Research button
- Style: same as Research (#5AA9FF bg, dark text, rounded)
- Disabled state when in garage stage (staff_max = 0): use `button_rectangle_border.png` style, muted text, tooltip "Upgrade to Microbrewery to hire staff"

### Layout Detail
```
HBoxContainer (bottom bar, centered)
├── Button "Start Brewing >"  (accent #FFC857, 240x48)
├── Button "Research"         (primary #5AA9FF, 160x48)
└── Button "Staff"            (primary #5AA9FF, 160x48)
```

---

## 2. Staff Management Screen (Overlay)

Full-screen overlay (same pattern as ResearchTree: dim bg + centered panel).

```
┌──────────────────────────────────────────────────────────────────────┐
│ ░░░░░░░░░░░░░░░░░░░░░░░ dim bg (0.6 alpha) ░░░░░░░░░░░░░░░░░░░░░░ │
│ ░░ ┌────────────────────────────────────────────────────────┐ ░░░░░ │
│ ░░ │  STAFF MANAGEMENT                    Staff: 1/2    [X] │ ░░░░░ │
│ ░░ │  ─────────────────────────────────────────────────────  │ ░░░░░ │
│ ░░ │                                                         │ ░░░░░ │
│ ░░ │  YOUR STAFF                                             │ ░░░░░ │
│ ░░ │  ┌─────────────────────────────────────────────────┐   │ ░░░░░ │
│ ░░ │  │ 👤 Lars the Brewer    Lv.3   Salary: $80/turn  │   │ ░░░░░ │
│ ░░ │  │ Creativity: ████████░░  72                      │   │ ░░░░░ │
│ ░░ │  │ Precision:  ██████░░░░  55                      │   │ ░░░░░ │
│ ░░ │  │ Assigned: Mashing  Spec: None                   │   │ ░░░░░ │
│ ░░ │  │              [ Assign ] [ Train ] [ Fire ]      │   │ ░░░░░ │
│ ░░ │  └─────────────────────────────────────────────────┘   │ ░░░░░ │
│ ░░ │                                                         │ ░░░░░ │
│ ░░ │  ─────────────────────────────────────────────────────  │ ░░░░░ │
│ ░░ │  AVAILABLE CANDIDATES              [ Refresh: Next Turn]│ ░░░░░ │
│ ░░ │  ┌──────────────────┐ ┌──────────────────┐            │ ░░░░░ │
│ ░░ │  │ 👤 Eva Hopkins   │ │ 👤 Klaus Malter  │            │ ░░░░░ │
│ ░░ │  │ Creativity: 45   │ │ Creativity: 30   │            │ ░░░░░ │
│ ░░ │  │ Precision:  62   │ │ Precision:  78   │            │ ░░░░░ │
│ ░░ │  │ Salary: $60/turn │ │ Salary: $75/turn │            │ ░░░░░ │
│ ░░ │  │    [ Hire $0 ]   │ │    [ Hire $0 ]   │            │ ░░░░░ │
│ ░░ │  └──────────────────┘ └──────────────────┘            │ ░░░░░ │
│ ░░ └────────────────────────────────────────────────────────┘ ░░░░░ │
└──────────────────────────────────────────────────────────────────────┘
```

### Panel: 900x550 (matches card tokens)
- Background: surface (#0B1220), border: muted (#8A9BB1), corner_radius: 4

### Header Row
```
HBoxContainer
├── Label "STAFF MANAGEMENT"  (lg/32px, white)
├── Label "Staff: 1/2"       (sm/20px, muted — shows current/max)
└── Button "X"               (close, danger hover)
```

### Your Staff Section
Each staff card is a PanelContainer:
```
PanelContainer (surface bg, primary border, 4px radius)
├── VBoxContainer (separation: 4, padding: 12)
│   ├── HBoxContainer
│   │   ├── Label "👤 Name"      (md/24px, white)
│   │   ├── Label "Lv.N"        (sm/20px, accent #FFC857)
│   │   └── Label "Salary: $N/turn" (sm/20px, muted, right-aligned)
│   ├── HBoxContainer — Creativity bar
│   │   ├── Label "Creativity:" (xs/16px, muted)
│   │   ├── ProgressBar         (fill: accent #FFC857, bg: surface)
│   │   └── Label "72"          (xs/16px, accent)
│   ├── HBoxContainer — Precision bar
│   │   ├── Label "Precision:"  (xs/16px, muted)
│   │   ├── ProgressBar         (fill: primary #5AA9FF, bg: surface)
│   │   └── Label "55"          (xs/16px, primary)
│   ├── HBoxContainer — Assignment/Spec
│   │   ├── Label "Assigned: Mashing" (xs/16px, success if assigned, muted if none)
│   │   └── Label "Spec: None"  (xs/16px, muted or accent if specialized)
│   └── HBoxContainer — Actions
│       ├── Button "Assign"     (primary, sm)
│       ├── Button "Train"      (accent, sm — disabled if in training)
│       └── Button "Fire"       (danger, sm)
```

- If staff member is **in training**: show "Training... (1 turn)" in warning color, disable Train and Assign buttons
- If staff member reaches **level 5 without specialization**: show "Specialize!" button in accent color instead of Train

### Candidate Cards Section
```
HBoxContainer (separation: 16)
├── PanelContainer (candidate card, 200x180)
│   ├── VBoxContainer
│   │   ├── Label "Name"         (sm/20px, white)
│   │   ├── Label "Creativity: N" (xs/16px, accent)
│   │   ├── Label "Precision: N"  (xs/16px, primary)
│   │   ├── Label "Salary: $N/turn" (xs/16px, muted)
│   │   └── Button "Hire"        (success #5EE8A4, sm)
└── ... (2-3 candidates)
```

- Candidate cards: surface bg, muted border, 4px radius
- "Hire" button disabled if staff roster is full
- Candidates refresh each turn (not player-controllable)

---

## 3. Assign Phase Popup

Small dialog when clicking "Assign" on a staff card.

```
┌────────────────────────────┐
│  ASSIGN TO PHASE           │
│  ─────────────────────     │
│  [ Mashing    ]            │
│  [ Boiling    ]            │
│  [ Fermenting ]            │
│  [ Unassign   ]            │
│                            │
│        [ Cancel ]          │
└────────────────────────────┘
```

- Each phase button shows current assignee if any: "Mashing (Lars)"
- Selecting a phase already assigned to someone else swaps them
- Style: small centered dialog, surface bg, muted border

### Layout
```
VBoxContainer (centered, 280x250)
├── Label "ASSIGN TO PHASE" (md/24px, white)
├── HSeparator
├── Button "Mashing"    (full width, primary if available)
├── Button "Boiling"    (full width, primary if available)
├── Button "Fermenting" (full width, primary if available)
├── Button "Unassign"   (full width, muted/danger)
└── Button "Cancel"     (muted)
```

---

## 4. Training Dialog

Small dialog when clicking "Train" on a staff card.

```
┌────────────────────────────────────┐
│  TRAIN STAFF: Lars                 │
│  ─────────────────────             │
│  Choose training focus:            │
│                                    │
│  [ Creativity Training  $200 ]     │
│    +5-10 creativity points         │
│                                    │
│  [ Precision Training   $200 ]     │
│    +5-10 precision points          │
│                                    │
│  Staff unavailable for 1 turn.     │
│                                    │
│           [ Cancel ]               │
└────────────────────────────────────┘
```

### Layout
```
VBoxContainer (centered, 360x300)
├── Label "TRAIN STAFF: Name" (md/24px, white)
├── HSeparator
├── Label "Choose training focus:" (sm/20px, muted)
├── Button "Creativity Training $200" (accent, full width)
├── Label "+5-10 creativity points" (xs/16px, muted)
├── Button "Precision Training $200"  (primary, full width)
├── Label "+5-10 precision points" (xs/16px, muted)
├── Label "Staff unavailable for 1 turn." (xs/16px, warning #FFB347)
└── Button "Cancel" (muted)
```

---

## 5. Specialization Dialog (at Level 5)

```
┌────────────────────────────────────────┐
│  SPECIALIZE: Lars (Level 5!)           │
│  ─────────────────────                 │
│  Choose a brewing specialty:           │
│  2x bonus in chosen phase,            │
│  0.5x in others.                       │
│                                        │
│  [ Mashing Specialist    ]             │
│  [ Boiling Specialist    ]             │
│  [ Fermenting Specialist ]             │
│                                        │
│  This cannot be undone!                │
│                                        │
│           [ Cancel ]                   │
└────────────────────────────────────────┘
```

- Warning text in danger color (#FF7B7B)
- Confirmation dialog after selection: "Are you sure? This is permanent."

---

## 6. BrewingPhases — Staff Assignment Display

During brewing, show assigned staff and their bonus below each phase slider.

```
┌─────────────────────────────────────────────────────────┐
│  BREWING PHASES                                         │
│  ─────────────────────────────────────────────────────  │
│                                                         │
│  MASHING                                                │
│  Mash Temperature                                       │
│  62°C ──┼──┼──●──┼──┼──┼──┼── 69°C                     │
│               65°C                                      │
│  👤 Lars: +14 flavor, +11 technique                     │
│                                                         │
│  BOILING                                                │
│  Boil Duration                                          │
│  30m ──┼──┼──●──┼──┼──┼── 90m                           │
│            60 min                                       │
│  (no staff assigned)                                    │
│                                                         │
│  FERMENTING                                             │
│  Fermentation Temperature                               │
│  15°C ──┼──┼──┼──●──┼──┼──┼──┼──┼──┼── 25°C            │
│                  19°C                                   │
│  (no staff assigned)                                    │
│                                                         │
│  ┌───────────────────────────────────────────────┐      │
│  │  Flavor: 89              Technique: 86        │      │
│  └───────────────────────────────────────────────┘      │
│                                         [ Brew! ]       │
└─────────────────────────────────────────────────────────┘
```

### Staff Bonus Line (per phase)
```
HBoxContainer (separation: 4)
├── Label "👤" (xs/16px)
├── Label "Name:" (xs/16px, white)
├── Label "+N flavor" (xs/16px, accent)
├── Label "+N technique" (xs/16px, primary)
```

- If no staff assigned: Label "(no staff assigned)" in muted, xs/16px
- Bonus calculation: `creativity * level_mult * spec_mult / 10` (flavor), same for precision (technique)
- Specialized staff: show spec icon or "(specialist)" tag in accent

---

## 7. Salary Deduction — Turn End Toast

At end of turn (during RESULTS → EQUIPMENT_MANAGE transition):

```
Toast: "Salaries paid: -$140 (2 staff)"
```

- Uses existing ToastManager
- Warning color if salary pushes balance below $200

---

## Color Usage Summary

| Element | Color | Token |
|---------|-------|-------|
| Creativity stat/bar | #FFC857 | accent |
| Precision stat/bar | #5AA9FF | primary |
| Level badge | #FFC857 | accent |
| Assigned phase text | #5EE8A4 | success |
| Unassigned/empty | #8A9BB1 | muted |
| Training status | #FFB347 | warning |
| Fire button / permanent warning | #FF7B7B | danger |
| Staff card bg | #0B1220 | surface |
| Staff card border (hired) | #5AA9FF | primary |
| Candidate card border | #8A9BB1 | muted |

No new theme tokens needed — existing palette covers all states.

---

## Interaction Spec

### Hire Flow
1. Player clicks "Staff" button on brewery hub
2. Staff overlay opens with fade-in (0.2s ease-out, same as other overlays)
3. Player sees current roster (top) and candidates (bottom)
4. Click "Hire" → staff added to roster, candidate card removed, count updates
5. If roster full, remaining Hire buttons disable

### Assign Flow
1. Click "Assign" on a staff card
2. Assign Phase popup appears (small centered dialog)
3. Click a phase → staff assigned, popup closes, card updates
4. If phase already has someone, they get unassigned (swap)

### Train Flow
1. Click "Train" on a staff card
2. Training dialog appears
3. Click training type → money deducted, stat boosted, staff marked "in training"
4. Next brew turn: training completes, staff becomes available, toast notification

### Level Up
1. After brew completes, XP awarded to all assigned staff
2. If XP threshold reached → level up, stats increase 2-5 points
3. Toast: "Lars leveled up! (Lv.4) Creativity +3, Precision +4"

### Specialization
1. Staff reaches level 5 → "Specialize!" button appears on card
2. Click → specialization dialog
3. Select phase → confirmation dialog ("This is permanent!")
4. Confirm → staff card updates with spec badge, bonuses recalculated

### Fire Flow
1. Click "Fire" → confirmation dialog: "Fire Lars? This cannot be undone."
2. Confirm → staff removed from roster, slot freed

### Salary Deduction
1. End of each turn (in `_on_results_continue`), total salaries calculated
2. Deducted from balance before win/loss check
3. Toast notification with total amount
