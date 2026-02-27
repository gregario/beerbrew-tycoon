## ADDED Requirements

### Requirement: Four beer styles are available at game start
The system SHALL provide exactly four beer styles in the MVP: Lager, Pale Ale, Wheat Beer, and Stout. Each style SHALL have a defined name, description, ideal Flavor/Technique ratio, and a base demand weight.

#### Scenario: All four styles available
- **WHEN** the player opens the style selection screen
- **THEN** all four styles (Lager, Pale Ale, Wheat Beer, Stout) are displayed and selectable

### Requirement: Each beer style has a defined Flavor/Technique ratio target
The system SHALL associate each style with a target Flavor percentage (and implied Technique percentage = 100 - Flavor). These targets SHALL be distinct across styles to produce meaningfully different optimal slider positions.

#### Scenario: Styles have distinct targets
- **WHEN** the quality calculator processes two different styles with identical recipes
- **THEN** the quality scores SHALL differ because the ratio targets differ

### Requirement: Player must select a style before proceeding to recipe design
The system SHALL require the player to select one beer style before the recipe design step is accessible. No default selection SHALL be pre-applied.

#### Scenario: No style selected blocks progression
- **WHEN** the style selection screen is open and no style has been selected
- **THEN** the "Next" or "Design Recipe" action SHALL be disabled or hidden

#### Scenario: Style selected enables progression
- **WHEN** the player selects a beer style
- **THEN** the "Design Recipe" action SHALL become active

### Requirement: Market demand indicator is shown alongside each style
The system SHALL display the current market demand state for each style on the style selection screen, so the player can make an informed choice before committing.

#### Scenario: Demand indicator visible
- **WHEN** the style selection screen is open
- **THEN** each style SHALL show its current demand level (e.g., "High Demand", "Normal", or equivalent visual indicator)
