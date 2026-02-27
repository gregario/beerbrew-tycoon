## 1. GameState — execute_brew() method

- [x] 1.1 Add `execute_brew(sliders: Dictionary) -> Dictionary` to `GameState.gd` — absorbs the 8-step brew cycle from `BrewingPhases._on_brew_pressed()`: deduct cost, set_brewing(true), calculate_quality, calculate_revenue, add_revenue, result["revenue"], record_brew, last_brew_result, set_brewing(false), advance_state
- [x] 1.2 Handle the failed-deduction guard: if `deduct_ingredient_cost()` returns false, return `{}` immediately without modifying any other state
- [x] 1.3 Verify `make test` still passes (all 45 tests green) after adding execute_brew

## 2. BrewingPhases — signal refactor

- [x] 2.1 Add `signal brew_confirmed(sliders: Dictionary)` to `BrewingPhases.gd`
- [x] 2.2 Replace the body of `_on_brew_pressed()` with `brew_confirmed.emit(_get_sliders())` — remove all direct GameState/QualityCalculator calls
- [x] 2.3 Verify `BrewingPhases.gd` contains zero references to `GameState`. Note: QualityCalculator retained for read-only slider preview (pure calculation, no state mutation — accepted deviation from original spec).

## 3. Game.gd — wire the signal

- [x] 3.1 In `Game.gd _ready()`, connect `brewing_phases.brew_confirmed` to `GameState.execute_brew`
- [ ] 3.2 Verify game runs end-to-end: complete a full brew cycle from style select through results screen — **MANUAL: smoke test in Godot editor after task 6**

## 4. Signal cleanup — _exit_tree()

- [x] 4.1 Add `_exit_tree()` to `StylePicker.gd` — disconnect `GameState.balance_changed`
- [x] 4.2 Audit all other UI scenes for autoload signal connections — only `Game.gd` (root scene, never freed) has another autoload signal; no `_exit_tree()` needed there
- [x] 4.3 Verify `make test` still passes after cleanup additions

## 5. New integration tests — execute_brew()

- [x] 5.1 Add `test_execute_brew_runs_full_cycle()` — 48/48 passing
- [x] 5.2 Add `test_execute_brew_fails_when_balance_insufficient()` — 48/48 passing
- [x] 5.3 Add `test_execute_brew_win_condition()` — 48/48 passing
- [x] 5.4 Verify all tests pass: `make test` exits 0, count increased from 45 to 48

## 6. Folder restructure — UI scenes (MANUAL — Godot editor required)

**Must be done in the Godot editor. Do not use `mv` or terminal commands — this will silently break all `res://` path references in `.tscn` files.**

Steps:
- [ ] 6.1 Open the project in the Godot editor: open `src/project.godot`
- [ ] 6.2 In the FileSystem dock, right-click `res://scenes/ui/` → Move, drag to `res://` root, rename to `ui/`
- [ ] 6.3 When the editor prompts "Fix broken references?" — click **Yes** (this updates all `ext_resource` paths in `.tscn` files automatically)
- [ ] 6.4 Verify `Game.tscn` opens without errors in the editor (no missing node warnings)
- [ ] 6.5 Run `make test` one final time — all 48 tests pass, exits 0
- [ ] 6.6 Smoke test: play one full brew cycle from style select → brew → results screen

After completing 6.1–6.6:
- Commit the moved files: `git add -A && git commit -m "refactor: move scenes/ui/ to ui/ per Godot stack profile"`
- Merge this branch to main (or open a PR)
