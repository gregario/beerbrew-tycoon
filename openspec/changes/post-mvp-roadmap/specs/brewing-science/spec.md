## ADDED Requirements

### Requirement: Mash temperature affects fermentability
The Mashing phase slider SHALL map to a mash temperature range (62-69°C). Lower temperatures (62-65°C) SHALL produce more fermentable wort (higher ABV potential, lighter body). Higher temperatures (66-69°C) SHALL produce less fermentable wort (lower ABV potential, fuller body). The temperature-to-fermentability curve SHALL be a continuous function, not discrete steps.

#### Scenario: Low mash temperature produces dry beer
- **WHEN** the mashing slider is set below 30% (mapping to ~62-64°C)
- **THEN** the resulting wort fermentability SHALL be above 0.75
- **THEN** flavor points from mashing SHALL favor "crisp" and "dry" characteristics

#### Scenario: High mash temperature produces full-bodied beer
- **WHEN** the mashing slider is set above 70% (mapping to ~67-69°C)
- **THEN** the resulting wort fermentability SHALL be below 0.60
- **THEN** flavor points from mashing SHALL favor "sweet" and "full-bodied" characteristics

### Requirement: Boil duration affects hop utilization
The Boiling phase slider SHALL map to a hop schedule emphasis. Low slider values SHALL emphasize bittering (early hop additions, high alpha acid utilization). High slider values SHALL emphasize aroma (late hop additions, low alpha acid utilization but high aroma oil retention).

#### Scenario: Bittering-focused boil
- **WHEN** the boiling slider is set below 30%
- **THEN** the resulting beer SHALL have high bitterness contribution and low aroma contribution
- **THEN** technique points from boiling SHALL be higher (precise bittering is technical)

#### Scenario: Aroma-focused boil
- **WHEN** the boiling slider is set above 70%
- **THEN** the resulting beer SHALL have low bitterness contribution and high aroma contribution
- **THEN** flavor points from boiling SHALL be higher (aroma is creative/flavor-forward)

### Requirement: Fermentation temperature affects flavor profile
The Fermenting phase slider SHALL map to fermentation temperature relative to the yeast's ideal range. Within the ideal range produces clean fermentation. Above the ideal range produces fruity esters and fusel alcohols (can be desirable for some styles). Below the ideal range produces slow, clean fermentation with potential stalling risk.

#### Scenario: Fermentation within yeast ideal range
- **WHEN** the fermenting slider maps to a temperature within the selected yeast's ideal_temp_min_c and ideal_temp_max_c
- **THEN** the fermentation quality bonus SHALL be at maximum (1.0)
- **THEN** no off-flavor penalties SHALL apply

#### Scenario: Fermentation above yeast ideal range
- **WHEN** the fermenting slider maps to a temperature more than 3°C above the yeast's ideal_temp_max_c
- **THEN** the fermentation quality bonus SHALL be reduced
- **THEN** an ester/fusel off-flavor tag SHALL be added to the result

### Requirement: Stochastic noise on brewing outcomes
All brewing phase outcomes SHALL include a small random noise factor (±5% of the calculated value). This noise SHALL be seeded per-brew so results are not perfectly deterministic but are reproducible with the same seed.

#### Scenario: Same inputs produce slightly different outputs
- **WHEN** the player brews two beers with identical recipes and slider settings
- **THEN** the quality scores SHALL differ by up to ±5%
- **THEN** the scores SHALL NOT differ by more than 10%
