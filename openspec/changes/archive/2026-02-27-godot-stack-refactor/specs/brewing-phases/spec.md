## MODIFIED Requirements

### Requirement: Player can confirm the brew
The system SHALL provide a "Brew" button that, when pressed, finalizes slider positions and emits a `brew_confirmed(sliders: Dictionary)` signal. The BrewingPhases scene SHALL NOT call any GameState methods directly. The brew cycle is executed by the system in response to the signal.

#### Scenario: Brew button emits signal
- **WHEN** the player presses the "Brew" button
- **THEN** the `brew_confirmed` signal is emitted with the current slider values as a Dictionary

#### Scenario: BrewingPhases has no direct GameState dependency
- **WHEN** the BrewingPhases scene is loaded
- **THEN** it SHALL NOT reference GameState, QualityCalculator, or any autoload — it only reads slider values and emits a signal
