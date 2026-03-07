## ADDED Requirements

### Requirement: Three brewing phases with effort-allocation sliders
The system SHALL present three sequential brewing phases: Mashing, Boiling, and Fermenting. Each phase SHALL have a slider that the player uses to allocate effort (0–100%). Each slider allocation SHALL produce a calculated number of Flavor points and Technique points for that phase.

#### Scenario: All three sliders present
- **WHEN** the brewing phases screen is shown
- **THEN** three labeled sliders (Mashing, Boiling, Fermenting) are visible and interactive

#### Scenario: Slider values generate points
- **WHEN** the player adjusts a phase slider
- **THEN** the projected Flavor and Technique point contributions for that phase update in real time

### Requirement: Each phase has a defined Flavor/Technique contribution profile
The system SHALL define for each phase how slider position maps to Flavor vs. Technique points. The profiles SHALL be distinct per phase (e.g., Mashing leans Technique, Boiling produces both, Fermenting leans Flavor) so slider positioning is meaningfully different.

#### Scenario: Phase profiles produce different point mixes
- **WHEN** all sliders are set to the same value
- **THEN** the total Flavor and Technique point mix SHALL reflect each phase's distinct contribution profile

### Requirement: Player can confirm the brew
The system SHALL provide a "Brew" button that, when pressed, finalizes slider positions and emits a `brew_confirmed(sliders: Dictionary)` signal. The BrewingPhases scene SHALL NOT call any GameState methods directly. The brew cycle is executed by the system in response to the signal.

#### Scenario: Brew button emits signal
- **WHEN** the player presses the "Brew" button
- **THEN** the `brew_confirmed` signal is emitted with the current slider values as a Dictionary

#### Scenario: BrewingPhases has no direct GameState dependency
- **WHEN** the BrewingPhases scene is loaded
- **THEN** it SHALL NOT reference GameState, QualityCalculator, or any autoload — it only reads slider values and emits a signal

### Requirement: Sliders have sensible defaults
The system SHALL initialize each phase slider to a neutral midpoint (50%) when the brewing phases screen opens. Players may adjust from that default.

#### Scenario: Default slider positions
- **WHEN** the brewing phases screen opens
- **THEN** all three sliders are positioned at 50%

---

## Brewing Depth Expansion — Updates

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

### Requirement: Yeast-dependent ferment range
The Ferment slider range SHALL adjust based on the selected yeast's temperature range. Ale yeast: 15-24C, Lager yeast: 4-12C, Saison yeast: 20-35C, Wheat yeast: 16-26C.

#### Scenario: Lager yeast slider range
- **WHEN** the player has selected a lager yeast
- **THEN** the ferment slider SHALL range from 4-12C with the ideal zone highlighted

#### Scenario: Saison yeast slider range
- **WHEN** the player has selected saison yeast
- **THEN** the ferment slider SHALL range from 20-35C (wider and hotter than ale)

### Requirement: Equipment bonus display includes new bonuses
BrewingPhases SHALL display active bonuses from new equipment categories (Measurement, Water Treatment) alongside existing equipment/staff/automation bonuses.

#### Scenario: Measurement bonus display
- **WHEN** the player has a Digital Thermometer equipped
- **THEN** the bonus display SHALL show "Temp numbers visible" alongside other active bonuses
