# Stage 6 — Meta-Progression Design Deliverables

## Overview

Stage 6 adds roguelite persistence between runs. Four new screens, one new token color, and modifications to existing GameOverScreen and Game.gd reset flow.

---

## New Token Addition

Add to `theme.json` palette:
- `"meta"`: `"#B88AFF"` — purple, used for unlock points and meta-progression UI accents

---

## Screen 1: Run Summary & Unlock Points (post-game-over)

**When**: Shown after GameOverScreen "New Run" button is pressed (or automatically after game over stats are dismissed).

**Pattern**: CanvasLayer overlay (layer=10), extends existing overlay architecture.

```
┌─────────────────────────────────────────────────────────┐
│                    RUN COMPLETE                          │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │  UNLOCK POINTS EARNED                             │  │
│  │                                                   │  │
│  │  Turns survived (12)          ·····  +3 UP        │  │
│  │  Total revenue ($8,420)       ·····  +4 UP        │  │
│  │  Best quality (87)            ·····  +4 UP        │  │
│  │  Competition medals (2)       ·····  +2 UP        │  │
│  │  Run won                      ·····  +5 UP        │  │
│  │  Challenge modifier (1.5x)    ·····  ×1.5         │  │
│  │  ─────────────────────────────────────────         │  │
│  │  TOTAL                        ·····  27 UP        │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
│  Lifetime points: 27  |  Available: 27                  │
│                                                         │
│               [ Continue to Unlocks ]                   │
└─────────────────────────────────────────────────────────┘
```

**Layout**: 900x550 card, VBoxContainer.
- Title: "RUN COMPLETE" (xl/40px, Display-Bold, centered)
- Inner panel: GridContainer (2 cols), metric name left (sm/20px), points right (sm/20px, meta purple)
- Challenge modifier row only if active (accent color)
- HSeparator before total
- Total row: bold, larger (md/24px)
- Lifetime/available: muted text (xs/16px, centered)
- Footer: single CTA button "Continue to Unlocks" (meta purple bg, dark text)

**Point Calculation** (from spec):
- Turns survived: `min(turns / 5, 5)` → 0-5 UP
- Revenue: `min(int(revenue / 2000), 5)` → 0-5 UP
- Best quality: `min(int(best_quality / 20), 5)` → 0-5 UP
- Medals: 1 UP per medal (max 5)
- Win bonus: 5 UP
- Challenge multiplier: 1.5x total if any challenge modifier active

---

## Screen 2: Meta-Progression Unlock Shop

**When**: Shown after Run Summary "Continue to Unlocks" button. Also accessible from Main Menu.

**Pattern**: CanvasLayer overlay, tabbed layout (like EquipmentShop automation tab pattern).

```
┌─────────────────────────────────────────────────────────┐
│  UNLOCK SHOP                          Available: 27 UP  │
│                                                         │
│  [ Styles ] [ Blueprints ] [ Ingredients ] [ Perks ]    │
│  ─────────────────────────────────────────────────────── │
│                                                         │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐       │
│  │  Amber Ale  │ │  Porter     │ │  Saison     │       │
│  │             │ │             │ │             │       │
│  │  Malt-      │ │  Roasted    │ │  Spicy,     │       │
│  │  forward,   │ │  coffee     │ │  fruity     │       │
│  │  caramel    │ │  notes      │ │  esters     │       │
│  │             │ │             │ │             │       │
│  │  Cost: 5 UP │ │  Cost: 8 UP │ │  Cost: 8 UP │       │
│  │             │ │             │ │             │       │
│  │ [ Unlock ]  │ │ [ Unlock ]  │ │  UNLOCKED   │       │
│  └─────────────┘ └─────────────┘ └─────────────┘       │
│                                                         │
│  ScrollContainer (if more than 3 items per row)         │
│                                                         │
│                        [ Done ]                         │
└─────────────────────────────────────────────────────────┘
```

**Layout**: 900x550 card.
- Header: HBox — title (lg/32px, Display-Bold) + available UP (meta purple, md/24px, right-aligned)
- Tab bar: HBoxContainer of 4 buttons (Styles / Blueprints / Ingredients / Perks)
  - Active tab: primary (#5AA9FF) bg
  - Inactive tab: surface bg, muted border
- Content area: ScrollContainer > GridContainer (3 columns)
  - Each unlock card: 250x220 PanelContainer
    - Name (sm/20px, Display-Bold, centered)
    - Description (xs/16px, muted, autowrap, centered)
    - Cost (sm/20px, meta purple, centered)
    - Button: "Unlock" (primary bg) or "UNLOCKED" label (success color, no button)
  - Locked items with insufficient points: button disabled, muted cost text
- Footer: "Done" button (primary bg, centered)

**Tab Contents**:

| Tab | Items | Cost Range | Description |
|-----|-------|-----------|-------------|
| Styles | Beer styles not in base 4 | 5-10 UP | Available from turn 1 next run |
| Blueprints | Equipment items | 5-8 UP | 50% research cost reduction |
| Ingredients | Rare ingredients | 3-6 UP | Available earlier in future runs |
| Perks | Passive bonuses (see below) | 8-12 UP | Select up to 3 per run |

**Perk Items** (Perks tab):
- "Nest Egg" — +5% starting cash (8 UP)
- "Quick Study" — +1 base RP per brew (10 UP)
- "Landlord's Friend" — -10% rent (8 UP)
- "Style Specialist" — +5% quality for one style family (12 UP)

---

## Screen 3: Run Start Screen (Perk & Modifier Selection)

**When**: Shown when starting a new run (after "New Run" from main menu or after unlock shop).

**Pattern**: CanvasLayer overlay. Two-section layout.

```
┌─────────────────────────────────────────────────────────┐
│                    NEW RUN SETUP                        │
│                                                         │
│  ACTIVE PERKS (0/3)                                     │
│  ┌───────────┐ ┌───────────┐ ┌───────────┐ ┌────────┐  │
│  │ Nest Egg  │ │ Quick     │ │ Landlord  │ │ Style  │  │
│  │ +5% cash  │ │ Study     │ │ -10% rent │ │ Spec.  │  │
│  │           │ │ +1 RP     │ │           │ │ +5% Q  │  │
│  │  [ ON ]   │ │  [ OFF ]  │ │  [ ON ]   │ │ LOCKED │  │
│  └───────────┘ └───────────┘ └───────────┘ └────────┘  │
│                                                         │
│  ─────────────────────────────────────────────────────  │
│                                                         │
│  MODIFIERS (0/2)                                        │
│  ┌──────────────────────┐ ┌──────────────────────────┐  │
│  │ CHALLENGE (1.5x UP)  │ │ BONUS                    │  │
│  │                      │ │                          │  │
│  │ □ Tough Market       │ │ □ Master Brewer          │  │
│  │   Demand -20%        │ │   +10% quality           │  │
│  │ □ Budget Brewery     │ │ □ Lucky Break            │  │
│  │   Half starting cash │ │   No infection (5 brews) │  │
│  │ □ Ingredient Short.  │ │ □ Generous Market        │  │
│  │   60% ingredients    │ │   +20% demand            │  │
│  │                      │ │                          │  │
│  │ 🔒 = not yet unlocked│ │ 🔒 = not yet unlocked   │  │
│  └──────────────────────┘ └──────────────────────────┘  │
│                                                         │
│                   [ Start Brewing! ]                    │
└─────────────────────────────────────────────────────────┘
```

**Layout**: 900x600 card (slightly taller than standard).
- Title: "NEW RUN SETUP" (xl/40px, Display-Bold, centered)
- **Perks Section**:
  - Label: "ACTIVE PERKS (N/3)" (md/24px, meta purple)
  - HBoxContainer of perk cards (180x120 each)
    - Unlocked: toggle ON/OFF button (ON = success border, OFF = muted border)
    - Locked: muted bg, "LOCKED" label, no interaction
    - Max 3 can be ON — toggling a 4th disables the earliest
  - Only show unlocked perks + locked placeholder slots
- HSeparator
- **Modifiers Section**:
  - Label: "MODIFIERS (N/2)" (md/24px, accent color)
  - Two columns: Challenge (left) and Bonus (right) — HBoxContainer of two PanelContainers
  - Each modifier: checkbox (custom — toggle button) + name + description
  - Locked modifiers: greyed out checkbox, muted text, lock icon prefix
  - Max 2 total modifiers (across both columns)
  - Challenge column header includes "(1.5x UP)" in accent color
- Footer: "Start Brewing!" button (accent bg, dark text, 240x48)

**Interaction Notes**:
- Perk toggle: tap card to toggle ON/OFF. If already 3 active, show toast "Max 3 perks active — deselect one first"
- Modifier toggle: checkbox-style. If already 2 active, show toast "Max 2 modifiers — deselect one first"
- Locked items are non-interactive with tooltip explaining unlock condition
- "Start Brewing!" emits `run_started` signal with selected perks and modifiers

---

## Screen 4: Achievements Panel

**When**: Accessible from Main Menu. Shows unlock conditions for modifiers.

**Pattern**: CanvasLayer overlay, simple list layout.

```
┌─────────────────────────────────────────────────────────┐
│  ACHIEVEMENTS                                           │
│  ─────────────────────────────────────────────────────── │
│                                                         │
│  ✓  First Victory                    COMPLETED          │
│     Win a run                                           │
│     Unlocks: Tough Market modifier                      │
│                                                         │
│  ✓  Budget Master                    COMPLETED          │
│     Win with <$1000 equipment spend                     │
│     Unlocks: Budget Brewery modifier                    │
│                                                         │
│  □  Perfect Brew                     IN PROGRESS        │
│     Brew a 95+ quality beer (best: 87)                  │
│     Unlocks: Master Brewer modifier                     │
│                                                         │
│  □  Survivor                         IN PROGRESS        │
│     Survive 20 turns (best: 12)                         │
│     Unlocks: Lucky Break modifier                       │
│                                                         │
│  □  Diversified                      IN PROGRESS        │
│     Unlock all 4 distribution channels                  │
│     Unlocks: Generous Market modifier                   │
│                                                         │
│  □  Scarcity Brewer                  IN PROGRESS        │
│     Win using only 10 unique ingredients                │
│     Unlocks: Ingredient Shortage modifier               │
│                                                         │
│                        [ Close ]                        │
└─────────────────────────────────────────────────────────┘
```

**Layout**: 900x550 card.
- Title: "ACHIEVEMENTS" (lg/32px, Display-Bold)
- HSeparator
- ScrollContainer > VBoxContainer of achievement rows
  - Each row: HBoxContainer
    - Status icon: checkmark (success #5EE8A4) or empty box (muted)
    - VBoxContainer:
      - Name (sm/20px, Display-Bold)
      - Description (xs/16px, muted)
      - "Unlocks: [modifier name]" (xs/16px, accent color)
    - Status label: "COMPLETED" (success) or "IN PROGRESS" (muted), right-aligned
  - Completed rows: full opacity
  - In-progress rows: show progress hint (e.g., "best: 87" for quality achievement)
  - Separator between rows (subtle, muted at 30% opacity)
- Footer: "Close" button (primary bg, centered)

**Achievement Definitions** (6 achievements, one per modifier):

| Achievement | Condition | Unlocks |
|-------------|-----------|---------|
| First Victory | Win any run | Tough Market |
| Budget Master | Win with <$1000 equipment spend | Budget Brewery |
| Perfect Brew | Brew 95+ quality beer | Master Brewer |
| Survivor | Survive 20 turns | Lucky Break |
| Diversified | Unlock all 4 distribution channels | Generous Market |
| Scarcity Brewer | Win using <=10 unique ingredients | Ingredient Shortage |

---

## Screen 5: Main Menu Update

**When**: Game launch. Replaces current immediate Game.tscn load.

**Pattern**: CanvasLayer or root scene (Node2D). Simple centered layout.

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│                                                         │
│                    BEERBREW TYCOON                      │
│                                                         │
│              ┌──────────────────────┐                   │
│              │     [ New Run ]      │                   │
│              │     [ Continue ]     │                   │
│              │     [ Unlocks ]      │                   │
│              │     [ Achievements ] │                   │
│              │     [ Quit ]         │                   │
│              └──────────────────────┘                   │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Runs: 3  |  Best: $12,400  |  Medals: 7  |  UP: 42│ │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
│  Last run: Artisan path, 15 turns, Won                  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

**Layout**: Full-screen (1280x720).
- Background: brewery scene dimmed or solid background color (#0F1724)
- Title: "BEERBREW TYCOON" (xl/40px, Display-Bold, accent color, centered)
- Button column: VBoxContainer (centered, separation=16)
  - "New Run" — accent bg (#FFC857), primary CTA (240x48)
  - "Continue" — primary bg (#5AA9FF), only if save exists (240x48)
  - "Unlocks" — surface bg, muted border (240x48)
  - "Achievements" — surface bg, muted border (240x48)
  - "Quit" — surface bg, danger border (240x48)
- Stats bar: HBoxContainer in PanelContainer (muted bg)
  - Total runs, best revenue, total medals, available UP
  - All xs/16px, muted text
- Last run summary: single line, xs/16px, muted, centered

**Flow**:
- "New Run" → Run Start Screen (perk/modifier selection) → Game.tscn
- "Continue" → Load save → Game.tscn
- "Unlocks" → Meta-Progression Unlock Shop
- "Achievements" → Achievements Panel
- "Quit" → Exit game

---

## Modified Existing Screens

### GameOverScreen Changes

Add to existing GameOverScreen, below the stats grid:
- "Unlock Points Earned: +N" label (meta purple, sm/20px)
- Change "New Run" button to flow through Run Summary → Unlock Shop → Run Start instead of directly resetting

### BreweryScene Hub Changes

No changes needed — hub buttons remain as-is during gameplay.

---

## Interaction Spec

### Transitions
- GameOver → "New Run" → Run Summary (fade in 0.2s)
- Run Summary → "Continue to Unlocks" → Unlock Shop (fade in 0.2s)
- Unlock Shop → "Done" → Run Start Screen (fade in 0.2s)
- Run Start → "Start Brewing!" → Game.tscn reset + new run (fade out 0.3s)
- Main Menu → "New Run" → Run Start Screen (fade in 0.2s)

### Unlock Point Animation (stretch goal)
- Points count up from 0 to total with 0.05s delay per point
- Each category row highlights as its points are added
- Total pulses once when complete

### Perk Toggle
- ON: card border → success (#5EE8A4), slight scale pulse (1.0 → 1.05 → 1.0, 0.15s)
- OFF: card border → muted, no animation
- Max reached: toast notification "Max 3 perks — deselect one first"

### Modifier Toggle
- Same as perk toggle but with accent (#FFC857) for challenge, primary (#5AA9FF) for bonus
- Locked: no interaction, tooltip on hover

### Sound Cues
- Unlock point tally: soft click per point (reuse existing SFX)
- Unlock purchased: success chime (reuse sfx_results)
- Perk toggled: soft click
- Run started: brew SFX

---

## Persistence Architecture

### Meta Save File (`meta.json` — separate from run saves)
```json
{
  "version": 1,
  "total_runs": 3,
  "lifetime_unlock_points": 42,
  "available_unlock_points": 15,
  "unlocked_styles": ["amber_ale", "saison"],
  "unlocked_blueprints": ["digital_thermometer", "conical_fermenter"],
  "unlocked_ingredients": ["citra_hops", "brett_yeast"],
  "unlocked_perks": ["nest_egg", "quick_study"],
  "achievements": {
    "first_victory": true,
    "budget_master": true,
    "perfect_brew": false,
    "survivor": false,
    "diversified": false,
    "scarcity_brewer": false
  },
  "achievement_progress": {
    "best_quality": 87,
    "best_turns": 15,
    "best_equipment_spend": 2400,
    "max_channels": 2,
    "min_unique_ingredients": 18
  },
  "run_history": [
    {
      "path": "artisan",
      "turns": 15,
      "revenue": 12400,
      "won": true,
      "medals": 3,
      "unlock_points": 18
    }
  ],
  "last_active_perks": ["nest_egg", "quick_study"],
  "last_active_modifiers": ["tough_market"]
}
```

### Key Design Decisions
1. Meta save is **separate** from run saves — never overwritten by run reset
2. Run history stores last 10 runs (ring buffer)
3. Achievement progress tracks best-ever stats across all runs
4. Last active perks/modifiers remembered as defaults for next run
