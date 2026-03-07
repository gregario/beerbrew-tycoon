## ADDED Requirements

### Requirement: Conditioning game state
A new CONDITIONING state SHALL exist between RESULTS and SELL in the GameState state machine. The state transition SHALL be: BREWING_PHASES → RESULTS → CONDITIONING → SELL.

#### Scenario: State flow with conditioning
- **WHEN** the player finishes viewing results and advances state
- **THEN** the game SHALL transition to CONDITIONING state showing the conditioning overlay

### Requirement: Conditioning overlay
A ConditioningOverlay SHALL display the current beer with off-flavor intensities and a week selector (0-4 weeks). The overlay SHALL show a live preview of how off-flavors decay at each conditioning duration and the quality bonus gained.

#### Scenario: Player selects conditioning duration
- **WHEN** the player moves the conditioning slider to 3 weeks
- **THEN** the overlay SHALL show projected off-flavor decay (e.g., diacetyl reduced by 80%) and projected conditioning quality bonus (+3%)

#### Scenario: Player skips conditioning
- **WHEN** the player selects 0 weeks conditioning
- **THEN** no off-flavor decay is applied, no quality bonus, and the game advances to SELL immediately

### Requirement: Off-flavor decay during conditioning
Each off-flavor type SHALL have a decay rate per week of conditioning. Diacetyl decays fastest (0.25/week), acetaldehyde moderate (0.15/week), esters slow (0.05/week). Oxidation SHALL NOT decay (it's permanent).

#### Scenario: Diacetyl cleanup
- **WHEN** a beer has 0.8 diacetyl intensity and the player conditions for 3 weeks
- **THEN** diacetyl intensity SHALL reduce to max(0, 0.8 - 3 × 0.25) = 0.05

#### Scenario: Oxidation does not decay
- **WHEN** a beer has 0.4 oxidation intensity and the player conditions for 4 weeks
- **THEN** oxidation intensity SHALL remain at 0.4

### Requirement: Conditioning quality bonus
Each week of conditioning SHALL add a 1% quality bonus (up to 4% at 4 weeks). This is applied as a flat addition to the final quality score before clamping to 0-100.

#### Scenario: Quality bonus from conditioning
- **WHEN** a beer with base quality 72 is conditioned for 2 weeks
- **THEN** the quality bonus SHALL be +2 and the adjusted quality SHALL be 74 (before off-flavor penalties)

### Requirement: Conditioning cost
Each week of conditioning SHALL cost the player rent/4 (proportional weekly rent). This creates a cash trade-off for quality improvement.

#### Scenario: Conditioning costs rent
- **WHEN** the player conditions for 3 weeks with rent at $400
- **THEN** the player SHALL be charged 3 × ($400 / 4) = $300
