## ADDED Requirements

### Requirement: Equipment data model
Each equipment item SHALL be a Godot Resource with: name (String), tier (int 1-7), category (String: "brewing", "fermentation", "packaging", "utility"), cost (int), capacity_liters (int), sanitation_bonus (int), temp_control_bonus (int), efficiency_bonus (float), batch_size_multiplier (float), description (String), and required_stage (String: "garage", "microbrewery", "artisan", "mass_market").

#### Scenario: Equipment resource has all required properties
- **WHEN** an Equipment resource is loaded
- **THEN** it SHALL have all specified properties with correct types
- **THEN** tier SHALL be between 1 and 7

### Requirement: Equipment catalog with tiered progression
The game SHALL include at least 15 equipment items across 4 categories and 7 tiers. Tiers 1-2 SHALL be available in the garage stage. Tiers 3-4 in microbrewery. Tiers 5-7 in artisan/mass-market stages.

#### Scenario: Equipment tiers match stage availability
- **WHEN** the player is in the garage stage
- **THEN** only tier 1-2 equipment SHALL be purchasable
- **WHEN** the player reaches the microbrewery stage
- **THEN** tier 3-4 equipment SHALL become available

### Requirement: Equipment purchasing
The player SHALL be able to purchase equipment from an equipment shop screen. Purchasing deducts the cost from balance. Equipment is immediately available after purchase. The player cannot purchase equipment they already own or equipment above their current stage tier.

#### Scenario: Player buys equipment
- **WHEN** the player purchases a $500 BIAB setup
- **THEN** $500 SHALL be deducted from balance
- **THEN** the BIAB setup SHALL appear in owned equipment
- **THEN** its stat bonuses SHALL be applied to brewing parameters

#### Scenario: Player cannot afford equipment
- **WHEN** the player's balance is less than the equipment cost
- **THEN** the purchase button SHALL be disabled
- **THEN** the equipment SHALL show a "Can't afford" indicator

### Requirement: Station slots in brewery
The brewery SHALL have a fixed number of station slots per stage (garage: 3, microbrewery: 5, artisan/mass-market: 7). Equipment must be placed in a station slot to be active. Unplaced equipment provides no bonuses.

#### Scenario: Garage has 3 station slots
- **WHEN** the player is in the garage stage
- **THEN** the brewery SHALL display 3 station slots
- **THEN** only 3 equipment items can be active simultaneously

### Requirement: Equipment affects brewing quality
Active equipment's bonuses SHALL aggregate and modify brewing parameters. sanitation_bonus increases sanitation_quality. temp_control_bonus increases temp_control_quality. efficiency_bonus multiplies technique points. batch_size_multiplier affects revenue per brew.

#### Scenario: Equipment bonuses apply to brewing
- **WHEN** the player has active equipment with sanitation_bonus=20 and temp_control_bonus=15
- **THEN** sanitation_quality SHALL be base (50) + 20 = 70
- **THEN** temp_control_quality SHALL be base (50) + 15 = 65
