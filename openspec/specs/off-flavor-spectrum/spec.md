## ADDED Requirements

### Requirement: Off-flavor intensity scale
Each off-flavor SHALL have a float intensity value 0.0-1.0 instead of binary presence. Named thresholds: subtle (< 0.3), noticeable (0.3-0.6), dominant (> 0.6). Intensity determines quality penalty magnitude.

#### Scenario: Subtle off-flavor
- **WHEN** a beer has ester intensity 0.2
- **THEN** the quality penalty SHALL be small (1-3 points) and the tasting note SHALL say "hint of fruit"

#### Scenario: Dominant off-flavor
- **WHEN** a beer has fusel intensity 0.8
- **THEN** the quality penalty SHALL be severe (15-25 points) and the tasting note SHALL say "harsh alcohol burn"

### Requirement: New off-flavor types
FailureSystem SHALL support additional off-flavor types beyond the current esters/fusel/DMS:
- **Diacetyl** (butter): caused by incomplete fermentation, highest risk when ferment is too short. Decays fastest during conditioning
- **Oxidation** (cardboard/stale): caused by oxygen exposure post-ferment, risk scales with batch size and mitigated by closed transfer equipment. Does NOT decay during conditioning
- **Acetaldehyde** (green apple): caused by premature packaging, decays during conditioning

#### Scenario: Diacetyl generation
- **WHEN** fermentation is rushed (short ferment time or rapid temp change)
- **THEN** diacetyl intensity SHALL be generated proportional to the ferment rush factor

#### Scenario: Oxidation from batch size
- **WHEN** batch size multiplier is > 1.5 and player lacks closed transfer equipment
- **THEN** oxidation risk SHALL increase proportionally to batch size

### Requirement: Context-dependent off-flavor evaluation
Each BeerStyle SHALL define acceptable_flavors: Dictionary mapping off-flavor type to maximum acceptable intensity. Off-flavor intensity BELOW the acceptable threshold SHALL not incur a penalty and MAY provide a style bonus.

#### Scenario: Esters acceptable in Hefeweizen
- **WHEN** a Hefeweizen has ester_banana intensity 0.6
- **THEN** NO penalty SHALL be applied (Hefeweizen acceptable_flavors has ester_banana: 0.8) and a style bonus SHALL be applied

#### Scenario: Esters unacceptable in Lager
- **WHEN** a Lager has ester_banana intensity 0.3
- **THEN** a penalty SHALL be applied (Lager acceptable_flavors has ester_banana: 0.1 — intensity exceeds threshold)

#### Scenario: Diacetyl in English Bitter
- **WHEN** an English-style beer has diacetyl intensity 0.2
- **THEN** NO penalty SHALL be applied (traditional character, acceptable up to 0.25)

### Requirement: Off-flavor result display
ResultsOverlay SHALL display all off-flavors with their intensity, severity label, and context (good/bad for this style). A color system SHALL indicate: green (acceptable/desired), yellow (subtle/mild concern), red (problematic/dominant).

#### Scenario: Context coloring
- **WHEN** a Hefeweizen shows ester_banana at 0.5 intensity
- **THEN** the off-flavor row SHALL be colored green with label "Desired character"

#### Scenario: Problem off-flavor display
- **WHEN** a Lager shows fusel at 0.4 intensity
- **THEN** the off-flavor row SHALL be colored red with label "Hot alcohol — ferment cooler"
