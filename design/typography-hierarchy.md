# Typography & Information Hierarchy

## Type Scale

| Role | Token | Size | Font | Usage |
|------|-------|------|------|-------|
| Hero | xl | 40px | Display-Bold | Score displays, game over titles. One per screen max. |
| Page Title | lg | 32px | Display-Bold | Screen title in header bar. Exactly one per card. |
| Section Header | md | 24px | Inter-Regular | Category labels, phase names, money amounts. |
| Body | sm | 20px | Inter-Regular | Descriptions, stats, summaries. Theme default — no override. |
| Caption | xs | 16px | Inter-Regular | Slider values, minor labels, hints. |

## Rules

- Never skip levels (hero -> caption with nothing between is wrong)
- Display-Bold only for hero and page title
- One hero element per screen maximum
- Page title is always first in header bar
- Body text (20px) is the theme default — do not add font_size overrides for it

## Information Hierarchy

Three levels of visual emphasis:

| Level | Treatment | Examples |
|-------|-----------|---------|
| Primary | Hero/lg size, bold font, centered or top | Quality score, game over title, screen title |
| Secondary | md size, standard font, supporting position | Revenue, style name, category headers |
| Tertiary | sm/xs size, muted color optional, grid/bottom | Breakdown stats, hints, slider values |

## Per-Screen Hierarchy

| Screen | Primary | Secondary | Tertiary |
|--------|---------|-----------|----------|
| StylePicker | Screen title | Balance, style names | Demand badges, descriptions |
| RecipeDesigner | Screen title | Category headers | Ingredient names, summary |
| BrewingPhases | Screen title | Phase names | Hint, slider values, preview |
| ResultsOverlay | Quality score | Revenue/balance, style | Breakdown, recipe, rent warning |
| GameOverScreen | Win/loss title | Message | Stats grid |
