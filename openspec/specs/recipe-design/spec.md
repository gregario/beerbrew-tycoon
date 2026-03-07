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

---

## Brewing Depth Expansion — Updates

### Requirement: Recipe design includes hop allocation
When selecting hops, RecipeDesigner SHALL show hop timing allocation UI if EquipmentManager.is_revealed("hop_schedule") is true. Each selected hop SHALL be assignable to Bittering, Flavor, Aroma, or Dry Hop slots.

#### Scenario: Hop allocation visible
- **WHEN** the player has hop schedule equipment and selects Cascade hops
- **THEN** timing slot buttons (Bittering/Flavor/Aroma/Dry Hop) SHALL appear for Cascade

#### Scenario: Hop allocation not visible
- **WHEN** the player lacks hop schedule equipment
- **THEN** no timing allocation UI is shown and all hops default to Bittering slot

### Requirement: Water profile selector
RecipeDesigner SHALL display a water profile selector before ingredient selection when EquipmentManager.is_revealed("water_selector") is true. The selector SHALL show all 5 water profiles with name and brief description.

#### Scenario: Water selector shown
- **WHEN** the player has water treatment equipment
- **THEN** a water profile dropdown/selector SHALL appear at the top of RecipeDesigner with 5 options

#### Scenario: Water selector hidden
- **WHEN** the player lacks water treatment equipment
- **THEN** no water selector is shown and default tap water is used

### Requirement: Recipe stores water and hop allocation
GameState.current_recipe SHALL be extended to include water_profile (WaterProfile resource or null) and hop_allocations (Dictionary mapping hop_id to Array of slot names).

#### Scenario: Recipe with full data
- **WHEN** the player completes recipe design with water profile "hoppy" and Cascade allocated to ["aroma", "dry_hop"]
- **THEN** current_recipe SHALL include water_profile pointing to the hoppy WaterProfile and hop_allocations with the cascade allocation
