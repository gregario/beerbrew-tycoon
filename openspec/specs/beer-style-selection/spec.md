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

---

## Brewing Depth Expansion — Updates

### Requirement: Style picker shows families
StylePicker SHALL group styles by family with visual family headers. Locked families (not yet researched) SHALL show as greyed-out with a "Requires [research node]" label.

#### Scenario: Family grouping display
- **WHEN** the player opens StylePicker
- **THEN** styles SHALL be grouped under family headers (Ales, Dark, Wheat, Lager, Belgian, Modern, Specialty)

#### Scenario: Locked family display
- **WHEN** the player has not unlocked "lager_brewing" research
- **THEN** the Lager family SHALL appear greyed-out with "Requires: Lager Brewing" label

### Requirement: Expanded style data properties
Each BeerStyle resource SHALL include new properties alongside existing ones:
- family (String): style family grouping
- water_affinity (Dictionary): mapping water profile_id to affinity score 0.0-1.0
- hop_schedule_expectations (Dictionary): mapping slot name to importance weight 0.0-1.0
- yeast_temp_flavors (Dictionary): mapping flavor compound names to desirability -1.0 to 1.0
- acceptable_off_flavors (Dictionary): mapping off-flavor type to maximum acceptable intensity
- primary_lesson (String): brewing concept this style teaches

#### Scenario: Style resource with expanded data
- **WHEN** the Hefeweizen BeerStyle resource is loaded
- **THEN** it SHALL have water_affinity (balanced: 0.8, soft: 0.7), hop_schedule_expectations (bittering: 0.8, aroma: 0.3), acceptable_off_flavors (ester_banana: 0.8, phenol_clove: 0.6), primary_lesson "yeast_temp_interaction"

### Requirement: Market demand per style family
MarketManager seasonal demand SHALL consider style families. Winter increases demand for dark family, summer increases wheat and lager, spring favors ales, autumn favors belgian and specialty.

#### Scenario: Winter dark family demand
- **WHEN** the current season is winter
- **THEN** all styles in the dark family SHALL receive a seasonal demand bonus
