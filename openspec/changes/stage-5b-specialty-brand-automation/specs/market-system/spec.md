## ADDED Requirements

### Requirement: Brand recognition demand modifier
MarketManager SHALL apply a brand recognition demand volume multiplier when calculating demand for a style. The multiplier SHALL be `1.0 + (brand_recognition[style] / 100.0) * 0.5`.

#### Scenario: Brand recognition boosts demand volume
- **WHEN** Pale Ale has brand recognition of 60
- **THEN** the demand volume for Pale Ale SHALL be multiplied by 1.3 (1.0 + 0.6 * 0.5)
- **THEN** this multiplier SHALL stack multiplicatively with seasonal and trending modifiers

### Requirement: Brand recognition tracking in MarketManager
MarketManager SHALL maintain a brand_recognition Dictionary (style_name → float). It SHALL expose methods: add_brand_recognition(style, channel), tick_brand_decay(brewed_style), get_brand_recognition(style), and get_brand_demand_multiplier(style).

#### Scenario: Brand recognition API works correctly
- **WHEN** add_brand_recognition("Pale Ale", "retail") is called
- **THEN** brand_recognition["Pale Ale"] SHALL increase by 7.5 (base 5 × retail 1.5)
- **WHEN** get_brand_demand_multiplier("Pale Ale") is called with recognition at 50
- **THEN** the return value SHALL be 1.25

### Requirement: Brand recognition displayed in MarketForecast
The MarketForecast overlay SHALL include brand recognition data in the Forecast tab, showing a bar or number for each style's recognition level and the resulting demand bonus.

#### Scenario: MarketForecast shows brand data
- **WHEN** the player views the Forecast tab in MarketForecast
- **THEN** each style SHALL show brand recognition (0-100) and demand bonus percentage
