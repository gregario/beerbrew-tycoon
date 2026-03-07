## ADDED Requirements

### Requirement: Water profile resource
The system SHALL define a WaterProfile resource class with properties: profile_id (String), display_name (String), mineral_description (String), style_affinities (Dictionary mapping style_id to float 0.0-1.0).

#### Scenario: Water profile data files
- **WHEN** the game loads
- **THEN** 5 WaterProfile .tres files SHALL exist at res://data/water/: soft.tres (Pilsen), balanced.tres, malty.tres (Dublin), hoppy.tres (Burton), juicy.tres (Vermont)

### Requirement: Water profile selection in recipe design
The system SHALL present a water profile selector in RecipeDesigner when the player has the "water_selector" reveal from equipment. The selector SHALL show all 5 profiles with their display name and mineral description.

#### Scenario: Player without water research sees no selector
- **WHEN** the player has no equipment that reveals "water_selector"
- **THEN** no water profile selector is shown and the default "tap_water" profile (0.6 affinity for all styles) is used

#### Scenario: Player with water equipment selects a profile
- **WHEN** the player has equipment revealing "water_selector" and selects "hoppy" water profile
- **THEN** GameState.current_water_profile SHALL be set to the hoppy WaterProfile resource

### Requirement: Water-style affinity scoring
QualityCalculator SHALL include a water chemistry score component weighted at 10% of the total quality score. The score SHALL be the WaterProfile's affinity value for the current style (0.0-1.0).

#### Scenario: Perfect water match
- **WHEN** the player uses "hoppy" water for a Pale Ale (affinity 0.95)
- **THEN** the water chemistry component SHALL contribute 0.95 × 10% = 9.5 points to the final score

#### Scenario: Wrong water for style
- **WHEN** the player uses "hoppy" water for a Stout (affinity 0.3)
- **THEN** the water chemistry component SHALL contribute 0.3 × 10% = 3.0 points to the final score

#### Scenario: No water selection (default tap)
- **WHEN** the player has no water selector equipment
- **THEN** the water chemistry component SHALL contribute 0.6 × 10% = 6.0 points (neutral default)

### Requirement: Water discovery
The discovery system SHALL include water-related discoveries that fire when the player brews with different water profiles and notices score changes.

#### Scenario: First water discovery
- **WHEN** the player brews the same style with two different water profiles and one scores significantly higher
- **THEN** a discovery toast SHALL appear: "Water chemistry affects [style]! [profile] water seems to work well"
