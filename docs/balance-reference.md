# BeerBrew Tycoon — Balance Reference

## Economy Flow

Starting balance: $500
Win conditions:
- Default: $10,000 balance
- Artisan: 5 medals + 100 reputation
- Mass-Market: $50,000 revenue + 4 channels
Loss condition: Balance < $50

## Revenue Per Brew (approximate)

Base price: $180-$350 per style
Quality multiplier: 0.5x (Q=0) to 2.0x (Q=100)
Batch size: 10 units (20 with mass-market)
Channel margins: taproom 1.0x, bars 0.7x, retail 0.5x, events 1.5x
Demand multiplier: 0.3x-3.0x (seasonal + trend + brand)

Typical early revenue (Q=50, taproom only): 10 × $200 × 1.0 × 1.0 = $2,000
Typical mid revenue (Q=70, 2 channels): ~$3,000-5,000
Typical late revenue (Q=85, 3 channels + trend): ~$8,000-15,000

## Costs Per Turn Cycle (4 turns)

Ingredients: $50-200 per brew × 4 = $200-800
Rent: $150 (garage) to $800 (mass-market)
Staff salaries: $0-400 (0-4 staff)
Equipment: one-time $60-3,500
Training: $200 per session
Competition entry: $100-300
Market research: $100

## Progression Pace

Garage → Microbrewery: ~turn 10-15 ($5,000 + 10 beers, costs $3,000)
Microbrewery → Fork: ~turn 25-35 ($15,000 + 25 beers)
Default win: ~turn 30-50
Artisan win: ~turn 50-80 (5 medals + 100 rep takes time)
Mass-market win: ~turn 40-60 ($50k revenue + channels)

## Research Pace

RP per brew: 2 + quality/20 = 2-7 RP
Total tree cost: ~450 RP
Full tree completion: ~70-120 brews (unrealistic in one run)
Typical run unlocks: 5-10 nodes

## Meta-Progression

Unlock points per run: 0-25 (37 with challenge modifier)
Unlock costs: 3-12 UP per item
Perk impacts: +5% cash, +1 RP, -10% rent, +5% quality
Modifier impacts: ±20% demand, 0.5x cash, +10% quality, 5-brew immunity, 60% ingredients

## Key Ratios

Revenue/cost per brew: ~2:1 early, ~5:1 late (healthy margin growth)
Rent as % of revenue: ~30% early (tight), ~5% late (manageable)
Equipment ROI: T2 equipment pays back in 3-5 brews
Research ROI: Each node takes 3-10 brews to afford, unlocks significant capability

---

## Quality Scoring System (7 Components)

Final quality = weighted sum of 7 components, clamped 0-100:

| Component      | Weight | Description                                     |
|----------------|--------|-------------------------------------------------|
| Style Match    | 25%    | ratio_score*0.5 + ingredient_score*0.5          |
| Fermentation   | 25%    | Yeast-temp accuracy, flavor compounds, stability |
| Science        | 15%    | Mash temp + boil duration vs style ideals        |
| Water          | 10%    | Water profile affinity to style (default tap=60) |
| Hop Schedule   | 10%    | Hop allocation match to style expectations       |
| Novelty        | 10%    | Repeat penalty: -15% per repeat, floor 40%       |
| Conditioning   |  5%    | +25 per week, max 100 (4 weeks)                  |

### Fermentation Sub-Components

Fermentation score (25% of final) = weighted average of three sub-components:

- **Accuracy (40%)**: Yeast-temp accuracy from BrewingScience.calc_yeast_accuracy(). How close fermentation temp is to the yeast's ideal range.
- **Flavor Compounds (40%)**: Match between yeast-temp flavor compound output (esters, phenols, etc.) and the style's desired flavor profile (`yeast_temp_flavors`). Default 0.7 if no yeast or no style data.
- **Temperature Stability (20%)**: Default 0.6. Equipment with `ferment_temp_control` bonus sets this to 1.0.

### Water Scoring

- No water profile (tap water): default 60/100
- With WaterProfile resource: `affinity = water_profile.get_affinity(style_id)` mapped to 0-100
- Water profiles: soft, balanced, malty, hoppy, juicy (each style has per-profile affinity 0.0-1.0)

### Hop Schedule Scoring

- No allocations: default 50/100
- No style expectations: default 70/100
- With allocations: count of hops allocated to slots matching style expectations / total hops * 100
- Slots: bittering, flavor, aroma, dry_hop

### Conditioning Bonus

- 0-4 weeks, +25 points per week (score 0-100, contributes 5% of final)
- Quality bonus: +1% per week applied directly to final_score
- Cost: weeks * (rent / 4) — proportional to current rent
- Off-flavor decay applied during conditioning (see below)

## Off-Flavor Spectrum

Off-flavors use float intensities (0.0-1.0), not binary flags:

| Off-Flavor      | Cause                    | Risk Factor           |
|-----------------|-------------------------|-----------------------|
| Esters          | High ferment temp        | base_risk * 0.6       |
| Fusel Alcohols  | Very high ferment temp   | base_risk * 0.4 (>0.3)|
| DMS             | Short boil               | base_risk * 0.3       |
| Diacetyl        | Rushed fermentation      | base_risk * 0.5       |
| Oxidation       | Oxygen exposure + batch  | base_risk * 0.3 + batch |
| Acetaldehyde    | Premature packaging      | base_risk * 0.3 (>0.2)|

Base risk = max(0, (100 - temp_control_quality) / 100).

### Conditioning Decay Rates (per week)

| Off-Flavor      | Decay Rate | Weeks to Clear (from 0.5) |
|-----------------|------------|--------------------------|
| Diacetyl        | 0.25/wk    | 2 weeks                  |
| Acetaldehyde    | 0.15/wk    | ~3.3 weeks               |
| Fusel Alcohols  | 0.10/wk    | 5 weeks                  |
| Esters          | 0.05/wk    | 10 weeks                 |
| DMS             | 0.05/wk    | 10 weeks                 |
| Oxidation       | 0.00/wk    | Never (permanent)        |

### Severity Labels

- **Subtle** (intensity < 0.3): minor impact
- **Noticeable** (0.3-0.6): moderate impact
- **Dominant** (> 0.6): severe impact

### Style Acceptability

Each style defines `acceptable_off_flavors` thresholds. Off-flavor intensity at or below threshold = "desired", up to +0.15 above = "neutral", beyond = "flaw". Penalty = excess * 25 points per type.

## Research Tree

31 nodes across 4 categories:

| Category    | Nodes | Examples                                              |
|-------------|-------|-------------------------------------------------------|
| Techniques  | 16    | mash_basics, water_basics, advanced_water, ph_management, hop_timing, dry_hopping, yeast_health, temp_profiling, wild_fermentation |
| Ingredients |  4    | american_hops, premium_hops, specialist_yeast, specialty_malts |
| Equipment   |  4    | homebrew_upgrades, adjunct_brewing, semi_pro_equipment, pro_equipment |
| Styles      |  7    | ale_fundamentals, lager_brewing, dark_styles, wheat_traditions, ipa_mastery, belgian_arts, modern_techniques |

RP per brew: 2 + quality/20 (range 2-7).

## Measurement Equipment

5 measurement items that unlock progressive quality feedback:

| Item                | Effect                                           |
|---------------------|--------------------------------------------------|
| Thermometer         | Basic mash/ferment temperature readings           |
| Digital Thermometer | Precise temperature with decimal accuracy          |
| pH Meter            | Water and mash pH measurement                     |
| Refractometer       | Real-time gravity readings during brew             |
| Water Kit           | Full water chemistry analysis for profile matching |
