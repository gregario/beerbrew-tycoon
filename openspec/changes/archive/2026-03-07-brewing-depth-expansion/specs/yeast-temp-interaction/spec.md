## ADDED Requirements

### Requirement: Yeast flavor compound generation
Each Yeast resource SHALL define a yeast_flavor_profile: Dictionary mapping temperature ranges to flavor compound outputs. Flavor compounds include: ester_banana, ester_fruit, phenol_clove, phenol_pepper, fusel, clean.

#### Scenario: Wheat yeast at warm temperature
- **WHEN** Wheat yeast (WB-06) ferments at 24°C (above its crossover point of 20°C)
- **THEN** the yeast flavor output SHALL be dominated by ester_banana with low phenol_clove

#### Scenario: Wheat yeast at cool temperature
- **WHEN** Wheat yeast (WB-06) ferments at 16°C (below its crossover point)
- **THEN** the yeast flavor output SHALL be dominated by phenol_clove with low ester_banana

#### Scenario: Saison yeast wants heat
- **WHEN** Saison yeast (Belle Saison) ferments at 30°C (high for most yeasts)
- **THEN** the yeast flavor output SHALL be high phenol_pepper and ester_fruit with NO fusel penalty (saison is the exception — hotter is better)

#### Scenario: Lager yeast must be cold
- **WHEN** Lager yeast (W-34/70) ferments at 18°C (too warm for lager)
- **THEN** the yeast flavor output SHALL include significant ester_fruit and fusel, penalizing quality

#### Scenario: Clean ale yeast is forgiving
- **WHEN** Clean ale yeast (US-05) ferments anywhere in 16-22°C range
- **THEN** the yeast flavor output SHALL be predominantly "clean" with minimal off-character

### Requirement: Yeast flavor contributes to quality
The yeast flavor compound output SHALL feed into the fermentation quality score (25% weight). Desired compounds for the current style increase the score; undesired compounds decrease it.

#### Scenario: Banana esters in Hefeweizen
- **WHEN** a Hefeweizen is brewed with high ester_banana from warm wheat yeast
- **THEN** the fermentation quality score SHALL receive a bonus (banana is desired for Hefeweizen)

#### Scenario: Banana esters in Lager
- **WHEN** a Lager is brewed with high ester_banana from incorrectly warm fermentation
- **THEN** the fermentation quality score SHALL receive a penalty (esters are undesired in lager)

### Requirement: Yeast-temp discovery
The discovery system SHALL fire yeast-temperature discoveries when players observe flavor compound changes from temperature variation.

#### Scenario: Banana vs clove discovery
- **WHEN** the player brews two wheat beers at different temps and gets different dominant flavors
- **THEN** a discovery toast SHALL appear: "Temperature controls banana vs clove character in wheat beer!"

#### Scenario: Saison heat discovery
- **WHEN** the player brews saison at high temp and gets a better score than at moderate temp
- **THEN** a discovery toast SHALL appear: "Saison yeast loves heat — the opposite of other yeasts!"
