## ADDED Requirements

### Requirement: Distribution channels
The game SHALL support multiple sales channels: Taproom (default, available from garage), Local Bars (unlocked at microbrewery), Retail/Bottle Shops (requires research), and Events/Festivals (periodic, requires application). Each channel has different margin multipliers and volume limits.

#### Scenario: Channel properties
- **WHEN** the player brews a beer
- **THEN** revenue SHALL be calculated per active channel:
  - Taproom: margin 1.0x, volume limit = batch_size × 0.3
  - Local Bars: margin 0.7x, volume limit = batch_size × 0.5
  - Retail: margin 0.5x, volume limit = batch_size × 1.0
  - Events: margin 1.5x, volume limit = batch_size × 0.2 (when available)

### Requirement: Channel unlocking and management
Channels beyond Taproom SHALL require prerequisites (brewery stage, research, or reputation thresholds). The player SHALL manage which channels receive their beer. Total allocation across channels SHALL NOT exceed batch size.

#### Scenario: Unlocking local bars channel
- **WHEN** the player reaches microbrewery stage
- **THEN** the "Local Bars" distribution channel SHALL become available
- **THEN** the player can allocate a portion of each brew to local bars

### Requirement: Channel-specific demand
Each channel SHALL have its own demand profile. Taproom customers prefer variety and quality. Bars prefer consistent popular styles. Retail prefers recognizable brands. Events reward specialty/unique beers.

#### Scenario: High-quality specialty beer sells well at events
- **WHEN** the player sells a specialty beer (score 85+) at an event
- **THEN** the event margin multiplier SHALL apply (1.5x)
- **THEN** reputation gain SHALL be higher than selling through other channels
