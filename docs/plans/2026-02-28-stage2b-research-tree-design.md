# Stage 2B: Research Tree — Design Document

## Overview

A 20-node research tree that gates progression behind Research Points (RP) earned from brewing. Players spend RP to unlock new ingredients, beer styles, equipment tiers, and brewing technique bonuses. The UI is a simple node graph with category tabs, drawn prerequisite lines, and positioned node cards.

## RP Accumulation

**Formula:** `2 + int(quality_score / 20)`

| Quality Score | RP Earned |
|--------------|-----------|
| 0-19 | 2 |
| 20-39 | 3 |
| 40-59 | 4 |
| 60-79 | 5 |
| 80-99 | 6 |
| 100 | 7 |

Total RP to unlock all 20 nodes: ~340 RP (~60-70 brews at moderate quality).

RP shown in ResultsOverlay after each brew: "+X RP" in accent color. Toast notification via ToastManager.

## ResearchNode Resource

`ResearchNode.gd` — pure data Resource, mirrors Equipment.gd:

```gdscript
class_name ResearchNode
extends Resource

enum Category { TECHNIQUES, INGREDIENTS, EQUIPMENT, STYLES }

@export var node_id: String
@export var node_name: String
@export var description: String
@export var category: Category
@export var rp_cost: int
@export var prerequisites: Array[String] = []  # node_ids
@export var unlock_effect: Dictionary = {}      # type + payload
```

20 `.tres` files stored in `src/data/research/<category>/`.

## The 20 Research Nodes

### Techniques (6 nodes)

| Node | RP | Prerequisites | Unlock Effect |
|------|----|---------------|---------------|
| Mash Basics | 0 | — | Starts unlocked. Baseline mash slider |
| Advanced Mashing | 15 | Mash Basics | +5% mash score bonus |
| Decoction Technique | 30 | Advanced Mashing | +10% efficiency bonus |
| Hop Timing | 0 | — | Starts unlocked. Baseline hop slider |
| Dry Hopping | 20 | Hop Timing | +15% aroma intensity bonus |
| Water Chemistry | 25 | Advanced Mashing | -50% noise on brew outcomes |

### Ingredients (4 nodes)

| Node | RP | Prerequisites | Unlock Effect |
|------|----|---------------|---------------|
| Specialty Malts | 10 | — | Unlocks crystal_60, chocolate_malt, roasted_barley |
| American Hops | 15 | — | Unlocks cascade, centennial |
| Premium Hops | 25 | American Hops | Unlocks citra, simcoe |
| Specialist Yeast | 20 | — | Unlocks belle_saison, wb06_wheat, kveik_voss |

### Equipment (4 nodes)

| Node | RP | Prerequisites | Unlock Effect |
|------|----|---------------|---------------|
| Homebrew Upgrades | 0 | — | Starts unlocked. Tier 1-2 available |
| Semi-Pro Equipment | 20 | Homebrew Upgrades | Unlocks Tier 3 equipment |
| Pro Equipment | 35 | Semi-Pro Equipment | Unlocks Tier 4 equipment |
| Adjunct Brewing | 15 | Homebrew Upgrades | Unlocks all 4 adjuncts |

### Styles (6 nodes)

| Node | RP | Prerequisites | Unlock Effect |
|------|----|---------------|---------------|
| Ale Fundamentals | 0 | — | Starts unlocked. Pale Ale available |
| Lager Brewing | 15 | Ale Fundamentals | Unlocks Lager style |
| Wheat Traditions | 15 | Ale Fundamentals | Unlocks Wheat Beer style |
| Dark Styles | 20 | Specialty Malts | Unlocks Stout style |
| IPA Mastery | 25 | American Hops, Ale Fundamentals | Placeholder for future IPA style |
| Belgian Arts | 30 | Specialist Yeast, Wheat Traditions | Placeholder for future Belgian style |

**Cross-category dependencies:** Dark Styles requires Specialty Malts (Ingredients), IPA Mastery requires American Hops (Ingredients), Belgian Arts requires Specialist Yeast (Ingredients).

## ResearchManager Autoload

Mirrors EquipmentManager pattern.

**State:**
- `research_points: int = 0`
- `unlocked_nodes: Array[String] = []`
- `catalog: Dictionary = {}` (node_id -> ResearchNode)
- `bonuses: Dictionary = {}` (bonus_name -> value, read by BrewingScience/QualityCalculator)
- `unlocked_equipment_tier: int = 2` (read by EquipmentShop)

**Signals:**
- `research_unlocked(node_id: String)`
- `rp_changed(new_amount: int)`

**Methods:**
- `can_unlock(node_id) -> bool` — prereqs met, enough RP, not already unlocked
- `unlock(node_id)` — deduct RP, add to unlocked_nodes, apply effect, emit signals
- `is_unlocked(node_id) -> bool`
- `get_available_nodes() -> Array` — prereqs met but not yet unlocked
- `add_rp(amount: int)` — add RP, emit rp_changed
- `save_state() -> Dictionary` / `load_state(data: Dictionary)` / `reset()`

**Effect types in unlock_effect dictionary:**
- `{"type": "unlock_ingredients", "ids": ["crystal_60", ...]}` — sets ingredient.unlocked = true
- `{"type": "unlock_style", "ids": ["lager"]}` — sets style.unlocked = true
- `{"type": "unlock_equipment_tier", "tier": 3}` — sets unlocked_equipment_tier
- `{"type": "brewing_bonus", "bonuses": {"mash_score_bonus": 0.05}}` — adds to bonuses dict
- `{"type": "unlock_adjuncts", "ids": [...]}` — same as unlock_ingredients

On `load_state()`: re-apply all unlock effects from unlocked_nodes to restore runtime state.

## Gating Changes to Existing Systems

### BeerStyle.gd
Add `@export var unlocked: bool = true`. Update .tres files:
- Pale Ale: `unlocked = true`
- Lager, Wheat Beer, Stout: `unlocked = false`

### StylePicker.gd
Filter to show only `style.unlocked == true`. Show locked styles greyed out with "Research required" (same pattern as locked ingredients in RecipeDesigner).

### EquipmentShop.gd
Filter items by `equipment.tier <= ResearchManager.unlocked_equipment_tier`. Default tier limit = 2. Locked tiers shown greyed with "Research required".

### QualityCalculator.gd
Read `ResearchManager.bonuses` for:
- `mash_score_bonus`: added to science sub-score
- `efficiency_bonus`: added to existing efficiency calculation

### BrewingScience.gd
Read `ResearchManager.bonuses` for:
- `noise_reduction`: multiply noise by 0.5
- `aroma_bonus`: multiply aroma intensity by 1.15

### GameState.gd
- Add `RESEARCH_MANAGE` to State enum
- Add RP accumulation in `execute_brew()`: `ResearchManager.add_rp(2 + int(quality_score / 20))`
- `reset()` calls `ResearchManager.reset()`

## Research Tree UI

Code-only Control (no .tscn), mirrors EquipmentShop pattern.

### Layout
```
DimOverlay (ColorRect, 60% opacity)
└─ CenterContainer
   └─ PanelContainer (900x600, surface #0B1220, 2px border)
      └─ VBoxContainer
         ├─ Header HBox: "Research Tree" (lg/32px) + "RP: XX" (md/24px, accent #FFC857)
         ├─ HSeparator
         ├─ Category tabs HBox: [Techniques] [Ingredients] [Equipment] [Styles]
         └─ ScrollContainer
            └─ NodeGraph (custom Control with _draw())
```

### NodeGraph
- Positions node cards as PanelContainers at fixed x,y coordinates per category
- Roots at left, children spaced rightward
- Draws prerequisite lines in `_draw()` between card positions
- Line colors: muted for locked connections, success for unlocked

### Node Cards (140x100px)
- Name, RP cost, status icon, brief unlock description
- **Unlocked:** success border #5EE8A4
- **Available (can afford):** primary border #5AA9FF
- **Available (can't afford):** accent border #FFC857
- **Locked (prereqs unmet):** muted #8A9BB1, dimmed

### Interaction
- Click available node → confirmation: "Unlock [name] for [cost] RP?" → Yes/No
- Click unlocked node → shows what it unlocked (informational)
- Click locked node → shows prerequisites needed
- Cross-category prerequisites shown as text label: "Requires: Specialty Malts (Ingredients)"

### Access Point
- "Research" button on BreweryScene (visible during EQUIPMENT_MANAGE state)
- Button click → GameState.set_state(RESEARCH_MANAGE) → Game.gd shows ResearchTree
- ResearchTree emits `closed` signal → returns to previous state

## Save/Load

`ResearchManager.save_state()` returns:
```gdscript
{
    "research_points": int,
    "unlocked_nodes": Array[String]
}
```

`load_state()` restores state and re-applies all unlock effects. Integrated into SaveManager alongside EquipmentManager.

## Tests (test_research_manager.gd)

- RP accumulation: verify `2 + score/20` formula
- Prerequisite checking: can't unlock node when prereqs unmet
- Unlock flow: RP deducted, node added, effect applied
- Ingredient unlock: verify `.unlocked` flips to true
- Style unlock: verify `.unlocked` flips to true
- Equipment tier gating: verify tier limit increases
- Brewing bonuses: verify bonuses dictionary populated
- Save/load roundtrip: state persists correctly
- Reset: clears all state
