## ADDED Requirements

### Requirement: execute_brew is the canonical entry point for a brew turn
The system SHALL use `GameState.execute_brew(sliders)` as the single, authoritative entry point for executing a brew turn. No external caller (UI scene, test, or other system) SHALL directly sequence the individual economy methods (deduct_ingredient_cost, calculate_revenue, add_revenue, record_brew, advance_state) to perform a brew turn. Those methods remain public for isolated unit testing only.

#### Scenario: Single entry point enforced by convention
- **WHEN** a brew turn is triggered from any UI scene
- **THEN** the scene emits a signal, and the signal handler calls `GameState.execute_brew()` — not the individual methods in sequence
