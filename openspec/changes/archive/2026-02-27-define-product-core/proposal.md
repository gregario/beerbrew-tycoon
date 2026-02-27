## Why

BeerBrew Tycoon has no formal product specs — only raw reference notes. Before any implementation begins, the core product must be defined as structured, OpenSpec-managed specs so that all future work has a stable foundation to build on.

## What Changes

- Define the full product vision: a brewery management sim inspired by Game Dev Tycoon with roguelite meta-progression between runs
- Establish the MVP scope: a single garage-stage run with core brewing loop, quality scoring, and win/lose conditions
- Define the core mechanics as discrete, implementable capabilities
- Set the platform target: Godot 4 / GDScript, PC (Steam), pixel art isometric view

## Capabilities

### New Capabilities

- `brewery-scene`: Pixel art isometric garage view with fixed station slots, player character, and visual progression
- `beer-style-selection`: Library of beer styles (starting with 4), each with defined Flavor/Technique ratio targets
- `recipe-design`: Ingredient selection system (malts, hops, yeast) that affects flavor profile and quality
- `brewing-phases`: Three-phase brewing loop (Mashing, Boiling, Fermenting) with effort-allocation sliders generating Flavor and Technique points
- `quality-scoring`: Score calculation from Flavor/Technique ratio match, ingredient-style compatibility, and novelty modifier
- `market-system`: Market demand simulation with per-style demand windows that shift over turns and affect revenue
- `economy`: Cash balance, ingredient costs, rent cycle, revenue calculation, and win/lose conditions
- `results-ui`: Post-brew results screen showing quality score breakdown, revenue, and balance
- `game-over-ui`: End-of-run screen with final stats for both win and loss outcomes

### Modified Capabilities

## Impact

- All source code will live in `/src/` as a Godot 4 project
- All tests will live in `/tests/`
- No existing code is affected — this is a greenfield product definition
- The `reference/` folder documents can be archived once specs are complete
