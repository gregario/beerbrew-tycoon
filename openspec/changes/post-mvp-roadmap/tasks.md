## 1. Stage 1A — Ingredient System Overhaul

- [ ] 1.1 Create Malt, Hop, and Yeast Resource classes with typed numeric properties and flavor tags
- [ ] 1.2 Create ingredient catalog: 8+ malts (Pilsner through Roasted Barley), 8+ hops (Saaz through Citra), 6+ yeasts (US-05 through Kveik) as .tres files
- [ ] 1.3 Update RecipeDesigner to support multi-select: 1-3 malts, 1-2 hops, 1 yeast with combined property display
- [ ] 1.4 Add recipe summary panel showing estimated color, bitterness, body, flavor tags, total cost
- [ ] 1.5 Update GameState and economy to calculate multi-ingredient costs
- [ ] 1.6 Write GUT tests for ingredient resources, multi-selection, cost calculation

## 2. Stage 1B — Brewing Science

- [ ] 2.1 Map mashing slider to temperature range (62-69°C) with fermentability curve function
- [ ] 2.2 Map boiling slider to hop schedule emphasis (bittering ↔ aroma) affecting flavor/technique split
- [ ] 2.3 Map fermenting slider to temperature relative to yeast ideal range with quality bonus/penalty
- [ ] 2.4 Add stochastic noise (±5%) to brewing outcomes with per-brew seed
- [ ] 2.5 Update BrewingPhases UI to display temperature/parameter labels on each slider
- [ ] 2.6 Add green zone indicator on fermenting slider showing yeast ideal range
- [ ] 2.7 Write GUT tests for all brewing science calculations and edge cases

## 3. Stage 1C — Failure Modes & QA

- [ ] 3.1 Add sanitation_quality and temp_control_quality stats to GameState (default 50)
- [ ] 3.2 Implement infection probability calculation and quality penalty (40-60% score reduction)
- [ ] 3.3 Implement off-flavor probability calculation and quality penalty (15-30% score reduction)
- [ ] 3.4 Add QA checkpoint toast notifications (pre-boil gravity, boil vigor, final gravity)
- [ ] 3.5 Update ResultsOverlay to show failure mode information (infection/off-flavor tags)
- [ ] 3.6 Write GUT tests for failure probability, penalties, and edge cases

## 4. Stage 1D — Quality Scoring Overhaul

- [ ] 4.1 Refactor QualityCalculator to use expanded 7-component scoring formula
- [ ] 4.2 Implement brewing science accuracy sub-scoring (mash temp, ferment temp, hop schedule)
- [ ] 4.3 Add equipment quality bonus component (aggregated efficiency_bonus)
- [ ] 4.4 Add staff skill bonus component (assigned staff stats)
- [ ] 4.5 Replace novelty modifier with market saturation modifier
- [ ] 4.6 Add failure mode multiplicative penalties to final score
- [ ] 4.7 Update score breakdown display in ResultsOverlay for new components
- [ ] 4.8 Write GUT tests for complete scoring formula with all components

## 5. Stage 1E — Save/Load System

- [ ] 5.1 Implement SaveManager autoload with save_game() and load_game() methods
- [ ] 5.2 Serialize all GameState to JSON (balance, turn, history, market state)
- [ ] 5.3 Implement auto-save after each brew turn
- [ ] 5.4 Create meta.json for cross-run progression data (separate from run saves)
- [ ] 5.5 Add save format versioning with migration function support
- [ ] 5.6 Add Continue/New Game options to a main menu screen
- [ ] 5.7 Write GUT tests for save/load roundtrip, migration, and meta persistence

## 6. Stage 2A — Equipment System

- [ ] 6.1 Create Equipment Resource class with tier, category, stats, and cost properties
- [ ] 6.2 Create equipment catalog: 15+ items across brewing/fermentation/packaging/utility categories, tiers 1-7
- [ ] 6.3 Build EquipmentShop UI screen (card-based, shows available/owned/locked items)
- [ ] 6.4 Implement equipment purchasing (cost deduction, ownership tracking in GameState)
- [ ] 6.5 Implement station slot system (3 slots in garage, equipment must be placed to be active)
- [ ] 6.6 Aggregate active equipment bonuses into brewing parameters (sanitation, temp control, efficiency)
- [ ] 6.7 Update BreweryScene to display equipment in station slots visually
- [ ] 6.8 Write GUT tests for equipment purchase, slot system, bonus aggregation

## 7. Stage 2B — Research Tree

- [ ] 7.1 Create ResearchNode Resource class (name, category, rp_cost, prerequisites, unlock_effect)
- [ ] 7.2 Design research tree: Techniques (6 nodes), Ingredients (4 nodes), Equipment (4 nodes), Styles (6 nodes)
- [ ] 7.3 Implement RP accumulation after each brew (base_rp + quality_score/20)
- [ ] 7.4 Build ResearchTree UI screen (visual node graph with unlock states)
- [ ] 7.5 Implement research purchasing and unlock effect application
- [ ] 7.6 Gate ingredients, techniques, equipment tiers, and styles behind research nodes
- [ ] 7.7 Write GUT tests for RP calculation, prerequisite checking, unlock effects

## 8. Stage 3A — Staff System

- [ ] 8.1 Create Staff Resource class (name, creativity, precision, level, salary, specialization)
- [ ] 8.2 Implement staff candidate generation (random stats/salary, 2-3 candidates per cycle)
- [ ] 8.3 Build HiringScreen UI (candidate cards with stats, hire button)
- [ ] 8.4 Implement staff assignment to brewing phases with bonus point calculation
- [ ] 8.5 Implement staff experience gain and leveling (level up increases stats by 2-5)
- [ ] 8.6 Implement staff training (spend money to boost specific stat, unavailable for 1 turn)
- [ ] 8.7 Implement staff specialization at level 5 (double bonus in specialized phase, half in others)
- [ ] 8.8 Add salary deduction per turn to economy
- [ ] 8.9 Update BrewingPhases UI with staff assignment slots
- [ ] 8.10 Write GUT tests for hiring, assignment, leveling, training, specialization

## 9. Stage 3B — Brewery Expansion

- [ ] 9.1 Implement brewery stage transitions (garage → microbrewery threshold: $5000 + 10 beers)
- [ ] 9.2 Build expansion choice UI screen (cost, benefits, new capabilities)
- [ ] 9.3 Increase station slots on expansion (3 → 5 for microbrewery)
- [ ] 9.4 Scale rent per stage (garage $150, microbrewery $400)
- [ ] 9.5 Create microbrewery BreweryScene layout (larger room, 5 slots, staff sprites)
- [ ] 9.6 Gate staff hiring behind microbrewery stage
- [ ] 9.7 Gate tier 3-4 equipment behind microbrewery stage
- [ ] 9.8 Write GUT tests for stage transitions, slot changes, rent scaling

## 10. Stage 4A — Contracts

- [ ] 10.1 Create Contract Resource (client, style, min quality, reward, deadline, penalty)
- [ ] 10.2 Implement contract generation (2-3 per cycle, refresh every 3 turns)
- [ ] 10.3 Build ContractBoard UI screen (available contracts, active contracts with deadlines)
- [ ] 10.4 Implement contract fulfillment check on brew completion (style match + quality threshold)
- [ ] 10.5 Implement contract rewards (base + bonus for exceeding quality) and failure penalties
- [ ] 10.6 Write GUT tests for contract generation, fulfillment, rewards, deadline expiry

## 11. Stage 4B — Competitions

- [ ] 11.1 Implement competition event scheduling (every 8-10 turns)
- [ ] 11.2 Build competition entry UI (select beer, pay entry fee, see category)
- [ ] 11.3 Implement simulated judging (3 competitors with scaling random scores)
- [ ] 11.4 Award prizes by tier (gold/silver/bronze: cash, reputation, rare unlocks)
- [ ] 11.5 Track competition medals in brew history and GameState
- [ ] 11.6 Write GUT tests for competition scheduling, judging, prize awarding

## 12. Stage 4C — Market & Distribution Overhaul

- [ ] 12.1 Implement seasonal demand cycles (4 seasons × 6 turns, per-style modifiers)
- [ ] 12.2 Implement trending style system (random style spike every 8-12 turns for 4-6 turns)
- [ ] 12.3 Replace novelty penalty with market saturation (per-style, decays when not brewing)
- [ ] 12.4 Build MarketForecast UI screen (seasons, trends, saturation, research predictions)
- [ ] 12.5 Implement distribution channels (taproom, bars, retail, events) with margin/volume
- [ ] 12.6 Build distribution allocation UI (split batch across channels)
- [ ] 12.7 Implement market research purchase (reveals upcoming trends)
- [ ] 12.8 Implement player-set pricing with price-demand curve
- [ ] 12.9 Update revenue formula for multi-channel + pricing
- [ ] 12.10 Write GUT tests for seasonal cycles, saturation, channels, pricing, revenue

## 13. Stage 5 — Artisan vs Mass-Market Fork

- [ ] 13.1 Build fork choice screen (at microbrewery, $15,000 + 25 beers threshold)
- [ ] 13.2 Implement artisan path: +20% quality bonus, rare ingredients, competition discounts
- [ ] 13.3 Implement artisan win condition (5 medals + reputation 100)
- [ ] 13.4 Implement artisan specialty beers (sour, barrel-aged, experimental with extended fermentation)
- [ ] 13.5 Implement mass-market path: 2x batch size, automation equipment, bulk discounts
- [ ] 13.6 Implement mass-market win condition ($50,000 revenue + all 4 channels)
- [ ] 13.7 Implement brand recognition system (per-style, builds with consistent sales)
- [ ] 13.8 Implement automation equipment (flat bonuses replacing staff need)
- [ ] 13.9 Create artisan and mass-market BreweryScene layouts (7 station slots each)
- [ ] 13.10 Scale rent for artisan ($600) and mass-market ($800) stages
- [ ] 13.11 Write GUT tests for both paths, win conditions, unique mechanics

## 14. Stage 6 — Roguelite Meta-Progression

- [ ] 14.1 Implement unlock point calculation on run end (based on performance metrics)
- [ ] 14.2 Build meta-progression screen (categories: styles, blueprints, ingredients, staff traits, perks)
- [ ] 14.3 Implement style unlock persistence (unlocked styles available from turn 1 in future runs)
- [ ] 14.4 Implement equipment blueprint unlocks (50% research cost reduction)
- [ ] 14.5 Implement brewery perks (3 max active: +5% cash, +1 RP, -10% rent, style bonuses)
- [ ] 14.6 Build run start screen (select perks + modifiers before starting)
- [ ] 14.7 Implement run modifiers: challenge (Tough Market, Budget Brewery, Ingredient Shortage) and bonus (Master Brewer, Lucky Break, Generous Market)
- [ ] 14.8 Implement achievement system for modifier unlocks
- [ ] 14.9 Update main menu with meta-progression info and run history
- [ ] 14.10 Write GUT tests for unlock points, persistence, perks, modifiers, achievements

## 15. Integration & Polish

- [ ] 15.1 End-to-end playtest: complete run from garage through artisan OR mass-market win
- [ ] 15.2 End-to-end playtest: complete 2 runs testing meta-progression persistence
- [ ] 15.3 Balance pass: tune all numeric parameters (costs, thresholds, bonuses, probabilities)
- [ ] 15.4 UI polish pass: ensure all new screens follow design system (card layout, typography, states)
- [ ] 15.5 Performance check: 60fps at each stage with all systems active
- [ ] 15.6 Update all design docs and specs to reflect final implemented state
