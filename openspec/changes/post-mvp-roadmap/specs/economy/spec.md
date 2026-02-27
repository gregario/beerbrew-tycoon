## MODIFIED Requirements

### Requirement: Revenue calculation
Revenue SHALL be calculated using an expanded formula that accounts for distribution channels, pricing, and batch size:
`revenue = sum_per_channel(units_sold × set_price × quality_multiplier × demand_multiplier × channel_margin)`
where units_sold per channel = min(allocation, channel_volume_limit × batch_size_multiplier).
Quality multiplier: score 50 = 1.0x, score 100 = 2.0x, score 0 = 0.5x (unchanged from MVP).
In the garage stage with only the taproom channel, this simplifies to approximately the MVP formula.

#### Scenario: Multi-channel revenue calculation
- **WHEN** the player sells a quality-80 beer through taproom (30 units at $5) and bars (50 units at $3.50)
- **THEN** taproom revenue SHALL be 30 × $5 × 1.6 × demand × 1.0
- **THEN** bars revenue SHALL be 50 × $3.50 × 1.6 × demand × 0.7
- **THEN** total revenue SHALL be the sum of both channels

#### Scenario: Garage stage uses simplified revenue (backward compatible)
- **WHEN** the player is in the garage stage with only taproom active
- **THEN** revenue SHALL approximate the MVP formula: base_price × quality_multiplier × demand_multiplier

### Requirement: Expanded cost structure
Costs SHALL include: ingredient costs (per brew), rent (per N turns, scaling by stage), staff salaries (per turn, post-microbrewery), equipment maintenance (per 5 turns for owned equipment), research costs (RP, not cash), and competition entry fees (per event).

#### Scenario: Turn-end cost deductions
- **WHEN** a turn ends at microbrewery stage
- **THEN** staff salaries SHALL be deducted from balance
- **WHEN** a rent turn occurs
- **THEN** rent SHALL be deducted at the current stage rate

### Requirement: Win conditions per path
Win conditions SHALL vary by brewery path:
- **Garage (MVP)**: balance >= $10,000
- **Artisan**: 5 competition medals + reputation >= 100
- **Mass-Market**: total revenue >= $50,000 + all 4 distribution channels active

#### Scenario: Path-specific win condition checked
- **WHEN** the player is on the artisan path
- **THEN** the win condition check SHALL evaluate medals and reputation, not cash balance
