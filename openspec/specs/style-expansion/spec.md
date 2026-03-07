## ADDED Requirements

### Requirement: Style families
Beer styles SHALL be organized into families. Each BeerStyle resource SHALL have a family property (String). Families: ales, dark, wheat, lager, belgian, modern, specialty.

#### Scenario: Style family grouping
- **WHEN** the StylePicker displays available styles
- **THEN** styles SHALL be grouped by family with family headers

### Requirement: Nine new beer styles
The following styles SHALL be added as BeerStyle .tres resources with complete data (flavor_technique_ratio, base_price, water_affinity, hop_schedule_expectations, yeast_temp_flavors, acceptable_off_flavors):

Ales family:
- IPA: hop-forward, expects aroma+dry hop, water_affinity hoppy=0.95, base_price $280

Dark family:
- Porter: moderate roast, balanced water, base_price $240
- Imperial Stout: high gravity, malty water, base_price $400

Wheat family:
- Hefeweizen: yeast-driven (banana/clove), balanced water, base_price $220, acceptable ester_banana up to 0.8

Lager family:
- Czech Pilsner: delicate, soft water=0.95, needs long boil for pilsner malt, base_price $260
- Helles: subtle malt, soft water, base_price $230
- Marzen: toasty malt, balanced water, base_price $250

Belgian family:
- Saison: high-temp ferment, peppery phenols desired, base_price $300
- Belgian Dubbel: dark fruit, Belgian yeast, base_price $350

Modern family:
- NEIPA: biotransformation dry hop, juicy water=0.95, base_price $320

#### Scenario: New style data is complete
- **WHEN** any new style resource is loaded
- **THEN** it SHALL have all required properties: style_id, style_name, family, flavor_ratio, technique_ratio, base_price, water_affinity, hop_schedule_expectations, acceptable_off_flavors

### Requirement: Research-gated style unlocking
New style families SHALL be unlocked via the research tree. Ales family is available at game start. Other families require research nodes.

#### Scenario: Lager family locked at start
- **WHEN** the player starts a fresh run without lager research
- **THEN** Czech Pilsner, Helles, and Marzen SHALL NOT appear in StylePicker

#### Scenario: Research unlocks family
- **WHEN** the player unlocks "lager_brewing" research node
- **THEN** Czech Pilsner, Helles, and Marzen SHALL appear in StylePicker

### Requirement: Each style teaches a brewing principle
Each new style SHALL have a primary_lesson property describing what brewing concept it teaches. This is used by the discovery system to guide discovery priorities.

#### Scenario: Czech Pilsner teaches water chemistry
- **WHEN** the player brews a Czech Pilsner
- **THEN** the discovery system SHALL prioritize water-related discoveries (soft water is critical for pilsner)

#### Scenario: Hefeweizen teaches yeast-temp interaction
- **WHEN** the player brews a Hefeweizen
- **THEN** the discovery system SHALL prioritize yeast flavor compound discoveries (banana vs clove)
