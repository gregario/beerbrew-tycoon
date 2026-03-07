## ADDED Requirements

### Requirement: Final quality score composition
The system SHALL produce a final quality score (0-100) from seven weighted components:
- **Style Match** (25%): flavor/technique ratio closeness to style's ideal + ingredient compatibility
- **Fermentation** (25%): ferment temp accuracy + yeast-temp flavor compound match + temp stability
- **Science** (15%): mash score (with close-enough zone) + boil score (with malt-specific DMS awareness)
- **Water Chemistry** (10%): water profile affinity for current style
- **Hop Schedule** (10%): hop allocation match to style expectations
- **Novelty** (10%): decreases by 0.15 per repeat recipe, floored at 0.4
- **Conditioning** (5%): flat +1% per week of conditioning (0-4 weeks, applied post-calculation)

#### Scenario: Full quality calculation with all components
- **WHEN** a brew completes with all inputs (sliders, water profile, hop allocations, conditioning weeks)
- **THEN** the quality score SHALL be the weighted sum of all 7 components, clamped to 0-100

#### Scenario: Legacy brew without new inputs
- **WHEN** a brew completes without water profile or hop allocations (old save or pre-equipment)
- **THEN** water component SHALL use default 0.6, hop schedule SHALL use default 0.5, conditioning SHALL be 0

### Requirement: Quality breakdown object
QualityCalculator.calculate_quality() SHALL return a Dictionary with individual component scores alongside the final_score, enabling UI display of each component's contribution.

#### Scenario: Breakdown includes all components
- **WHEN** quality is calculated
- **THEN** the result Dictionary SHALL include keys: final_score, style_match, fermentation, science, water, hop_schedule, novelty, conditioning, off_flavors (Array)

### Requirement: Fermentation as dominant quality lever
The fermentation component (25%) SHALL be calculated from: yeast-temp accuracy (how close ferment temp is to yeast's ideal range), yeast flavor compound desirability for the style, and temperature stability (based on equipment — fermentation chamber eliminates drift penalty).

#### Scenario: Perfect fermentation
- **WHEN** the player ferments at yeast's ideal temp with a fermentation chamber (no drift) and the yeast flavor compounds match the style
- **THEN** the fermentation component SHALL score 0.95-1.0

#### Scenario: Poor fermentation
- **WHEN** the player ferments 5C above yeast's ideal with no temp control (drift penalty)
- **THEN** the fermentation component SHALL score 0.3-0.5 with off-flavor generation
