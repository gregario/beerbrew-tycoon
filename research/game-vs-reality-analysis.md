# Game vs Reality Analysis

Comparing BeerBrew Tycoon's current systems against real brewing knowledge.
Goal: Make the game more representative of real brewing while keeping the Game Dev Tycoon-style fun loop.

---

## Executive Summary

The game already has strong bones. The 3-slider brewing phase, ingredient system, and quality scoring capture the spirit of brewing well. The biggest gaps are:

1. **Water chemistry is completely missing** — it's one of the most impactful variables in real brewing
2. **Hop schedule is oversimplified** — no distinction between bittering/aroma/dry hop additions
3. **Brewing process is too compressed** — missing steps that create interesting decisions (sparging, cooling, conditioning)
4. **Beer styles are too few** — 4 styles vs the 34+ major BJCP categories
5. **Equipment doesn't map to real brewing tiers** — current categories don't reflect the meaningful extract→BIAB→all-grain→pro progression
6. **Off-flavor system is too binary** — real brewing has a spectrum of defects tied to specific process decisions
7. **The discovery system could go much deeper** — the Brulosophy "70% doesn't matter" finding is a perfect game mechanic

---

## Detailed Analysis by System

### 1. BREWING PHASES (3 Sliders)

**Current**: Mashing (62-69C), Boiling (30-90 min), Fermenting (15-25C)

**Reality Check:**
- Mashing temp range is accurate (62-69C covers beta/alpha amylase range)
- Boiling range is reasonable (though Brulosophy shows 30 min vs 90 min often doesn't matter)
- Fermentation temp is reasonable but the range should vary by yeast type
- Missing: hop timing decisions, water treatment, sparging, cooling, conditioning, dry hopping

**Recommendations:**

| Priority | Change | Rationale |
|----------|--------|-----------|
| HIGH | Add **Hop Schedule** as a brewing decision | Real brewing's biggest player-facing decision after ingredients. Allow bittering (60min), flavor (15min), aroma (5min), dry hop allocations of the selected hops |
| HIGH | Add **Water Profile** selection (unlocked via research) | Chloride:sulfate ratio is one of the most impactful variables. Simple "malty/balanced/hoppy" water slider |
| MEDIUM | Make ferment temp range **yeast-dependent** | Lager yeast: 4-12C, Ale yeast: 15-24C, Saison/Kveik: 20-40C. Slider range changes with yeast selection |
| MEDIUM | Add **Conditioning Time** decision (0-4 weeks) | Longer = smoother, fewer off-flavors. But costs turns/time. Trade-off: quality vs throughput |
| LOW | Add **Cooling Method** (equipment-gated) | No-chill vs immersion vs plate chiller. Affects DMS risk and infection chance |
| LOW | Mash length as optional shortcut | Brulosophy shows 20 min vs 60 min doesn't matter — reward players who discover this with a time-saving shortcut |

**The Brulosophy Twist:** Since mash temp moderate differences (65 vs 67C) are NOT significant in reality, the game should have a "close enough" zone where small differences don't matter, but large differences (62 vs 69C) do. This rewards learning the general principle without punishing small imprecision — matching reality.

---

### 2. INGREDIENTS

**Current**: 26 ingredients (8 malts, 8 hops, 6 yeasts, 4 adjuncts) with 5-axis flavor profiles

**Reality Check:**
- Good foundation, but real brewing has 50+ common malt varieties, 100+ hop varieties, 20+ common yeast strains
- Flavor profile axes (bitterness, sweetness, roastiness, fruitiness, funkiness) miss some key dimensions
- No water as an ingredient
- No concept of hop freshness, grain freshness
- No concept of grain bill percentages (real recipes are precise about % of each grain)

**Recommendations:**

| Priority | Change | Rationale |
|----------|--------|-----------|
| HIGH | Add **Water** as a selectable ingredient/profile | Most impactful missing ingredient. Even a simple profile selection (Soft/Balanced/Hoppy/Dark) would add realism |
| HIGH | Expand hop varieties to ~20 | Modern brewing is hop-driven. Add: Mosaic, Galaxy, Nelson Sauvin, Amarillo, El Dorado, Sabro. Each with distinct character |
| HIGH | Add **hop usage allocation** | When selecting hops, let player assign them to Bittering/Aroma/Dry Hop slots. Same hop, different usage = very different result |
| MEDIUM | Add flavor axis: **Body/Mouthfeel** | Crystal malts add body, oats add silkiness. "Body" is distinct from sweetness |
| MEDIUM | Add flavor axis: **Crispness/Clean** | Lagers, pilsners have a "clean" quality. Currently no way to express this |
| MEDIUM | Expand yeast to ~12 strains | Add: Belgian (Trappist), Saison, Kveik, Brett, Lager (Bohemian vs Munich). Each dramatically changes the beer |
| MEDIUM | Expand specialty malts | Add: Vienna, Biscuit, Crystal 40, Crystal 120, Black Patent, Acidulated. More recipe nuance |
| LOW | Add **adjunct expansion** | Coffee, cacao, vanilla, fruit, oak, spices — unlocked via research. Huge flavor impact |
| LOW | Ingredient freshness mechanic | Fresh hops (seasonal) vs old hops. Adds market timing dimension |

---

### 3. QUALITY SCORING

**Current**: 6 components — Ratio (40%), Ingredient (20%), Science (20%), Novelty (10%), Base (10%)

**Reality Check:**
- Ratio score (flavor vs technique balance per style) is a good abstraction
- Science score (mash/boil/yeast accuracy) is solid but could be deeper
- Missing: water chemistry impact, hop schedule impact, conditioning impact
- Novelty penalty is game-mechanic-only (not real) — but good for gameplay
- The 40% weight on "ratio" (flavor/technique balance) is abstract — real quality comes from specific ingredient+process combinations

**Recommendations:**

| Priority | Change | Rationale |
|----------|--------|-----------|
| HIGH | Add **Water Chemistry Score** component | If water profiles are added, this should be 10-15% of quality. Right water for right style = big impact (like Burton water for IPA) |
| HIGH | Add **Hop Schedule Score** | If hop allocation is added, reward correct usage (bittering hops early, aroma hops late). 10% weight |
| MEDIUM | Reduce Ratio Score to 25-30% | Make room for water + hop schedule. Ratio is too abstract to carry 40% |
| MEDIUM | Make **yeast-style match** more impactful | Using Belgian yeast in a Pale Ale should be a bigger penalty/different result than using clean ale yeast. Currently somewhat covered by ingredient compatibility |
| LOW | Add **conditioning bonus** | If conditioning time is added, it should improve score slightly and reduce off-flavor probability |

---

### 4. EQUIPMENT

**Current**: 15 pieces across Brewing/Fermentation/Packaging/Utility, Tiers 1-4

**Reality Check:**
- Current categories (Brewing, Fermentation, Packaging, Utility) are reasonable
- But the progression doesn't match the real journey: Extract → BIAB → 2-vessel → 3-vessel → Electric → Pro
- Missing critical equipment: thermometer, pH meter, water filter, grain mill, wort chiller
- Current equipment affects stats (sanitation, temp_control, efficiency, batch_size) which is good
- But the most impactful real upgrade (fermentation chamber for temp control) should be MORE impactful

**Recommendations:**

| Priority | Change | Rationale |
|----------|--------|-----------|
| HIGH | Restructure **Brewing category** to match real progression | Extract Kit → BIAB Bag → Mash Tun + Kettle → 3-Vessel → Electric System. Each tier unlocks brewing capabilities |
| HIGH | Add **measurement tools** as a category | Thermometer → Digital Thermometer → pH Meter → Refractometer. Ties to the "equipment reveals information" design vision |
| HIGH | Make **fermentation chamber** the single biggest quality upgrade | In reality, ferment temp control is the #1 quality improvement a brewer can make |
| MEDIUM | Add **water treatment tools** | Carbon filter (removes chlorine) → Water report → RO system → Mineral additions. Unlocks water chemistry gameplay |
| MEDIUM | Equipment should **reveal information** per future-vision.md | Thermometer shows temp numbers on slider, pH meter shows mash efficiency, refractometer shows gravity estimates. This IS the discovery loop |
| LOW | Rename/restructure to match real brewing terms | "Extract Kit", "BIAB Setup", "Mash Tun", "3-Vessel Rig", "Electric Brewhouse" are more evocative than generic tier names |

---

### 5. RESEARCH TREE

**Current**: 20 nodes across Techniques/Ingredients/Equipment/Styles

**Reality Check:**
- Good structure, but could be more tied to real brewing knowledge progression
- Missing: water chemistry branch, hop techniques branch, fermentation science branch
- Real brewing learning is more about understanding *why* things work than unlocking recipes

**Recommendations:**

| Priority | Change | Rationale |
|----------|--------|-----------|
| HIGH | Add **Water Science** branch | Water Treatment → Mineral Adjustment → pH Management → Advanced Water Chemistry. Unlocks water profile gameplay |
| HIGH | Add **Hop Mastery** branch | Hop Timing → Dry Hopping → Biotransformation → Hop Blending. Reflects real hop knowledge progression |
| MEDIUM | Add **Fermentation Science** branch | Yeast Health → Temp Profiling → Diacetyl Rest → Mixed Fermentation. The real quality lever |
| MEDIUM | Rename "Techniques" nodes to match real skills | "Mash Basics" → "Understanding Mash Temperature", "Advanced Mashing" → "Step Mashing & Decoction" |
| LOW | Research should unlock **knowledge tooltips** | Each node, when unlocked, adds real brewing info to the UI. "You now understand that higher mash temps = fuller body." The player is literally learning brewing |

---

### 6. BEER STYLES

**Current**: 4 styles (Pale Ale, Stout, Wheat Beer, Lager)

**Reality Check:**
- Only 4 styles is the biggest content gap. Real BJCP has 34+ categories with 100+ sub-styles
- The current styles are good starting points but miss major families

**Recommendations:**

| Priority | Change | Rationale |
|----------|--------|-----------|
| HIGH | Expand to 12-16 styles across progression | This is the roguelite content backbone. Each style teaches different brewing principles |
| HIGH | Group styles into unlockable families | Ales (start) → Lagers (research) → Belgians (research) → Sours (late research) → Historical (meta-progression) |

**Proposed Style Expansion (16 styles):**

| Style | Family | Unlock | What It Teaches |
|-------|--------|--------|-----------------|
| American Pale Ale | Ale | Start | Hop-malt balance basics |
| Amber Ale | Ale | Start | Specialty malt character |
| IPA | Ale | Research | Hop scheduling, dry hopping |
| Porter | Dark | Research | Dark malt blending |
| Stout (Dry) | Dark | Research | Roast character, full mash |
| Imperial Stout | Dark | Late Research | High gravity, complexity |
| Hefeweizen | Wheat | Research | Yeast-driven character (ester/phenol) |
| Witbier | Wheat | Research | Adjuncts (spices, citrus) |
| Czech Pilsner | Lager | Research | Clean fermentation, water chemistry |
| Helles | Lager | Research | Subtle malt, decoction potential |
| Marzen/Oktoberfest | Lager | Research | Toasty malt, clean lager |
| Saison | Belgian | Research | High-temp fermentation, wild character |
| Belgian Dubbel | Belgian | Late Research | Dark fruit, Belgian yeast, sugar |
| Barleywine | Strong | Late Research | High gravity, aging, complexity |
| Berliner Weisse | Sour | Late Research | Kettle souring, acidity |
| NEIPA | Modern | Late Research | Biotransformation, water chemistry, hop science |

Each new style should introduce a brewing concept the player hasn't encountered.

---

### 7. FAILURE MODES / OFF-FLAVORS

**Current**: Binary infection roll + off-flavor roll (esters/fusel/DMS). Sanitation and temp_control stats.

**Reality Check:**
- Good foundation, but too binary (pass/fail)
- Real off-flavors are a spectrum, not on/off
- Missing several important off-flavors: diacetyl, acetaldehyde, oxidation, phenolic, astringency
- Off-flavors should be tied to specific process decisions, not just stat thresholds

**Recommendations:**

| Priority | Change | Rationale |
|----------|--------|-----------|
| HIGH | Add **Diacetyl** as a failure mode | Caused by rushing fermentation (too short conditioning). The "butter" flavor is one of the most common homebrew flaws |
| HIGH | Add **Oxidation** as a failure mode | Tied to equipment quality (open vs closed transfers). Becomes relevant as player scales up |
| MEDIUM | Make off-flavors a **spectrum** not binary | Instead of "off-flavor: yes/no", have a severity scale (subtle → noticeable → dominant). Subtle off-flavors reduce score slightly, dominant ones wreck it |
| MEDIUM | Tie each off-flavor to **specific process decisions** | DMS = short boil + pilsner malt. Fusel = high ferment temp. Diacetyl = incomplete fermentation. Phenolic = water chlorine. This makes them learnable/preventable |
| LOW | Add **oxidation risk** that increases with batch size | Bigger batches are harder to handle without oxidation. Equipment (kegging, CO2 system) mitigates |
| LOW | Some off-flavors should be **style-appropriate** | Esters in a Hefeweizen are GOOD. Slight diacetyl in an English Bitter is traditional. Context matters |

---

### 8. DISCOVERY SYSTEM (The Core Innovation)

**Current**: Attribute discovery (chance to notice a flavor) + Process attribution (chance to link it to a process step). 17 attributes tied to mash/boil/hop/ferment.

**Reality Check:**
This is the game's most unique mechanic and it maps PERFECTLY to how real brewers learn. Real brewers gradually develop the ability to: (1) taste a flavor, (2) name it, (3) understand what caused it, (4) intentionally control it.

**The Brulosophy Insight for Discovery:**
The 70% "doesn't matter" finding creates a fascinating game mechanic: **the player should discover that some things DON'T matter.** This is as valuable a discovery as finding what does matter. Discovering "mash length doesn't affect my beer" is a real aha moment that lets you save time/money.

**Recommendations:**

| Priority | Change | Rationale |
|----------|--------|-----------|
| HIGH | Add **"Non-Discovery" discoveries** | "You brewed with a 20-min mash and a 60-min mash. They taste the same!" This IS the Brulosophy finding and it's powerful game design. Reward shortcuts |
| HIGH | Add **Water-related discoveries** | "This beer tastes crisper — could it be the water?" → "Sulfate seems to make hops pop!" |
| HIGH | Add **Hop schedule discoveries** | "Late hop additions seem more aromatic" → "Adding hops at flameout preserves volatile oils" |
| MEDIUM | Add **Yeast character discoveries** | "This yeast makes banana flavors!" → "Warmer fermentation increases banana esters in wheat yeast" |
| MEDIUM | Add **Negative discoveries** (off-flavor attribution) | "This beer tastes like butter" → "Diacetyl comes from rushing fermentation" |
| MEDIUM | Equipment should unlock **discovery visibility** | Thermometer = see temp. pH meter = see mash efficiency. The discovery IS the equipment |
| LOW | Add **"Good Combo" markers** per future-vision.md | Once player discovers Cascade + Pale Ale = great match, show a marker. Like GDT's good combos |
| LOW | **Meta-progression discoveries** persist across runs | "I learned water chemistry matters" persists. New runs start with some discoveries. This IS the roguelite hook |

---

### 9. MARKET / ECONOMY

**Current**: Seasonal demand, trending styles, saturation, 4 distribution channels, player pricing.

**Reality Check:**
- Seasonal demand is realistic (stouts in winter, wheat in summer)
- The distribution channel progression (taproom → bars → retail → events) is solid
- Missing: style popularity trends over years (IPA boom, sour trend, NEIPA craze)

**Recommendations:**

| Priority | Change | Rationale |
|----------|--------|-----------|
| MEDIUM | Add **craft beer trend waves** | If historical decades are added (per future vision), each decade has trending styles: 80s = lagers, 90s = amber ales, 2000s = IPAs, 2010s = NEIPAs, 2020s = sours/lagers return |
| MEDIUM | **Quality perception** should matter | A 90-score Pale Ale should earn more reputation than a 90-score Lager (some styles have higher ceilings for market prestige) |
| LOW | Add **beer rating platforms** (late game) | Like Untappd/RateBeer — adds a social scoring dimension alongside sales |
| LOW | Add **seasonal ingredient availability** | Fresh hop season (fall), seasonal fruits, limited availability creates market timing |

---

### 10. BREWING PROCESS EXPANSION (New Steps)

The current 3-step process (Mash → Boil → Ferment) could grow as the player progresses. This matches the "equipment reveals complexity" vision perfectly.

**Proposed Progressive Process Expansion:**

| Game Stage | Visible Steps | New Decision |
|-----------|--------------|-------------|
| Garage (start) | Mash → Boil → Ferment | Current 3 sliders |
| + Thermometer | Same, but with temp numbers | Player sees numbers, can be more precise |
| + Water Kit | Water → Mash → Boil → Ferment | Water profile selection added |
| + Hop Timer | Mash → Boil (with hop schedule) → Ferment | Hop additions at different times |
| + Ferment Chamber | Mash → Boil → Ferment (with profile) | Ferment temp profile (start low, ramp up) |
| + Dry Hop Rack | Mash → Boil → Ferment → Dry Hop | Post-ferment hop addition |
| + Conditioning Tank | Mash → Boil → Ferment → Condition → Package | Conditioning time decision |
| Pro Stage | Full Dashboard | All steps visible with real-time metrics |

This progressive revelation is the game's strongest design concept. Each equipment purchase literally teaches the player a new aspect of brewing.

---

## Summary: Top 10 Recommendations

Ranked by impact on making the game more representative while keeping it fun:

1. **Add Water Chemistry** — Simple profile selector (Soft/Balanced/Hoppy/Dark), unlocked via research. Most impactful missing variable.

2. **Add Hop Schedule** — Let players allocate hops to Bittering/Aroma/Dry Hop slots. Transforms hop gameplay from "pick hops" to "how to use hops."

3. **Expand Beer Styles to 12-16** — Each style teaches a different brewing principle. This IS the roguelite content.

4. **Equipment reveals information (progressive disclosure)** — Per future-vision.md, this is the killer feature. Thermometer shows numbers, pH meter shows efficiency, etc. The game literally teaches brewing through equipment purchases.

5. **Add "Non-Discovery" discoveries (Brulosophy mechanic)** — Discovering that something DOESN'T matter is as valuable as discovering what does. Rewards experimentation with efficiency shortcuts.

6. **Expand Off-Flavors to a spectrum** — Diacetyl, oxidation, acetaldehyde as learnable/preventable defects tied to specific decisions. Not just random rolls.

7. **Make Fermentation the king of quality** — It's the #1 real-world quality lever. Fermentation chamber should be the single biggest equipment upgrade, and temp control should have the most nuanced impact.

8. **Restructure Equipment to match real progression** — Extract → BIAB → All-Grain → Electric → Pro. Each tier unlocks new brewing capabilities, not just stat bonuses.

9. **Expand Yeast varieties and impact** — Different yeast strains in the same recipe = completely different beers. This is one of brewing's biggest "aha" moments.

10. **Add Conditioning as a quality/time trade-off** — Longer conditioning = better beer but fewer brews per run. Classic roguelite resource tension.

---

## The Brulosophy Game Design Principle

The single most important insight from Brulosophy for this game:

> **Most of what brewers worry about doesn't matter. The things that DO matter are fewer but more impactful than expected.**

This maps perfectly to a discovery-based roguelite:
- Early game: player is overwhelmed with choices, doesn't know what matters
- Mid game: through experimentation and discovery, player learns what actually impacts their beer
- Late game: player has deep knowledge, can make efficient/creative decisions based on real understanding
- Meta-progression: discoveries persist, each run starts with more brewing knowledge

The game should **never explicitly tell the player what matters**. They should discover it through brewing, exactly like a real brewer does. The Brulosophy community spent 10 years and 300+ experiments figuring this out. Your player gets to experience that same journey in a compressed, fun format.
