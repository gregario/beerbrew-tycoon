# Stage 4C — Market & Distribution Design

## Decisions

- **UI structure**: Single "Market" overlay with tabs (Forecast / Channels / Research)
- **Sell timing**: New SELL state after RESULTS, before EQUIPMENT_MANAGE
- **Novelty vs saturation**: Keep both — novelty stays in QualityCalculator (recipe-level), saturation is a new demand multiplier (style-level)
- **Architecture**: Single MarketManager autoload replaces MarketSystem

## Game Flow

```
MARKET_CHECK → STYLE_SELECT → RECIPE_DESIGN → BREWING_PHASES → RESULTS → SELL → EQUIPMENT_MANAGE
```

The SELL step opens a SellOverlay where the player allocates batch across channels and sets price, seeing projected revenue in real-time.

## MarketManager Architecture

MarketManager autoload replaces MarketSystem. Manages:

### Seasonal Cycles
- 4 seasons × 6 turns = 24-turn year cycle
- Per-style seasonal modifiers (e.g., Stout +0.3 in Winter, -0.2 in Summer)
- Patterns are consistent across runs for learnability

### Trending Styles
- Random style spike every 8-12 turns, lasts 4-6 turns
- +0.5 demand bonus for trending style
- Toast notification announces trends

### Market Saturation
- Brewing a style increases its saturation by 0.1 (floor penalty: 0.5)
- Saturation recovers +0.05 per turn when not brewing that style
- Separate from novelty (novelty = recipe-level quality penalty, saturation = style-level demand penalty)

### Combined Demand
```
demand_multiplier = clamp(1.0 + seasonal_modifier + trend_bonus - saturation_penalty, 0.3, 2.5)
```

### Distribution Channels

| Channel | Margin | Volume | Unlock |
|---------|--------|--------|--------|
| Taproom | 1.0× | 30% batch | Always |
| Local Bars | 0.7× | 50% batch | Microbrewery stage |
| Retail | 0.5× | 100% batch | Research unlock |
| Events | 1.5× | 20% batch | Periodic + reputation |

### Player Pricing
- Slider: -30% to +50% of base_price
- Volume modifier: `1.0 + (base_price - set_price) / base_price * 0.5`, clamped 0.3–1.5
- Quality effect: higher quality tolerates premium pricing better

### Market Research
- Cost: $100
- Reveals upcoming trends 1-2 turns early
- Shows seasonal forecast and demand breakdown

### Revenue Formula
```
For each channel:
  channel_revenue = allocated_units × adjusted_price × channel.margin × quality_mult × demand_mult
Total = sum(channel_revenues)
```

Where:
- `adjusted_price = base_price × (1 + price_offset)`
- `allocated_units ≤ batch_size × channel.volume_pct`
- Unallocated units are wasted

### Save/Load
Standard pattern: `save_data() → Dictionary`, `load_data(data)`, `reset()`.

## UI Wireframes

### Hub Button
```
[Start Brewing >] [Research] [Staff] [Contracts] [Compete] [Market]
```
"Market" button: blue #5AA9FF, 160×48px.

### MarketForecast Overlay — Forecast Tab (900×550)
```
┌─────────────────────────────────────────────────────────────┐
│  MARKET FORECAST              Season: Winter (Turn 4/6)  [X]│
├─────────────────────────────────────────────────────────────┤
│  [Forecast]  [Channels]  [Research]                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  SEASONAL DEMAND          TRENDING: Stout (+0.5) 3 turns    │
│  ┌──────────────────────────────────────────────────┐       │
│  │ Style      │ Spring │ Summer │ Fall  │ Winter*  ││       │
│  │ Pale Ale   │  +0.1  │  +0.2  │  0.0  │  -0.1   ││       │
│  │ Stout      │  -0.1  │  -0.2  │  +0.1 │  +0.3 ▲ ││       │
│  │ Wheat Beer │  +0.2  │  +0.3  │  0.0  │  -0.2   ││       │
│  │ IPA        │  0.0   │  +0.1  │  +0.2 │  0.0    ││       │
│  └──────────────────────────────────────────────────┘       │
│                                                             │
│  SATURATION                                                 │
│  Pale Ale  ████░░░░░░  0.3 penalty (recovering)            │
│  Stout     ░░░░░░░░░░  0.0 (fresh)                         │
│  Wheat     ██░░░░░░░░  0.1 penalty                         │
│                                                             │
│  COMBINED DEMAND (current)                                  │
│  Stout: 1.0 + 0.3 + 0.5 - 0.0 = 1.8x ▲▲                  │
│  Pale Ale: 1.0 - 0.1 + 0.0 - 0.3 = 0.6x ▼                │
└─────────────────────────────────────────────────────────────┘
```

### MarketForecast — Channels Tab
```
┌─────────────────────────────────────────────────────────────┐
│  [Forecast]  [Channels]  [Research]                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────┐  ┌─────────────────────┐          │
│  │ TAPROOM             │  │ LOCAL BARS           │          │
│  │ Margin: 1.0×        │  │ Margin: 0.7×        │          │
│  │ Volume: 30%         │  │ Volume: 50%         │          │
│  │ Status: Available   │  │ Status: Available   │          │
│  │ Prefers: Quality    │  │ Prefers: Popular    │          │
│  └─────────────────────┘  └─────────────────────┘          │
│                                                             │
│  ┌─────────────────────┐  ┌─────────────────────┐          │
│  │ RETAIL              │  │ EVENTS              │          │
│  │ Margin: 0.5×        │  │ Margin: 1.5×        │          │
│  │ Volume: 100%        │  │ Volume: 20%         │          │
│  │ Status: Locked      │  │ Status: Locked      │          │
│  │ Unlock: Research    │  │ Unlock: Reputation   │          │
│  └─────────────────────┘  └─────────────────────┘          │
└─────────────────────────────────────────────────────────────┘
```

### SellOverlay (post-brew, 900×550)
```
┌─────────────────────────────────────────────────────────────┐
│  SELL: Pale Ale                    Demand: 0.6×          [X]│
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  PRICING                          Batch Size: 18 units      │
│  Base Price: $200                                           │
│  Your Price: $220 (+10%)     <=========O=========>          │
│  Volume Effect: 0.95x (slight reduction)                    │
│                                                             │
│  DISTRIBUTION                     Allocated: 14/18          │
│  ┌────────────────────────────────────────────────────┐     │
│  │ Taproom    [=====-----] 5 units   -> $209 est.     │     │
│  │ Local Bars [==========-] 9 units  -> $264 est.     │     │
│  │ Retail     Locked                                  │     │
│  │ Events     Locked                                  │     │
│  └────────────────────────────────────────────────────┘     │
│                                                             │
│  ┌──────────────────────────────────────────────────┐       │
│  │  PROJECTED REVENUE          $473                 │       │
│  │  (4 unsold units wasted)                         │       │
│  └──────────────────────────────────────────────────┘       │
│                                                             │
│                                        [Confirm Sale]       │
└─────────────────────────────────────────────────────────────┘
```

### Revenue Breakdown (in ResultsOverlay after sale)
```
Revenue Breakdown:
  Taproom (5 units x $220 x 1.0x)    +$209
  Local Bars (9 units x $220 x 0.7x) +$264
  Unsold (4 units)                      -
  ─────────────────────────────────────────
  Total Revenue                       +$473
  Balance                            $2,923
```

## Interaction Notes

- Price slider snaps to 5% increments (-30% to +50%)
- Channel allocation uses +/- buttons or sliders, total cannot exceed batch size
- Projected revenue updates in real-time as player adjusts
- Unsold units shown with muted text as waste feedback
- Trend toast notifications appear at start of turn when trend changes
- Season name shown in hub header alongside stage name

## Color Tokens (existing palette)

- Demand up: #5EE8A4 (success green)
- Demand down: #FF7B7B (danger red)
- Trending badge: #FFC857 (accent gold)
- Saturation bar: #FFB347 (warning orange)
- Locked channel: #8A9BB1 (muted)
