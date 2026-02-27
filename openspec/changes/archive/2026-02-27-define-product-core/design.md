## Context

BeerBrew Tycoon is a greenfield Godot 4 game. There is no existing codebase — only reference notes in `reference/`. The design must produce a working MVP: one complete garage-stage run of the core brewing loop, playable in 15–30 minutes. All implementation will use GDScript (no C#, no GDExtension).

## Goals / Non-Goals

**Goals:**
- Define the architectural shape of the Godot 4 project: scene tree, autoloads, data model
- Establish the core game loop as a state machine the entire game flows through
- Define how game data (beer styles, ingredients, market state) is represented and accessed
- Make all technical decisions that would otherwise be re-litigated during implementation

**Non-Goals:**
- Art pipeline details (handled by the solo developer with AI tooling)
- Audio implementation specifics
- Save/load system (explicitly excluded from MVP)
- Any system beyond the garage stage

## Decisions

### 1. Scene architecture: single root scene + overlay subscenes

**Decision:** One root `Game` scene owns the game state. The garage brewery view, UI panels, and overlays are separate scenes instantiated and swapped by the root.

**Rationale:** Godot's scene tree works best when each distinct screen/state is its own scene. A monolithic scene would be hard to iterate. Separate overlay scenes (recipe picker, results screen, game over) can be developed and tested independently.

**Alternative considered:** A single enormous scene with all nodes hidden/shown. Rejected — hard to maintain and clutters the scene tree.

---

### 2. Game loop: explicit state machine (GameState autoload)

**Decision:** An autoload singleton `GameState` drives the entire game loop as an explicit state machine with states: `MARKET_CHECK → STYLE_SELECT → RECIPE_DESIGN → BREWING_PHASES → RESULTS → MARKET_CHECK` (cycling), plus `GAME_OVER`.

**Rationale:** The game loop is fundamentally sequential and turn-based. An explicit enum-driven state machine makes transitions testable, debuggable, and immune to UI event ordering bugs.

**Alternative considered:** Signal-driven flow with no central state. Rejected — difficult to reason about state, easy to get into impossible combinations (e.g., slider active when no style is selected).

---

### 3. Data: Resources for static data, Dictionary for runtime state

**Decision:** Beer styles and ingredients are defined as Godot `Resource` files (`.tres` or `.res`) loaded at startup. Runtime state (cash balance, current recipe, market demand, turn counter) lives in `GameState` as typed GDScript variables.

**Rationale:** Godot Resources are the idiomatic data container for static game data. They support the inspector, are serializable, and don't require custom file parsing. Runtime state doesn't need persistence (no save/load in MVP), so plain variables are sufficient.

---

### 4. Quality score: pure function, no side effects

**Decision:** Quality scoring is a pure GDScript function `calculate_quality(style, recipe, history) -> float` in a stateless `QualityCalculator` autoload. It takes all inputs and returns a score — no global state reads.

**Rationale:** Pure functions are trivially testable. The scoring formula is the heart of the game loop; it must be testable without spinning up scenes.

---

### 5. Market system: array of demand weights, rotated on a turn schedule

**Decision:** Market demand is an array of weights per style, updated every N turns (configurable constant, starting at 3 turns). One or two styles get a 1.5× demand multiplier; others are 1.0×. The active demand state is stored in `GameState`.

**Rationale:** Simple to implement, simple to understand as a player. Complexity can grow in future runs (trends, events) without breaking this interface.

---

### 6. Testing: GUT (Godot Unit Test) framework

**Decision:** Use GUT (Godot Unit Testing) for all unit tests. Tests live in `/tests/` and cover quality scoring, economy math, and market rotation logic.

**Rationale:** GUT is the de facto standard for Godot unit testing, integrates with the editor, and supports CI. The pure-function design of the scoring and economy systems makes them trivially testable.

---

### 7. Project structure

```
/src/
  project.godot
  autoloads/
    GameState.gd       # state machine + runtime state
    QualityCalculator.gd
    MarketSystem.gd
  scenes/
    Game.tscn          # root scene
    BreweryScene.tscn  # garage view
    ui/
      StylePicker.tscn
      RecipeDesigner.tscn
      BrewingPhases.tscn
      ResultsOverlay.tscn
      GameOverScreen.tscn
  data/
    styles/            # BeerStyle Resources
    ingredients/       # Ingredient Resources
  scripts/
    BeerStyle.gd       # Resource subclass
    Ingredient.gd      # Resource subclass
/tests/
  test_quality_calculator.gd
  test_market_system.gd
  test_economy.gd
```

## Risks / Trade-offs

- **Pixel art scope creep** → Mitigation: define exact sprite counts in specs; use placeholders during code development
- **Slider UX feel** → The brewing phase sliders are the core interaction; poor feel will kill the game. Mitigation: prototype the slider UI first before polishing any other screen
- **Novelty penalty tuning** → Too aggressive = frustrating; too lenient = trivial. Mitigation: expose as a configurable constant, tune in playtesting
- **GUT integration** → GUT requires a Godot editor to run; not trivially CI-friendly. Mitigation: accept editor-run tests for MVP, add headless CI later
