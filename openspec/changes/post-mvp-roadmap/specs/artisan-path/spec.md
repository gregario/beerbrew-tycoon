## ADDED Requirements

### Requirement: Artisan brewery mechanics
The artisan path SHALL emphasize quality, reputation, and competition wins. Artisan breweries SHALL have: +20% quality score bonus for all beers, access to rare/experimental ingredients, competition entry discounts (50% off fees), and a reputation-based win condition.

#### Scenario: Artisan quality bonus applies
- **WHEN** the player is on the artisan path
- **THEN** all beer quality scores SHALL receive a +20% multiplicative bonus
- **THEN** rare ingredients SHALL be available in the ingredient catalog

### Requirement: Artisan win condition
The artisan path win condition SHALL be: earn 5 competition medals (any tier) AND achieve a reputation score of 100+. This replaces the cash-based MVP win condition with a prestige-based one.

#### Scenario: Artisan win condition met
- **WHEN** the player has 5+ competition medals and reputation >= 100
- **THEN** the game SHALL display the artisan victory screen
- **THEN** meta-progression rewards SHALL be awarded based on medal tiers earned

### Requirement: Artisan specialty beers
The artisan path SHALL unlock specialty beer categories: Sour/Wild Ales (long fermentation, high risk/reward), Barrel-Aged beers (time investment, premium pricing), and Experimental Brews (random ingredient combos, unique flavor profiles).

#### Scenario: Sour beer available on artisan path
- **WHEN** the player is on the artisan path and has researched "Wild Fermentation"
- **THEN** Sour/Wild Ale styles SHALL be available
- **THEN** these styles SHALL require 3-5 turn fermentation (longer than normal 1 turn)
- **THEN** quality variance SHALL be higher (more risk) but max quality potential SHALL be higher
