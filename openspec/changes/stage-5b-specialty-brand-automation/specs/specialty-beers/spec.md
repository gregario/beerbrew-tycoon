## ADDED Requirements

### Requirement: Specialty beer categories
The game SHALL support three specialty beer categories exclusive to the artisan path: Sour/Wild Ales, Experimental Brews, and (future) Barrel-Aged beers. Specialty styles SHALL be gated behind the "Wild Fermentation" research node AND the artisan path.

#### Scenario: Specialty styles available after research
- **WHEN** the player is on the artisan path AND has researched "Wild Fermentation"
- **THEN** Sour/Wild Ale and Experimental Brew styles SHALL appear in the style picker

#### Scenario: Specialty styles unavailable on mass-market path
- **WHEN** the player is on the mass-market path
- **THEN** specialty beer styles SHALL NOT appear in the style picker regardless of research

### Requirement: Sour/Wild Ales require multi-turn fermentation
Sour/Wild Ale styles SHALL require 3-5 turns of fermentation. The beer enters an aging queue when brewed and resolves automatically when fermentation completes. The player SHALL continue brewing normally while beers age.

#### Scenario: Sour ale enters aging queue
- **WHEN** the player completes brewing a Sour Ale
- **THEN** the beer SHALL enter the aging queue with turns_remaining based on the style (e.g., 3 for Berliner Weisse, 5 for Lambic)
- **THEN** the player SHALL NOT receive results immediately
- **THEN** a toast notification SHALL inform the player the beer is aging

#### Scenario: Aged beer completes
- **WHEN** an aging beer's turns_remaining reaches 0
- **THEN** the beer SHALL resolve with quality calculation including variance
- **THEN** results SHALL appear alongside the current turn's results
- **THEN** revenue from the aged beer SHALL be added to the current turn

### Requirement: Specialty beer quality variance
Specialty beers SHALL have higher quality variance than normal beers (±15 points vs normal ±5) AND a quality ceiling boost of +10 points. Variance SHALL be determined at brew time using a seeded RNG to ensure save/load consistency.

#### Scenario: Specialty beer has higher variance
- **WHEN** a specialty beer resolves
- **THEN** the quality score SHALL vary by up to ±15 points from the base calculation
- **THEN** the maximum possible quality SHALL be 10 points higher than a normal beer with the same inputs

#### Scenario: Variance is deterministic with seed
- **WHEN** a specialty beer is brewed with a given seed
- **THEN** saving, quitting, and reloading SHALL produce the same variance result

### Requirement: Experimental brews apply ingredient mutation
Experimental Brew style SHALL use normal recipe selection but apply a random "mutation" to one ingredient's flavor profile after brewing. The mutation is revealed in the results, creating unpredictable but potentially superior outcomes.

#### Scenario: Experimental brew mutates one ingredient
- **WHEN** the player brews an Experimental Brew
- **THEN** one randomly selected ingredient SHALL have its flavor_points and technique_points randomized (within ±50% of original values)
- **THEN** the results screen SHALL show which ingredient mutated and the new values
- **THEN** the discovery system SHALL have a chance to reveal the mutation as a new flavor insight

### Requirement: SpecialtyBeerManager autoload
A SpecialtyBeerManager autoload SHALL manage the aging queue, track in-progress fermentations, and handle specialty beer resolution. It SHALL expose methods for queuing beers, ticking turns, and checking for completed beers.

#### Scenario: Aging queue persists across saves
- **WHEN** the player saves with beers in the aging queue
- **THEN** loading the save SHALL restore all aging beers with correct turns_remaining

#### Scenario: Aging queue ticks each turn
- **WHEN** the player completes a turn (after results continue)
- **THEN** all aging beers SHALL have turns_remaining decremented by 1
