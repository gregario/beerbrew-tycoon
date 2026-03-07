## 1. Specialty Beer Data & Manager

- [ ] 1.1 Add specialty fields to BeerStyle Resource (is_specialty: bool, fermentation_turns: int, variance_modifier: float, specialty_category: String) and create 3 specialty BeerStyle .tres files (Berliner Weisse 3 turns, Lambic 5 turns, Experimental Brew 1 turn)
- [ ] 1.2 Create SpecialtyBeerManager autoload with aging queue (Array of Dicts), queue_beer(), tick_aging(), get_completed_beers(), save/load support
- [ ] 1.3 Integrate SpecialtyBeerManager with GameState lifecycle — tick_aging() in _on_results_continue, resolve completed beers with revenue, reset on new run

## 2. Wild Fermentation Research Node

- [ ] 2.1 Create wild_fermentation.tres research node (Techniques category, 30 RP, prerequisite: specialist_yeast, effect: unlock_specialty_beers) and register in ResearchManager catalog
- [ ] 2.2 Add unlock_specialty_beers effect handling in ResearchManager — set a flag that SpecialtyBeerManager checks, gate specialty styles in style picker

## 3. Experimental Brew Mutation

- [ ] 3.1 Implement ingredient mutation logic in SpecialtyBeerManager — randomly select one ingredient, randomize its flavor/technique points within ±50%, store mutation data for results display
- [ ] 3.2 Integrate mutation with QualityCalculator — pass mutated ingredient values when scoring experimental brews

## 4. Quality Scoring Updates

- [ ] 4.1 Add specialty beer variance to QualityCalculator — ±15 variance (vs ±5 normal) with seeded RNG, +10 ceiling boost, apply when is_specialty flag is true
- [ ] 4.2 Add automation bonus integration to QualityCalculator — max(staff_bonus, automation_bonus) per phase, get automation bonuses from EquipmentManager

## 5. Brand Recognition System

- [ ] 5.1 Add brand_recognition Dictionary to MarketManager with methods: add_brand_recognition(style, channel), tick_brand_decay(brewed_style), get_brand_recognition(style), get_brand_demand_multiplier(style), save/load
- [ ] 5.2 Integrate brand recognition with demand volume calculation in MarketManager — multiply demand by brand multiplier (1.0 + recognition/100 * 0.5)
- [ ] 5.3 Integrate brand gain into sell flow — call add_brand_recognition() when player sells beer in SellOverlay, call tick_brand_decay() at end of turn

## 6. Automation Equipment

- [ ] 6.1 Add automation fields to Equipment Resource (mash_bonus, boil_bonus, ferment_bonus), create 4 automation .tres files (Auto-Mash T3 $800, Automated Boil T4 $1500, Fermentation Controller T4 $1800, Full Automation Suite T5 $3500)
- [ ] 6.2 Add automation bonus aggregation to EquipmentManager — get_automation_mash_bonus(), get_automation_boil_bonus(), get_automation_ferment_bonus() from active slotted automation equipment
- [ ] 6.3 Add path-gating in EquipmentShop — hide automation category for artisan path players using PathManager.get_current_path_name()

## 7. UI Updates

- [ ] 7.1 Add specialty styles to style picker — show Sour/Wild Ale and Experimental Brew options when wild_fermentation researched AND on artisan path, with fermentation turn indicator
- [ ] 7.2 Add aging queue display — show aging beers with turns remaining (toast on queue entry, panel in BreweryScene or ResultsOverlay for completed aged beers)
- [ ] 7.3 Add brand recognition display to MarketForecast — bar/number per style in Forecast tab showing recognition level and demand bonus %
- [ ] 7.4 Update BrewingPhases UI to show automation vs staff bonuses — display both values per phase, highlight the active (higher) one
- [ ] 7.5 Show experimental brew mutation results — display which ingredient mutated and new values in ResultsOverlay

## 8. Integration & Testing

- [ ] 8.1 Write GUT tests for SpecialtyBeerManager (aging queue CRUD, tick, completion, save/load, mutation logic)
- [ ] 8.2 Write GUT tests for brand recognition (gain per channel, decay, demand multiplier, save/load)
- [ ] 8.3 Write GUT tests for automation equipment (bonus aggregation, staff vs automation max, path-gating)
- [ ] 8.4 Write GUT tests for quality scoring updates (specialty variance, automation bonus integration, mutation scoring)
- [ ] 8.5 Verify all existing 484 tests still pass with new changes
