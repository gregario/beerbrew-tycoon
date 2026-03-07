## MODIFIED Requirements

### Requirement: Execute brew with expanded inputs
GameState.execute_brew() SHALL accept an expanded input that includes slider values, water profile, hop allocations, and conditioning weeks. The method signature SHALL remain backward-compatible by using optional parameters or Dictionary keys.

#### Scenario: Full brew execution with new inputs
- **WHEN** execute_brew is called with sliders, water_profile, hop_allocations, and conditioning_weeks
- **THEN** all inputs SHALL be passed to QualityCalculator and the result SHALL include all component scores

#### Scenario: Backward-compatible execution
- **WHEN** execute_brew is called with only slider values (legacy)
- **THEN** water_profile SHALL default to "tap_water" (0.6 affinity), hop_allocations SHALL default to all-bittering, conditioning_weeks SHALL default to 0

### Requirement: Conditioning cost deduction
When conditioning_weeks > 0, execute_brew (or the conditioning state handler) SHALL deduct the conditioning cost (weeks × rent/4) from the player's balance before proceeding to sell.

#### Scenario: Conditioning cost applied
- **WHEN** the player conditions for 2 weeks with rent at $400
- **THEN** $200 SHALL be deducted from balance before the SELL state

### Requirement: Off-flavor result tracking
execute_brew result Dictionary SHALL include an off_flavors Array of Dictionaries, each with: type (String), intensity (float), context (String: "desired"/"neutral"/"flaw"), and display_name (String).

#### Scenario: Off-flavor in result
- **WHEN** a brew generates diacetyl at 0.4 intensity in a Lager
- **THEN** the result off_flavors array SHALL include {type: "diacetyl", intensity: 0.4, context: "flaw", display_name: "Diacetyl (butter)"}
