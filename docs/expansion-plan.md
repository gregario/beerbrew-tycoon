# BeerBrew Tycoon — Post-Roadmap Expansion Plan

## Vision

Transform the game from "brewery management sim with brewing minigame" into "the Brulosophy experience as a game" — where the player genuinely learns to brew through discovery, not tutorials. The core loop becomes deeper and more visually satisfying, while business systems and character progression add replayability.

## Four Expansion Pillars

### Pillar 1: Starter Characters

Players choose a character at run start (or meta-unlock new ones). Each character brings:

**Starting Water Chemistry** — The killer differentiator. Each character's hometown determines their tap water profile, which naturally advantages certain styles:
- **Dublin** — High carbonate, high chloride. Great for stouts/porters (smooth roast, full body). Poor for pilsners/IPAs
- **Burton-on-Trent** — High sulfate, high calcium. Legendary for IPAs/pale ales (crisp hop bitterness). Poor for delicate lagers
- **Pilsen** — Very soft, low mineral. Perfect for Czech pilsners/light lagers. Underwhelming for hop-forward styles
- **Munich** — Moderate carbonate, balanced. Good for amber/dark lagers (Marzen, Bock). Versatile
- **San Diego** — Moderate sulfate, low chloride. Modern West Coast IPA water. Clean and dry
- **Vermont** — High chloride, moderate sulfate. The NEIPA water (soft, juicy hop character)

Water profile affects quality scoring from brew 1 — before the player even understands why. Discovery moment: "Why do my stouts always score higher?" → eventually learns it's the water. Can be overridden later via Water Science research (mineral adjustments).

**Starting Stats & Knowledge:**
- Different taste skill starting levels (general + style-specific)
- Different starting equipment (e.g., one character starts with a thermometer = sees temp numbers from brew 1)
- Different starting research (e.g., one character has "basic_mashing" pre-unlocked)
- Different financial situations (e.g., trust fund kid has more starting cash, broke student has less but more taste skill)

**Personality / Backstory — affects meta-progression unlocks:**
- "The Homebrewer" — balanced stats, basic kit. The default
- "The Chemist" — starts with water awareness, pH meter. Analytical approach
- "The Chef" — higher adjunct/ingredient knowledge. Flavor-first
- "The Engineer" — starts with better equipment. Process-first
- "The Sommelier" — high taste skill, low brewing skill. Can taste but can't execute yet
- "The Inheritor" — starts with more money but an old brewery with outdated equipment

**Meta-unlock characters:** Win with specific conditions to unlock new starter characters for future runs. E.g., win via artisan path → unlock "The Artisan" character with barrel-aging knowledge.

### Pillar 2: Brewing Depth (THE core expansion)

Transform the 3-slider brewing phase into a deep, discovery-driven experience.

**New Brewing Decisions:**
- **Water Profile** selection (unlocked via research or starter character). Soft/Balanced/Malty/Hoppy/Juicy presets. Style-matching scoring component (~10% of quality)
- **Hop Schedule** — allocate selected hops to Bittering (60min) / Aroma (5min) / Dry Hop slots. Same hop, different usage = very different result. Scoring component (~10%)
- **Conditioning Time** — 0-4 weeks post-ferment. Off-flavors decay over time (diacetyl first, then others). Fermenter occupied during conditioning. The GDT "when to ship" decision: quality vs throughput vs rent
- **"Close Enough" Zones** — Brulosophy scoring: mash temp ±2°C of ideal = no penalty. Boil 45-90 min = same for non-pilsner malts. Player discovers these through experimentation
- **Yeast-Temp Interaction** — Wheat yeast: warm=banana, cool=clove. Saison: hotter=better (inverts all other yeast rules). Belgian: warm=spicy. Lager: must be cold. Temp controls which flavor compounds appear

**Expanded Off-Flavors (spectrum, not binary):**
- Diacetyl (butter) — from rushing fermentation. Fixable with conditioning
- Oxidation — scales with batch size, mitigated by equipment (closed transfers, CO2)
- DMS — pilsner malt + short boil specific (style/ingredient conditional)
- Esters/Phenols become context-dependent: flaw in lager, feature in wheat beer
- Severity scale: subtle (small penalty) → noticeable → dominant (wrecks the beer)

**Progressive Process Revelation:**
- Garage: 3 sliders (mash temp, boil time, ferment temp). No numbers without thermometer
- +Thermometer: see temperature numbers on sliders
- +Water Kit: water profile selector appears as new pre-mash step
- +Hop Timer: hop schedule UI appears within boil phase
- +Ferment Chamber: ferment temp drift eliminated, temp profile option
- +Dry Hop Rack: post-ferment dry hop step appears
- +Conditioning Tank: conditioning time slider after ferment
- Each equipment purchase literally teaches the player a new aspect of brewing

**"Non-Discovery" Discoveries (the Brulosophy mechanic):**
- After enough brews with varied mash temps within ±2°C: "Your last two beers used 65°C and 67°C mashing — they taste identical!"
- After short vs long boils with non-pilsner malt: "A 30-minute boil tastes the same as 90 minutes with this malt!"
- Discovering what DOESN'T matter is as rewarding as discovering what does. Unlocks efficiency shortcuts

**Beer Style Expansion (12-16 styles):**
- Each style teaches a different brewing principle
- Grouped into unlock families: Ales (start) → Lagers (research) → Belgians → Sours → Modern
- New styles: IPA, Porter, Imperial Stout, Hefeweizen, Witbier, Czech Pilsner, Helles, Saison, Belgian Dubbel, Barleywine, NEIPA

**Quality Scoring Rebalance:**
- Style Match: 25% (down from 40% — ratio is too abstract)
- Fermentation: 25% (THE dominant lever — matches reality)
- Science: 15% (mash + boil accuracy)
- Water Chemistry: 10% (new)
- Hop Schedule: 10% (new)
- Novelty: 10% (unchanged)
- Conditioning: 5% (new)

### Pillar 3: Visual Overhaul & Bubble Animation

The brew room and all scenes need a complete overhaul. Current programmatic UI works for systems but needs proper scenes, character sprites, and animations.

**Brew Room Vision:**
- Isometric brewery view with visible equipment stations
- **Player character + staff characters** visible at their stations during brewing
- Characters are right-clickable for actions (like GDT):
  - Player character: view stats, brewing journal
  - Staff: assign role, send to training, view skills
  - Founder character cannot be sent on vacation (always present, like GDT)
- Current hub buttons (Equipment, Research, Staff, Contracts, Compete, Market) remain in their positions — don't move them. Character right-click is an ADDITIONAL interaction layer, not a replacement

**Bubble Animation System (per brewing phase):**
- Quality bubbles (gold/amber) — flavor development, good conversion
- Technique bubbles (blue) — process precision, correct temps
- Off-Flavor bubbles (context-colored) — red in wrong style, gold in right style
- Discovery bubbles (green/teal) — learning something new
- Bubbles float up from characters and equipment during each phase
- Bubble ratio tells the story: mostly gold/blue = good brew. Too much red = problems
- Phase timing: Mash ~2min, Boil ~2min (with hop addition bursts), Ferment ~3-5min (longest), Conditioning ~1-2min

**Phase-Specific Visuals:**
- Mashing: character stirring mash tun, thermometer visible (if owned)
- Boiling: kettle rolling, hop addition events (burst of aromatic bubbles at each timing)
- Fermentation: airlock bubbling (audio: bloop bloop bloop), temp drift on thermometer if no chamber
- Conditioning: off-flavor bubbles "popping" and disappearing over time (like GDT bug fixing)

**Temperature Drift Visualization:**
- Without ferment chamber: thermometer visibly creeps up/down. Player watches helplessly as ester bubbles increase
- With chamber: thermometer rock solid. Clean bubble stream. Player FEELS the upgrade's value

**Tasting Panel Progression:**
- Garage: friends around table, casual reactions ("not bad!", "I'd drink this again")
- Micro: local beer critics, specific notes ("nice hop balance", "slight diacetyl")
- Competition: formal judges with score cards
- Late game: online reviews, magazine ratings

**Scene Overhaul Scope:**
- All current programmatic overlays are functional but need proper .tscn scenes
- Panels/modals are close to good for post-MVP — focus overhaul on the brew room and brewing phases
- Hub buttons stay where they are; new interactions layer on top

### Pillar 4: Business Depth (endgame content)

Deeper late-game systems that diverge artisan vs mass-market.

**Continuous Time (replacing turn-based):**
- Week-based ticker (like GDT). Time flows, costs accrue
- Ale fermentation: 2 weeks. Lager: 4 weeks. Barrel-aged: 8+ weeks
- Garage: low pressure, brew at own pace, day job covers basics
- Micro+: rent + salaries tick weekly. Idle fermenters = wasted capacity. Pressure to keep brewing
- Conditioning occupies fermenter space — pipeline management with multiple fermenters

**Taproom Management (Stage 3+):**
- Highest margin channel (60%+, 4-5x wholesale)
- Staff it, run events, build local following
- Upgrades: seating, food menu, live music → increase revenue
- Passive income between brews (critical for cash flow)

**Artisan Endgame:**
- Barrel aging program (buy barrels, age for multiple turns, premium products)
- Hop farm (late-game investment, reduces costs, freshness bonus, "estate" beers)
- Collaboration brews with NPC breweries (combined bonuses, reputation boost)
- B-Corp / sustainability certification (brand value)

**Mass-Market Endgame:**
- Own pub chain (buy locations, each a profit centre with 65% margin)
- Contract brewing (brew for other brands, steady utilization revenue)
- Marketing/merchandise/brand licensing
- Pipeline management across multiple brew lines

**Contract/Gypsy Brewing (alternative early scaling):**
- Pay per batch to use larger equipment
- Lower margin but no capital cost
- Test recipes at commercial scale before committing

**Style Expansion as Content:**
- 12-16 styles (up from 4+3 specialty), each teaching a brewing principle
- Style families unlock via research tree progression
- Per-style reputation tracking (GDT high-score mechanic: market expects improvement)

---

## Implementation Priority

| Phase | Pillar | Rationale |
|-------|--------|-----------|
| **Phase 1** | Brewing Depth | Transforms the core loop. Deepest research backing. Everything else layers on top of better brewing |
| **Phase 2** | Starter Characters | Adds replayability and ties into water chemistry from Phase 1. Relatively small scope |
| **Phase 3** | Visual Overhaul | Bubble animations need brewing depth systems to animate. Scene overhaul needs characters. Build on Phase 1+2 foundations |
| **Phase 4** | Business Depth | Endgame content. Needs the deeper brewing and visual systems to feel meaningful. Largest scope |

Phase 1 (Brewing Depth) is the clear starting point — it's where the research is deepest, it transforms the core experience, and all other pillars depend on it.

---

## Sources

All recommendations synthesized from:
- `research/brulosophy-to-game-loop.md` — Brulosophy findings → game mechanics mapping
- `research/game-vs-reality-analysis.md` — Gap analysis with top 10 recommendations
- `research/game-dev-tycoon-reference.md` — GDT systems adaptation (bubbles, phases, scaling)
- `research/brewing-knowledge.md` — Real brewing science knowledge base
- `research/brewery-progression-real-world.md` — Real brewery growth (Wicklow Wolf, Galway Bay, BrewDog)
- `design/future-vision.md` — Equipment-driven UI progression, brewing journal, endgame divergence
