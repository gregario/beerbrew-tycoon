## Context

The codebase was built before the Godot stack profile existed. It works correctly (45/45 tests passing) but has three architectural violations:

1. **Brew logic in a UI scene.** `BrewingPhases._on_brew_pressed()` runs the full brew cycle: deducts ingredient cost, calls `QualityCalculator`, calculates revenue, updates `GameState`, and advances the state machine. This couples a UI scene to the game loop, makes the logic untestable without a scene, and violates the stack rule "UI scenes react to signals — never make decisions."

2. **No signal cleanup.** `StylePicker` connects to `GameState.balance_changed` in `_ready()` with no `_exit_tree()` disconnect. Any scene reload or future scene management could fire callbacks on freed objects.

3. **Wrong folder for UI scenes.** Stack profile defines `res://ui/` for UI-only scenes. Current code uses `res://scenes/ui/`. Minor but inconsistent with the standard.

## Goals / Non-Goals

**Goals:**
- Move brew cycle logic from `BrewingPhases` into `GameState.execute_brew(sliders)`
- `BrewingPhases` emits `brew_confirmed(sliders)` signal — knows nothing about `GameState`
- `Game.gd` wires `brew_confirmed` → `GameState.execute_brew`
- All UI scenes with autoload signal connections have `_exit_tree()` cleanup
- UI scenes relocated from `scenes/ui/` to `ui/` (via Godot editor)
- New integration tests cover `execute_brew()` as a complete cycle
- All 45 existing tests continue to pass

**Non-Goals:**
- Refactoring `RecipeDesigner` or `ResultsOverlay` signal patterns (lower severity, deferred)
- Changing any game mechanics, balance values, or visible behaviour
- Touching `QualityCalculator` or `MarketSystem`
- UI visual changes of any kind

## Decisions

### Decision 1 — Signal over direct call in BrewingPhases

**Chosen:** `BrewingPhases` emits `brew_confirmed(sliders: Dictionary)`. `Game.gd` connects it to `GameState.execute_brew`.

**Alternative considered:** `BrewingPhases` calls `GameState.execute_brew(sliders)` directly. Simpler, fewer lines. Still an improvement over the current state.

**Rationale:** The stack profile states "UI scenes communicate via signals, not direct calls." Option 2 makes `BrewingPhases` a pure input device with zero coupling to the game layer. `Game.gd` is already the designated wiring layer — this is exactly its job.

### Decision 2 — execute_brew() lives on GameState, not a new class

**Chosen:** `GameState.execute_brew(sliders: Dictionary) -> Dictionary`

**Alternative considered:** A separate `BrewController` autoload or helper class.

**Rationale:** The brew cycle is a state transition. `GameState` already owns all the methods it calls (`deduct_ingredient_cost`, `add_revenue`, `record_brew`, `advance_state`). Adding a method to `GameState` is composition of existing logic, not new coupling. A new class would add an autoload for a single method.

### Decision 3 — Existing integration tests are preserved, not replaced

**Chosen:** Keep `_brew_and_advance()` helper and all existing tests. Add new `execute_brew()` tests alongside them.

**Alternative considered:** Rewrite integration tests to use `execute_brew()` exclusively.

**Rationale:** Existing tests deliberately bypass `QualityCalculator` (passing a fixed quality score) to isolate economy logic. That is correct test design — they test one thing at a time. `execute_brew()` tests cover the seam between QualityCalculator and GameState, which is new coverage. Both layers are valuable.

### Decision 4 — Folder move is a manual Godot editor task

**Chosen:** Document as a task that must be performed in the Godot editor, not by script.

**Rationale:** Moving files outside the editor breaks all `res://` path references in `.tscn` files silently. The Godot editor detects moves and offers to fix references automatically. Attempting this via `mv` would require manually updating every `ext_resource` path in every scene file — fragile and error-prone.

## Risks / Trade-offs

**[Risk] execute_brew() connects two autoloads (GameState calls QualityCalculator).**
→ Mitigation: GameState already calls MarketSystem internally (in `calculate_revenue`). Autoload-to-autoload calls are an established pattern in this project. Risk is low.

**[Risk] Folder move could break scene references if done outside the editor.**
→ Mitigation: Task is explicitly marked as editor-only. Headless execution is prohibited for this step.

**[Risk] New signal connection in Game.gd could fail silently if node names change.**
→ Mitigation: `@onready` caching means a mismatch errors at startup, not silently. Covered by smoke testing.

**[Trade-off] _exit_tree() cleanup adds boilerplate to every UI scene.**
→ Accepted: This is the correct Godot pattern. The alternative (leaked signal connections) causes intermittent crashes that are hard to diagnose.

## Migration Plan

1. All GDScript changes are backwards-compatible — no scene files change (except the folder move).
2. The folder move is the only step that requires the Godot editor. It must be done first or last — not mid-way — to keep the project in a runnable state.
3. Recommended order: GDScript changes first (testable headlessly), folder move last (requires editor verification).
4. Rollback: git revert. No data migrations, no external dependencies.

## Open Questions

None. All decisions are resolved.
