## ADDED Requirements

### Requirement: Equipment reveals feature
Each Equipment resource SHALL have an optional reveals property: Array[String] listing feature IDs that the equipment makes visible in the UI. Feature IDs include: temp_numbers, water_selector, hop_schedule, dry_hop_rack, ferment_profile, conditioning_tank, ph_meter.

#### Scenario: Thermometer reveals temperature numbers
- **WHEN** the player owns and has equipped a Thermometer (or higher temp measurement equipment)
- **THEN** the brewing phase sliders SHALL show numerical temperature/time values instead of generic position indicators

#### Scenario: No measurement equipment
- **WHEN** the player has no measurement equipment
- **THEN** the brewing phase sliders SHALL show only relative position (low/medium/high) without exact numbers

### Requirement: EquipmentManager reveals aggregation
EquipmentManager SHALL aggregate all reveals arrays from equipped items into a queryable set. A method is_revealed(feature_id: String) -> bool SHALL return true if any equipped item reveals that feature.

#### Scenario: Query reveals
- **WHEN** the player has a Thermometer (reveals: ["temp_numbers"]) equipped
- **THEN** EquipmentManager.is_revealed("temp_numbers") SHALL return true

#### Scenario: No reveals for unowned features
- **WHEN** the player has no water treatment equipment
- **THEN** EquipmentManager.is_revealed("water_selector") SHALL return false

### Requirement: New measurement equipment category
A new equipment category "Measurement" SHALL be added with items:
- Thermometer (T1, $30): reveals temp_numbers
- Digital Thermometer (T2, $80): reveals temp_numbers + ferment_profile
- pH Meter (T2, $120): reveals ph_meter
- Refractometer (T3, $200): reveals gravity_readings

#### Scenario: Measurement equipment available in shop
- **WHEN** the player opens the Equipment Shop
- **THEN** a "Measurement" tab SHALL show measurement tools alongside existing categories

### Requirement: Water treatment equipment
A Water Kit equipment item SHALL exist that reveals "water_selector". It SHALL be purchasable after researching "Water Science" in the research tree.

#### Scenario: Water kit purchase
- **WHEN** the player has unlocked "water_basics" research and purchases a Water Kit
- **THEN** EquipmentManager.is_revealed("water_selector") SHALL return true and RecipeDesigner SHALL show the water profile selector

### Requirement: UI progressive disclosure
RecipeDesigner and BrewingPhases SHALL check EquipmentManager.is_revealed() before showing optional UI elements. Elements SHALL gracefully appear/disappear without layout breakage.

#### Scenario: Water selector appears after equipment purchase
- **WHEN** the player purchases Water Kit mid-run
- **THEN** the next brew's RecipeDesigner SHALL show the water profile selector that was previously hidden

#### Scenario: Hop schedule appears after equipment
- **WHEN** the player has equipment revealing "hop_schedule"
- **THEN** RecipeDesigner SHALL show hop timing allocation UI when selecting hops
