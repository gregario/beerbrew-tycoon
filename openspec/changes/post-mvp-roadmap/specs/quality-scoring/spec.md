## MODIFIED Requirements

### Requirement: Quality score calculation
The final quality score (0.0-100.0) SHALL be calculated from the following components, expanded from MVP:
1. **Flavor/Technique ratio match** (~35% weight) — how close the F/T ratio matches the style's ideal
2. **Ingredient-style compatibility** (~15% weight) — ingredient flavor tags and properties vs style preferences
3. **Brewing science accuracy** (~20% weight, NEW) — mash temp appropriateness for style, fermentation temp accuracy relative to yeast, hop schedule match
4. **Equipment quality bonus** (~10% weight, NEW) — aggregated equipment efficiency_bonus
5. **Staff skill bonus** (~10% weight, NEW) — assigned staff stats contribution
6. **Novelty/saturation modifier** (~10% weight) — market saturation replaces simple repeat penalty
7. **Failure mode penalties** (multiplicative, NEW) — infection and off-flavor penalties multiply the final score

#### Scenario: Full score calculation with all components
- **WHEN** the player brews with ratio match 90, ingredient compat 80, brewing science 85, equipment bonus 70, staff bonus 60, saturation modifier 0.9, no failures
- **THEN** the weighted score SHALL be calculated from all components
- **THEN** the score breakdown SHALL show each component's contribution

#### Scenario: Infection penalty reduces score
- **WHEN** a beer scores 80 before failure penalties
- **THEN** if infection occurred, final score SHALL be 80 × 0.4-0.6 = 32-48
- **THEN** the breakdown SHALL show the infection penalty clearly

### Requirement: Brewing science scoring sub-components
The brewing science accuracy component SHALL evaluate: mash temperature appropriateness for the beer style (some styles want lower/higher mash temps), fermentation temperature accuracy (within yeast ideal range = full points), and hop schedule match (bittering vs aroma emphasis matching style expectations).

#### Scenario: Style-appropriate mash temperature scores high
- **WHEN** the player brews a Stout with a high mash temperature (fuller body)
- **THEN** the mash temp appropriateness score SHALL be high (stouts want full body)
- **WHEN** the player brews a Lager with a high mash temperature
- **THEN** the mash temp appropriateness score SHALL be low (lagers want crisp/dry)
