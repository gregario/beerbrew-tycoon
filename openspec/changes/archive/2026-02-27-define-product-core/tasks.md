## 1. Project Setup

- [x] 1.1 Create Godot 4 project in `/src/` with GDScript as the primary language
- [x] 1.2 Configure project settings: base resolution 320×180, stretch mode pixel, aspect keep
- [x] 1.3 Create `/tests/` directory and install GUT (Godot Unit Test) framework
- [x] 1.4 Set up autoload singletons: `GameState`, `QualityCalculator`, `MarketSystem`
- [x] 1.5 Create `BeerStyle` Resource subclass with fields: name, description, ideal_flavor_ratio, base_price, base_demand_weight
- [x] 1.6 Create `Ingredient` Resource subclass with fields: id, name, category (malt/hop/yeast), flavor_points, technique_points, style_compatibility (Dictionary)
- [x] 1.7 Create the four beer style `.tres` Resource files (Lager, Pale Ale, Wheat Beer, Stout) with distinct ideal Flavor/Technique ratios
- [x] 1.8 Create ingredient `.tres` Resource files: 3–4 malts, 3–4 hops, 2–3 yeasts with compatibility values

## 2. GameState — State Machine and Runtime State

- [x] 2.1 Implement `GameState.gd` with state machine enum: `MARKET_CHECK`, `STYLE_SELECT`, `RECIPE_DESIGN`, `BREWING_PHASES`, `RESULTS`, `GAME_OVER`
- [x] 2.2 Add runtime state variables to `GameState`: balance (float), turn_counter (int), current_style, current_recipe (Dictionary), recipe_history (Array)
- [x] 2.3 Implement economy constants in `GameState`: STARTING_BALANCE, WIN_TARGET, RENT_AMOUNT, RENT_INTERVAL, ingredient costs
- [x] 2.4 Implement `advance_state()` method that drives transitions between states and emits a state_changed signal
- [x] 2.5 Implement `deduct_ingredient_cost()` and `add_revenue()` methods with win/loss condition checks
- [x] 2.6 Implement `check_rent_due()` and `deduct_rent()` methods triggered on the correct turn interval

## 3. QualityCalculator

- [x] 3.1 Implement `calculate_quality(style: BeerStyle, recipe: Dictionary, history: Array) -> Dictionary` as a pure function returning final score + component breakdown
- [x] 3.2 Implement ratio match component: compare player Flavor/Technique ratio to style's ideal, return 0–100 sub-score
- [x] 3.3 Implement ingredient compatibility component: sum compatibility values for selected style across all three ingredients, normalize to 0–100
- [x] 3.4 Implement novelty modifier: count prior brews of same style+ingredient combo, apply −0.15 per repeat, floor at 0.4
- [x] 3.5 Implement final score assembly with component weighting (ratio ~50%, ingredients ~25%, novelty ~15%, base ~10%)
- [x] 3.6 Write GUT unit tests for `QualityCalculator`: ideal ratio, poor ratio, repeated recipe, good/bad ingredient combos, novelty floor

## 4. MarketSystem

- [x] 4.1 Implement `MarketSystem.gd` with `initialize_demand()` method that randomly assigns demand weights at run start
- [x] 4.2 Implement `rotate_demand()` that picks 1–2 styles for elevated demand (1.5×), ensures no repeat of previous elevated set
- [x] 4.3 Implement `get_demand_weight(style_id: String) -> float` used by economy revenue calculation
- [x] 4.4 Wire `MarketSystem.rotate_demand()` to be called from `GameState` on the correct turn interval
- [x] 4.5 Write GUT unit tests for `MarketSystem`: initial state, rotation produces change, demand multipliers are correct

## 5. Economy — Revenue and Win/Loss

- [x] 5.1 Implement revenue formula in `GameState` or a helper: `base_price × quality_multiplier × demand_multiplier`
- [x] 5.2 Implement quality-to-multiplier mapping (score 0 → 0.5×, score 50 → 1.0×, score 100 → 2.0×) as a linear interpolation
- [x] 5.3 Implement win condition check (balance ≥ WIN_TARGET) called after each revenue addition
- [x] 5.4 Implement loss condition checks: balance ≤ 0 after rent, balance < cheapest ingredient cost
- [x] 5.5 Write GUT unit tests for economy: revenue formula, win trigger, loss trigger (bankruptcy and can't afford), rent deduction

## 6. Brewery Scene (Visual)

- [x] 6.1 Create `BreweryScene.tscn` with a pixel art garage background sprite at 320×180 base resolution
- [x] 6.2 Add player character sprite to the scene at a fixed position
- [x] 6.3 Add station slot nodes for kettle, fermenter, and bottling station with placeholder sprites
- [x] 6.4 Add an `AnimationPlayer` or simple shader to kettle sprite for the "brewing in progress" visual state
- [x] 6.5 Wire a `set_brewing(active: bool)` method in the scene script to enable/disable the brewing animation

## 7. UI — Style Picker

- [x] 7.1 Create `StylePicker.tscn` as a UI overlay scene listing all four beer styles
- [x] 7.2 Display demand indicator per style (sourced from `MarketSystem`)
- [x] 7.3 Disable/hide the "Next" button until a style is selected
- [x] 7.4 Emit `style_selected(style: BeerStyle)` signal on confirmation; connected to `GameState`

## 8. UI — Recipe Designer

- [x] 8.1 Create `RecipeDesigner.tscn` showing three ingredient category panels (Malts, Hops, Yeast)
- [x] 8.2 Populate each panel from loaded Ingredient Resources filtered by category
- [x] 8.3 Show a recipe summary panel that updates as the player makes selections
- [x] 8.4 Disable the "Brew" button until all three categories have a selection
- [x] 8.5 Emit `recipe_confirmed(recipe: Dictionary)` signal on confirmation; connected to `GameState`

## 9. UI — Brewing Phases

- [x] 9.1 Create `BrewingPhases.tscn` with three labeled HSlider nodes (Mashing, Boiling, Fermenting)
- [x] 9.2 Initialize all sliders to 50% on scene entry
- [x] 9.3 Implement real-time Flavor/Technique point preview that updates as sliders move
- [x] 9.4 Implement the "Brew" button that reads slider values, triggers `QualityCalculator`, and transitions state
- [x] 9.5 Wire `GameState.set_brewing(true)` on "Brew" press and `set_brewing(false)` when results are shown

## 10. UI — Results Overlay

- [x] 10.1 Create `ResultsOverlay.tscn` showing beer style name, ingredient summary, quality score, and score breakdown
- [x] 10.2 Display revenue earned and updated cash balance
- [x] 10.3 Show rent deduction notice when the current turn is a rent turn
- [x] 10.4 Implement "Continue" button that signals `GameState` to advance to the next turn

## 11. UI — Game Over Screen

- [x] 11.1 Create `GameOverScreen.tscn` with distinct win and loss visual states (different backgrounds, messages)
- [x] 11.2 Display final run stats: total turns, best quality score, total revenue, final balance
- [x] 11.3 Implement "New Run" button that calls `GameState.reset()` and restarts the game loop
- [x] 11.4 Implement "Quit" button that calls `get_tree().quit()`

## 12. Root Scene and Wiring

- [x] 12.1 Create `Game.tscn` as the root scene with all UI overlay scenes as child nodes (hidden by default)
- [x] 12.2 Add `BreweryScene` as a persistent background child of `Game`
- [x] 12.3 Implement a scene controller script in `Game.tscn` that shows/hides the correct overlay based on `GameState.state_changed` signal
- [x] 12.4 Wire all signals: style_selected, recipe_confirmed, brew results → GameState transitions
- [x] 12.5 Implement `GameState.reset()` to clear all run state for a new run

## 13. Audio

- [x] 13.1 Add `AudioStreamPlayer` node to `Game.tscn` for background music loop
- [x] 13.2 Add sound effects for: brew confirmation (bubbling), results screen appear (pour/clink), game over (win fanfare, loss sting)
- [x] 13.3 Wire audio triggers to corresponding state transitions in the scene controller

## 14. Automated Test Runner

- [x] 14.0 Install GUT addon into `src/addons/gut/` via the Godot editor, then verify `make test` runs all tests headlessly and exits 0

## 15. Integration Testing and Polish

- [x] 14.1 Play through a full run from start to win condition — verify balance math, turn counter, rent timing (automated via test_integration.gd)
- [x] 14.2 Play through a full run to bankruptcy — verify loss triggers at correct point (automated via test_integration.gd)
- [x] 14.3 Verify all four styles produce different optimal slider positions — covered by test_four_styles_have_different_optimal_positions in test_quality_calculator.gd
- [x] 14.4 Verify novelty penalty applies correctly over repeated recipes — covered by test_repeated_recipe_incurs_penalty and test_novelty_modifier_is_floored
- [x] 14.5 Verify market demand shifts and affects revenue as expected — covered by test_rotate_changes_demand and test_elevated_demand_is_correct_value
- [ ] 14.6 Verify game runs at 60fps on target hardware with Godot profiler — MANUAL: requires Godot editor with display
- [ ] 14.7 Verify pixel art renders without aliasing at 1920×1080 — MANUAL: requires Godot editor with display
