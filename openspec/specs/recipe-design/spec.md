## ADDED Requirements

### Requirement: Player selects one ingredient from each of three categories
The system SHALL present three ingredient categories — Malts, Hops, and Yeast — and require the player to select exactly one ingredient from each category before proceeding to brewing phases. The MVP ingredient set SHALL be: Malts (3–4 options), Hops (3–4 options), Yeast (2–3 options).

#### Scenario: One ingredient per category required
- **WHEN** the recipe design screen is open
- **THEN** each category shows its available ingredients and exactly one must be selected to proceed

#### Scenario: Proceeding without full selection blocked
- **WHEN** the player has not selected an ingredient in one or more categories
- **THEN** the "Brew" or "Next" action SHALL be disabled

### Requirement: Each ingredient has defined attributes affecting quality scoring
The system SHALL associate each ingredient with a compatibility modifier per beer style and a contribution to Flavor points, Technique points, or both. These attributes SHALL be used by the quality calculator.

#### Scenario: Ingredient attributes feed into quality score
- **WHEN** a brew is completed
- **THEN** the quality score SHALL differ based on which ingredient combination was selected

### Requirement: Recipe history is tracked for novelty calculation
The system SHALL record each completed brew's exact style + ingredient combination (malt ID, hop ID, yeast ID). The quality calculator SHALL receive this history to apply a novelty modifier.

#### Scenario: Repeated recipe receives novelty penalty
- **WHEN** the player brews the same style with the same malt, hop, and yeast combination more than once
- **THEN** subsequent brews of that combination SHALL receive a lower novelty score than the first

#### Scenario: Different recipe receives no penalty
- **WHEN** the player brews a new style or changes any ingredient from a previous brew
- **THEN** no novelty penalty is applied for that brew

### Requirement: Selected recipe is displayed as a summary before brewing
The system SHALL show a compact summary of the chosen style and all three selected ingredients before the player enters the brewing phases step.

#### Scenario: Recipe summary visible
- **WHEN** all three ingredients have been selected
- **THEN** the current recipe (style + malt + hop + yeast) is displayed in a summary area
