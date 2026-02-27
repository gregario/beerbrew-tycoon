## MODIFIED Requirements

### Requirement: Recipe ingredient selection
The player SHALL select ingredients from each category to design a recipe. For the MVP, one ingredient per category was required. Post-MVP, the player SHALL select 1-3 malts, 1-2 hops, and exactly 1 yeast per recipe. The recipe designer screen SHALL display ingredient properties (numeric stats and flavor tags) alongside each option. Selected ingredients' combined properties SHALL be shown in a recipe summary panel before brewing.

#### Scenario: Player selects multiple malts
- **WHEN** the player is on the recipe designer screen
- **THEN** the player SHALL be able to select 1-3 malts from the available catalog
- **THEN** the recipe summary SHALL show the weighted average of selected malts' properties
- **THEN** the total cost SHALL update as ingredients are added

#### Scenario: Player selects multiple hops
- **WHEN** the player is on the recipe designer screen
- **THEN** the player SHALL be able to select 1-2 hops from the available catalog
- **THEN** the recipe summary SHALL show the combined hop properties (summed alpha acid, max aroma)

#### Scenario: Recipe summary shows combined properties
- **WHEN** the player has selected all ingredients
- **THEN** a summary panel SHALL display: estimated color, estimated bitterness, estimated body, flavor tags, and total cost

## ADDED Requirements

### Requirement: Ingredient catalog browsing
The recipe designer SHALL include a catalog browser that displays all available ingredients with their full properties, organized by category. Locked ingredients (not yet researched) SHALL be shown dimmed with unlock requirements.

#### Scenario: Catalog shows locked ingredients
- **WHEN** the player opens the ingredient catalog
- **THEN** available ingredients SHALL be selectable with full property display
- **THEN** locked ingredients SHALL be shown dimmed with "Requires: [research node name]" text
