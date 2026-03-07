## Context

Stage 5A established the artisan/mass-market fork with PathManager (strategy pattern), ArtisanPath/MassMarketPath subclasses, and ForkChoiceOverlay. Currently the paths differ only by numerical modifiers (+20% quality vs 2x batch, etc.) and win conditions. Stage 5B adds the signature gameplay systems that make each path genuinely distinct.

The project has 484 passing GUT tests and established autoloads: PathManager, ResearchManager, EquipmentManager, StaffManager, MarketManager, QualityCalculator, GameState. All follow the Resource-based data model + autoload manager pattern.

## Goals / Non-Goals

**Goals:**
- Add artisan specialty beers (sour/wild, barrel-aged, experimental) with multi-turn fermentation
- Add brand recognition tracking (0-100 per style) that increases demand volume
- Add automation equipment category exclusive to mass-market path
- Integrate all three systems with existing autoloads without breaking current 484 tests

**Non-Goals:**
- Visual scene (.tscn) creation — requires Godot editor, handled separately
- Meta-progression integration — deferred to Stage 6
- Balancing pass — tuning numbers comes after playtesting
- Barrel-aged beer implementation — deferred, too complex for this stage (sour/wild and experimental only)

## Decisions

### 1. Specialty Beer Architecture: BeerStyle flags + SpecialtyBeerManager autoload

Specialty beers extend the existing BeerStyle Resource with new fields rather than creating a separate Resource class. A new `SpecialtyBeerManager` autoload handles multi-turn fermentation state.

**Rationale**: BeerStyle already flows through RecipeDesigner → BrewingPhases → QualityCalculator. Adding fields (is_specialty, fermentation_turns, variance_modifier) keeps the existing pipeline intact. A separate manager handles fermentation state (which beers are aging, turns remaining) because GameState shouldn't grow unbounded.

**Alternative considered**: Separate SpecialtyBeer Resource inheriting BeerStyle — rejected because it would require type checks throughout the pipeline and break existing style-selection UI.

### 2. Multi-Turn Fermentation: Aging Queue in SpecialtyBeerManager

Sour/wild ales require 3-5 turns of fermentation. Instead of blocking the player, beers enter an "aging queue" — the player brews normally each turn, and aged beers complete in the background.

**Rationale**: Blocking the player for 3-5 turns would be un-fun. An aging queue lets the player keep brewing while specialty beers mature. When an aged beer completes, results appear alongside the current turn's results.

**Structure**: `aging_queue: Array[Dictionary]` where each entry has `{style, recipe, quality_base, turns_remaining, variance_seed}`. Each turn, all entries decrement. When `turns_remaining == 0`, the beer resolves with variance applied.

### 3. Specialty Beer Variance: Seeded RNG with Quality Ceiling Boost

Specialty beers use higher variance (±15 quality points vs normal ±5) but also raise the quality ceiling by +10. The variance is determined at brew time using a seed, so save/load produces consistent results.

**Rationale**: High risk/reward is the core fantasy. The ceiling boost ensures that on average, specialty beers reward the investment. Seeded RNG prevents save-scumming.

### 4. Brand Recognition: Dictionary in MarketManager

Brand recognition lives as a `brand_recognition: Dictionary` (style_name → float 0-100) inside MarketManager rather than a separate autoload.

**Rationale**: Brand recognition directly modifies demand volume, which MarketManager already calculates. Adding it to MarketManager keeps demand logic co-located. The data is simple (one float per style) and doesn't warrant its own manager.

**Formula**: After selling a beer, `brand_recognition[style] += brand_gain`. `brand_gain = base_gain * channel_multiplier` where base_gain = 5, retail multiplier = 1.5, bars = 1.0, taproom = 0.5, events = 0.3. Brand decays by 2 per turn for styles not brewed. Demand volume multiplier = `1.0 + (brand_recognition[style] / 100.0) * 0.5` (max +50% volume at 100 recognition).

### 5. Automation Equipment: New Category in Equipment Resource

Automation equipment uses the existing Equipment Resource with `category = "automation"` and a new `is_automation: bool` flag. The EquipmentShop path-gates automation items.

**Rationale**: Reusing the Equipment Resource and EquipmentManager avoids a parallel system. The shop already has category filtering. Path-gating is a simple check: `PathManager.get_current_path_name() == "mass_market"`.

**Staff vs Automation rule**: In QualityCalculator, for each brewing phase, `phase_bonus = max(staff_bonus, automation_bonus)`. This is checked per-phase, not globally, so a player could have staff excelling at mashing and automation excelling at fermentation.

### 6. Wild Fermentation Research Node: New Node in Techniques Category

A new research node `wild_fermentation` (cost: 30 RP, prerequisite: `specialist_yeast`) gates specialty beer access for artisan path players.

**Rationale**: Gating behind research ensures specialty beers are a mid-to-late game unlock, not immediately available after the fork. Requiring specialist_yeast as a prerequisite creates a natural progression path.

### 7. Experimental Brews: Random Ingredient Modifier

Experimental brews use normal recipe selection but apply a random "mutation" — one ingredient's flavor profile is randomized, creating unpredictable results. This uses a simpler mechanism than full random recipes.

**Rationale**: Fully random recipes would bypass the recipe designer and break the player's sense of agency. A single-ingredient mutation keeps the player in control while adding surprise. The mutation is revealed after brewing, adding a discovery element.

## Risks / Trade-offs

- **Aging queue complexity** → Mitigated by keeping it as a simple array of dicts in SpecialtyBeerManager with clear turn-tick logic. Save/load serializes the array directly.
- **Brand recognition balance** → Values (base_gain=5, decay=2, max bonus=+50%) are initial guesses. Mitigated by making them constants that are easy to tune.
- **Automation vs staff confusion** → Players might not understand the "higher wins" rule. Mitigated by showing both values in the brewing phase UI with the active one highlighted.
- **Specialty beer quality variance could feel unfair** → Mitigated by the ceiling boost (+10) ensuring positive expected value, and by showing the variance range to players before they commit.
- **Barrel-aged beers deferred** → Sour/wild and experimental cover the core specialty fantasy. Barrel-aged can be added later as a simpler extension of the aging queue.
