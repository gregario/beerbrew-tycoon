## ADDED Requirements

### Requirement: Typed ingredient subclasses with brewing-specific properties
Each ingredient type SHALL be a typed Godot Resource subclass extending a base Ingredient class. Base Ingredient SHALL have: ingredient_id (String), ingredient_name (String), description (String), category (enum: MALT, HOP, YEAST, ADJUNCT), cost (int), flavor_tags (Array[String] — display-only descriptors), flavor_profile (Dictionary with keys: bitterness, sweetness, roastiness, fruitiness, funkiness — all float 0-1), and unlocked (bool — for progressive reveal).

Malt SHALL additionally have: color_srm (float), body_contribution (float 0-1), sweetness (float 0-1), fermentability (float 0-1), is_base_malt (bool).

Hop SHALL additionally have: alpha_acid_pct (float), aroma_intensity (float 0-1), variety_family (String: "noble", "british", "american", "new_world").

Yeast SHALL additionally have: attenuation_pct (float 0.6-0.95), ideal_temp_min_c (float), ideal_temp_max_c (float), flocculation (String: "low", "medium", "high").

Adjunct SHALL additionally have: fermentable (bool), adjunct_type (String: "sugar", "fining", "fruit", "spice", "enzyme", "culture"), effect_description (String).

#### Scenario: Malt resource has all required properties
- **WHEN** a Malt resource is loaded
- **THEN** it SHALL have all base Ingredient fields plus color_srm, body_contribution, sweetness, fermentability, is_base_malt

#### Scenario: Hop resource has all required properties
- **WHEN** a Hop resource is loaded
- **THEN** it SHALL have all base Ingredient fields plus alpha_acid_pct, aroma_intensity, variety_family

#### Scenario: Yeast resource has all required properties
- **WHEN** a Yeast resource is loaded
- **THEN** it SHALL have all base Ingredient fields plus attenuation_pct, ideal_temp_min_c, ideal_temp_max_c, flocculation

#### Scenario: Adjunct resource has all required properties
- **WHEN** an Adjunct resource is loaded
- **THEN** it SHALL have all base Ingredient fields plus fermentable, adjunct_type, effect_description

### Requirement: Flavor profile on all ingredients
Every ingredient SHALL have a flavor_profile Dictionary with 5 numeric axes (bitterness, sweetness, roastiness, fruitiness, funkiness) all float 0-1. These axes SHALL be used by the scoring system to compute recipe-style flavor match. flavor_tags (Array[String]) SHALL be display-only descriptors for player readability.

#### Scenario: Flavor profile used in scoring
- **WHEN** a recipe's combined flavor profile is computed
- **THEN** each axis SHALL be the weighted average across all selected ingredients' flavor_profile values
- **THEN** the combined profile SHALL be compared to the style's ideal_flavor_profile

### Requirement: Expanded ingredient catalog with 4 categories
The game SHALL include at least 8 malts, 8 hops, 6 yeasts, and 4 adjuncts. Malts SHALL span from light base malts (SRM < 5) to dark specialty malts (SRM > 400). Hops SHALL span from low-alpha noble (< 5%) to high-alpha American (> 12%). Adjuncts SHALL include fermentable and non-fermentable types.

#### Scenario: Catalog has minimum variety
- **WHEN** the ingredient catalog is loaded
- **THEN** there SHALL be at least 8 malts, 8 hops, 6 yeasts, and 4 adjuncts
- **THEN** malt color_srm SHALL range from under 5 to over 400
- **THEN** hop alpha_acid_pct SHALL range from under 5 to over 12
- **THEN** at least one adjunct SHALL be non-fermentable

### Requirement: Progressive ingredient discovery
Ingredients SHALL have an unlocked flag. At game start, approximately half the catalog SHALL be unlocked (basic malts, common hops, standard yeasts, no adjuncts). Remaining ingredients SHALL unlock as the player brews more, levels up, or learns methods. Locked ingredients SHALL be visible but not selectable in the UI.

#### Scenario: Locked ingredient visible but not selectable
- **WHEN** the player opens the recipe designer
- **THEN** locked ingredients SHALL appear dimmed with "Locked" text
- **THEN** locked ingredients SHALL NOT be selectable

### Requirement: Multiple ingredient selection per category
The player SHALL select 1-3 malts (at least 1 base malt required), 1-2 hops, exactly 1 yeast, and 0-2 adjuncts per recipe. Each additional ingredient adds its properties to the recipe's combined totals.

#### Scenario: Player selects multiple malts
- **WHEN** the player selects 2 malts for a recipe
- **THEN** the recipe's malt properties SHALL be the weighted average of both malts' numeric properties
- **THEN** the recipe's flavor_tags SHALL be the union of both malts' flavor_tags

#### Scenario: Base malt required
- **WHEN** the player has selected only specialty malts (no base malt)
- **THEN** a warning SHALL be displayed
- **THEN** the "Start Brewing" button SHALL remain disabled

#### Scenario: Player selects adjuncts
- **WHEN** the player selects 1-2 adjuncts
- **THEN** adjunct effects SHALL apply to the recipe
- **THEN** non-fermentable adjuncts SHALL add properties without increasing fermentability

### Requirement: Ingredient cost affects brew economics
Each ingredient's cost SHALL be deducted from the player's balance when brewing. Total ingredient cost = sum of all selected ingredients' costs. The flat INGREDIENT_COST constant SHALL be removed.

#### Scenario: Multiple ingredient costs are summed
- **WHEN** the player brews with a $20 malt, a $15 malt, a $25 hop, a $15 yeast, and a $20 adjunct
- **THEN** the total ingredient cost deducted SHALL be $95

#### Scenario: Loss condition uses cheapest possible recipe
- **WHEN** the player's balance is less than the cost of the cheapest valid recipe (1 cheapest base malt + 1 cheapest hop + 1 cheapest yeast)
- **THEN** the loss condition SHALL trigger

### Requirement: Compatibility defined on BeerStyle
BeerStyle SHALL gain preferred_ingredients (Dictionary mapping ingredient_id to compatibility float 0-1) and ideal_flavor_profile (Dictionary with the 5 flavor axes). Compatibility scoring SHALL check selected ingredients against the style's preferred_ingredients. The old style_compatibility field on Ingredient SHALL be removed.

#### Scenario: Style defines compatible ingredients
- **WHEN** a Stout style has preferred_ingredients including "roasted_barley": 0.9
- **THEN** selecting Roasted Barley for a Stout SHALL contribute a high compatibility score
- **WHEN** an ingredient is not listed in preferred_ingredients
- **THEN** it SHALL receive a neutral compatibility score of 0.5
