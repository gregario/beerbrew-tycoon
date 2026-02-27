## ADDED Requirements

### Requirement: Sanitation stat affects infection probability
The game SHALL track a sanitation_quality stat (0-100, default 50). Each brew SHALL calculate an infection probability: `infection_chance = max(0, (100 - sanitation_quality) / 200.0)`. If infection occurs, quality score SHALL be reduced by 40-60% and the result SHALL include an "infected" flag with a descriptive message.

#### Scenario: Good sanitation prevents infection
- **WHEN** sanitation_quality is 80 or above
- **THEN** infection_chance SHALL be 10% or less

#### Scenario: Poor sanitation causes infection
- **WHEN** sanitation_quality is 30
- **THEN** infection_chance SHALL be 35%
- **WHEN** infection occurs
- **THEN** quality score SHALL be multiplied by 0.4-0.6
- **THEN** result SHALL include infected=true and a message explaining the infection

### Requirement: Temperature control stat affects off-flavor probability
The game SHALL track a temp_control_quality stat (0-100, default 50). Each brew SHALL calculate an off-flavor probability based on temp_control_quality. Off-flavors (esters, fusel alcohols, DMS) reduce quality score by 15-30% and add descriptive tags to the result.

#### Scenario: Good temperature control prevents off-flavors
- **WHEN** temp_control_quality is 80 or above
- **THEN** off_flavor_chance SHALL be 10% or less

#### Scenario: Poor temperature control causes off-flavors
- **WHEN** temp_control_quality is 30
- **THEN** off_flavor_chance SHALL be 35%
- **WHEN** off-flavor occurs
- **THEN** quality score SHALL be multiplied by 0.7-0.85
- **THEN** result SHALL include off_flavor tags describing the specific defect

### Requirement: QA checkpoints during brewing
The brewing process SHALL include QA checkpoint notifications at key points: pre-boil gravity check (after mashing), boil vigor check (during boiling), and final gravity check (after fermenting). Each checkpoint SHALL display a toast notification with the reading and whether it's within acceptable range.

#### Scenario: Pre-boil gravity check displays after mashing
- **WHEN** the mashing phase is complete
- **THEN** a toast notification SHALL display the estimated pre-boil gravity
- **THEN** the notification SHALL indicate if efficiency is low, normal, or high

### Requirement: Equipment upgrades improve failure stats
Equipment purchases SHALL improve sanitation_quality and/or temp_control_quality. Better equipment directly reduces failure probabilities, creating a clear upgrade incentive.

#### Scenario: Equipment improves sanitation
- **WHEN** the player purchases a CIP-capable equipment upgrade
- **THEN** sanitation_quality SHALL increase by the equipment's sanitation_bonus value
