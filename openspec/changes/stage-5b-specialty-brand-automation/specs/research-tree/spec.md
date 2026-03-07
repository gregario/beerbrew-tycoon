## ADDED Requirements

### Requirement: Wild Fermentation research node
The research tree SHALL include a new "Wild Fermentation" node in the Techniques category. Cost: 30 RP. Prerequisite: specialist_yeast. Effect: unlocks specialty beer styles for artisan path players.

#### Scenario: Wild Fermentation node exists in tree
- **WHEN** the player opens the research screen
- **THEN** a "Wild Fermentation" node SHALL appear in the Techniques category
- **THEN** it SHALL show prerequisite: Specialist Yeast
- **THEN** it SHALL cost 30 RP

#### Scenario: Researching Wild Fermentation unlocks specialty beers
- **WHEN** an artisan path player researches Wild Fermentation
- **THEN** Sour/Wild Ale and Experimental Brew styles SHALL become available in the style picker
- **WHEN** a mass-market path player researches Wild Fermentation
- **THEN** specialty styles SHALL NOT become available (path-gated)

### Requirement: Wild Fermentation research node data file
A wild_fermentation.tres Resource file SHALL be created in src/data/research/techniques/ with: node_id="wild_fermentation", display_name="Wild Fermentation", category=TECHNIQUES, rp_cost=30, prerequisites=["specialist_yeast"], effect_type="unlock_specialty_beers", description="Ancient techniques of spontaneous fermentation. Unlocks sour and experimental beer styles."

#### Scenario: Research node file loads correctly
- **WHEN** the research catalog is loaded
- **THEN** wild_fermentation SHALL be included with correct properties
- **THEN** it SHALL appear after specialist_yeast in the prerequisite chain
