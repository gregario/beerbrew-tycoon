## ADDED Requirements

### Requirement: Persistent unlock categories
Between runs, the player SHALL earn unlock points based on run performance. Unlock categories SHALL include: Beer Styles (unlock new styles for future runs), Equipment Blueprints (start with knowledge of advanced equipment), Ingredient Access (rare ingredients available earlier), Staff Traits (new employee archetypes), and Brewery Perks (passive bonuses).

#### Scenario: Unlock points earned from completed run
- **WHEN** a run ends (win or loss)
- **THEN** unlock points SHALL be awarded based on: turns survived, total revenue, best quality score, competition medals, and whether the player won
- **THEN** a meta-progression screen SHALL display earned points and available unlocks

### Requirement: Style unlocks persist across runs
Beer styles unlocked via meta-progression SHALL be available from the start of all future runs, in addition to the base 4 styles. Unlocked styles appear in the style picker without needing research.

#### Scenario: Previously unlocked style available at run start
- **WHEN** the player unlocked "IPA" via meta-progression in a previous run
- **THEN** IPA SHALL be available in the style picker from turn 1 of new runs

### Requirement: Equipment blueprints reduce costs
Equipment blueprints earned via meta-progression SHALL reduce the research cost (not purchase cost) of that equipment tier by 50%. The player still needs to buy the equipment but doesn't need to research it first.

#### Scenario: Blueprint reduces research cost
- **WHEN** the player has the "Conical Fermenter" blueprint from a previous run
- **THEN** researching conical fermenters SHALL cost 50% fewer RP

### Requirement: Brewery perks as passive bonuses
Brewery perks SHALL provide small persistent bonuses: +5% starting cash, +1 base RP per brew, -10% rent, +5% quality bonus for a specific style family. Maximum 3 perks active per run.

#### Scenario: Active perks apply at run start
- **WHEN** the player starts a new run with 3 selected perks
- **THEN** all 3 perk effects SHALL be active from turn 1
- **THEN** perk effects SHALL be displayed on the brewery info screen
