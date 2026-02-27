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
