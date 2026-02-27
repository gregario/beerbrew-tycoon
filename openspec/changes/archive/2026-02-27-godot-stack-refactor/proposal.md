## Why

The Godot stack profile has been established for the AI-Factory, defining architectural standards that all Godot projects must follow. The beerbrew-tycoon codebase predates this profile and has three violations: gameplay logic executing inside a UI scene, missing signal cleanup, and UI scenes in the wrong folder. Addressing these now keeps the codebase aligned with the factory standard before it grows further.

## What Changes

- `GameState` gains an `execute_brew(sliders)` method that owns the full brew cycle (cost deduction, quality calculation, revenue calculation, result storage, state advancement)
- `BrewingPhases` is reduced to a pure input scene — emits a `brew_confirmed(sliders)` signal, calls nothing on `GameState` directly
- `Game.gd` connects `BrewingPhases.brew_confirmed` to `GameState.execute_brew`
- All UI scenes that connect to autoload signals gain `_exit_tree()` disconnect guards
- UI scenes are moved from `res://scenes/ui/` to `res://ui/` to match the stack profile folder layout (manual Godot editor task)
- New integration tests cover the `execute_brew()` full cycle

## Capabilities

### New Capabilities

- `brew-execution`: The brew cycle (cost, quality, revenue, history, state transition) as a single callable method on GameState, testable without a scene

### Modified Capabilities

- `brewing-phases`: Requirements change — this scene no longer drives the game loop. It is a pure input device that emits a signal. It must not call GameState directly.
- `economy`: `execute_brew()` is added as the canonical entry point for a brew turn. The individual methods (deduct_ingredient_cost, add_revenue, etc.) remain but are now called internally by execute_brew rather than externally by a UI scene.

## Impact

- `src/autoloads/GameState.gd` — new `execute_brew()` method
- `src/scenes/ui/BrewingPhases.gd` — `_on_brew_pressed()` replaced with signal emit
- `src/scenes/Game.gd` — new signal connection wired
- `src/scenes/ui/StylePicker.gd` — `_exit_tree()` added
- All other UI scenes — `_exit_tree()` added where autoload signals are connected
- `src/tests/test_integration.gd` — new execute_brew cycle tests added
- Folder: `src/scenes/ui/` → `src/ui/` (editor-only move, all .tscn references auto-updated)
- No public API changes. No breaking changes to existing tests.
