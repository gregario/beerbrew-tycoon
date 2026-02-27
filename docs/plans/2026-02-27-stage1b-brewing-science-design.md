# Stage 1B: Brewing Science — Design Document

## Scope

Stage 1B adds brewing science calculations, garage-appropriate slider UI, a taste skill system, and a basic discovery mechanic. The player sees real physical inputs (temperatures, times) but must learn through brewing what those inputs do to the beer.

### In Scope
1. Brewing science engine (under the hood)
2. Garage-feel slider UI with real units and discrete stops
3. Taste skill foundation (general + per-style)
4. Taste-gated results feedback
5. Basic discovery system (attribute + process attribution)

### Out of Scope (captured in `design/future-vision.md`)
- Equipment-driven UI reveals (later stages)
- Training courses for taste skill
- Brewing journal / book
- Quality bubble animations (Game Dev Tycoon style)
- Meta-progression carry-over
- Historical decade theming

---

## 1. Brewing Science Engine

All calculations happen under the hood. The player sets real physical parameters but doesn't know the optimal values until taste skill and discoveries reveal them.

### Mashing — Temperature Control
- Slider range: **62°C to 69°C**, step: **1°C** (8 discrete stops)
- Default: 65°C (midpoint)
- Fermentability curve: `0.82 - ((temp - 62) / 7.0 * 0.25)`
  - 62°C → 0.82 fermentability (dry, crisp)
  - 69°C → 0.57 fermentability (full, sweet)
- Style compatibility: each BeerStyle has an `ideal_mash_temp` (e.g., Stout: 67-69°C, Lager: 62-64°C)
- Scoring: distance from ideal range penalizes quality

### Boiling — Duration
- Slider range: **30 min to 90 min**, step: **10 min** (7 discrete stops)
- Default: 60 min
- Hop utilization: `alpha_acid_pct * (duration / 90.0)` — longer boil = more bittering
- Aroma retention: `1.0 - (duration / 90.0)` — shorter boil = more aroma
- Style compatibility: each BeerStyle has an `ideal_boil_range` (e.g., IPA: 60-90 min for bittering, Wheat: 30-50 min for aroma)

### Fermenting — Temperature Control
- Slider range: **15°C to 25°C**, step: **1°C** (11 discrete stops)
- Default: 20°C
- Compared against yeast's `ideal_temp_min_c` and `ideal_temp_max_c`
- Quality scoring:
  - Within ideal range: 1.0 bonus, clean profile
  - 1-2°C outside: 0.85 bonus, mild off-notes
  - 3°C+ above: 0.6 bonus, ester/fusel off-flavor tags added
  - 3°C+ below: 0.6 bonus, slow fermentation / stalling risk tag

### Stochastic Noise
- ±5% random variation on fermentability, hop utilization, and yeast accuracy
- Applied multiplicatively: `value * randf_range(0.95, 1.05)`
- Per-brew seed for test reproducibility: `seed(brew_turn_number)`

### Equipment-Driven Noise
- `temp_control_quality` (default: 50 for garage) determines temperature drift
- Drift magnitude: `±(100 - quality) / 25`°C
  - Garage (50): ±2°C drift from set temp
  - Good equipment (75): ±1°C
  - Excellent (100): ±0°C
- Applied to mash temp and ferment temp before calculations

---

## 2. Slider UI Design

### Layout Changes
```
┌─────────────────────────────────────────┐
│  BREWING PHASES                         │
│  ─────────────────────────────────────  │
│  Set your brewing parameters.           │
│                                         │
│  MASHING                                │
│  Mash Temperature                       │
│  62°C ──●──┼──┼──┼──┼──┼──┼── 69°C     │
│              65°C                       │
│                                         │
│  BOILING                                │
│  Boil Duration                          │
│  30m ──┼──┼──●──┼──┼──┼── 90m          │
│            60 min                       │
│                                         │
│  FERMENTING                             │
│  Fermentation Temperature               │
│  15°C ──┼──┼──●──┼──┼──┼──┼──┼──┼── 25°C│
│             18°C                        │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │ Flavor: 75    Technique: 75     │    │
│  └─────────────────────────────────┘    │
│                            [ Brew! ]    │
└─────────────────────────────────────────┘
```

### Specific Changes from Current UI
- **Phase subtitles**: "(Technique-heavy)" etc. → physical parameter names ("Mash Temperature", "Boil Duration", "Fermentation Temperature")
- **Slider ranges**: 0-100 → real physical ranges (62-69, 30-90, 15-25)
- **Slider step**: continuous → discrete (1°C or 10 min)
- **Value labels**: plain "50" → "65°C" / "60 min" / "18°C"
- **Min/max labels**: new Labels at each end of slider showing range bounds
- **Tick marks**: visual tick marks on slider track (Godot HSlider `tick_count` + `ticks_on_borders`)
- Preview panel (Flavor/Technique) remains unchanged

### Scene Tree Changes (BrewingPhases.tscn)
- Add `MashingMin` and `MashingMax` Labels flanking slider
- Add `BoilingMin` and `BoilingMax` Labels flanking slider
- Add `FermentingMin` and `FermentingMax` Labels flanking slider
- Change slider rows from VBox to nested HBox (min label | slider | max label) + value below
- Update slider properties: min_value, max_value, step, tick_count

---

## 3. Taste Skill System

### Data Model
```
# On GameState
var general_taste: int = 0
var style_taste: Dictionary = {}  # { "IPA": 2, "Stout": 0 }
```

### Progression
- `general_taste` increments by 1 after each brew
- `style_taste[style]` increments by 1 after brewing that style
- No cap for now (future: equipment/training accelerates growth)
- No training courses in 1B (future work)

### Feedback Tiers

| general_taste | Feedback Depth | Example Output |
|---|---|---|
| 0 | Near-zero insight | "Your friends try it... 'It's definitely beer!'" |
| 1 | One vague descriptor | "Seems kinda bitter." |
| 2 | Two descriptors + body | "Hoppy with a light body. Not bad." |
| 3 | Flavor tags + one process hint | "Citrusy hops, clean finish. The fermentation temp felt right." |
| 4 | Full tasting notes + process links | "Bright citrus aroma, crisp dry body from the low mash temp. Clean fermentation — your yeast was happy." |
| 5+ | Phase-by-phase breakdown | "Mash at 63°C gave excellent fermentability. 60-min boil extracted good bitterness from Cascade. Fermentation at 19°C was dead center for US-05." |

Style taste adds bonus detail for that specific style (at style_taste 2+: "This is a solid IPA" vs "This beer is... something").

### UI Treatment (ResultsOverlay)
- Add "Tasting Notes" text block below quality score / star rating
- Text generated from taste level + brewing science outputs + discovered attributes
- Caption: "Your palate: Novice (Lv 2)" — text description scales with level
- Palate level names: Novice (0-1), Developing (2-3), Experienced (4-5), Expert (6+)

---

## 4. Discovery System

### Mechanic: Two Chance Rolls Per Brew

**Roll 1 — Attribute Discovery**
- Trigger: after every brew
- Base chance: `20% + (general_taste * 5%)`
  - Taste 0: 20%, Taste 4: 40%, Taste 8: 60%
- On success: player discovers one undiscovered flavor attribute from the brew's output
- Notification: toast — "You noticed something... this beer has a **citrusy aroma**."
- Only discovers attributes actually present in the current brew's science output

**Roll 2 — Process Attribution**
- Trigger: only if player has discovered attributes
- Base chance: `10% + (style_taste[current_style] * 5%)`
- On success: links a discovered attribute to the brewing step that caused it
- Notification: toast — "**Citrus aroma** seems to come from **shorter boil times** with aromatic hops."
- This is the "good combo" — once linked, it becomes a persistent hint

### Data Model
```
# On GameState
var discoveries: Dictionary = {}
# Structure:
# {
#   "citrus_aroma": {
#     "discovered": true,
#     "linked_to": "",          # or "boiling"
#     "linked_detail": ""       # or "short boil + aromatic hops"
#   }
# }
```

### Discovery Pool

| Category | Attribute Key | Display Name | Linked To | Link Detail |
|---|---|---|---|---|
| Body | dry_body | Dry Body | mashing | low mash temperature |
| Body | crisp_body | Crisp Body | mashing | low-mid mash temperature |
| Body | medium_body | Medium Body | mashing | moderate mash temperature |
| Body | full_body | Full Body | mashing | high mash temperature |
| Body | sweet_body | Sweet Body | mashing | very high mash temperature |
| Bitterness | low_bitter | Low Bitterness | boiling | short boil time |
| Bitterness | balanced_bitter | Balanced Bitterness | boiling | moderate boil time |
| Bitterness | assertive_bitter | Assertive Bitterness | boiling | long boil time + high alpha hops |
| Aroma | floral_aroma | Floral Aroma | boiling | short boil + floral hop variety |
| Aroma | citrus_aroma | Citrus Aroma | boiling | short boil + citrus hop variety |
| Aroma | piney_aroma | Piney Aroma | boiling | short-mid boil + piney hop variety |
| Aroma | earthy_aroma | Earthy Aroma | boiling | any boil + earthy hop variety |
| Aroma | spicy_aroma | Spicy Aroma | boiling | short boil + spicy hop variety |
| Fermentation | clean_ferment | Clean Fermentation | fermenting | temp within yeast ideal range |
| Fermentation | fruity_esters | Fruity Esters | fermenting | temp above yeast ideal range |
| Fermentation | fusel_alcohols | Fusel Alcohols | fermenting | temp well above yeast ideal range |
| Fermentation | stalled_ferment | Stalled Fermentation | fermenting | temp below yeast ideal range |

### Where Discoveries Appear
- **ResultsOverlay**: discovered attributes highlighted in tasting notes (bold or accent color)
- **BrewingPhases**: once a process link is discovered, a small hint icon (info circle) appears next to the relevant slider — tooltip shows learned link on hover (future enhancement)
- Full "good combo" overlay markers deferred to equipment upgrade stages

---

## 5. Integration Points

### GameState Changes
- Add: `general_taste: int = 0`
- Add: `style_taste: Dictionary = {}`
- Add: `discoveries: Dictionary = {}`
- Add: `temp_control_quality: int = 50`

### QualityCalculator Changes
- Add brewing science scoring component (fermentability match, hop utilization, yeast accuracy)
- Apply equipment-driven temperature noise before calculations
- Apply ±5% stochastic noise to outputs
- Generate flavor attribute tags based on brewing outputs (for discovery system)

### BrewingPhases Changes
- Slider ranges, steps, labels as specified in Section 2
- Scene tree restructure for min/max labels

### ResultsOverlay Changes
- Add tasting notes text block
- Add palate level caption
- Highlight discovered attributes

### Toast System
- Discovery notifications use existing toast system
- Two new toast types: attribute_discovered, process_linked
