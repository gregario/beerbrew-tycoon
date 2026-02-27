## Context

BeerBrew Tycoon MVP is complete: a single-run garage brewing loop with 4 beer styles, simple ingredients, 3-phase slider brewing, quality scoring, market demand rotation, and win/lose conditions. 54 GUT tests pass. The UI uses a card-based design system with Kenney Green assets, a generated theme, and reusable components (CardContainer, Toast, Tooltip).

The product vision calls for a full brewery empire game with 6 stages of post-MVP features. Three reference documents drive the design:
- **product.md**: Defines brewery progression (garage → micro → artisan/mass-market), roguelite meta-progression, and GDT-inspired mechanics.
- **deep-research-report.md**: Game Dev Tycoon system analysis (employees, engine R&D, market research, contracts, marketing, labs, company growth).
- **brewing-research.md**: Real brewing science from Palmer's "How to Brew" (mash enzymes, fermentation control, equipment tiers, failure modes, QA checks, scaling).

Each stage must be independently shippable as an Early Access update. Stages build on each other but each delivers a complete, testable increment.

## Goals / Non-Goals

**Goals:**
- Define a 6-stage roadmap where each stage is independently valuable and shippable
- Keep the "fun over realism" principle from GDT — brewing science informs mechanics but doesn't overwhelm
- Maintain the existing architecture patterns (autoloads, resources, signals, card-based UI)
- Each stage adds ~2-4 weeks of implementation work (solo dev + AI)
- Preserve all existing tests; each stage adds its own test suite

**Non-Goals:**
- Realistic brewing simulator (we use science to inform fun, not replicate lab accuracy)
- Multiplayer or online features
- Mobile port (design for it, but don't implement)
- Procedural art generation (pixel art stays hand-crafted or AI-assisted)
- Stages 5-6 detailed implementation design (those will get their own design docs when reached)

## Decisions

### 1. Stage ordering: Deepen core loop before adding breadth

**Decision**: Enhanced brewing → Equipment → Staff → Market → Fork → Meta-progression.

**Rationale**: The MVP loop is the foundation everything else builds on. Deepening ingredient/brewing science first means equipment, staff, and market systems have richer mechanics to interact with. The GDT research confirms this — their game added employees and engine R&D after the core game-making loop was solid.

**Alternative considered**: Adding staff first (more visible change). Rejected because staff stats multiplying a shallow brewing system produces shallow gameplay.

### 2. Data model: Resource-based with typed properties

**Decision**: Use Godot's `Resource` system for all game data (Ingredient, Equipment, Staff, etc.) with `.tres` files for static catalogs and runtime instances for save state.

**Rationale**: Consistent with MVP pattern (BeerStyle is already a Resource). Resources are serializable (save/load), editable in Godot inspector, and lightweight. The pitfall of custom class names in `.tres` type fields is documented in STACK.md — use `type="Resource"` always.

**Alternative considered**: JSON data files loaded at runtime. Rejected — loses Godot editor integration and type safety.

### 3. Ingredient system: Numeric properties with flavor tags

**Decision**: Each ingredient gets numeric properties (alpha_acid, color_srm, attenuation, body_contribution, etc.) plus categorical flavor tags (citrus, caramel, roasty, floral). Quality scoring uses the numerics; UI displays the tags for player readability.

**Rationale**: Maps directly to brewing-research.md data model. Numeric properties enable deterministic scoring with stochastic noise. Tags give players intuitive understanding without needing to read numbers.

### 4. Brewing science: Simplified enzyme curves, not full chemistry

**Decision**: Model mash temperature as a single slider mapping to a fermentability curve (lower temp = more fermentable = higher ABV potential, lower body; higher temp = less fermentable = lower ABV, fuller body). Don't model individual enzymes, pH, or water chemistry in Stage 1.

**Rationale**: Palmer's enzyme windows (alpha-amylase vs beta-amylase) are fascinating but too granular for a tycoon game. The simplified curve captures the meaningful player choice (dry vs. sweet/full) without requiring brewing knowledge.

**Alternative considered**: Full enzyme modeling with pH. Rejected for Stage 1 — could add as "advanced brewing" research unlock in later stages.

### 5. Failure modes: Probability-based with player feedback

**Decision**: Track a "sanitation" stat (0-100) and "temperature control" stat (0-100) that affect failure probabilities. Poor sanitation = chance of infection. Poor temp control = chance of off-flavors. Display clear feedback: "Your batch got infected! Improve sanitation to prevent this." Equipment upgrades improve these stats.

**Rationale**: Failure modes create the "learn by failing" loop from GDT. Making them probability-based (not deterministic) creates tension without being punishing. Clear feedback teaches players what to improve.

### 6. Equipment tiers: 7-tier progression mapped from brewing research

**Decision**: Map the real-world equipment ladder to game tiers:

| Tier | Name | Unlocks | Batch Size |
|------|------|---------|------------|
| 1 | Extract Kit | Starting equipment | Small |
| 2 | BIAB Setup | Mash temp control | Small |
| 3 | Mash Tun + Kettle | Sparge/efficiency | Medium |
| 4 | 3-Vessel + Pumps | Recirculation, consistency | Medium |
| 5 | Electric All-in-One | PID temp control, automation | Medium-Large |
| 6 | Conical Fermenters | Yeast harvesting, closed transfer | Large |
| 7 | Nano/Micro System | CIP, glycol, commercial scale | Very Large |

Tiers 1-4 = garage/microbrewery. Tiers 5-7 = artisan/mass-market stage.

### 7. Staff system: GDT-style with brewing-specific stats

**Decision**: Staff have two primary stats: **Creativity** (affects flavor points, recipe experimentation) and **Precision** (affects technique points, consistency, QA). Like GDT, specialization is better than generalization. Staff can be assigned to specific brewing phases and trained between brews.

**Alternative considered**: Three stats (add "Efficiency" for speed). Rejected — two stats is cleaner and mirrors GDT's Design/Technology split.

### 8. Save system: Resource serialization + JSON meta

**Decision**: Save game state by serializing all runtime Resources to a JSON file. Meta-progression (cross-run unlocks) stored in a separate JSON file that persists independently.

**Rationale**: Godot's Resource serialization handles complex nested data. Separating run state from meta state means runs can be reset without losing progression.

### 9. Stage gating: Each stage behind a feature flag

**Decision**: Each stage's systems are gated by a simple feature flag dictionary in GameConfig. This allows incremental releases and testing.

**Rationale**: Stages build on each other but should be toggleable for testing and Early Access releases.

## Risks / Trade-offs

**[Scope creep per stage]** → Each stage is scoped to 2-4 weeks. If a stage balloons, split it. The proposal defines 17 new capabilities — not all need to ship in the first pass of their stage.

**[Breaking existing tests]** → Modified capabilities (recipe-design, brewing-phases, quality-scoring) touch tested code. Mitigation: keep existing tests green by making changes additive (new optional parameters, not changed signatures). Write adapter layers if needed.

**[Balancing complexity]** → More systems = more knobs to balance. Mitigation: each stage gets a dedicated balance pass with playtest data before the next stage begins.

**[Save system migration]** → As stages add new data, save files from earlier versions may be incompatible. Mitigation: version the save format from Stage 1; write migration functions for each version bump.

**[Equipment tier balance]** → 7 tiers may be too many for the game's pacing. Mitigation: start with tiers 1-4 in Stage 2; add 5-7 only with Stage 5 (artisan/mass-market).

## Open Questions

- Should Stage 1 include water chemistry as a simple lever (hard/soft water presets), or defer entirely to a research unlock?
- How long should a full run take after all stages are implemented? MVP targets 15-30 min; full game might target 60-90 min.
- Should competitions (Stage 4) use a simulated judging AI or pre-scripted results with randomness?
- Does the artisan/mass-market fork (Stage 5) create genuinely divergent codepaths, or just different parameter sets on shared systems?
