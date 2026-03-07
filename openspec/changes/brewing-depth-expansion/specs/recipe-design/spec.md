## MODIFIED Requirements

### Requirement: Recipe design includes hop allocation
When selecting hops, RecipeDesigner SHALL show hop timing allocation UI if EquipmentManager.is_revealed("hop_schedule") is true. Each selected hop SHALL be assignable to Bittering, Flavor, Aroma, or Dry Hop slots.

#### Scenario: Hop allocation visible
- **WHEN** the player has hop schedule equipment and selects Cascade hops
- **THEN** timing slot buttons (Bittering/Flavor/Aroma/Dry Hop) SHALL appear for Cascade

#### Scenario: Hop allocation not visible
- **WHEN** the player lacks hop schedule equipment
- **THEN** no timing allocation UI is shown and all hops default to Bittering slot

## ADDED Requirements

### Requirement: Water profile selector
RecipeDesigner SHALL display a water profile selector before ingredient selection when EquipmentManager.is_revealed("water_selector") is true. The selector SHALL show all 5 water profiles with name and brief description.

#### Scenario: Water selector shown
- **WHEN** the player has water treatment equipment
- **THEN** a water profile dropdown/selector SHALL appear at the top of RecipeDesigner with 5 options

#### Scenario: Water selector hidden
- **WHEN** the player lacks water treatment equipment
- **THEN** no water selector is shown and default tap water is used

### Requirement: Recipe stores water and hop allocation
GameState.current_recipe SHALL be extended to include water_profile (WaterProfile resource or null) and hop_allocations (Dictionary mapping hop_id to Array of slot names).

#### Scenario: Recipe with full data
- **WHEN** the player completes recipe design with water profile "hoppy" and Cascade allocated to ["aroma", "dry_hop"]
- **THEN** current_recipe SHALL include water_profile pointing to the hoppy WaterProfile and hop_allocations with the cascade allocation
