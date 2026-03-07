## ADDED Requirements

### Requirement: Brew cycle is executable as a single GameState method
The system SHALL expose a `GameState.execute_brew(sliders: Dictionary) -> Dictionary` method that encapsulates the complete brew turn: ingredient cost deduction, quality calculation, revenue calculation, revenue application, brew history recording, and state advancement. This method SHALL be callable from any context (UI scenes, tests, or other systems) without requiring a scene to be active.

#### Scenario: execute_brew runs the full cycle
- **WHEN** `execute_brew(sliders)` is called with valid sliders, style, and recipe set on GameState
- **THEN** ingredient cost is deducted, quality is calculated, revenue is added, brew is recorded, and state advances — all in one call

#### Scenario: execute_brew returns a result dictionary
- **WHEN** `execute_brew(sliders)` completes successfully
- **THEN** it returns a Dictionary containing at minimum `final_score` and `revenue` keys

#### Scenario: execute_brew fails gracefully if cost cannot be deducted
- **WHEN** `execute_brew(sliders)` is called but the player's balance is less than the ingredient cost
- **THEN** it returns an empty Dictionary and does not modify balance, history, or state

#### Scenario: execute_brew result is stored on GameState
- **WHEN** `execute_brew(sliders)` completes
- **THEN** `GameState.last_brew_result` contains the returned Dictionary so the results screen can display it

### Requirement: Brew cycle is testable without instantiating a scene
The brew cycle SHALL be fully exercisable in headless GUT tests by calling `GameState.execute_brew()` directly. No scene instantiation SHALL be required to test a complete brew turn.

#### Scenario: Headless brew cycle test
- **WHEN** a GUT test sets style and recipe on GameState, then calls `execute_brew(sliders)`
- **THEN** the test can assert on balance change, turn counter, last_brew_result, and emitted signals — without loading any scene

---

## Brewing Depth Expansion — Updates

### Requirement: Execute brew with expanded inputs
GameState.execute_brew() SHALL accept an expanded input that includes slider values, water profile, hop allocations, and conditioning weeks. The method signature SHALL remain backward-compatible by using optional parameters or Dictionary keys.

#### Scenario: Full brew execution with new inputs
- **WHEN** execute_brew is called with sliders, water_profile, hop_allocations, and conditioning_weeks
- **THEN** all inputs SHALL be passed to QualityCalculator and the result SHALL include all component scores

#### Scenario: Backward-compatible execution
- **WHEN** execute_brew is called with only slider values (legacy)
- **THEN** water_profile SHALL default to "tap_water" (0.6 affinity), hop_allocations SHALL default to all-bittering, conditioning_weeks SHALL default to 0

### Requirement: Conditioning cost deduction
When conditioning_weeks > 0, execute_brew (or the conditioning state handler) SHALL deduct the conditioning cost (weeks x rent/4) from the player's balance before proceeding to sell.

#### Scenario: Conditioning cost applied
- **WHEN** the player conditions for 2 weeks with rent at $400
- **THEN** $200 SHALL be deducted from balance before the SELL state

### Requirement: Off-flavor result tracking
execute_brew result Dictionary SHALL include an off_flavors Array of Dictionaries, each with: type (String), intensity (float), context (String: "desired"/"neutral"/"flaw"), and display_name (String).

#### Scenario: Off-flavor in result
- **WHEN** a brew generates diacetyl at 0.4 intensity in a Lager
- **THEN** the result off_flavors array SHALL include {type: "diacetyl", intensity: 0.4, context: "flaw", display_name: "Diacetyl (butter)"}
