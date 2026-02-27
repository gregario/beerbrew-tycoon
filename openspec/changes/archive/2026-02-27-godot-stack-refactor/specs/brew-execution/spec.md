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
