## MODIFIED Requirements

### Requirement: Progressive phase display
BrewingPhases SHALL conditionally show additional brewing steps based on EquipmentManager.is_revealed(). The base 3 phases (Mash, Boil, Ferment) always appear. Additional steps appear when their reveal conditions are met.

#### Scenario: Base phases only
- **WHEN** the player has no measurement or specialty equipment
- **THEN** only Mash, Boil, and Ferment phases SHALL appear with sliders showing relative position (no numbers)

#### Scenario: Temperature numbers revealed
- **WHEN** EquipmentManager.is_revealed("temp_numbers") is true
- **THEN** Mash and Ferment sliders SHALL show numerical temperature values

#### Scenario: Hop schedule visible
- **WHEN** EquipmentManager.is_revealed("hop_schedule") is true and the player has allocated hops to timing slots
- **THEN** the Boil phase SHALL show hop addition timing indicators

## ADDED Requirements

### Requirement: Yeast-dependent ferment range
The Ferment slider range SHALL adjust based on the selected yeast's temperature range. Ale yeast: 15-24°C, Lager yeast: 4-12°C, Saison yeast: 20-35°C, Wheat yeast: 16-26°C.

#### Scenario: Lager yeast slider range
- **WHEN** the player has selected a lager yeast
- **THEN** the ferment slider SHALL range from 4-12°C with the ideal zone highlighted

#### Scenario: Saison yeast slider range
- **WHEN** the player has selected saison yeast
- **THEN** the ferment slider SHALL range from 20-35°C (wider and hotter than ale)

### Requirement: Equipment bonus display includes new bonuses
BrewingPhases SHALL display active bonuses from new equipment categories (Measurement, Water Treatment) alongside existing equipment/staff/automation bonuses.

#### Scenario: Measurement bonus display
- **WHEN** the player has a Digital Thermometer equipped
- **THEN** the bonus display SHALL show "Temp numbers visible" alongside other active bonuses
