## ADDED Requirements

### Requirement: Close enough zone for mash temperature
BrewingScience.calc_mash_score() SHALL implement a flat zone where mash temperatures within ±2°C of the style's ideal produce a 1.0 score (no penalty). Penalties SHALL ramp linearly only beyond the ±2°C zone.

#### Scenario: Mash temp within close enough zone
- **WHEN** the style ideal mash temp is 66°C and the player sets 67.5°C (within ±2°C)
- **THEN** the mash score component SHALL be 1.0 (full marks)

#### Scenario: Mash temp outside close enough zone
- **WHEN** the style ideal mash temp is 66°C and the player sets 62°C (4°C off)
- **THEN** the mash score component SHALL be penalized based on the 2°C excess beyond the flat zone

#### Scenario: Extreme mash temp deviation
- **WHEN** the style ideal mash temp is 66°C and the player sets 69°C (3°C off, 1°C beyond zone)
- **THEN** a moderate penalty SHALL apply, significantly less than the old linear model

### Requirement: Close enough zone for boil duration
BrewingScience.calc_boil_score() SHALL implement a flat zone where boil times between 45-90 minutes produce identical scores for non-pilsner base malts. For pilsner malt, short boils (<45 min) SHALL increase DMS risk.

#### Scenario: Short boil with pale malt
- **WHEN** the player uses pale malt and boils for 30 minutes
- **THEN** the boil score SHALL be within 5% of a 90-minute boil score (minimal difference)

#### Scenario: Short boil with pilsner malt
- **WHEN** the player uses pilsner malt and boils for 30 minutes
- **THEN** the DMS off-flavor risk SHALL increase significantly (pilsner malt exception)

### Requirement: Non-discovery discovery system
The discovery system SHALL track pairs of brews with varied process parameters and identical quality outcomes. When two brews differ in a "doesn't matter" variable but produce similar quality, a "non-discovery" toast SHALL fire.

#### Scenario: Mash duration non-discovery
- **WHEN** the player brews twice with mash temps within the close-enough zone (e.g., 65°C and 67°C) and gets similar quality
- **THEN** a toast SHALL appear: "Your last two brews used different mash temps — they taste identical!"

#### Scenario: Boil length non-discovery
- **WHEN** the player brews twice with different boil times (30 min vs 90 min) using non-pilsner malt and gets similar quality
- **THEN** a toast SHALL appear: "A shorter boil works just as well with this malt!"

### Requirement: Non-discovery unlocks efficiency shortcuts
When a non-discovery is triggered, the discovery system SHALL record it as a known shortcut. Future brews can reference known shortcuts to provide hints (e.g., "You know mash temp doesn't need to be exact").

#### Scenario: Shortcut recorded
- **WHEN** a non-discovery fires for mash temperature tolerance
- **THEN** DiscoveryManager SHALL record "mash_temp_tolerance" as a known shortcut persisted in save state
