# Stage 1A — Ingredient System Overhaul Design

## Summary

Replace the MVP's simple ingredient system (11 ingredients, single-select, flat cost) with a typed, brewing-science-informed ingredient model supporting multi-select recipes, per-ingredient costs, flavor profiles, and progressive discovery.

## Key Decisions

- **Approach A: Typed subclasses** — Malt, Hop, Yeast, Adjunct each extend a base Ingredient class with domain-specific properties.
- **Remove flavor_bonus/technique_bonus** — replaced by brewing-specific properties that feed into scoring via compatibility + brewing science (Stage 1B).
- **Flavor representation: axes + tags** — numeric axes (bitterness, sweetness, roastiness, fruitiness, funkiness) for scoring math; descriptive tags for player readability.
- **Compatibility moves to BeerStyle** — styles define what ingredients work for them, not the other way around.
- **Progressive catalog reveal** — ingredients unlock as you brew, level up, or learn methods. No supplier system.
- **Toggle-button multi-select UI** with counter badges per category.

## Brainstorming Insights (captured for later stages)

- **Continuous clock** (not turn-based) — replaces turn system in a future stage. Rent/salaries tick monthly. Brews take game-time.
- **Methods/Techniques** — learned through research (books, training, YouTube). Applied to equipment. Some methods create specialty ingredients. Stage 2B.
- **Owner has 4 skills** — Brewing, Management, Science, Taste. Levels up through practice and training. Stage 3A.
- **Hop timing** — early=bittering, late=aroma, dry hop=max aroma. Fits Stage 1B (boiling slider → hop schedule).
- **Sours + contamination** — Lactobacillus, cross-contamination risk on plastic, specialist equipment. Artisan path Stage 5.
- **Gluten-free/reduced** — specialist sales modifier. Distribution stage.
- **Packaging methods** — bottle conditioning vs fermenter vs kegging vs canning. Equipment/distribution stages.

## Data Model

### Base Ingredient

```
ingredient_id: String
ingredient_name: String
description: String
category: enum { MALT, HOP, YEAST, ADJUNCT }
cost: int
flavor_tags: Array[String]        # display-only ("citrus", "caramel", "roasty")
flavor_profile: Dictionary        # {bitterness: 0.0, sweetness: 0.0, roastiness: 0.0, fruitiness: 0.0, funkiness: 0.0}
unlocked: bool                    # progressive reveal
```

### Malt extends Ingredient

```
color_srm: float      # 2 (Pilsner) to 550 (Black Patent)
body_contribution: float  # 0-1
sweetness: float       # 0-1
fermentability: float  # 0-1
is_base_malt: bool     # at least 1 required per recipe
```

### Hop extends Ingredient

```
alpha_acid_pct: float   # 2-18%
aroma_intensity: float  # 0-1
variety_family: String  # "noble", "british", "american", "new_world"
```

### Yeast extends Ingredient

```
attenuation_pct: float     # 0.6-0.95
ideal_temp_min_c: float
ideal_temp_max_c: float
flocculation: String       # "low", "medium", "high"
```

### Adjunct extends Ingredient

```
fermentable: bool          # lactose=false, brewing sugar=true
adjunct_type: String       # "sugar", "fining", "fruit", "spice", "enzyme", "culture"
effect_description: String # what it does mechanically
```

### BeerStyle gains

```
preferred_ingredients: Dictionary  # ingredient_id → compatibility (0-1)
ideal_flavor_profile: Dictionary   # target flavor axes for this style
```

## Ingredient Catalog

### Malts (8)

| Name | SRM | Body | Sweet | Ferment | Base? | Cost | Tags |
|------|-----|------|-------|---------|-------|------|------|
| Pilsner Malt | 2 | 0.3 | 0.2 | 0.9 | yes | $15 | light, clean, bready |
| Pale Malt | 4 | 0.4 | 0.3 | 0.85 | yes | $15 | bready, neutral |
| Maris Otter | 5 | 0.5 | 0.35 | 0.8 | yes | $20 | biscuit, rich |
| Munich Malt | 10 | 0.5 | 0.4 | 0.75 | yes | $20 | toasty, malty |
| Crystal 60 | 60 | 0.7 | 0.7 | 0.3 | no | $25 | caramel, toffee |
| Chocolate Malt | 400 | 0.6 | 0.2 | 0.15 | no | $25 | chocolate, coffee |
| Roasted Barley | 550 | 0.5 | 0.1 | 0.1 | no | $25 | roasty, burnt, dry |
| Wheat Malt | 3 | 0.6 | 0.3 | 0.85 | yes | $15 | soft, bready, haze |

### Hops (8)

| Name | Alpha% | Aroma | Family | Cost | Tags |
|------|--------|-------|--------|------|------|
| Saaz | 3.5 | 0.7 | noble | $20 | spicy, herbal, earthy |
| Hallertau | 4.0 | 0.8 | noble | $20 | floral, mild, noble |
| East Kent Goldings | 5.5 | 0.6 | british | $20 | earthy, honey, smooth |
| Fuggle | 4.5 | 0.5 | british | $20 | woody, earthy, minty |
| Cascade | 6.0 | 0.8 | american | $25 | citrus, grapefruit, floral |
| Centennial | 10.0 | 0.7 | american | $25 | citrus, pine, balanced |
| Citra | 12.0 | 0.95 | american | $30 | tropical, mango, passion fruit |
| Simcoe | 13.0 | 0.8 | american | $30 | pine, earthy, citrus |

### Yeast (6)

| Name | Atten% | Temp Range | Flocc | Cost | Tags |
|------|--------|------------|-------|------|------|
| US-05 (Clean Ale) | 0.77 | 15-24°C | medium | $15 | clean, neutral, versatile |
| S-04 (English Ale) | 0.74 | 15-20°C | high | $15 | malty, fruity, english |
| W-34/70 (Lager) | 0.83 | 9-15°C | high | $20 | clean, crisp, lager |
| WB-06 (Wheat) | 0.86 | 15-24°C | low | $20 | banana, clove, wheat |
| Belle Saison | 0.90 | 17-35°C | low | $25 | spicy, dry, peppery |
| Kveik (Voss) | 0.78 | 20-40°C | high | $25 | orange, tropical, fast |

### Adjuncts (4)

| Name | Type | Fermentable | Cost | Tags | Effect |
|------|------|-------------|------|------|--------|
| Lactose | sugar | no | $20 | sweet, creamy | Adds body + sweetness without ABV |
| Brewing Sugar | sugar | yes | $10 | light, dry | Boosts ABV, thins body |
| Irish Moss | fining | no | $10 | — | Improves clarity |
| Flaked Oats | grain | yes | $15 | smooth, silky | Head retention + mouthfeel |

### Progressive Reveal

At game start: first 4-5 malts, first 4 hops, first 3 yeasts, no adjuncts unlocked. Others reveal as player brews more, levels up, or learns methods (unlock triggers defined in Stage 2B).

## Recipe Designer UI

- Same 900x550 card container
- 4 category columns: Malt, Hops, Yeast, Adjuncts
- Header per column: "MALTS (1/3)" with counter badge in accent color
- Toggle buttons per ingredient (click to add/remove)
- Dimmed entries for locked ingredients ("Locked" caption)
- Limit reached → remaining unselected buttons dim
- Per button: name (left), cost caption (right). Hover → tooltip with description, tags, properties
- Recipe summary panel (above footer): 5 flavor axis bars, color swatch from SRM, total cost
- Warning if no base malt selected
- "Start Brewing →" enabled when: 1+ base malt, 1+ hop, 1 yeast

Selection limits: 1-3 malts, 1-2 hops, 1 yeast, 0-2 adjuncts.

## Scoring Integration

Replace `_compute_ingredient_score` in QualityCalculator:

1. **Ingredient-style fit** — check selected ingredients against style's `preferred_ingredients`. Matched=high, unknown=0.5, poor=low.
2. **Flavor profile match** — compute recipe's combined flavor profile (weighted average from all ingredients), compare to style's `ideal_flavor_profile` via distance metric.

Weight stays at 25% (full 7-component formula in Stage 1D).

Update novelty/history to handle variable ingredient counts (arrays of IDs per category).

## Economy Changes

- Remove flat `INGREDIENT_COST = 50.0`
- Total cost = sum of all selected ingredients' `cost` values
- `deduct_ingredient_cost()` takes recipe, sums costs dynamically
- Loss condition: balance < cheapest possible recipe (~$50, now data-driven)
