## ADDED Requirements

### Requirement: Specialty beer variance modifier
The quality scoring system SHALL apply a variance modifier to specialty beers. Specialty beers SHALL have ±15 point variance (vs ±5 for normal beers) and a +10 quality ceiling boost. Variance SHALL be calculated using a seeded RNG stored at brew time.

#### Scenario: Specialty beer variance applied
- **WHEN** a specialty beer's quality is calculated with base score 70 and variance seed producing +0.5 normalized
- **THEN** the final score SHALL be 70 + (0.5 × 15) + 10 ceiling boost = 87.5, clamped to 0-100

#### Scenario: Normal beer variance unchanged
- **WHEN** a normal (non-specialty) beer's quality is calculated
- **THEN** variance SHALL remain at ±5 with no ceiling boost

### Requirement: Automation bonus integration in quality calculation
The quality scoring system SHALL accept automation bonuses as an alternative to staff bonuses. For each brewing phase, the effective bonus SHALL be max(staff_bonus, automation_bonus).

#### Scenario: Automation bonus used in quality calculation
- **WHEN** automation provides +8 to mashing and staff provides +5
- **THEN** the quality calculation SHALL use +8 for the mash phase contribution

### Requirement: Experimental brew mutation affects scoring
When an experimental brew mutation occurs, the quality scoring system SHALL use the mutated ingredient values (modified flavor_points/technique_points) instead of the original values.

#### Scenario: Mutated ingredient changes quality score
- **WHEN** an experimental brew mutates an ingredient's flavor_points from 10 to 15
- **THEN** the quality calculation SHALL use 15 for that ingredient's flavor contribution
