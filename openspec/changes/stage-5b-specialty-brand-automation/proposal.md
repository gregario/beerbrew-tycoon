## Why

Stage 5A established the artisan/mass-market fork with base mechanics (quality bonus, batch size, win conditions). However, the two paths currently feel thin — the fork is mostly numerical modifiers. Stage 5B adds the signature gameplay systems that make each path genuinely distinct: artisan players get high-risk specialty beers that reward experimentation, mass-market players get automation equipment and brand-building that reward consistency and scale.

## What Changes

- **Artisan Specialty Beers**: Unlock sour/wild ales (3-5 turn fermentation, high variance/high ceiling), barrel-aged beers (time investment, premium pricing), and experimental brews (random ingredient combos). Gated behind "Wild Fermentation" research node.
- **Brand Recognition System**: Per-style tracking (0-100 scale) that builds from consistent brewing and sales through retail/bars channels. Higher brand recognition increases demand volume. Available to both paths but mass-market benefits more due to volume focus.
- **Automation Equipment**: New equipment category exclusive to mass-market path. Provides flat bonuses to brewing phases, reducing staff dependency. Does NOT stack with staff bonuses — whichever is higher applies. Available through EquipmentShop when on mass-market path.

## Capabilities

### New Capabilities
- `specialty-beers`: Artisan-exclusive beer categories (sour/wild, barrel-aged, experimental) with multi-turn fermentation and unique scoring mechanics
- `brand-recognition`: Per-style brand tracking system that increases demand volume through consistent brewing and channel sales
- `automation-equipment`: Mass-market-exclusive equipment category providing flat brewing phase bonuses as staff alternative

### Modified Capabilities
- `quality-scoring`: Specialty beers introduce variance modifiers and multi-turn fermentation scoring
- `equipment-system`: New automation equipment category with path-gating and staff-bonus exclusivity rule
- `market-system`: Brand recognition feeds into demand volume calculations for retail/bars channels
- `research-tree`: New "Wild Fermentation" node gates specialty beer access for artisan path

## Impact

- **PathManager / ArtisanPath**: Specialty beer unlock logic, fermentation turn tracking
- **ResearchManager**: New research node for Wild Fermentation
- **QualityCalculator**: Variance modifiers for specialty beers, automation bonus integration
- **EquipmentManager / EquipmentShop**: Automation equipment category, path-gating in shop
- **MarketManager**: Brand recognition demand modifier in volume calculations
- **StaffManager integration**: Staff vs automation "higher wins" comparison
- **GameState**: Multi-turn fermentation state tracking, brand recognition persistence
- **Save/Load**: Brand recognition data, in-progress fermentation state, automation equipment
- **UI**: Specialty beer indicators in RecipeDesigner, brand recognition display in MarketForecast, automation equipment in EquipmentShop
