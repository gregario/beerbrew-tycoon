## ADDED Requirements

### Requirement: Seasonal demand cycles
Market demand SHALL follow seasonal patterns. Each "season" lasts 6 turns. Certain styles SHALL have predictable seasonal boosts (e.g., stouts in winter/cold season, wheat beers in summer/hot season). Seasonal patterns are consistent across runs so players can learn and plan.

#### Scenario: Seasonal demand boost applies
- **WHEN** the current season is "winter" (turns 1-6 of each 24-turn year cycle)
- **THEN** Stout demand multiplier SHALL receive a +0.3 seasonal bonus
- **THEN** Wheat Beer demand multiplier SHALL receive a -0.2 seasonal penalty

### Requirement: Trending styles
In addition to seasonal patterns, a random trending style SHALL emerge every 8-12 turns. The trending style gets a +0.5 demand bonus for 4-6 turns. Trend announcements appear as toast notifications before they take effect.

#### Scenario: Trend is announced and applies
- **WHEN** a new trend emerges for "Pale Ale"
- **THEN** a toast notification SHALL announce "Pale Ale is trending!"
- **THEN** Pale Ale demand multiplier SHALL increase by 0.5 for the trend duration

### Requirement: Market saturation replaces simple novelty
The MVP novelty modifier (penalizing repeat recipes) SHALL be expanded into market saturation. Brewing the same style repeatedly saturates local demand for that style, reducing its demand multiplier by 0.1 per brew (floor: 0.5). Saturation recovers by 0.05 per turn when not brewing that style.

#### Scenario: Style saturation from repeated brewing
- **WHEN** the player brews Pale Ale 3 times consecutively
- **THEN** Pale Ale's demand multiplier SHALL be reduced by 0.3 from saturation
- **WHEN** the player brews other styles for 4 turns
- **THEN** Pale Ale saturation SHALL recover by 0.2

### Requirement: Market research purchasable
The player SHALL be able to spend money on market research reports that reveal: upcoming seasonal changes, trending styles before they're publicly announced (1-2 turns early), and demand breakdown by channel.

#### Scenario: Market research reveals upcoming trend
- **WHEN** the player purchases a market research report ($100)
- **THEN** the report SHALL show which style will trend in 1-2 turns
- **THEN** seasonal demand forecasts SHALL be displayed
