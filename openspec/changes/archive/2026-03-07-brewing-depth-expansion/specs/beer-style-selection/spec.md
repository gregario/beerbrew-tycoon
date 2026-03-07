## MODIFIED Requirements

### Requirement: Style picker shows families
StylePicker SHALL group styles by family with visual family headers. Locked families (not yet researched) SHALL show as greyed-out with a "Requires [research node]" label.

#### Scenario: Family grouping display
- **WHEN** the player opens StylePicker
- **THEN** styles SHALL be grouped under family headers (Ales, Dark, Wheat, Lager, Belgian, Modern, Specialty)

#### Scenario: Locked family display
- **WHEN** the player has not unlocked "lager_brewing" research
- **THEN** the Lager family SHALL appear greyed-out with "Requires: Lager Brewing" label

## ADDED Requirements

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
