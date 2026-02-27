## ADDED Requirements

### Requirement: Mass-market brewery mechanics
The mass-market path SHALL emphasize volume, efficiency, and brand recognition. Mass-market breweries SHALL have: 2x batch size multiplier, access to automation equipment (reduces labor costs), bulk ingredient discounts (20% off ingredient costs), and a revenue-based win condition.

#### Scenario: Mass-market batch size bonus
- **WHEN** the player is on the mass-market path
- **THEN** batch_size_multiplier SHALL be doubled
- **THEN** automation equipment tiers SHALL be available for purchase
- **THEN** ingredient costs SHALL be reduced by 20%

### Requirement: Mass-market win condition
The mass-market path win condition SHALL be: accumulate $50,000 in total revenue AND establish distribution in all 4 channels. This rewards efficiency and market coverage over quality.

#### Scenario: Mass-market win condition met
- **WHEN** the player has total revenue >= $50,000 and all 4 distribution channels active
- **THEN** the game SHALL display the mass-market victory screen

### Requirement: Brand recognition system
The mass-market path SHALL track brand recognition per beer style. Consistently brewing and selling a style increases its brand recognition (0-100). High brand recognition increases demand volume for that style through retail and bars channels.

#### Scenario: Brand recognition builds from consistent brewing
- **WHEN** the player brews and sells Pale Ale through retail 5 times
- **THEN** Pale Ale brand recognition SHALL increase by approximately 25
- **THEN** retail demand volume for Pale Ale SHALL increase proportionally

### Requirement: Automation reduces staff dependency
Mass-market automation equipment SHALL reduce the need for staff by providing flat stat bonuses to brewing phases. This allows mass-market players to run with fewer staff at higher volume.

#### Scenario: Automation equipment replaces staff contribution
- **WHEN** the player has automation equipment installed
- **THEN** brewing phases SHALL receive bonus points from automation (independent of staff)
- **THEN** the automation bonus SHALL NOT stack with staff assignment (whichever is higher applies)
