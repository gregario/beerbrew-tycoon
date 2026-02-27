# Brewing Process Research — How to Brew (Palmer) + Industry Sources

## Source
Based on "How to Brew" by John J. Palmer (4th ed, Brewers Publications) and AHA/industry references.

## Canonical Brewing Flow

1. Pre-brew prep (water, milling, sanitize, yeast prep)
2. Mashing (convert starches → sugars)
3. Lautering/sparging (separate wort from grain)
4. Boil (hop additions, evaporation, sterilization, kettle chemistry)
5. Whirlpool / hop stand / trub separation
6. Rapid cooling (chillers) → transfer to fermenter
7. Pitch yeast / oxygenate → primary fermentation (active)
8. Conditioning/secondary (diacetyl rest, dry hopping, cold crash)
9. Packaging: bottling (priming) or kegging/canning (force carbonation)
10. Cellaring / dispense / QA

## Game Loop Mapping

- **Short loop** = brew day & primary fermentation (hours → days)
- **Medium loop** = packaging & first tasting (2–4 weeks for ales)
- **Long/meta loop** = recipe learning, yeast lineage, water profile mastery, equipment upgrades

## Mashing Parameters

- Single infusion: 148–156°F (64–69°C) — lower = more fermentable, higher = fuller body
- Time: 45–90 minutes
- Water-to-grist ratio affects enzyme activity
- Methods: single infusion, step mash, decoction
- Alpha-amylase & beta-amylase windows: 62–65°C for fermentable; 66–69°C for body

## Boil Parameters

- Duration: 60–90 minutes
- Hop schedule: bittering (60 min), flavor (15–30 min), aroma (0–10 min / whirlpool / dry hop)
- Additives: Irish moss, Whirlfloc, kettle sugar

## Fermentation Parameters

- Ales: ~18–22°C; lagers: lower
- Pitch rate: ~0.75–1.5 million cells/mL/°Plato for ales
- Oxygenation: ~8–10 ppm DO for ales
- Temperature is THE major flavor control point

## Equipment Tiers (Progression Ladder)

1. **Extract kit** — kettle, fermenter, capper, sanitizer, hydrometer. Low cost/skill.
2. **BIAB (brew in a bag)** — single vessel all-grain. Low equipment cost.
3. **Two-vessel** — HLT + mash tun or mash tun + kettle. Sparge control, higher efficiency.
4. **Three-vessel (HLT / Mash Tun / Boil Kettle) with pumps** — recirculation, higher throughput.
5. **Electric all-in-one** (Anvil, Unibrau) — PID temp control, integrated heating.
6. **Conical stainless fermenters** — yeast harvesting, closed transfers.
7. **Nano/micro commercial** — 1–30 BBL; CIP, glycol, automation/PLC.

## Ingredients

### Grains/Malts
- Base malts (Pilsner, Pale, Maris Otter) — main fermentable sugars
- Specialty malts (Crystal, Chocolate, Roasted) — color, flavor, body
- Adjuncts (flaked oats, corn, rice) — head retention, mouthfeel

### Hops
- Alpha acid % (bittering), oil profile (aroma)
- Families: Czech noble, British, American (Citra/Cascade/Simcoe), New World
- Forms: whole-cone, pellet, plug

### Yeast
- Ale strains, lager strains, kveik, saison, Brettanomyces
- Pitch rate math & viability
- Lactobacillus / Pediococcus for sours

### Water & Salts
- Ca, Mg, Na, SO4, Cl, HCO3 — flavor and mash pH effects
- Target mash pH 5.2–5.6

### Additives
- Priming sugar, clarifying agents, finings, fruit, spices, wood chips

## Quality Checkpoints

- Pre-boil gravity (efficiency check)
- Mash pH 5.2–5.6 (wrong pH → tannin extraction)
- Boil vigor/time (short boil → DMS)
- Fermentation temp drift → off-flavors (esters, fusel alcohols)
- Final gravity stability before packaging (early packaging → bottle bombs)
- Sanitation quality → infection probability

## Common Failure Modes

- Poor sanitation → bacterial infection (sour flavors)
- Under/overpitching → stressed yeast → off-flavors, stalled fermentation
- Fermentation temp swings → esters/fusel alcohols
- Slow cooling → DMS & haze
- Tannin extraction (sparge too hot / pH too high)
- Improper priming → over/under carbonation

## Designable Game Knobs

- Sanitation quality: reduces infection chance
- Fermentation control: temp rigs → lower off-flavors, faster turnaround
- Mash precision: narrower ABV variance, more consistent color
- Hop utilization tech: maximize aroma with less alpha acid
- Yeast tech: starters & repitching → saves cost (requires conicals)
- Packaging tech: bottling vs kegging vs canning (capital vs margin)
- Scale: batch size multiplier with nonlinear cost/risk

## Scaling Realities

- Efficiency rises with equipment + technique; complexity and fixed costs increase
- Time-to-market shortens with automation but capital cost increases
- Yeast/sanitation requirements increase with batch size — contaminated big-batch = big loss

## Data Model Fields

- ProcessStep: {id, name, inputs[], outputs[], duration_min, temp_range_C, critical_checks[], failure_modes[], required_equipment[]}
- Equipment: {id, name, tier, capacity_liters, cost, automation_level, maintenance_per_batch}
- Ingredient: {id, type, unit_cost, storage_life_days, parameters[]}
- YeastProfile: {strain, ideal_temp_range_C, attenuation_pct, flocculation, starter_required}
- WaterProfile: {ca, mg, na, so4, cl, hco3, pH}
- QA_Check: {name, acceptable_range, sample_method, timepoint, consequence_if_fail}
