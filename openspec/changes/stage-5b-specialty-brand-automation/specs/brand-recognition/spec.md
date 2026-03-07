## ADDED Requirements

### Requirement: Brand recognition tracks per-style awareness
The system SHALL track brand recognition as a float (0.0-100.0) per beer style. Brand recognition SHALL increase when the player brews and sells a style, and SHALL decay over time for styles not brewed.

#### Scenario: Brand recognition starts at zero
- **WHEN** a new run begins or the player chooses a path
- **THEN** all styles SHALL have brand recognition of 0.0

#### Scenario: Brand recognition increases on sale
- **WHEN** the player sells a Pale Ale through retail
- **THEN** Pale Ale brand recognition SHALL increase by base_gain (5) × channel_multiplier (1.5 for retail) = 7.5
- **THEN** brand recognition SHALL be clamped to 100.0 maximum

### Requirement: Brand recognition decays for inactive styles
Brand recognition SHALL decay by 2.0 per turn for each style the player did NOT brew that turn. This encourages consistent brewing of signature styles.

#### Scenario: Brand decays for unbrewed styles
- **WHEN** the player brews Pale Ale but not Stout on a given turn
- **THEN** Stout brand recognition SHALL decrease by 2.0
- **THEN** Pale Ale brand recognition SHALL NOT decay (it was brewed)
- **THEN** brand recognition SHALL be clamped to 0.0 minimum

### Requirement: Channel multipliers for brand gain
Different distribution channels SHALL contribute differently to brand recognition: retail = 1.5×, bars = 1.0×, taproom = 0.5×, events = 0.3×. Selling through higher-visibility channels builds brand faster.

#### Scenario: Retail builds brand faster than taproom
- **WHEN** the player sells the same style through retail and taproom in different turns
- **THEN** the retail sale SHALL increase brand recognition by 3× more than the taproom sale

### Requirement: Brand recognition increases demand volume
Brand recognition SHALL provide a demand volume multiplier: `1.0 + (brand_recognition / 100.0) * 0.5`. At maximum brand recognition (100), demand volume for that style SHALL be 50% higher.

#### Scenario: High brand recognition boosts demand
- **WHEN** a style has brand recognition of 80
- **THEN** the demand volume multiplier for that style SHALL be 1.4 (1.0 + 0.8 * 0.5)

#### Scenario: Zero brand recognition has no effect
- **WHEN** a style has brand recognition of 0
- **THEN** the demand volume multiplier SHALL be 1.0 (no bonus)

### Requirement: Brand recognition is visible in MarketForecast
The MarketForecast overlay SHALL display brand recognition levels for all styles, showing both the current value and the demand bonus it provides.

#### Scenario: MarketForecast shows brand data
- **WHEN** the player opens the MarketForecast overlay
- **THEN** each style SHALL show its brand recognition value (0-100)
- **THEN** each style SHALL show the resulting demand volume bonus percentage

### Requirement: Brand recognition persists in save/load
Brand recognition data SHALL be saved as part of the game state and restored correctly on load.

#### Scenario: Brand recognition survives save/load
- **WHEN** the player has Pale Ale brand recognition at 45 and saves
- **THEN** loading the save SHALL restore Pale Ale brand recognition to 45
