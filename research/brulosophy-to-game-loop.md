# Brulosophy Findings → Game Loop Mapping

How each real-world Brulosophy experiment finding translates into a concrete game mechanic, discovery moment, or design decision within BeerBrew Tycoon's turn-by-turn loop.

---

## The Core Insight

Brulosophy's 300+ experiments revealed a counter-intuitive truth: **most of what brewers obsess over doesn't measurably affect the beer.** Only ~30% of tested variables produced a statistically significant difference in blind triangle tests.

This is not a limitation — it's the **entire game design philosophy.**

The game should present the player with a wall of apparent complexity (just like real brewing forums do to new brewers), then reward them for discovering — through their own experimentation — which variables actually move the needle. The journey from "everything matters and I'm overwhelmed" to "I know exactly which 3 things to focus on" IS the skill curve.

This maps to Game Dev Tycoon's core loop: early on, you don't know which genre/topic/platform combos work. You experiment, fail, learn. Eventually you develop intuition. The difference: in GDT the combos are arbitrary. In BeerBrew, they're based on real brewing science. **The player is actually learning to brew.**

---

## CRITICAL DESIGN PRINCIPLE: The 70% Must Be Played, Not Skipped

The Brulosophy finding that ~70% of variables don't matter is a finding FOR US AS DESIGNERS — it tells us how to weight our scoring systems. **It is NOT something the player starts knowing.** The player must discover this through gameplay.

This means:

### Every variable must FEEL like it matters at first

The game must present ALL brewing variables — mash temp, boil length, mash method, cooling, pitch rate, vessel type, etc. — as if they are all equally important. The UI should not hint at which ones matter. Sliders should all look the same. No tooltips saying "this doesn't affect much." The brewing forums, recipe books, and conventional wisdom that new brewers encounter IRL all say "you MUST do X, Y, Z" — the game should create that same pressure.

The player's early experience should feel like: "There are 12 things to get right and I don't know which ones are important." Just like a real new brewer reading their first homebrew book.

### Discovery of irrelevance IS the progression

When a player brews two beers — one with a 20-minute mash and one with a 60-minute mash — and they taste the same, **that is an earned discovery.** It cost them time, ingredients, and a brew slot to run that experiment. The reward is efficiency: they now know they can save time/money on mash length and spend that budget on things that actually matter (better yeast, fermentation control, water chemistry).

This is the roguelite knowledge loop:
- **Run 1:** Player carefully does everything "by the book." Gets decent beer. Doesn't know WHY it was decent
- **Run 2:** Player changes one variable (shorter boil). Same result. "Huh, that didn't matter?"
- **Run 3:** Player changes fermentation temp by 5°C. HUGE difference. "THAT matters!"
- **Run 4:** Player has learned: focus on fermentation, don't sweat boil length. Better beer with less effort
- **Run N:** Player has a mental model of brewing that matches reality. They are genuinely skilled

### The "doesn't matter" variables are TRAPS (in a good way)

Optimization-minded players will try to perfect everything. The game should let them waste time on mash precision and decoction mashing — then reward them when they eventually discover it wasn't worth the effort. This creates a satisfying "aha" that ONLY works if the game first convinced them it mattered.

Think of it like GDT's genre/topic combos: some combos are bad, but you don't know which until you've tried them. The TRYING is the game. The LEARNING is the reward.

### The 30% that DOES matter should hit HARD

When the player finally discovers that fermentation temperature, water chemistry, or yeast strain dramatically changes their beer, the impact should be viscerally obvious — a big score jump, a noticeable tasting note change, a visual difference in the bubble animation. This contrast with the "meh, same thing" result of tweaking mash length makes the real discoveries feel genuinely exciting.

The asymmetry is the point: lots of small "doesn't matter" discoveries punctuated by rare, powerful "THIS matters" discoveries. Like real brewing. Like real science.

### Meta-progression preserves discoveries

In a roguelite, knowledge persists between runs even when resources don't. A player who has discovered "mash length doesn't matter" in Run 1 should carry that knowledge into Run 2 — perhaps as a journal entry, an unlocked shortcut, or a research node that starts pre-completed. They don't have to re-learn it. But they DO have to discover new things (water chemistry, dry hopping, yeast manipulation) in each subsequent run.

The 70% "doesn't matter" discoveries are EARLY-RUN content. They're what you learn in the first 10-20 brews. The 30% "does matter" discoveries are MID-TO-LATE content. And the style-specific exceptions ("...except for pilsner malt") are EXPERT content that keeps even experienced players learning.

---

## Category 1: Things That DON'T Matter (The "Relax" Discoveries)

These are the ~70% of Brulosophy experiments where tasters couldn't tell the difference. In game terms, these are **efficiency discoveries** — the player learns they can skip/shortcut these without penalty, freeing up resources (time, money, attention) for what actually matters. **But they must EARN these discoveries by experimenting, not be handed them.**

### 1.1 Mash Temperature (Moderate Differences)

**Brulosophy Finding:** 65°C vs 67°C — tasters cannot reliably distinguish. Only extreme differences (62°C vs 69°C) produce noticeable results.

**Current Game:** Mash slider 62-69°C. Science score penalizes any deviation from style's ideal range (distance / 7.0 penalty). Every degree matters equally.

**Proposed Change:** Introduce a **"close enough" zone** around the style's ideal.

| Deviation from ideal | Score Impact | Discovery |
|---------------------|-------------|-----------|
| 0-2°C off | Full score (no penalty) | "Mash temp doesn't need to be exact — close enough works!" |
| 2-4°C off | Mild penalty (linear) | Normal behavior |
| 4+°C off | Steep penalty | "Big mash temp changes really affect body" |

**Game Loop Impact:**
- **Early game:** Player agonizes over exact mash temp (like a real beginner)
- **Discovery moment:** After 5-10 brews, TasteSystem reveals: "Your last two beers used 65°C and 67°C mashing — they taste identical." Toast notification
- **Efficiency gain:** Player stops micro-optimizing mash temp, focuses attention on things that matter
- **Meta-learning:** Player literally learns the Brulosophy finding through gameplay

**Implementation:** Modify `BrewingScience.calc_mash_score()` to have a flat "1.0" zone within ±2°C of ideal, then ramp penalty beyond that.

---

### 1.2 Mash Length (Duration)

**Brulosophy Finding:** 20-minute mash vs 60-minute mash — no significant difference. Conversion happens fast.

**Current Game:** No mash length mechanic (mash is just a temp slider).

**Proposed Mechanic:** If/when the game adds process time as a resource (turns, brew day length), mash duration should be a discoverable shortcut.

**Game Loop Impact:**
- **Default:** Game implies a 60-minute mash (standard advice everywhere)
- **Discovery:** After unlocking "Advanced Mashing" research, player can try short mashes
- **Result:** Short mash produces identical quality → discovery toast: "A 20-minute mash works just as well! You saved time."
- **Efficiency gain:** Shorter brew day = lower cost per brew or ability to double-batch

**Why this matters for game design:** This teaches the player that conventional wisdom isn't always right — a core theme of the Brulosophy philosophy and a satisfying game moment.

---

### 1.3 Boil Length

**Brulosophy Finding:** 30-minute boil vs 90-minute boil — no significant difference for most malts. Exception: pilsner malt has higher DMS precursors, so short boils are riskier there.

**Current Game:** Boil slider 30-90 min. Score penalized by distance from style ideal / 60.0.

**Proposed Change:** Similar "close enough" zone, PLUS a pilsner malt exception.

| Scenario | Score Impact |
|----------|-------------|
| Any boil 45-90 min with non-pilsner base malt | Minimal difference (flat zone) |
| Boil < 45 min with pilsner malt | DMS risk increases significantly |
| Boil < 45 min with other base malts | Small DMS risk only |
| 90+ min boil | Marginal color/flavor development (diminishing returns) |

**Game Loop Impact:**
- **Early game:** Player follows "always boil 60 minutes" advice
- **Discovery:** After experimenting with short boils: "A 30-minute boil tastes the same as 90 minutes with this malt!"
- **Exception discovery:** Using pilsner malt with a short boil → DMS off-flavor → "Pilsner malt needs a longer boil to drive off DMS"
- **Skill expression:** Experienced player knows WHICH malts need long boils and which don't

**Implementation:** Modify `BrewingScience.calc_boil_score()` to check base malt type. Add `dms_risk` property to malt resources. Pilsner malt gets `dms_risk: 0.8`, pale malt gets `dms_risk: 0.2`.

---

### 1.4 Decoction vs Single Infusion Mash

**Brulosophy Finding:** Triple decoction (complex, time-consuming) vs single infusion (simple) — rarely significant. Maybe a tiny "something" but not worth the effort.

**Current Game:** No mash method mechanic.

**Proposed Mechanic:** Unlockable via research. A "mash method" dropdown: Single Infusion (default) / Step Mash / Decoction.

| Method | Time Cost | Quality Bonus | Discovery |
|--------|----------|--------------|-----------|
| Single Infusion | 1x (baseline) | 0 | Default |
| Step Mash | 1.5x | +1-2% (marginal) | "Slightly more complex flavor, but barely noticeable" |
| Decoction | 2x | +2-3% (marginal) | "Traditional brewers swear by it, but it barely matters" |

**Game Loop Impact:** This is a **trap for optimization-minded players.** The time/cost of decoction barely justifies the quality gain. The smart player discovers it's not worth it for most styles — UNLESS they're brewing a traditional Czech Pilsner or German Bock where the +2-3% might win a competition by 1 point.

**The lesson:** Sometimes the "better" technique isn't worth the cost. Resource optimization > perfectionism.

---

### 1.5 No-Chill (Overnight Cooling)

**Brulosophy Finding:** Rapid chilling vs leaving wort to cool overnight — often not significant.

**Current Game:** No cooling mechanic.

**Proposed Mechanic:** Equipment-gated. Early game = no-chill (default, free). Later = immersion chiller, plate chiller.

| Method | Equipment | Cost | Infection Risk | DMS Risk |
|--------|----------|------|---------------|----------|
| No-chill | None (default) | Free | +5% infection | +10% DMS (with pilsner malt) |
| Immersion chiller | T2 equipment | $150 | +2% | +2% |
| Plate chiller | T3 equipment | $400 | +0% | +0% |

**Game Loop Impact:**
- **Early game:** Player has no chiller. Occasional DMS or infection
- **Discovery:** "Maybe I should chill faster..." → buys chiller → fewer off-flavors
- **Brulosophy twist:** The improvement is real but SMALL. Player who saves money by skipping the chiller isn't punished much. It's a marginal upgrade, not essential
- **This teaches:** Equipment upgrades help, but sanitation and fermentation control matter more

---

### 1.6 Yeast Pitch Rate (Normal Gravity)

**Brulosophy Finding:** Direct pitch (one packet) vs. yeast starter (calculated optimal cells) — often not significant for normal-gravity beers. Becomes significant for high-gravity beers.

**Current Game:** No pitch rate mechanic. Yeast is selected, not managed.

**Proposed Mechanic:** Yeast starter as an optional pre-brew step (costs a turn or money).

| Scenario | Effect |
|----------|--------|
| Direct pitch, normal OG (<1.060) | No penalty — works fine |
| Direct pitch, high OG (>1.060) | -10% quality, higher off-flavor risk |
| Yeast starter, any OG | Full quality, lower off-flavor risk |
| Under-pitch (reusing old yeast without starter) | Variable — sometimes fine, sometimes stressed fermentation |

**Game Loop Impact:**
- **Early game:** Player just picks yeast and ferments. Works fine for normal beers
- **Discovery:** Player tries an Imperial Stout (high OG) with direct pitch → off-flavors → "High gravity beers need more yeast"
- **Research unlock:** "Yeast Health" research node unlocks yeast starters
- **Efficiency discovery:** For normal beers, starters are unnecessary — player learns to save the cost/time

---

### 1.7 Fermentation Vessel

**Brulosophy Finding:** Plastic bucket vs glass carboy vs stainless conical — no significant taste difference.

**Current Game:** Fermentation equipment (bucket → carboy → temp chamber → conical) gives stat bonuses.

**Proposed Change:** The vessel itself shouldn't affect flavor. What matters is:
- **Temperature control** (fermentation chamber upgrade = the real quality leap)
- **Closed transfer** (conical = less oxidation at scale)
- **Convenience** (conical = yeast harvesting, dumping trub)

**Game Loop Impact:** Player discovers that the $30 plastic bucket makes beer that tastes the same as the $500 conical. The conical's value is in PROCESS (less oxidation, yeast reuse) not FLAVOR. This teaches the Brulosophy lesson: fancy equipment doesn't make better beer — temperature control does.

---

## Category 2: Things That DO Matter (The "Focus Here" Discoveries)

These are the ~30% where tasters COULD tell the difference. These should be the game's **primary skill expression levers** — the decisions that separate good players from great ones.

### 2.1 Fermentation Temperature (THE Big One)

**Brulosophy Finding:** Fermenting ale yeast at 50°F vs 68°F — SIGNIFICANT. This is consistently the most impactful variable they've tested. Temperature swings, extreme temps, and wrong temps for yeast type all produce noticeable differences.

**Current Game:** Ferment slider 15-25°C. Science score penalizes distance from yeast ideal range. Fermentation chamber is one of several equipment upgrades.

**Proposed Change:** Make fermentation temp THE dominant quality lever.

**Detailed Mechanic:**

```
Ferment Quality = base quality * temp_accuracy * temp_stability

temp_accuracy:
  Within yeast ideal range: 1.0
  1-2°C outside: 0.90 (mild ester/fusel shift)
  3-5°C outside: 0.70 (noticeable off-flavors)
  5+°C outside: 0.40 (dominant off-flavors)

temp_stability (based on equipment):
  No temp control: random ±3°C drift each brew (simulated)
  Basic control (fridge): ±1°C drift
  Digital controller: ±0.5°C drift
  Pro system: ±0.1°C drift

Drift effect: actual_temp = set_temp + random_drift
  → Off-flavors calculated from ACTUAL temp, not set temp
  → Player without temp control can't reliably hit targets
```

**Game Loop Impact:**
- **Early game (no temp control):** Player sets ferment to 18°C but actual temp drifts to 21°C → esters → "Why does my beer taste fruity?"
- **Discovery:** "Fermentation temperature seems unstable" → realizes they need a fermentation chamber
- **Equipment purchase:** Fermentation chamber = THE upgrade. Immediately noticeable quality improvement
- **Mastery:** Player learns each yeast has a sweet spot. Belgian yeast WANTS high temps (esters are desired). Lager yeast needs cold. Clean ale yeast is forgiving in the middle
- **Advanced play:** Player learns to manipulate temp intentionally. Start cool → ramp warm = clean start, then let yeast clean up diacetyl. This is real advanced brewing technique

**Why this should be dominant:** In real brewing, fermentation temperature control is the single biggest quality improvement a homebrewer can make. The game should reflect this. A player with a $30 thermometer and a $100 fermentation chamber will make better beer than a player with $2000 of brewing equipment but no temp control.

---

### 2.2 Water Chemistry (Chloride:Sulfate Ratio)

**Brulosophy Finding:** Adjusted vs unadjusted water — SIGNIFICANT (p=0.003 in one test). The chloride:sulfate ratio meaningfully shifts perception between malty and hoppy.

**Current Game:** No water mechanic at all.

**Proposed Full Mechanic:**

**Water Profile Selection (unlocked via "Water Science" research):**

| Profile | Cl:SO4 Ratio | Effect |
|---------|-------------|--------|
| Soft (Pilsen) | Low everything | Clean, delicate. Best for: pilsners, light lagers |
| Balanced | ~1:1 | Neutral. Works for anything. Default/safe |
| Malty (Dublin) | High Cl, low SO4 | Enhances malt sweetness, fullness. Best for: stouts, porters, amber |
| Hoppy (Burton) | Low Cl, high SO4 | Accentuates hop bitterness, dry finish. Best for: IPA, pale ale |
| Juicy (NEIPA) | High Cl, moderate SO4 | Soft, round, enhances juicy hops. Best for: NEIPA, wheat |

**Scoring Integration:**

```
water_match_score:
  Perfect match (right profile for style): 1.0 (+10% quality component)
  Neutral (Balanced profile): 0.7 (safe but not optimal)
  Wrong profile: 0.4 (actively hurts — hoppy water on a stout = harsh)
  No water treatment (pre-research): 0.6 (tap water is "whatever it is")
```

**Game Loop Impact:**
- **Early game:** No water awareness. Player uses tap water (invisible, no choice)
- **Research unlock:** "Water Treatment" → player sees water profile selector for the first time
- **First discovery:** Player tries "Hoppy" water on an IPA → score jumps → "The water made my IPA crisper and more bitter!"
- **Mistake discovery:** Player tries "Hoppy" water on a Stout → harsh, thin → "Wrong water for this style"
- **Mastery:** Player matches water to style instinctively. Like a real brewer adjusting minerals

**Why this is game-changing:** Water is the "hidden variable" of real brewing. Most beginners don't even know it matters. The moment the player discovers water chemistry is the game's biggest "aha" moment — just like in real brewing.

---

### 2.3 Yeast Strain Selection

**Brulosophy Finding:** Different yeast strains in the same recipe — ALWAYS significant. US-05 (clean) vs S-04 (English fruity) vs Belgian strains produce completely different beers from identical wort.

**Current Game:** 6 yeast strains with different attenuation, temp ranges, and flocculation. Ingredient compatibility scoring exists.

**Proposed Enhancement:** Make yeast the biggest flavor contributor (it is in real life).

**Yeast Character System:**

```
Each yeast produces "character compounds" based on ferment temp:

Clean Ale (US-05):
  At ideal temp (18-20°C): neutral (lets malt/hops shine)
  Warm (22+°C): mild fruitiness
  Cold (15°C): very clean but slow

English Ale (S-04):
  At ideal temp (18-20°C): fruity esters, slight malt enhancement
  Warm (22+°C): intense fruit, possible fusel
  Cold (16°C): restrained fruit, malty

Wheat (WB-06):
  At ideal temp (18-22°C): banana + clove balance
  Warm (24+°C): dominant banana (isoamyl acetate)
  Cold (16°C): dominant clove (4-vinyl guaiacol)
  THIS is a real discovery: temp controls banana vs clove in wheat beer

Belgian:
  At ideal temp (20-25°C): spicy phenols, fruity esters
  Warm (28+°C): intense pepper, bubble gum
  Cool (18°C): restrained, more like clean ale

Saison:
  At ideal temp (25-35°C): peppery, dry, complex
  HOTTER is BETTER for saison (unique among yeasts)
  Discovery: "Saison yeast loves heat — the opposite of everything else!"

Lager:
  At ideal temp (9-12°C): super clean, crisp
  Warm (15+°C): estery, defeats the purpose
  THIS teaches: lagers need cold fermentation (and equipment to do it)
```

**Game Loop Impact:**
- **Experiment 1:** Player brews Pale Ale with US-05 → clean, hop-forward
- **Experiment 2:** Same recipe with S-04 → fruity, rounder, different beer
- **Discovery:** "Different yeast completely changes the beer! The yeast IS the beer."
- **Wheat beer discovery:** Player adjusts ferment temp and gets banana vs clove → "Temperature controls which yeast flavors appear!"
- **Saison revelation:** Everything the player learned about "ferment cool for clean beer" is inverted. Saison wants it HOT. Mind-blown moment

---

### 2.4 Dry Hopping (Timing and Amount)

**Brulosophy Finding:** Dry hop timing (during ferment vs post-ferment) — often significant for hop-forward styles. Biotransformation (dry hopping during active fermentation) creates different character than cold-side dry hopping.

**Current Game:** No dry hopping mechanic.

**Proposed Full Mechanic (unlocked via "Dry Hopping" research):**

**Dry Hop Timing Options:**

| Timing | Character | Best For |
|--------|----------|----------|
| No dry hop | Bittering/boil character only | Traditional styles, lagers |
| Active ferment (biotransformation) | Juicy, fruity, tropical. Yeast transforms hop oils | NEIPA, modern IPA |
| Post-ferment (cold-side) | Raw hop aroma, dank, resinous | West Coast IPA, DIPA |
| Both (double dry hop) | Maximum hop intensity. Risk of vegetal/grassy | DIPA, Imperial IPA |

**Scoring:**

```
dry_hop_score (0-1.0, applies to hop-forward styles only):
  Style wants dry hops + correct timing: 1.0
  Style wants dry hops + wrong timing: 0.7 (still good, just not optimal)
  Style wants dry hops + no dry hop: 0.5 (missing expected aroma)
  Style doesn't want dry hops + player dry hops anyway: 0.8 (not harmful, just wasteful)
```

**Game Loop Impact:**
- **Pre-research:** No dry hop option. IPAs are decent but lack "that aroma"
- **Research unlock:** "Dry Hopping" → player can now add hops post-boil
- **First dry hop:** IPA aroma explodes → "THIS is what my IPA was missing!"
- **Biotransformation discovery:** Dry hop during active ferment → juicy/tropical → "The yeast transformed the hop oils into something different"
- **NEIPA unlock:** Can't truly make NEIPA without biotransformation dry hopping. The style REQUIRES the technique

---

### 2.5 Oxidation

**Brulosophy Finding:** Oxidation — ALWAYS significant, ALWAYS negative. Exposure to oxygen post-fermentation ruins beer with cardboard/stale flavors.

**Current Game:** No oxidation mechanic.

**Proposed Mechanic:** Oxidation risk scales with batch size and is mitigated by equipment.

```
oxidation_risk = base_risk * batch_size_factor * equipment_factor

base_risk: 0.05 (5% base chance of noticeable oxidation)
batch_size_factor:
  Small (garage): 1.0 (small batches, less exposure)
  Medium (micro): 1.5 (more transfers, more exposure)
  Large (commercial): 2.0 (multiple transfers, packaging)
equipment_factor:
  Open transfers (default): 1.0
  Siphon + minimal splash: 0.7
  Closed transfer (CO2 push): 0.3
  Full CO2 packaging line: 0.1

If oxidation triggers:
  Mild: -5% quality, "slight cardboard note"
  Moderate: -15% quality, "stale, papery"
  Severe: -30% quality, "wet cardboard, undrinkable when warm"
```

**Game Loop Impact:**
- **Early game:** Small batches, low risk. Oxidation rarely happens
- **Scaling up:** Player expands → starts getting "cardboard" off-flavor → "What changed? My recipe is the same!"
- **Discovery:** "Oxidation increases with batch size — I need closed transfers"
- **Equipment solution:** Kegging system + CO2 setup eliminates it
- **Teaches:** Scaling up introduces NEW problems that didn't exist at small scale. This is a real brewery challenge

---

### 2.6 Grain Bill Composition

**Brulosophy Finding:** Base malt choice and specialty malt percentages — significant. 100% pale malt vs 90% pale + 10% crystal = noticeably different.

**Current Game:** Multi-select ingredients with flavor profiles. No percentage control.

**Proposed Enhancement:** Add grain bill percentage sliders.

```
Instead of: "Select 1-3 malts" (binary in/out)
Try: "Build grain bill" with percentages

Example Stout grain bill:
  Pale Malt: 70% (base)
  Roasted Barley: 15% (roast character)
  Crystal 60: 10% (caramel sweetness)
  Flaked Oats: 5% (body, silkiness)

Percentage affects intensity of each malt's flavor contribution.
Too much specialty malt (>30%) = cloying, unbalanced
Too little base malt (<60%) = weak body, poor conversion
```

**Game Loop Impact:**
- **Early game:** Simple ingredient selection (current system) — good for learning basics
- **Research unlock:** "Recipe Design" research → percentage sliders appear
- **Discovery:** Player adds 30% chocolate malt → acrid, harsh → "Too much! Specialty malts are powerful in small amounts"
- **Mastery:** Player learns that 5-15% specialty malt is the sweet spot. Subtlety > excess
- **This matches reality:** Real recipes are very precise about percentages. 8% crystal vs 15% crystal is a meaningful difference

---

## Category 3: Style-Dependent Variables (The "It Depends" Discoveries)

These are Brulosophy findings where the result depends on context. These create the deepest game knowledge — the player learns that **brewing rules aren't universal, they're style-specific.**

### 3.1 Esters (Fermentation By-Products)

**Brulosophy Finding:** Esters from warm fermentation are a FLAW in a Lager but DESIRED in a Hefeweizen or Belgian.

**Game Mechanic:**

```
ester_level = f(yeast_type, ferment_temp, deviation_from_ideal)

Context scoring:
  Lager with high esters: PENALTY (wrong for style)
  Hefeweizen with high esters: BONUS (banana is the point)
  Belgian with moderate esters: BONUS (fruity complexity)
  Clean Pale Ale with esters: MILD PENALTY (unexpected)
```

**Game Loop Impact:**
- Player brews a lager at 20°C → "estery, fruity" off-flavor → penalty
- Player brews a Hefeweizen at 24°C → "lovely banana character" → bonus
- Discovery: "The same 'off-flavor' is a feature in another style!"
- This is a REAL aha moment for brewers and directly teaches style awareness

---

### 3.2 DMS and Boil Length (Malt-Specific)

**Game Mechanic:**

```
dms_risk = f(base_malt_type, boil_length)

Pilsner malt + 30 min boil: HIGH DMS risk (creamed corn)
Pilsner malt + 60+ min boil: LOW DMS risk
Pale malt + 30 min boil: MINIMAL DMS risk
Munich malt + 30 min boil: LOW DMS risk

Discovery: "Pilsner malt needs a longer boil — other malts don't"
```

---

### 3.3 Water Profile and Style Matching

**Game Mechanic:**

```
Same water can be perfect or terrible depending on style:

Burton water (high sulfate):
  + IPA/Pale Ale: EXCELLENT (accentuates hops)
  + Stout: TERRIBLE (thin, harsh, overly bitter)

Dublin water (high carbonate):
  + Stout: EXCELLENT (smooths roast, adds fullness)
  + Pilsner: TERRIBLE (muddy, alkaline)

Pilsen water (very soft):
  + Czech Pilsner: EXCELLENT (clean, delicate)
  + IPA: UNDERWHELMING (hops don't pop)
```

**Discovery chain:**
1. "Water chemistry matters" (first awareness)
2. "Different water profiles suit different styles" (style matching)
3. "I can use water to ENHANCE the style's strengths" (mastery)

---

## The Discovery Taxonomy

All of the above maps to a structured discovery system. Here's how discoveries tier:

### Tier 1: Awareness Discoveries (First 10 brews)
- "Sanitation prevents infection" (learn from first infected batch)
- "Temperature affects fermentation" (learn from first off-flavor)
- "Different malts taste different" (learn from first specialty malt)
- "Hops can be bitter OR aromatic" (learn from different hop additions)

### Tier 2: Relationship Discoveries (10-25 brews)
- "Mash temperature controls body/dryness"
- "Fermentation temp is MORE important than mash temp"
- "Yeast choice changes the entire beer"
- "Water chemistry is the hidden variable"

### Tier 3: Efficiency Discoveries — THE BRULOSOPHY TIER (25-50 brews)
- "Mash temp doesn't need to be exact — ±2°C is fine"
- "Short boils work for most malts"
- "Expensive fermenters don't make better beer than cheap ones"
- "Decoction mash isn't worth the extra effort"
- "Direct pitch works for normal gravity"
- "No-chill is fine if you're careful"

### Tier 4: Exception Discoveries (50+ brews)
- "...EXCEPT pilsner malt needs a long boil"
- "...EXCEPT high gravity needs a yeast starter"
- "...EXCEPT saison yeast wants HIGH temps"
- "...EXCEPT esters are GOOD in wheat beer"
- "...EXCEPT Burton water makes a terrible stout"

### Tier 5: Mastery Discoveries (Meta-progression)
- "I can manipulate banana vs clove in wheat beer via temperature"
- "Biotransformation dry hopping creates juicy character"
- "Ferment temp ramping cleans up diacetyl"
- "Water profile is the style's secret weapon"

---

## How This Maps to the Turn-by-Turn Loop

### Current Loop:
```
Market Check → Style Select → Recipe Design → 3 Sliders → Results → Sell → Equipment
```

### Enhanced Loop (with Brulosophy integration):

```
TURN START
│
├─ Market Check (unchanged)
│
├─ Style Select (more styles, each teaches a principle)
│
├─ Water Profile (NEW — if researched. Quick choice: Soft/Balanced/Malty/Hoppy/Juicy)
│   └─ Discovery potential: "Right water for right style"
│
├─ Recipe Design (enhanced)
│   ├─ Grain bill with percentages (if researched)
│   ├─ Hop selection with allocation: Bittering / Aroma / Dry Hop (NEW)
│   ├─ Yeast selection (more strains, temp range shown if equipment reveals it)
│   └─ Optional: Yeast starter checkbox (if researched, costs $)
│
├─ Brewing Phases (enhanced sliders)
│   ├─ Mash Temp (with "close enough" zone — hidden until discovered)
│   ├─ Mash Method dropdown: Single/Step/Decoction (if researched)
│   ├─ Boil Length (with malt-specific DMS risk — hidden until discovered)
│   ├─ Hop Schedule timeline (if hop allocation was set)
│   ├─ Ferment Temp (yeast-dependent range, drift based on equipment)
│   └─ Conditioning Time (NEW — 0/1/2/3/4 weeks, quality vs throughput)
│
├─ Quality Calculation (enhanced weights)
│   ├─ Style Match (25%) — ratio + ingredient compatibility
│   ├─ Fermentation (25%) — temp accuracy + stability (THE dominant lever)
│   ├─ Science (15%) — mash + boil + yeast accuracy
│   ├─ Water (10%) — profile match to style (NEW)
│   ├─ Hop Schedule (10%) — bittering/aroma/dry hop appropriateness (NEW)
│   ├─ Novelty (10%) — recipe variation reward
│   └─ Conditioning (5%) — time investment bonus (NEW)
│
├─ Failure/Off-Flavor Roll (enhanced)
│   ├─ Infection (sanitation quality) — unchanged
│   ├─ Ferment off-flavors (temp accuracy + drift) — enhanced
│   ├─ DMS (boil length + malt type) — NEW conditional
│   ├─ Diacetyl (conditioning time + ferment management) — NEW
│   ├─ Oxidation (batch size + equipment) — NEW, scales with growth
│   └─ Context check: is this "off-flavor" actually good for this style?
│
├─ Discovery Roll (enhanced)
│   ├─ Attribute discovery (what flavor do I taste?)
│   ├─ Process attribution (what caused that flavor?)
│   ├─ Efficiency discovery (NEW — "this doesn't matter!")
│   ├─ Exception discovery (NEW — "...except when it does!")
│   └─ Good combo marker (NEW — "this ingredient + this style = great")
│
├─ Results + Tasting Notes (enhanced feedback)
│   ├─ Score breakdown (more granular)
│   ├─ Tasting notes (depth based on palate level)
│   ├─ Discovery toasts (attribute / process / efficiency / exception)
│   └─ Comparison to previous brews of same style
│
├─ Sell Phase (unchanged)
│
└─ Management Phase
    ├─ Equipment (unchanged)
    ├─ Research (expanded tree with water/hops/fermentation branches)
    ├─ Staff (unchanged)
    └─ NEW: Brewing Journal — cumulative record of all discoveries
```

---

## The Progression Arc (Player Knowledge Journey)

| Brews | Player State | Key Brulosophy Parallel |
|-------|-------------|----------------------|
| 1-5 | **Overwhelmed.** Too many choices, don't know what matters. Following "safe" defaults | "I read online you MUST do X, Y, Z..." |
| 6-15 | **Pattern recognition.** Starting to notice which changes affect score. First discoveries | "Wait, ferment temp seems really important..." |
| 16-30 | **Efficiency phase.** Discovering shortcuts (short mash, short boil). Pruning unnecessary steps | "Half the stuff I worried about doesn't matter!" |
| 31-50 | **Style specialization.** Learning style-specific rules. Exceptions to shortcuts | "...but THIS style needs a long boil" |
| 50+ | **Mastery.** Intentional process design. Every decision is informed by discovered knowledge | "I know exactly what my beer needs" |
| Meta | **Teaching.** Player's discovery journal persists. New runs start with accumulated wisdom | "I already know water chemistry matters" |

This IS the Brulosophy journey compressed into a game. The community spent 10 years discovering these findings. The player experiences the same revelations in 50 brews.

---

## Summary: The 6 Brulosophy Principles as Game Design Rules

1. **Present everything as if it matters** → The game must NEVER tell the player what's important and what's not. Every slider, every option, every choice should feel consequential at first. The UI treats all variables equally. The complexity is the starting state — simplicity is the EARNED state
2. **Most things don't matter — but the player must DISCOVER this** → The 70% that doesn't matter is not content to skip. It's content to PLAY THROUGH. Each "this doesn't matter" discovery is a reward that was earned through experimentation. The act of learning to ignore noise is the core skill
3. **A few things matter A LOT — and the contrast is the payoff** → Fermentation temp, water chemistry, yeast strain should dominate scoring. But the reason they FEEL impactful is because the player has already wasted 10 brews tweaking mash length and boil time for zero gain. The "does matter" hits hard BECAUSE of all the "doesn't matter" that preceded it
4. **Context changes everything** → The same technique/ingredient can be a flaw or a feature depending on style. This is the deepest layer — even once you know WHAT matters, you have to learn WHEN it matters
5. **Conventional wisdom is often wrong — and the game should teach the conventional wisdom first** → Early game hints, NPC advice, recipe books should all parrot the "standard" brewing advice (always mash 60 min, always boil 90 min, decoction is superior). The player who follows this advice makes decent beer. The player who QUESTIONS it through experimentation makes EFFICIENT beer. The game rewards the scientist, not the rule-follower
6. **Relax, don't worry** → The game should feel like the player is getting BETTER at something real, not just optimizing numbers. By the end of a run, the player has genuine brewing intuition. They know what matters and what doesn't. They earned that knowledge the same way real brewers do — through 300 experiments compressed into 50 brews
