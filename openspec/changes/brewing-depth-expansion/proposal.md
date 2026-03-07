## Why

The core brewing loop (3 sliders → quality score) is shallow compared to real brewing science. Brulosophy research shows ~70% of variables brewers obsess over don't matter, while ~30% (fermentation temp, water chemistry, yeast strain) matter enormously. This asymmetry is a perfect game mechanic: the player should discover what matters and what doesn't through experimentation, exactly like a real brewer. The current system treats all variables equally and misses the most impactful ones (water chemistry, hop scheduling, conditioning). Deepening the brew loop transforms the game from "brewery management sim with a minigame" into "the Brulosophy experience as a game."

## What Changes

- Add **water chemistry** as a new brewing decision and scoring component. 5 water profiles (Soft/Balanced/Malty/Hoppy/Juicy) that match or clash with beer styles. Unlockable via research
- Add **hop scheduling** — players allocate hops to Bittering/Aroma/Dry Hop slots instead of just selecting hops. New scoring component
- Add **conditioning time** (0-4 weeks post-ferment). Off-flavors decay over time, fermenters are occupied. Quality vs throughput tradeoff (the GDT "when to ship" decision)
- Implement **"close enough" zones** in scoring — mash temp ±2°C of ideal = no penalty, boil 45-90 min same for non-pilsner malts. Based on real Brulosophy findings
- Add **yeast-temp interaction system** — different yeasts produce different flavor compounds based on ferment temp (wheat: warm=banana/cool=clove, saison wants heat, lager must be cold)
- Expand **off-flavors to a spectrum** — diacetyl (butter), oxidation (cardboard), context-dependent esters/phenols. Severity scale (subtle → noticeable → dominant) instead of binary pass/fail
- Implement **progressive process revelation** — equipment purchases reveal new brewing steps and information (thermometer shows numbers, water kit adds water step, hop timer adds schedule UI)
- Add **"non-discovery" discoveries** — player learns what DOESN'T matter through experimentation. Efficiency shortcuts earned by brewing
- Expand **beer styles from 7 to 16** — each style teaches a different brewing principle. Grouped into unlock families
- **Rebalance quality scoring** — Fermentation 25%, Style Match 25%, Science 15%, Water 10%, Hop Schedule 10%, Novelty 10%, Conditioning 5%

## Capabilities

### New Capabilities
- `water-chemistry`: Water profile selection, style matching, scoring integration. 5 profiles with mineral compositions that advantage/disadvantage specific styles
- `hop-scheduling`: Hop allocation to Bittering/Aroma/Dry Hop timing slots. Scoring based on correct usage per style
- `conditioning`: Post-ferment conditioning phase (0-4 weeks). Off-flavor decay over time, fermenter occupation, quality bonus
- `brulosophy-scoring`: "Close enough" zones in mash/boil scoring. "Non-discovery" discovery system for efficiency shortcuts
- `yeast-temp-interaction`: Flavor compound generation based on yeast strain × ferment temperature. Context-dependent off-flavor evaluation (ester = bad in lager, good in wheat)
- `off-flavor-spectrum`: Expanded off-flavor system with severity scale, new failure modes (diacetyl, oxidation), and style-context evaluation
- `progressive-revelation`: Equipment reveals brewing steps and information. Ties equipment purchases to UI element visibility
- `style-expansion`: 9 new beer styles (IPA, Porter, Imperial Stout, Hefeweizen, Witbier, Czech Pilsner, Helles, Saison, NEIPA) with style families and unlock progression

### Modified Capabilities
- `quality-scoring`: Rebalanced weights (fermentation dominant at 25%, new water/hop/conditioning components). "Close enough" zones replace linear penalty curves
- `brew-execution`: Execute_brew must handle new inputs (water profile, hop allocation, conditioning decision). Expanded result dictionary
- `brewing-phases`: UI must show new steps based on equipment (water, hop schedule, conditioning). Progressive revelation of UI elements
- `recipe-design`: Recipe design adds hop allocation UI (Bittering/Aroma/Dry Hop slots) and water profile selection (if researched)
- `beer-style-selection`: 9 new styles with family grouping. Style data includes water affinity, hop schedule expectations, yeast-temp flavor profiles

## Impact

- **Autoloads**: BrewingScience (major changes — close-enough zones, yeast-temp interaction), QualityCalculator (rebalanced weights, new components), FailureSystem (spectrum severity, new failure modes, context evaluation), GameState (conditioning state, water profile, hop allocation tracking)
- **Resources**: BeerStyle .tres files need water affinity, hop expectations, yeast flavor profile data. 9 new BeerStyle resources. New WaterProfile resource class
- **Research tree**: New branches — Water Science (4 nodes), Hop Mastery (4 nodes), Fermentation Science (3 nodes). Existing nodes may need prerequisite adjustments
- **UI**: RecipeDesigner (hop allocation, water selector), BrewingPhases (progressive steps), ResultsOverlay (expanded off-flavor display, discovery toasts)
- **Equipment**: New measurement tools category (thermometer, pH meter, refractometer). Existing equipment tied to progressive revelation flags
- **Discovery system**: Extended with "non-discovery" discoveries (what doesn't matter) and water/hop/yeast discoveries
- **Tests**: Extensive new test coverage for scoring rebalance, off-flavor spectrum, conditioning mechanics, water matching, hop scheduling
