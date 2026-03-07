## Context

BeerBrew Tycoon is a brewery management sim (Godot 4) with 6 completed post-MVP stages (701 tests). The core brewing loop uses 3 sliders (mash temp, boil time, ferment temp) producing a quality score via QualityCalculator. Extensive research (5 documents covering brewing science experiments, GDT mechanics, real brewery economics) reveals the brewing phase should be much deeper — water chemistry, hop scheduling, conditioning, and discovery of what does/doesn't matter are all missing.

Current architecture: autoload singletons (GameState, QualityCalculator, BrewingScience, FailureSystem, ResearchManager, EquipmentManager), Resource-based data (.tres files for styles, ingredients, equipment), programmatic UI overlays (CanvasLayer, layer=10).

## Goals / Non-Goals

**Goals:**
- Deepen the brewing loop with water chemistry, hop scheduling, and conditioning decisions
- Implement tolerance-based scoring ("close enough" zones, yeast-temp interaction)
- Expand off-flavors from binary to spectrum with context-dependent evaluation
- Add progressive process revelation (equipment unlocks brewing steps/info)
- Expand beer styles to 16 with family-based unlock progression
- Rebalance quality scoring to reflect real brewing impact hierarchy
- Maintain backward compatibility with existing save/load and meta-progression systems

**Non-Goals:**
- Visual overhaul / bubble animation system (Pillar 3 — separate expansion)
- Starter characters (Pillar 2 — separate expansion, but water chemistry lays groundwork)
- Continuous time system replacing turns (Pillar 4 — separate expansion)
- Taproom management, pub chain, hop farm (Pillar 4)
- New .tscn scene files (all UI remains programmatic for now)

## Decisions

### 1. Water Chemistry: Resource-based profiles vs procedural calculation

**Decision:** Resource-based WaterProfile .tres files with predefined mineral compositions.

**Rationale:** 5 fixed profiles (Soft/Balanced/Malty/Hoppy/Juicy) is simpler for players and maps to the real-world city waters (Pilsen/generic/Dublin/Burton/Vermont). Procedural mineral math would be more realistic but overwhelms players and doesn't add fun. Research explicitly recommends simple profile selection. Profiles are loaded from `res://data/water/` and each BeerStyle .tres gets a `water_affinity` field mapping profile_id → score multiplier.

**Alternative considered:** Full mineral sliders (Ca, Mg, SO4, Cl, Na, HCO3). Rejected — too complex for game context, better suited to a brewing calculator app.

### 2. Hop Scheduling: Expand recipe design vs separate phase

**Decision:** Integrate into recipe design phase. When player selects hops, they also allocate each hop to a timing slot (Bittering 60min / Flavor 15min / Aroma 5min / Dry Hop). Allocation is per-hop, not global.

**Rationale:** Keeps the decision close to ingredient selection (natural flow). Each style's BeerStyle resource defines `hop_schedule_expectations` (e.g., IPA expects aroma+dry hop, lager expects bittering only). Scoring rewards matching expectations. The BrewingPhases slider for boil remains but becomes less about "how long" and more about the boil vigor (which interacts with DMS risk for pilsner malt).

**Alternative considered:** Hop timing as a sub-phase during brewing with visual hop additions. Deferred to visual overhaul (Pillar 3) — the mechanic works without the animation.

### 3. Conditioning: Separate game state vs inline in results

**Decision:** New `CONDITIONING` state between `RESULTS` and `SELL`. Player chooses 0-4 weeks. Each week reduces off-flavor severity by a decay function and applies a small quality bonus. Fermenter is occupied (tracked in GameState but only relevant when continuous time is added in Pillar 4).

**Rationale:** Conditioning is the GDT "when to ship" decision — it needs its own UI moment. A simple slider (0-4 weeks) with live preview of off-flavor decay keeps it lightweight. Cost: each week charges rent proportionally (rent/4 per week). This creates the quality-vs-cash tension.

**Alternative considered:** Auto-conditioning baked into quality score. Rejected — removes player agency and the interesting trade-off.

### 4. Scoring Rebalance: Gradual migration vs hard cutover

**Decision:** Hard cutover with new weight constants. Backward compatibility via existing test suite — all 701 tests must still pass (some assertions may need updating for new score ranges).

**Rationale:** The scoring rebalance is fundamental. Trying to maintain old weights alongside new ones creates confusion. Better to commit fully: Fermentation 25%, Style Match 25%, Science 15%, Water 10%, Hop Schedule 10%, Novelty 10%, Conditioning 5%. Tests that assert specific score values will need updating but the test structure remains.

**New component architecture:**
- `QualityCalculator.calculate_quality()` takes expanded inputs: sliders + water_profile + hop_allocations + conditioning_weeks
- Each component returns a 0-1.0 score, multiplied by its weight
- Components are independent functions, testable in isolation

### 5. Off-Flavor Spectrum: Enum severity vs float intensity

**Decision:** Float intensity 0.0-1.0 per off-flavor type, with named thresholds (subtle < 0.3, noticeable 0.3-0.6, dominant > 0.6).

**Rationale:** Floats allow smooth decay during conditioning (diacetyl decays at 0.2/week, oxidation doesn't decay). Style context evaluation: each BeerStyle has `acceptable_flavors` dict mapping off-flavor type to acceptable threshold (e.g., Hefeweizen: {"ester": 0.8} means esters up to 0.8 intensity are features not flaws). Penalty only applied for intensity above the style's acceptable threshold.

### 6. Progressive Revelation: Equipment flags vs capability system

**Decision:** Equipment flag system. Each Equipment .tres resource gets an optional `reveals` array of feature IDs (e.g., `["water_selector", "temp_numbers", "hop_schedule"]`). EquipmentManager aggregates all active equipment's `reveals` into a `Set[String]` queryable by UI. RecipeDesigner and BrewingPhases check `EquipmentManager.is_revealed("water_selector")` to show/hide UI elements.

**Rationale:** Simple, data-driven, no new autoloads needed. Equipment already has a resource system and manager. Adding a `reveals` field is minimal. UI just checks before showing elements.

**Alternative considered:** Separate ProgressionManager autoload tracking what's revealed. Rejected — over-engineered, equipment IS the progression.

### 7. Style Expansion: All at once vs phased

**Decision:** All 16 styles in one pass, but grouped into families with research-gated unlocks. Families: Ales (3 start unlocked), Dark (3, research-gated), Wheat (2, research-gated), Lager (3, research-gated), Belgian (2, late research), Modern (2, late research), Specialty (existing 3, unchanged).

**Rationale:** Styles are data (.tres files), not code. Creating 9 new .tres files is straightforward. The research gating uses the existing ResearchManager system. Each style needs: flavor_technique_ratio, base_price, water_affinity, hop_schedule_expectations, yeast_temp_flavors, acceptable_off_flavors. This is content work, not architecture.

## Risks / Trade-offs

- **[Scoring rebalance breaks existing balance]** → Mitigation: Balance reference doc exists (docs/balance-reference.md). Run economy simulation after rebalance to verify win is achievable in 30-60 turns. Adjust weights if needed
- **[Too many decisions overwhelm the player]** → Mitigation: Progressive revelation means players start with current 3-slider simplicity. New decisions only appear when equipment is purchased. The "close enough" zones mean imprecision is forgiven
- **[Test suite needs significant updates]** → Mitigation: Tests that assert specific scores will need new expected values. Test structure and coverage patterns remain. New components get independent test files
- **[Water chemistry scoring may be opaque]** → Mitigation: Discovery system reveals water-style relationships over time. ResultsOverlay shows water match score. Player learns through experimentation, not UI hints
- **[Conditioning adds turn length without proportional fun]** → Mitigation: Conditioning is optional (0 weeks is valid). Only 1 UI interaction (slider). Value is in the trade-off decision, not the waiting
- **[9 new styles is a lot of content to balance]** → Mitigation: Each style follows the same resource pattern. Flavor profiles are informed by BJCP guidelines (research/brewing-knowledge.md). Balance pass after implementation
