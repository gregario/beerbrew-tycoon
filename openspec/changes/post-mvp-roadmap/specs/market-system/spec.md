## MODIFIED Requirements

### Requirement: Market demand system
Market demand SHALL be driven by three layers replacing the MVP's simple rotation:
1. **Seasonal cycles** (predictable, learnable) — 4 seasons of 6 turns each in a 24-turn year. Each style has seasonal modifiers.
2. **Trending styles** (semi-random) — one style gets a demand spike every 8-12 turns for 4-6 turns.
3. **Market saturation** (player-driven) — repeatedly brewing the same style reduces its local demand.
The combined demand multiplier for a style = base (1.0) + seasonal_modifier + trend_bonus - saturation_penalty, clamped to 0.3-2.5.

#### Scenario: Combined demand calculation
- **WHEN** Pale Ale has seasonal_modifier +0.2, trend_bonus +0.5, saturation_penalty 0.1
- **THEN** Pale Ale demand multiplier SHALL be 1.0 + 0.2 + 0.5 - 0.1 = 1.6

#### Scenario: Market demand displayed before style selection
- **WHEN** the player opens the style picker
- **THEN** each style SHALL display its current combined demand multiplier
- **THEN** seasonal and trend indicators SHALL be visible (icons/badges)
- **THEN** saturation level SHALL be shown if above 0

## ADDED Requirements

### Requirement: Market forecast screen
The player SHALL be able to view a market forecast screen showing: current season and upcoming season, active trends with remaining duration, saturation levels per style, and (if market research purchased) upcoming trend predictions.

#### Scenario: Market forecast displays seasonal info
- **WHEN** the player opens the market forecast screen
- **THEN** the current season name and turn count SHALL be displayed
- **THEN** seasonal modifiers per style SHALL be listed
- **THEN** the next season's modifiers SHALL be shown (always visible, not requiring research)
