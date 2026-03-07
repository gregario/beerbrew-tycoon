## 1. Foundation: Resources & Data Model Extensions

- [ ] 1.1 Create WaterProfile resource class (profile_id, display_name, mineral_description, style_affinities Dictionary)
- [ ] 1.2 Create 5 WaterProfile .tres files (soft, balanced, malty, hoppy, juicy) at res://data/water/
- [ ] 1.3 Add new properties to BeerStyle resource: family, water_affinity, hop_schedule_expectations, yeast_temp_flavors, acceptable_off_flavors, primary_lesson
- [ ] 1.4 Update existing 7 BeerStyle .tres files (4 base + 3 specialty) with new properties
- [ ] 1.5 Add yeast_flavor_profile property to Yeast resource class (Dictionary mapping temp ranges to flavor compounds)
- [ ] 1.6 Update existing 6 Yeast .tres files with yeast_flavor_profile data
- [ ] 1.7 Add reveals property (Array[String]) to Equipment resource class
- [ ] 1.8 Update existing equipment .tres files with reveals data where applicable
- [ ] 1.9 Create 4 Measurement equipment .tres files (Thermometer $30 T1, Digital Thermometer $80 T2, pH Meter $120 T2, Refractometer $200 T3)
- [ ] 1.10 Create Water Kit equipment .tres file ($100 T2, reveals water_selector)

## 2. Style Expansion: 9 New Beer Styles

- [ ] 2.1 Create IPA BeerStyle .tres (ales family, hop-forward, hoppy water affinity 0.95)
- [ ] 2.2 Create Porter and Imperial Stout BeerStyle .tres files (dark family)
- [ ] 2.3 Create Hefeweizen BeerStyle .tres (wheat family, ester_banana acceptable 0.8)
- [ ] 2.4 Create Czech Pilsner, Helles, Marzen BeerStyle .tres files (lager family)
- [ ] 2.5 Create Saison and Belgian Dubbel BeerStyle .tres files (belgian family)
- [ ] 2.6 Create NEIPA BeerStyle .tres (modern family, juicy water affinity 0.95)
- [ ] 2.7 Add style family research nodes to ResearchManager catalog (lager_brewing, belgian_brewing, modern_techniques)
- [ ] 2.8 Update StylePicker to group styles by family with headers and locked family display

## 3. Tolerance Scoring: Close Enough Zones

- [ ] 3.1 Modify BrewingScience.calc_mash_score() to implement ±2°C flat zone (no penalty within zone)
- [ ] 3.2 Modify BrewingScience.calc_boil_score() to implement 45-90 min flat zone for non-pilsner malts
- [ ] 3.3 Add dms_risk property to Malt resource class and set pilsner_malt.tres to high DMS risk
- [ ] 3.4 Write tests for close-enough zones (verify flat zone, verify penalty ramp beyond zone, verify pilsner DMS exception)

## 4. Yeast-Temperature Interaction

- [ ] 4.1 Create YeastFlavorCalculator (function in BrewingScience) that computes flavor compound outputs from yeast strain × ferment temp
- [ ] 4.2 Implement flavor compound types: ester_banana, ester_fruit, phenol_clove, phenol_pepper, fusel, clean
- [ ] 4.3 Implement yeast-specific profiles: wheat (banana vs clove crossover at 20°C), saison (hotter=better), lager (must be cold), clean ale (forgiving 16-22°C)
- [ ] 4.4 Write tests for yeast-temp interaction (wheat at 24°C=banana, wheat at 16°C=clove, saison at 30°C=good, lager at 18°C=bad)

## 5. Off-Flavor Spectrum

- [ ] 5.1 Refactor FailureSystem to use float intensity 0.0-1.0 per off-flavor type instead of binary
- [ ] 5.2 Add new off-flavor types: diacetyl (ferment rush), oxidation (batch size × equipment), acetaldehyde (premature packaging)
- [ ] 5.3 Implement context-dependent evaluation using BeerStyle.acceptable_off_flavors thresholds
- [ ] 5.4 Implement off-flavor severity labels (subtle/noticeable/dominant) and context labels (desired/neutral/flaw)
- [ ] 5.5 Write tests for off-flavor spectrum (intensity scaling, context evaluation, diacetyl generation, oxidation from batch size)

## 6. Water Chemistry System

- [ ] 6.1 Add current_water_profile to GameState (defaults to null/tap water)
- [ ] 6.2 Implement water chemistry scoring component in QualityCalculator (profile affinity × 10% weight)
- [ ] 6.3 Add water profile selector UI to RecipeDesigner (visible only when is_revealed("water_selector"))
- [ ] 6.4 Write tests for water scoring (perfect match, wrong profile, default tap water)

## 7. Hop Scheduling System

- [ ] 7.1 Add hop_allocations to GameState.current_recipe (Dictionary mapping hop_id to slot Array)
- [ ] 7.2 Implement hop schedule scoring component in QualityCalculator (allocation match vs style expectations × 10% weight)
- [ ] 7.3 Add hop timing allocation UI to RecipeDesigner (visible only when is_revealed("hop_schedule"))
- [ ] 7.4 Write tests for hop scheduling (correct allocation, wrong allocation, default all-bittering)

## 8. Conditioning System

- [ ] 8.1 Add CONDITIONING state to GameState.State enum (between RESULTS and SELL)
- [ ] 8.2 Implement off-flavor decay function (per-type decay rates: diacetyl 0.25/week, acetaldehyde 0.15/week, esters 0.05/week, oxidation 0)
- [ ] 8.3 Implement conditioning quality bonus (+1% per week, max 4%)
- [ ] 8.4 Implement conditioning cost deduction (weeks × rent/4)
- [ ] 8.5 Create ConditioningOverlay UI (week selector 0-4, off-flavor decay preview, quality bonus preview, cost display)
- [ ] 8.6 Wire conditioning state in Game.gd (show overlay, handle confirm, advance to SELL)
- [ ] 8.7 Write tests for conditioning (decay math, quality bonus, cost deduction, state transition)

## 9. Quality Scoring Rebalance

- [ ] 9.1 Refactor QualityCalculator to use new 7-component weight system (Style 25%, Ferment 25%, Science 15%, Water 10%, Hops 10%, Novelty 10%, Conditioning 5%)
- [ ] 9.2 Implement fermentation component (yeast-temp accuracy + flavor compound desirability + stability)
- [ ] 9.3 Integrate water and hop schedule components
- [ ] 9.4 Update calculate_quality() signature to accept water_profile, hop_allocations, conditioning_weeks
- [ ] 9.5 Ensure backward compatibility (missing inputs get defaults)
- [ ] 9.6 Update existing tests to match new score ranges
- [ ] 9.7 Write tests for new scoring components in isolation and combined

## 10. Progressive Revelation

- [ ] 10.1 Add is_revealed(feature_id) method to EquipmentManager that aggregates all equipped items' reveals arrays
- [ ] 10.2 Update RecipeDesigner to check is_revealed() before showing water selector and hop allocation UI
- [ ] 10.3 Update BrewingPhases to check is_revealed("temp_numbers") before showing numerical values on sliders
- [ ] 10.4 Add yeast-dependent ferment slider range (ale 15-24°C, lager 4-12°C, saison 20-35°C, wheat 16-26°C)
- [ ] 10.5 Add Measurement tab to EquipmentShop
- [ ] 10.6 Write tests for reveals aggregation and UI conditional display

## 11. Discovery System Extensions

- [ ] 11.1 Implement non-discovery tracking (compare paired brews with varied "doesn't matter" variables)
- [ ] 11.2 Add non-discovery toasts (mash temp tolerance, boil length tolerance)
- [ ] 11.3 Add water-related discoveries (water-style affinity awareness)
- [ ] 11.4 Add yeast-temp discoveries (banana vs clove, saison heat)
- [ ] 11.5 Add hop schedule discoveries (late additions = more aroma)
- [ ] 11.6 Persist discovered shortcuts in save state
- [ ] 11.7 Write tests for non-discovery detection and toast triggering

## 12. Brew Execution & GameState Integration

- [ ] 12.1 Update GameState.execute_brew() to pass water_profile, hop_allocations, conditioning_weeks to QualityCalculator
- [ ] 12.2 Add off_flavors Array to brew result Dictionary (type, intensity, context, display_name)
- [ ] 12.3 Update state machine: advance_state() RESULTS → CONDITIONING → SELL
- [ ] 12.4 Update ResultsOverlay to display off-flavor spectrum with context coloring (green/yellow/red)
- [ ] 12.5 Update GameState.reset() and save/load for new state fields
- [ ] 12.6 Write integration tests for full brew cycle with all new components

## 13. Research Tree Expansion

- [ ] 13.1 Add Water Science branch (4 nodes: water_basics → mineral_adjustment → ph_management → advanced_water)
- [ ] 13.2 Add Hop Mastery branch (4 nodes: hop_timing → dry_hopping → biotransformation → hop_blending)
- [ ] 13.3 Add Fermentation Science branch (3 nodes: yeast_health → temp_profiling → diacetyl_rest)
- [ ] 13.4 Add style family unlock nodes (lager_brewing, belgian_brewing, modern_techniques)
- [ ] 13.5 Update ResearchTree UI to show new branches
- [ ] 13.6 Write tests for new research nodes and prerequisites

## 14. Balance & Polish

- [ ] 14.1 Run economy simulation with rebalanced scoring — verify win achievable in 30-60 turns
- [ ] 14.2 Tune water affinity values across all 16 styles
- [ ] 14.3 Tune hop schedule expectations across all 16 styles
- [ ] 14.4 Tune off-flavor generation rates and decay constants
- [ ] 14.5 Update docs/balance-reference.md with new economy constants
- [ ] 14.6 Update CLAUDE.md project state
