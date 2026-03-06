# Wireframe: Stage 4B — Competitions UI

## 1. Competition Announcement Toast

When a competition is scheduled (every 8-10 turns), a prominent toast appears:

```
Toast: "🏆 Competition announced! Oktoberfest Lager Cup — Entry: $200 — 2 turns to enter"
```
- Accent color (#FFC857)
- Shown at turn advancement in `_on_results_continue()`

---

## 2. Brewery Hub — Competitions Button

The brewery hub gains a "Competitions" button. When a competition is active (announced but not yet judged), the button shows a badge.

```
┌──────────────────────────────────────────────────────────────────────┐
│  Balance: $4,200                      Beers: 14/25                   │
│  MICROBREWERY                                                        │
│                                                                      │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  │
│  │  Kettle  │  │Fermenter│  │ Bottler │  │  Slot 4  │  │  Slot 5  │  │
│  │ Premium  │  │  Basic  │  │ [Empty] │  │ [Empty]  │  │ [Empty]  │  │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘  │
│                                                                      │
│  [ Start Brewing > ] [ Research ] [ Staff ] [ Contracts ] [ Compete ]│
└──────────────────────────────────────────────────────────────────────┘
```

- "Compete" button: right of Contracts button
- Style: accent (#FFC857 bg, dark text, 160x48) when competition active, primary (#5AA9FF) otherwise
- Badge: "Compete (!)" when a competition is announced and player hasn't entered yet

### Layout Detail
```
HBoxContainer (bottom bar, centered)
├── Button "Start Brewing >"  (accent #FFC857, 240x48)
├── Button "Research"         (primary #5AA9FF, 160x48)
├── Button "Staff"            (primary #5AA9FF, 160x48)
├── Button "Contracts"        (primary #5AA9FF, 160x48)
└── Button "Compete"          (accent #FFC857 when active / primary #5AA9FF, 160x48)
```

---

## 3. Competition Entry Screen (Overlay)

Full-screen overlay (same pattern as Contracts/Staff/Research overlays).

```
┌──────────────────────────────────────────────────────────────────────┐
│ ░░░░░░░░░░░░░░░░░░░░░░░ dim bg (0.6 alpha) ░░░░░░░░░░░░░░░░░░░░░░ │
│ ░░ ┌────────────────────────────────────────────────────────┐ ░░░░░ │
│ ░░ │  🏆 BEER COMPETITION                              [X] │ ░░░░░ │
│ ░░ │  ─────────────────────────────────────────────────────  │ ░░░░░ │
│ ░░ │                                                         │ ░░░░░ │
│ ░░ │  Oktoberfest Lager Cup                                  │ ░░░░░ │
│ ░░ │  Category: Lager           Entry Fee: $200              │ ░░░░░ │
│ ░░ │  Deadline: 2 turns remaining                            │ ░░░░░ │
│ ░░ │                                                         │ ░░░░░ │
│ ░░ │  PRIZES                                                 │ ░░░░░ │
│ ░░ │  ┌──────────┐  ┌──────────┐  ┌──────────┐             │ ░░░░░ │
│ ░░ │  │  🥇 GOLD  │  │ 🥈 SILVER │  │ 🥉 BRONZE │             │ ░░░░░ │
│ ░░ │  │  $800     │  │  $400     │  │  $200     │             │ ░░░░░ │
│ ░░ │  └──────────┘  └──────────┘  └──────────┘             │ ░░░░░ │
│ ░░ │                                                         │ ░░░░░ │
│ ░░ │  ─────────────────────────────────────────────────────  │ ░░░░░ │
│ ░░ │  SELECT ENTRY                                           │ ░░░░░ │
│ ░░ │  ┌─────────────────────────────────────────────────┐   │ ░░░░░ │
│ ░░ │  │ Your most recent brew:                           │   │ ░░░░░ │
│ ░░ │  │ Style: Lager    Quality: 72    (Matches!)        │   │ ░░░░░ │
│ ░░ │  │                        [ Enter Competition ]     │   │ ░░░░░ │
│ ░░ │  └─────────────────────────────────────────────────┘   │ ░░░░░ │
│ ░░ │                                                         │ ░░░░░ │
│ ░░ │  No entry yet. Brew a Lager to compete!                 │ ░░░░░ │
│ ░░ └────────────────────────────────────────────────────────┘ ░░░░░ │
└──────────────────────────────────────────────────────────────────────┘
```

### Panel: 900x550 (matches other overlays)
- Background: surface (#0B1220), border: accent (#FFC857), corner_radius: 4

### Header Row
```
HBoxContainer
├── Label "BEER COMPETITION"    (lg/32px, white)
└── Button "X"                   (close, danger hover)
```

### Competition Details Section
```
VBoxContainer (separation: 8)
├── Label "Oktoberfest Lager Cup"     (md/24px, accent #FFC857)
├── HBoxContainer
│   ├── Label "Category: Lager"       (sm/20px, muted #8A9BB1)
│   ├── Label "Entry Fee: $200"       (sm/20px, danger #FF7B7B)
├── Label "Deadline: 2 turns remaining" (sm/20px, warning #FFB347)
```

### Prizes Section
```
HBoxContainer (separation: 16)
├── PanelContainer (gold, 150x80)
│   ├── Label "GOLD"      (sm/20px, #FFD700)
│   └── Label "$800"      (md/24px, success #5EE8A4)
├── PanelContainer (silver, 150x80)
│   ├── Label "SILVER"    (sm/20px, #C0C0C0)
│   └── Label "$400"      (md/24px, success #5EE8A4)
├── PanelContainer (bronze, 150x80)
│   ├── Label "BRONZE"    (sm/20px, #CD7F32)
│   └── Label "$200"      (md/24px, success #5EE8A4)
```

### Entry Section
- If player has brewed a matching style: show most recent brew with quality, "Enter Competition" button
- "Enter Competition" button: accent (#FFC857 bg, dark text, 200x48)
- If category is "open": any style qualifies
- If no matching brew: show "(No qualifying brew — brew a [Style] to compete!)" in muted text
- If already entered: show "Entry submitted! Quality: 72" in success text, button disabled
- Entry uses the LAST brew result (not historical — the most recent `last_brew_result`)

### No Active Competition State
When no competition is active, show:
```
┌────────────────────────────────────────────────────┐
│  BEER COMPETITION                              [X] │
│  ─────────────────────────────────────────────────  │
│                                                     │
│  No competition currently active.                   │
│                                                     │
│  Next competition in: ~4 turns                      │
│                                                     │
│  MEDAL CABINET                                      │
│  Gold: 2   Silver: 1   Bronze: 3                    │
│                                                     │
└────────────────────────────────────────────────────┘
```

---

## 4. Competition Results Toast

After judging (when competition deadline expires):

### Gold Win
```
Toast: "🥇 GOLD MEDAL! Oktoberfest Lager Cup — Your Lager (Quality 82) won! +$800"
```
- Success color (#5EE8A4)

### Silver
```
Toast: "🥈 Silver Medal! Oktoberfest Lager Cup — +$400"
```
- Success color (#5EE8A4)

### Bronze
```
Toast: "🥉 Bronze Medal! Oktoberfest Lager Cup — +$200"
```
- Muted color (#8A9BB1)

### No Placement
```
Toast: "Competition ended. Your entry didn't place. Better luck next time!"
```
- Danger color (#FF7B7B)

### Rare Unlock (25% chance on gold)
```
Toast: "Gold medal bonus! Unlocked rare ingredient: Trappist Yeast"
```
- Accent color (#FFC857)

---

## 5. Results Overlay — Competition Badge

After brewing, if the player entered that brew into a competition, show a small indicator:

```
┌─────────────────────────────────────────────────────┐
│  BREW RESULTS                                        │
│  ─────────────────────────────────────────────       │
│  Quality: 78                  Revenue: $245          │
│  ─────────────────────────────────────────────       │
│                                                      │
│  COMPETITION ENTRY                                   │
│  ┌─────────────────────────────────────────────┐    │
│  │ Entered: Oktoberfest Lager Cup               │    │
│  │ Your quality: 78 — Results after deadline     │    │
│  └─────────────────────────────────────────────┘    │
│                                                      │
│                            [ Continue ]              │
└─────────────────────────────────────────────────────┘
```

- Accent border (#FFC857) for pending competition entry
- Only appears if the player has entered the current competition

---

## Color Usage Summary

| Element | Color | Token |
|---------|-------|-------|
| Competition name | #FFC857 | accent |
| Gold medal text | #FFD700 | (custom gold) |
| Silver medal text | #C0C0C0 | (custom silver) |
| Bronze medal text | #CD7F32 | (custom bronze) |
| Prize amounts | #5EE8A4 | success |
| Entry fee | #FF7B7B | danger |
| Deadline (safe) | #FFB347 | warning |
| Deadline (urgent) | #FF7B7B | danger |
| No placement result | #FF7B7B | danger |
| Entry button | #FFC857 | accent |
| Compete button (active) | #FFC857 | accent |
| Compete button (inactive) | #5AA9FF | primary |
| Medal cabinet counts | #8A9BB1 | muted |

No new theme tokens needed — existing palette plus standard medal colors cover all states.

---

## Interaction Spec

### Competition Scheduling Flow
1. CompetitionManager tracks turns since last competition
2. Every 8-10 turns (random interval), a competition is announced
3. Announcement toast shown at turn advancement
4. Competition has a 2-turn entry window
5. After entry window closes, judging occurs automatically

### Entry Flow
1. Player clicks "Compete" button on brewery hub
2. Competition overlay opens showing competition details and prizes
3. If player has a qualifying most-recent brew:
   - Shows brew style and quality
   - Player clicks "Enter Competition" and pays entry fee
   - Entry confirmed, toast shown
4. If no qualifying brew: message says to brew the right style
5. Player can only enter once per competition

### Judging Flow
1. When competition deadline reaches 0 (in `_on_results_continue`):
   - CompetitionManager generates 3 competitor scores
   - Competitor score range: `base + randi_range(-10, 10)` where base scales with turn count
   - Base formula: `min(40 + turn_counter * 1.5, 85)` — opponents get tougher over time
2. Player's entry quality compared against all 3 competitors
3. Placement determined: Gold (beat all 3), Silver (beat 2), Bronze (beat 1), No placement (beat 0)
4. Prize awarded, medal recorded
5. Result toast shown

### Medal Tracking
- `CompetitionManager.medals: Dictionary = {"gold": 0, "silver": 0, "bronze": 0}`
- Gold medals count toward artisan path win condition (Stage 5)
- Medals persisted in save/load

### Rare Unlock on Gold (25% chance)
1. On gold win, roll `randf() < 0.25`
2. If success: unlock a random locked ingredient via ResearchManager or IngredientCatalog
3. Show toast with unlocked ingredient name

### Save/Load
- `current_competition` Dictionary (or null if none active)
- `turns_until_next` counter
- `medals` Dictionary
- `player_entry` Dictionary (or null)
