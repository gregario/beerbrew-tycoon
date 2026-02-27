## Why

The MVP delivers a satisfying single-run garage brewing loop, but the product vision calls for a full brewery empire game with equipment progression, staff, market strategy, and roguelite replayability. The brewing research (Palmer's "How to Brew") provides deep domain knowledge to make the brewing system feel authentic, while the Game Dev Tycoon analysis maps proven tycoon mechanics to brewing equivalents. Now is the time to define the full post-MVP roadmap in stages so each can be designed and implemented incrementally.

## What Changes

The post-MVP roadmap adds six stages of features, each building on the last:

- **Stage 1 — Enhanced Brewing System**: Deepen the core loop with real brewing science. Expanded ingredient catalog (multiple malts, hops, yeasts with distinct numeric properties). Mash temperature windows affecting fermentability. Fermentation temperature as a flavor control point. Failure modes (infection, off-flavors, bottle bombs). QA checkpoints during brewing. Save/load system.
- **Stage 2 — Equipment & Research**: Equipment purchasing and upgrading across tiers (extract kit → BIAB → mash tun → conical → nano). Research tree for unlocking techniques, ingredients, and equipment. Equipment affects brewing parameters, quality ceiling, and batch size.
- **Stage 3 — Staff & Brewery Expansion**: Hire brewers with stats (creativity, precision, consistency). Microbrewery stage transition (garage → microbrewery with more station slots). Staff assignment to brewing phases. Training and specialization system.
- **Stage 4 — Market & Economy**: Brewing contracts (fulfill orders for guaranteed income). Beer competitions with judging and prizes. Market trends and seasonal demand cycles. Distribution channels (taproom, bars, retail, events). Pricing strategy.
- **Stage 5 — Artisan vs Mass-Market Fork**: Strategic path choice at microbrewery stage. Artisan path: quality focus, competition wins, premium pricing, niche market. Mass-market path: volume, efficiency, distribution reach. Different mechanics, UI, and win conditions per path.
- **Stage 6 — Roguelite Meta-Progression**: Persistent unlocks between runs (beer styles, equipment blueprints, ingredient access, staff traits, brewery perks). Run modifiers for variety. Achievement-based progression. Multiple run endings.

## Capabilities

### New Capabilities
- `ingredient-system`: Expanded ingredient catalog with numeric properties (alpha acid, attenuation, color contribution, flavor profile). Replaces MVP's simple ingredient selection with a data-driven system.
- `brewing-science`: Mash temperature windows (enzyme activity curves), fermentation temperature control, boil timing effects. Deterministic mechanics with stochastic noise.
- `failure-modes`: Infection probability (sanitation stat), off-flavor generation (temp drift), overcarbonation (packaging errors). QA checkpoints during brewing phases.
- `save-load`: Save and load game state. Required for longer play sessions as complexity grows.
- `equipment-system`: Equipment catalog with tiers, stats, costs. Station slots in brewery. Equipment affects brewing parameters and quality ceiling.
- `research-tree`: Unlock new techniques, ingredients, equipment, and beer styles through a research point system.
- `staff-system`: Hire, assign, train, and specialize brewers. Staff stats affect brewing phase output.
- `brewery-expansion`: Stage transitions (garage → microbrewery → artisan/mass-market). Room changes, station slot increases, rent scaling.
- `contracts`: Fulfill brewing orders from external clients for guaranteed income and reputation.
- `competitions`: Enter beers in competitions for prizes, reputation, and unlocks.
- `market-trends`: Seasonal demand cycles, trending styles, market saturation mechanics beyond MVP's simple rotation.
- `distribution`: Sales channels (taproom, bars, retail, events/festivals) with different margins and volume.
- `pricing-strategy`: Set prices per beer/channel. Price affects demand volume and perceived quality.
- `artisan-path`: Artisan brewery progression — quality-focused mechanics, competition track, premium market.
- `mass-market-path`: Mass-market brewery progression — volume/efficiency mechanics, distribution network, brand recognition.
- `meta-progression`: Persistent unlocks between runs. New styles, blueprints, ingredients, staff traits, brewery perks.
- `run-modifiers`: Modifiers that change run parameters (harder markets, limited ingredients, bonus starting cash).

### Modified Capabilities
- `recipe-design`: Recipe system expands to use new ingredient-system data model. Multiple ingredients per category instead of one.
- `brewing-phases`: Phases gain temperature parameters, timing effects, and staff assignment slots. Sliders interact with equipment stats.
- `quality-scoring`: Scoring incorporates brewing science (mash temp accuracy, fermentation control), equipment quality, staff skill, and failure mode penalties.
- `market-system`: Market rotation replaced by richer trend system with seasonal cycles and distribution channels.
- `economy`: Economy expands with equipment costs, staff salaries, research spending, contract income, competition prizes, and multi-channel revenue.

## Impact

- **Data model**: New resource types (Equipment, Ingredient with full properties, Staff, Research nodes, Contract, Competition). Existing BeerStyle resource gains additional fields.
- **Scene tree**: BreweryScene needs dynamic station slots, staff sprites, room transitions. New UI screens for equipment shop, research tree, staff management, contracts, competitions.
- **Game loop**: Turn structure expands — between-brew actions (hire, research, shop, enter competitions). Run lifecycle adds meta-progression layer.
- **Save system**: New persistence layer for mid-run saves and cross-run meta-progression.
- **Autoloads**: New managers (EquipmentManager, StaffManager, ResearchManager, ContractManager, MetaProgressionManager).
- **Testing**: Each stage needs comprehensive GUT tests. Existing tests remain valid but may need adaptation as systems expand.
