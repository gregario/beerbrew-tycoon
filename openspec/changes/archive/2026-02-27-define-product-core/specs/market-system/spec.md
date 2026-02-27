## ADDED Requirements

### Requirement: Market demand state is tracked per beer style
The system SHALL maintain a demand weight for each of the four beer styles. Demand weights SHALL be expressed as multipliers applied to revenue (e.g., 1.5× for high demand, 1.0× for normal). The initial demand state is randomized at run start.

#### Scenario: Demand state initialized at run start
- **WHEN** a new run begins
- **THEN** each beer style has an assigned demand weight and at least one style has elevated demand (1.5×)

### Requirement: Market demand rotates on a fixed turn schedule
The system SHALL rotate market demand every N turns (N = 3 as the default, configurable constant). On rotation, the system SHALL reassign demand weights such that 1–2 styles gain elevated demand and the rest return to normal. The elevated style(s) SHALL be selected randomly, but SHALL NOT repeat the same elevated set two rotations in a row.

#### Scenario: Demand rotates after N turns
- **WHEN** N turns have passed since the last demand rotation
- **THEN** the demand weights for all styles are recalculated and at least one style changes its demand level

#### Scenario: Demand does not repeat identical pattern
- **WHEN** a demand rotation occurs
- **THEN** the newly elevated style set SHALL differ from the previously elevated set

### Requirement: Demand state is visible to the player before style selection
The system SHALL display the current demand levels for all styles on the market check screen, which the player sees before selecting a beer style each turn.

#### Scenario: Market screen shows current demand
- **WHEN** the market check screen is displayed
- **THEN** each of the four styles shows its current demand indicator (e.g., "High", "Normal")

### Requirement: Demand multiplier applies to revenue calculation
The system SHALL multiply the base revenue for a brew by the demand weight of the brewed style at the time of sale.

#### Scenario: High-demand style earns more revenue
- **WHEN** a player brews a style with 1.5× demand
- **THEN** the revenue for that brew SHALL be 1.5× the base revenue compared to the same brew at 1.0× demand
