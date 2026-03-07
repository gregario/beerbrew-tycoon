# Stage 5B — Specialty, Brand & Automation: Design

## Overview

Three systems that deepen the artisan/mass-market fork: specialty beers with multi-turn fermentation (artisan), brand recognition that boosts demand (shared, benefits mass-market), and automation equipment that replaces staff dependency (mass-market).

## Design Tokens

No new tokens needed. All colors, spacing, and typography covered by existing theme.json palette:
- Accent (`#FFC857`): specialty markers, active automation highlight
- Success (`#5EE8A4`): completed aged beer panels, positive mutation deltas, brand demand bonus
- Danger (`#FF7B7B`): negative mutation deltas
- Muted (`#8A9BB1`): inactive bonus source, zero brand recognition
- Primary (`#5AA9FF`): brand recognition progress bars

## 1. Style Picker — Specialty Beers

**Visibility condition:** Artisan path AND wild_fermentation researched.

```
┌─ SELECT STYLE ────────────────────────────────────────────┐
│                                                            │
│  STANDARD STYLES                                           │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐     │
│  │ Pale Ale │ │  Stout   │ │  Wheat   │ │  Lager   │     │
│  │  ★★★☆☆  │ │  ★★☆☆☆  │ │  ★☆☆☆☆  │ │  ★☆☆☆☆  │     │
│  └──────────┘ └──────────┘ └──────────┘ └──────────┘     │
│                                                            │
│  SPECIALTY STYLES ✦                        [artisan only]  │
│  ┌──────────────────┐ ┌──────────────────┐                │
│  │ ✦ Berliner Weisse │ │ ✦ Experimental   │               │
│  │   Sour/Wild Ale   │ │   Random mutation │               │
│  │   Ages: 3 turns   │ │   High variance   │               │
│  │   ★★☆☆☆          │ │   ★☆☆☆☆          │               │
│  └──────────────────┘ └──────────────────┘                │
│  ┌──────────────────┐                                      │
│  │ ✦ Lambic          │   ✦ = specialty (high risk/reward)  │
│  │   Sour/Wild Ale   │   Aging beers don't block brewing.  │
│  │   Ages: 5 turns   │                                     │
│  │   ★☆☆☆☆          │                                     │
│  └──────────────────┘                                      │
│                                                            │
│            [Select]                [Back]                   │
└────────────────────────────────────────────────────────────┘
```

**Interaction:**
- Specialty cards use accent border (`#FFC857`) to distinguish from standard styles
- "✦" marker and "Ages: X turns" label are the key differentiators
- Selecting a specialty style shows a confirmation toast: "This beer will age for X turns before results"

## 2. Cellar Panel — Aging Queue on Brewery Hub

**Visibility condition:** At least one beer in aging queue. Hidden when empty.

```
┌─ BREWERY HUB ──────────────────────── Balance: $2,450 ────┐
│                                                            │
│  [Brew] [Sell] [Equipment] [Staff]                        │
│  [Research] [Contracts] [Compete] [Market]                │
│                                                            │
│  ┌─ CELLAR (2 aging) ───────────────────────────────────┐ │
│  │                                                       │ │
│  │  Lambic          ████████░░░░░░░░  3/5 turns         │ │
│  │  Berliner Weisse ██████████████░░  2/3 turns         │ │
│  │                                                       │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                            │
│  ⚠ Expansion available!                                  │
└────────────────────────────────────────────────────────────┘
```

**Interaction:**
- Progress bars: accent (`#FFC857`) fill on dark surface bg, 2px corner radius
- Style name + turn counter in X/Y format per row
- Panel appears below button grid, above expansion banner

## 3. Aged Beer Completion — ResultsOverlay

When an aged beer's turns_remaining reaches 0, a completion panel appears in ResultsOverlay:

```
┌─ BREW RESULTS ──────────────────────── Quality: 72 ───────┐
│                                                            │
│  [Normal results: score breakdown, revenue, etc.]         │
│                                                            │
│  ┌─ ✦ AGED BEER READY ──────────────── success border ──┐ │
│  │                                                       │ │
│  │  Lambic (Sour/Wild Ale)                              │ │
│  │  Aged 5 turns — Fermentation complete!               │ │
│  │                                                       │ │
│  │  Quality: 88 ★★★★☆    (variance: +12)               │ │
│  │  Revenue: +$420                                       │ │
│  │                                                       │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                            │
│                    [Continue]                               │
└────────────────────────────────────────────────────────────┘
```

**Interaction:**
- Success border (`#5EE8A4`) on completion panel
- Shows variance contribution so players understand risk/reward
- Toast fires when beer completes: "Your Lambic has finished aging!"
- Multiple completions same turn: stack panels vertically

## 4. Experimental Brew Mutation — ResultsOverlay

When an experimental brew resolves, a mutation panel shows what changed:

```
┌─ BREW RESULTS ──────────────────────── Quality: 78 ───────┐
│                                                            │
│  [Normal score breakdown panels...]                       │
│                                                            │
│  ┌─ ✦ MUTATION ──────────────────────── accent border ──┐ │
│  │                                                       │ │
│  │  Cascade Hops mutated!                               │ │
│  │                                                       │ │
│  │  Flavor:    10 → 14  (+4)          ↑ green           │ │
│  │  Technique:  8 →  5  (-3)          ↓ red             │ │
│  │                                                       │ │
│  │  "An unexpected fermentation reaction amplified       │ │
│  │   hop aromatics but reduced clarity."                 │ │
│  │                                                       │ │
│  └───────────────────────────────────────────────────────┘ │
│                                                            │
│  Revenue: +$185                                            │
│                    [Continue]                               │
└────────────────────────────────────────────────────────────┘
```

**Interaction:**
- Accent border (`#FFC857`) — notable, not inherently good/bad
- Positive changes in success (`#5EE8A4`), negative in danger (`#FF7B7B`)
- Italic flavor text gives thematic explanation
- "(Lucky!)" tag in success color if mutation improved overall score
- Discovery system can trigger from mutations — toast if new insight gained

## 5. Brand Recognition — MarketForecast

New section at top of existing Forecast tab:

```
┌─ MARKET FORECAST ─────────────── [Forecast] [Channels] [Research] ─┐
│                                                            │
│  BRAND RECOGNITION                                        │
│                                                            │
│  Pale Ale    ███████░░░  72   +36% demand                │
│  Stout       ███░░░░░░░  30   +15% demand                │
│  Wheat       █░░░░░░░░░  10    +5% demand                │
│  Lager       ░░░░░░░░░░   0    +0% demand                │
│  IPA         ████░░░░░░  45   +22% demand                │
│                                                            │
│ ─────────────────────────────────────────────────────────  │
│                                                            │
│  SEASONAL DEMAND              Season: Summer (turns 7-12) │
│  [existing seasonal grid...]                              │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

**Interaction:**
- Brand section above seasonal demand — most actionable info first
- Progress bars: primary (`#5AA9FF`) fill on dark surface bg, 2px corner radius
- Demand bonus in success (`#5EE8A4`) when > 0%, muted when 0%
- Only shows unlocked styles
- Bar width ~200px, style name label 80px fixed width
- Section separator: thin muted line at 0.2 alpha

## 6. Automation vs Staff Bonus — BrewingPhases

Extends existing bonus label line. Mass-market path only (when automation equipment is slotted):

```
┌─ MASHING ──────────────────────────────────────────────────┐
│                                                            │
│  Temperature    [====|=========]  65°C                    │
│  Duration       [========|=====]  45 min                  │
│                                                            │
│  Equipment: San +20, Temp +15, Eff +10%                   │
│  Bonus: Staff +5 | Auto +8 (active)                       │
│                                                            │
│  Points: Flavor 24 | Technique 18                         │
│                                                            │
│                    [Next Phase]                             │
└────────────────────────────────────────────────────────────┘
```

**Three display states:**

| State | Display | Colors |
|-------|---------|--------|
| Staff only (no automation) | `Bonus: Staff +5` | white |
| Automation only (no staff) | `Bonus: Auto +8` | white |
| Both present | `Bonus: Staff +5 \| Auto +8 (active)` | inactive=muted, active=accent |

**Interaction:**
- Uses existing `_update_bonus_label()` pattern
- Per-phase: mashing shows mash bonus, boiling shows boil bonus, fermenting shows ferment bonus
- "(active)" label on whichever wins the max() comparison
- Artisan path players never see automation — only "Bonus: Staff +X"
- Hidden entirely if neither applies (current behavior)

## 7. Automation Equipment in EquipmentShop

Automation appears as a new category tab in the shop, visible only for mass-market path:

```
┌─ EQUIPMENT SHOP ────── [Brewing] [Ferment] [Packaging] [Utility] [Auto] ─┐
│                                                            │
│  AUTOMATION                                  Balance: $X  │
│                                                            │
│  ┌─ Auto-Mash Controller ─── T3 ── $800 ───────────────┐ │
│  │  Mash: +5   Boil: +0   Ferment: +0                  │ │
│  │  "Automated temperature control for consistent mash" │ │
│  │                                    [Buy]             │ │
│  └──────────────────────────────────────────────────────┘ │
│  ┌─ Automated Boil System ─── T4 ── $1,500 ────────────┐ │
│  │  Mash: +0   Boil: +7   Ferment: +0                  │ │
│  │                                    [Buy]             │ │
│  └──────────────────────────────────────────────────────┘ │
│  ┌─ Fermentation Controller ── T4 ── $1,800 ───────────┐ │
│  │  Mash: +0   Boil: +0   Ferment: +8                  │ │
│  │                                    [Buy]             │ │
│  └──────────────────────────────────────────────────────┘ │
│  ┌─ Full Automation Suite ──── T5 ── $3,500 ────────────┐ │
│  │  Mash: +6   Boil: +6   Ferment: +6                  │ │
│  │                                    [Buy]             │ │
│  └──────────────────────────────────────────────────────┘ │
│                                                            │
│                    [Close]                                  │
└────────────────────────────────────────────────────────────┘
```

**Interaction:**
- [Auto] tab hidden for artisan path players
- Cards follow existing equipment card pattern
- Shows per-phase bonuses instead of sanitation/temp_control
- Tier-gating applies (T3 needs microbrewery, T5 needs mass-market stage)
- Owned items show "OK" badge in success, same as current equipment
