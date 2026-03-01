# Stage 2A: Equipment System Design

## Overview

Add an equipment system to BeerBrew Tycoon with purchasable, upgradeable brewing equipment that provides stat bonuses. Equipment is managed contextually from the BreweryScene, with station slots determining which items are active.

## Decisions Made

- **Stat bonuses only** — no UI information gating (deferred to later stage)
- **Contextual BreweryScene interaction** — click station slots on the brewery to manage equipment
- **Permanent purchases with upgrade paths** — buy once, upgrade for a discount
- **Tiers 1–4 only** — tiers 5–7 deferred to Stage 5
- **3 station slots** in garage stage

## Interaction Model

### BreweryScene Station Slots

The isometric garage shows 3 station positions as clickable areas:

- **Empty slots**: Dashed outline with "+" icon (muted color #8A9BB1)
- **Occupied slots**: Equipment name label with tier badge
- **Click any slot** → opens Equipment Popup anchored near the clicked position

### Equipment Popup (mini-card, ~500x400px)

Contextual based on slot state:

**Empty slot — "Choose Equipment":**
- Scrollable list of owned-but-unassigned items
- "Browse Shop" button to open full catalog

**Occupied slot — item details:**
- Equipped item stats display
- "Swap" button (pick from owned inventory)
- "Upgrade" button (if upgrade available, shows cost)
- "Browse Shop" button

### Equipment Shop Card (full overlay, 900x550px)

Standard card overlay (same pattern as StylePicker/RecipeDesigner):

- Category tabs: All / Brewing / Fermentation / Packaging / Utility
- Item rows: name, tier badge, stat bonuses, cost, Buy/Upgrade button
- Owned items marked with checkmark
- Upgradeable items show current → upgraded version with cost difference

## Equipment Catalog (Tiers 1–4)

### Brewing

| Item | Tier | Sanitation | Temp Ctrl | Efficiency | Cost | Upgrades To |
|------|------|-----------|-----------|------------|------|-------------|
| Extract Kit | 1 | 0 | 0 | 0.0 | 0 | BIAB Setup |
| BIAB Setup | 2 | +5 | +5 | +0.05 | 150 | Mash Tun |
| Mash Tun + HLT | 3 | +10 | +10 | +0.10 | 500 | 3-Vessel |
| 3-Vessel + Pumps | 4 | +15 | +15 | +0.15 | 1200 | — |

### Fermentation

| Item | Tier | Sanitation | Temp Ctrl | Efficiency | Cost | Upgrades To |
|------|------|-----------|-----------|------------|------|-------------|
| Bucket Fermenter | 1 | 0 | 0 | 0.0 | 0 | Carboy |
| Glass Carboy | 2 | +5 | +5 | +0.05 | 100 | Temp Chamber |
| Temp Control Chamber | 3 | +5 | +15 | +0.10 | 400 | SS Conical |
| SS Conical Fermenter | 4 | +15 | +10 | +0.10 | 900 | — |

### Packaging

| Item | Tier | Sanitation | Temp Ctrl | Efficiency | Cost | Upgrades To |
|------|------|-----------|-----------|------------|------|-------------|
| Bottles + Capper | 1 | 0 | 0 | 0.0 | 0 | Bench Capper |
| Bench Capper | 2 | +5 | 0 | +0.05 | 80 | Kegging Kit |
| Kegging Kit | 3 | +10 | +5 | +0.05 | 350 | Counter Pressure |
| Counter Pressure Filler | 4 | +10 | +5 | +0.10 | 800 | — |

### Utility

| Item | Tier | Sanitation | Temp Ctrl | Efficiency | Cost | Upgrades To |
|------|------|-----------|-----------|------------|------|-------------|
| Cleaning Bucket | 1 | +5 | 0 | 0.0 | 0 | Star San Kit |
| Star San Kit | 2 | +10 | 0 | +0.05 | 60 | CIP Pump |
| CIP Pump System | 3 | +20 | 0 | +0.05 | 300 | — |

### Starting State

Player begins with all tier-1 items owned. 3 of 4 must be assigned to the 3 station slots (player chooses).

### Upgrade Pricing

Upgrading costs ~60% of the target item's full price (trade-in discount).

## Game Flow Integration

### New State: EQUIPMENT_MANAGE

```
RESULTS → EQUIPMENT_MANAGE → STYLE_SELECT
```

- BreweryScene is the background during this state
- Player balance displayed prominently
- "Start Brewing →" button to proceed to Style Select
- No timer pressure

### GameState Additions

```gdscript
var owned_equipment: Array[String] = []     # equipment IDs
var station_slots: Array[String] = ["", "", ""]  # 3 slots
var active_bonuses: Dictionary = {}         # computed aggregate

signal equipment_purchased(equipment_id: String)
signal equipment_slotted(slot_index: int, equipment_id: String)
signal bonuses_updated(active_bonuses: Dictionary)
```

### Bonus Aggregation

When station_slots change, recalculate active_bonuses:

```
sanitation_quality = 50 + sum(slotted.sanitation_bonus)
temp_control_quality = 50 + sum(slotted.temp_control_bonus)
efficiency_multiplier = 1.0 + sum(slotted.efficiency_bonus)
batch_size_multiplier = product(slotted.batch_size_multiplier)  # default 1.0
```

### BrewingPhases Enhancement

Small label above sliders (muted color):
"Equipment bonuses: +X sanitation, +Y temp control, +Z% efficiency"

## Testing Strategy

### Core Tests

1. **Equipment Resource** — all 15 items load correctly, properties valid, upgrade chains resolve
2. **Purchase logic** — buy item → balance deducted, item in owned; can't buy if insufficient balance; can't buy already-owned
3. **Upgrade logic** — upgrade from base → target, discount applied, base removed, target added; slotted item stays slotted after upgrade
4. **Station slots** — assign, unassign, swap; can't assign unowned; max 3 enforced
5. **Bonus aggregation** — slotting/unslotting recalculates correctly; sanitation_quality and temp_control_quality update
6. **QualityCalculator integration** — efficiency bonus affects technique scoring; batch_size affects revenue

### Additional Tests

7. **Starting equipment state** — game initializes with tier-1 items owned, starting bonuses are zero (tier-1 items have zero bonuses)
8. **Economy balance** — equipment costs balanced against brew revenue; verify N brews needed for tier-2 upgrades
9. **Persistence/save-load** — equipment state survives save/load cycles
10. **State transitions** — EQUIPMENT_MANAGE transitions correctly to/from RESULTS and STYLE_SELECT
11. **Edge cases** — empty slots produce zero bonus; all slots filled; upgrading slotted item

## Architecture Notes

- Equipment follows the existing Resource pattern (like Ingredient, BeerStyle)
- Equipment data stored as .tres files in `data/equipment/`
- New EquipmentManager autoload handles purchase, upgrade, and slot logic
- UI follows existing signal-driven pattern: UI emits → autoload processes → signals broadcast → UI refreshes
- Shop card follows existing overlay pattern (DimOverlay + PanelContainer, 0.2s fade)
