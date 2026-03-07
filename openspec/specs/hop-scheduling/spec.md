## ADDED Requirements

### Requirement: Hop allocation slots
When selecting hops in RecipeDesigner, the player SHALL allocate each selected hop to one or more timing slots: Bittering (60min), Flavor (15min), Aroma (5min), Dry Hop (post-ferment). A hop MAY be split across multiple slots.

#### Scenario: Player allocates hops to timing slots
- **WHEN** the player selects Cascade hops
- **THEN** the UI SHALL show allocation buttons for Bittering/Flavor/Aroma/Dry Hop and the player SHALL assign the hop to at least one slot

#### Scenario: Multiple hops with different allocations
- **WHEN** the player selects Cascade (Aroma) and Centennial (Bittering)
- **THEN** GameState.current_recipe SHALL include a hop_allocations dictionary mapping each hop to its assigned slots

### Requirement: Hop schedule scoring
QualityCalculator SHALL include a hop schedule score component weighted at 10% of the total quality score. Each BeerStyle SHALL define hop_schedule_expectations (Dictionary mapping slot names to importance weights).

#### Scenario: IPA with correct hop schedule
- **WHEN** the player brews an IPA with hops allocated to Aroma and Dry Hop slots (matching IPA expectations)
- **THEN** the hop schedule score SHALL be high (0.8-1.0)

#### Scenario: Lager with unnecessary dry hop
- **WHEN** the player brews a Lager with hops allocated to Dry Hop (lager expects Bittering only)
- **THEN** the hop schedule score SHALL be moderate (0.5-0.7, not actively punished but not optimal)

#### Scenario: No hop allocation (legacy/default)
- **WHEN** the player does not allocate hops to specific slots (pre-equipment or old save)
- **THEN** all hops SHALL default to Bittering slot and the hop schedule score SHALL be 0.5 (neutral)

### Requirement: Dry hop as post-ferment step
Dry hopping SHALL be a visible step between Fermentation and Conditioning when the player has allocated any hops to the Dry Hop slot and has the "dry_hop_rack" equipment reveal.

#### Scenario: Dry hop step appears
- **WHEN** the player has dry_hop_rack equipment and allocated hops to Dry Hop
- **THEN** a brief dry hop step SHALL appear during brewing showing the dry hop addition

### Requirement: Hop schedule discovery
The discovery system SHALL include hop timing discoveries.

#### Scenario: Aroma hop discovery
- **WHEN** the player brews with hops in Aroma slot for the first time and scores higher than Bittering-only
- **THEN** a discovery toast SHALL appear: "Late hop additions seem more aromatic!"
