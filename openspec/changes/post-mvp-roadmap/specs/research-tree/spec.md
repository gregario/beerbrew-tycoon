## ADDED Requirements

### Requirement: Research point accumulation
The player SHALL earn Research Points (RP) after each brew. RP earned SHALL equal: `base_rp + (quality_score / 20)`. base_rp SHALL be 1. High-quality brews earn more RP (max ~6 per brew at score 100).

#### Scenario: Player earns research points from brewing
- **WHEN** the player completes a brew with quality score 80
- **THEN** RP earned SHALL be 1 + (80/20) = 5

### Requirement: Research tree with unlockable nodes
The game SHALL have a research tree with nodes organized into categories: Techniques, Ingredients, Equipment, and Styles. Each node has an RP cost, prerequisites (other nodes), and an unlock effect. The tree SHALL be displayed as a visual node graph.

#### Scenario: Research tree displays available nodes
- **WHEN** the player opens the research screen
- **THEN** unlocked nodes SHALL be highlighted
- **THEN** available nodes (prerequisites met, enough RP) SHALL be clearly purchasable
- **THEN** locked nodes (prerequisites not met) SHALL be dimmed with prerequisite info

### Requirement: Technique research unlocks
Technique research nodes SHALL unlock brewing capabilities: step mashing (multi-temperature mash), decoction mashing, dry hopping, cold crashing, yeast harvesting, and water chemistry adjustment. Each unlocked technique adds a new option or modifier to the brewing phases.

#### Scenario: Unlocking dry hopping adds brewing option
- **WHEN** the player researches "Dry Hopping"
- **THEN** a dry hop option SHALL appear in the fermenting phase
- **THEN** using dry hopping SHALL boost aroma contribution at the cost of additional hops

### Requirement: Ingredient research unlocks
Ingredient research nodes SHALL unlock access to advanced ingredients. Base ingredients are available from the start. Specialty malts, rare hop varieties, and specialized yeast strains require research to unlock.

#### Scenario: Unlocking specialty malts
- **WHEN** the player researches "Specialty Malts"
- **THEN** Crystal, Chocolate, and Roasted malts SHALL become available in the recipe designer

### Requirement: Style research unlocks
Style research nodes SHALL unlock new beer styles beyond the starting 4. Each style node costs RP and may require specific technique or ingredient prerequisites.

#### Scenario: Unlocking IPA style
- **WHEN** the player researches "IPA" (requires: American hops unlocked)
- **THEN** IPA SHALL appear as a brewable style in the style picker
