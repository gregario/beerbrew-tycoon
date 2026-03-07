# Stage 5A Design — Artisan vs Mass-Market Fork (Core)

## Overview

At MICROBREWERY stage with $15,000+ balance and 25+ beers brewed, players choose between two divergent endgame paths. This creates genuinely different gameplay experiences with distinct win conditions, bonuses, and brewery layouts.

Stage 5A implements the fork mechanism, path bonuses, win conditions, and separate brewery scenes. Stage 5B (later) adds specialty beers, brand recognition, and automation equipment.

## Architecture

### Strategy Pattern

Designed for future expansion to 10+ paths (Locavore, Distributor, Co-op, etc.).

**New files:**

- `src/scripts/paths/BreweryPath.gd` — Base class (extends Resource)
  - `get_path_name() -> String`
  - `get_quality_bonus() -> float` — multiplicative (1.0 = no bonus)
  - `get_batch_multiplier() -> float` — multiplicative (1.0 = no bonus)
  - `get_ingredient_discount() -> float` — multiplicative (1.0 = no discount)
  - `get_competition_discount() -> float` — multiplicative (1.0 = no discount)
  - `check_win_condition(game_state) -> bool`
  - `get_win_description() -> String`
  - `serialize() -> Dictionary`
  - `deserialize(data: Dictionary) -> void`

- `src/scripts/paths/ArtisanPath.gd` — extends BreweryPath
  - quality_bonus: 1.2 (+20%)
  - competition_discount: 0.5 (50% off entry fees)
  - Reputation tracking: `var reputation: int = 0`
  - Reputation gains: +5 gold, +3 silver, +1 bronze, +2 contract, +1 per brew quality > 80
  - Win condition: total_medals >= 5 AND reputation >= 100

- `src/scripts/paths/MassMarketPath.gd` — extends BreweryPath
  - batch_multiplier: 2.0 (doubles revenue scaling)
  - ingredient_discount: 0.8 (20% off all ingredients)
  - Win condition: total_revenue >= 50000 AND unlocked_channels >= 4

- `src/scripts/PathManager.gd` — Autoload
  - `var current_path: BreweryPath = null`
  - `choose_path(path_type: String) -> void` — instantiates subclass
  - `has_chosen_path() -> bool`
  - `can_choose_path() -> bool` — checks $15K + 25 brews + MICROBREWERY
  - Delegates all queries to current_path
  - Save/load: serializes path type + path-specific data

### Modified files

- `GameState.gd` — `check_win_condition()` delegates to PathManager when path chosen; fork threshold check in `_on_results_continue()`
- `QualityCalculator.gd` — applies `PathManager.get_quality_bonus()` as multiplicative factor
- `BreweryExpansion.gd` — `expand()` accepts Stage param for ARTISAN/MASS_MARKET fork
- `Game.gd` — shows ForkChoiceOverlay on threshold, swaps BreweryScene on choice
- `CompetitionManager.gd` — applies competition_discount to entry fees
- Ingredient cost calculation — applies ingredient_discount

## Fork Trigger & Flow

1. After `_on_results_continue()`, GameState checks `PathManager.can_choose_path()`
2. If true, emits signal caught by Game.gd
3. Game.gd shows ForkChoiceOverlay (mandatory — cannot dismiss without choosing)
4. Player selects a path → confirmation dialog ("This cannot be undone")
5. On confirm: `PathManager.choose_path(type)` → `BreweryExpansion.expand(stage)` → Game.gd swaps scene
6. Toast: "You've chosen the Artisan/Mass-Market path!"
7. All bonuses immediately active

## ForkChoiceOverlay

- CanvasLayer (layer=10), standard overlay pattern
- Title: "Your Brewery Has Grown — Choose Your Path"
- Two side-by-side cards comparing paths:
  - Path name, icon/accent color
  - Bonuses list
  - Win condition
  - Monthly rent
- "Choose This Path" button per card
- Confirmation dialog on selection

## Scene Layouts

### ArtisanBreweryScene.tscn
- 7 equipment station slots
- Reputation bar in header (progress X/100)
- Medal display (small icons)
- Hub buttons: Brew, Equipment, Research, Staff, Contracts, Compete, Market, Sell
- Warm accent color (amber/copper)
- Header: "Artisan Brewery"

### MassMarketBreweryScene.tscn
- 7 equipment station slots
- Revenue tracker in header ($X/$50K progress bar)
- Channel status display (4 icons, lit when active)
- Hub buttons: same set (+ future Automation button in 5B)
- Industrial accent color (steel blue/slate)
- Header: "Mass-Market Brewery"

## Win Conditions

| Path | Condition | Display |
|------|-----------|---------|
| None (pre-fork) | balance >= $10,000 | Existing |
| Artisan | total_medals >= 5 AND reputation >= 100 | Reputation bar + medal count |
| Mass-Market | total_revenue >= $50,000 AND channels >= 4 | Revenue tracker + channel icons |

## Reputation System (Artisan only)

- Stored on ArtisanPath instance
- Gains: +5 gold medal, +3 silver, +1 bronze, +2 contract fulfilled, +1 per brew with quality > 80
- Displayed as progress bar on ArtisanBreweryScene
- Persisted via PathManager save/load

## 5A Task Breakdown

1. BreweryPath base class + ArtisanPath + MassMarketPath
2. PathManager autoload (choose, query, save/load)
3. Fork threshold check in GameState + ForkChoiceOverlay UI
4. Integrate path bonuses: QualityCalculator, ingredient costs, competition fees, batch multiplier
5. Artisan win condition (5 medals + reputation 100) + reputation tracking
6. Mass-market win condition ($50K revenue + 4 channels)
7. ArtisanBreweryScene + MassMarketBreweryScene (separate .tscn)
8. Game.gd scene swap on path choice + BreweryExpansion integration
9. GUT tests for all of the above

## 5B Scope (deferred)

- Specialty beer styles (sour, barrel-aged, experimental) as new BeerStyle resources gated behind artisan + research
- Brand recognition system (per-style, builds with consistent mass-market sales)
- Automation equipment (flat bonuses replacing staff need, equipment tiers 5-7)
