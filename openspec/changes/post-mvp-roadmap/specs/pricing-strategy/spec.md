## ADDED Requirements

### Requirement: Player-set pricing
The player SHALL set a price per pint/unit for each beer before selling. Price affects demand volume: higher prices reduce volume sold, lower prices increase volume. The price-demand curve SHALL follow: `volume_modifier = 1.0 + (base_price - set_price) / base_price * 0.5`, clamped to 0.3-1.5.

#### Scenario: Premium pricing reduces volume
- **WHEN** the player sets price 50% above base price
- **THEN** volume_modifier SHALL be approximately 0.75
- **THEN** per-unit revenue SHALL be higher but total units sold lower

#### Scenario: Discount pricing increases volume
- **WHEN** the player sets price 30% below base price
- **THEN** volume_modifier SHALL be approximately 1.15
- **THEN** per-unit revenue SHALL be lower but total units sold higher

### Requirement: Quality affects price tolerance
Higher quality beers SHALL have a higher price ceiling before demand drops. Quality score above 80 allows premium pricing with less volume penalty. Quality below 50 makes any price increase sharply reduce demand.

#### Scenario: High-quality beer supports premium price
- **WHEN** a beer with quality 90 is priced at 40% above base
- **THEN** volume_modifier SHALL be approximately 0.85 (mild penalty)
- **WHEN** a beer with quality 40 is priced at 40% above base
- **THEN** volume_modifier SHALL be approximately 0.50 (harsh penalty)
