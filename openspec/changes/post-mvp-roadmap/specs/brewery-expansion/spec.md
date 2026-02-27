## ADDED Requirements

### Requirement: Brewery stages with transitions
The game SHALL support three brewery stages: Garage (starting), Microbrewery (mid-game), and a forked final stage (Artisan Brewery or Mass-Market Brewery). Transitioning requires meeting cash and reputation thresholds plus paying an upgrade cost.

#### Scenario: Transition from garage to microbrewery
- **WHEN** the player's balance exceeds $5,000 and they have brewed at least 10 beers
- **THEN** the "Expand to Microbrewery" option SHALL become available
- **WHEN** the player selects expansion and pays the $3,000 upgrade cost
- **THEN** the brewery stage SHALL change to "microbrewery"
- **THEN** station slots SHALL increase from 3 to 5
- **THEN** staff hiring SHALL become available
- **THEN** rent SHALL increase

### Requirement: Visual room changes on expansion
Each brewery stage SHALL have a distinct visual layout in the BreweryScene. Garage: small room, 3 station slots. Microbrewery: larger industrial space, 5 station slots, staff sprites. Artisan/Mass-Market: large facility, 7 station slots, specialized equipment visuals.

#### Scenario: Microbrewery scene loads after expansion
- **WHEN** the player expands to microbrewery
- **THEN** the BreweryScene SHALL transition to the microbrewery layout
- **THEN** new station slots SHALL be visible and interactive

### Requirement: Rent scaling per stage
Rent SHALL increase with each stage. Garage: $150/4 turns (MVP default). Microbrewery: $400/4 turns. Artisan: $600/4 turns. Mass-Market: $800/4 turns. Rent amounts SHALL be configurable.

#### Scenario: Rent increases after expansion
- **WHEN** the player expands from garage ($150 rent) to microbrewery
- **THEN** rent SHALL increase to $400 per rent period

### Requirement: Artisan vs Mass-Market fork
At the microbrewery stage, after meeting a second threshold (balance > $15,000, 25+ beers brewed), the player SHALL choose between Artisan Brewery and Mass-Market Brewery paths. This choice is permanent for the current run and fundamentally changes available mechanics.

#### Scenario: Fork choice is presented
- **WHEN** the player meets the fork threshold at microbrewery stage
- **THEN** a choice screen SHALL present Artisan and Mass-Market options
- **THEN** each option SHALL display its unique mechanics, benefits, and trade-offs
- **WHEN** the player selects a path
- **THEN** the brewery SHALL transition to the chosen stage permanently
