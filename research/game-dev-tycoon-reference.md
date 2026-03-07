# Game Dev Tycoon Systems Reference

How Game Dev Tycoon works mechanically, and how each system maps to BeerBrew Tycoon's brewing loop. This is a reference document for future OpenSpec tasks.

---

## 1. TIME SYSTEM

### How GDT Does It

**Continuous real-time ticker.** Time flows in weeks, grouped into months and years. The clock runs constantly — there is no "end turn" button. When you're not developing a game, time still passes (and costs still accrue).

- **Garage phase:** Minimal costs (~$11K/month living expenses). Solo developer. Time passes while idle — you can research, train, or do contract work between games
- **Office phase:** Monthly costs = rent + all employee salaries ($10K-40K+ per employee per month). Time pressure increases dramatically because idle time burns cash
- **Game development:** Takes ~8 months of in-game time for a standard game. Larger games take longer. During development, time continues to tick — you watch your team work in real-time
- **Between games:** Time keeps ticking. You can research, train staff, do contracts, or just bleed money. The pressure to start a new game increases with team size because idle employees still cost salary

**Key tension:** In the garage, time is abundant and cheap. As you scale, idle time becomes expensive. This creates natural pacing — early game is relaxed, late game is pressured.

### How BeerBrew Should Adapt This

**Current system:** Turn-based. Each brew is a discrete turn. No continuous time. No idle cost between brews. Rent is charged every 4 turns.

**Proposed continuous time model:**

```
Week-based ticker (like GDT):

GARAGE PHASE:
- Weekly cost: $0 (hobby budget from day job)
- Brew takes: 2-4 weeks depending on style (fermentation time!)
  - Ale: 2 weeks (fast ferment)
  - Lager: 4 weeks (cold, slow ferment)
  - Barrel-aged: 8+ weeks (aging time)
- Between brews: Time passes, costs are minimal
  - Can do: research, clean equipment, experiment
  - Conditioning: beer improves if you wait (quality vs throughput)
- Day job income: Small weekly $ to keep you afloat
- Over-budget: If ingredient costs exceed savings, must work overtime
  (skip a week = earn money but lose brewing time)

MICROBREWERY PHASE:
- Weekly costs: rent + staff salaries (continuous drain)
- Brew takes: same base, but can overlap batches with more fermenters
- Idle fermenters = wasted capacity = burning money for nothing
- Staff idle between brews = wasted salary
- Pressure to keep brewing to cover costs

ARTISAN/MASS-MARKET:
- Higher weekly costs, higher revenue potential
- Multiple batches in parallel (like GDT doing large games with full team)
- Seasonal planning matters (brew stouts in summer for winter release)
```

**The brewing-specific time twist:** Unlike GDT where development time is roughly uniform, BEER HAS REAL TIME CONSTRAINTS. Fermentation takes actual weeks. Lagers take longer than ales. Conditioning takes time. Barrel aging takes months. This creates a natural economic pressure:

- **Ales** = fast turnaround, lower revenue per unit, good cash flow
- **Lagers** = slow turnaround, higher price, ties up fermenter space
- **Barrel-aged** = very slow, premium price, but you need something else generating income while you wait
- **Conditioning** = optional extra time that improves quality. Trade-off: hold it longer for better beer, or release now to pay rent?

This is a REAL brewery decision. Wicklow Wolf might have a stout conditioning for 6 weeks while they sell pale ales to keep cash flowing.

---

## 2. DEVELOPMENT PHASES & BUBBLES (The Core Animation)

### How GDT Does It

**3 development phases, each with 3 sliders:**

| Phase | Sliders | Design/Tech Split |
|-------|---------|-------------------|
| Phase 1 | Engine (80T/20D), Gameplay (80D/20T), Story/Quests (80D/20T) |
| Phase 2 | Dialogues (90D/10T), Level Design (60T/40D), AI (80T/20T) |
| Phase 3 | World Design, Graphics, Sound |

**How it plays:**
1. Player sets sliders for Phase 1 (allocating time %)
2. Time starts flowing. Employees sit at desks
3. **Bubbles float up from employee heads** — colored Design (yellow) or Tech (blue) or Bug (red)
4. Bubble spawn rate = employee speed stat
5. Bubble color ratio = determined by current slider allocation and employee specialization
6. Progress bar fills as phase completes
7. Between phases: time pauses, player adjusts sliders for next phase
8. After Phase 3: Bug fixing phase begins. Bug bubbles get "popped" over time

**The bubbles are the game's core feedback loop.** You watch your team generate points in real-time. You see whether you're getting enough Design vs Tech. You see bugs spawning. It FEELS like work happening.

**Bug generation:**
- Each point spawn has a chance to become a bug instead
- Bug chance = ~31% at employee Level 1, ~6% at Level 4+
- Manager reduces bug chance for their team
- Bugs reduce final score via: `bug_ratio = 1 - (0.8 * bugs / (tech + design))`
- If ratio ≤ 0.6: "Riddled with bugs" message

**Between phases:** Time pauses. Player adjusts sliders. This is the DECISION MOMENT — you see your progress so far and adjust strategy.

### How BeerBrew Should Adapt This

**The brewing equivalent of GDT's 3 development phases:**

```
GDT Phase 1 (Engine/Gameplay/Story) → Brew Phase 1: MASHING
GDT Phase 2 (Dialogue/Level/AI)     → Brew Phase 2: BOILING (+ hop schedule)
GDT Phase 3 (World/Graphics/Sound)  → Brew Phase 3: FERMENTATION
GDT Bug Fixing                      → Brew Phase 4: CONDITIONING (optional)
```

**Bubble equivalent for brewing:**

Instead of Design/Tech/Bug bubbles, brewing produces:

| Bubble Type | Color | What It Represents | GDT Equivalent |
|------------|-------|-------------------|----------------|
| **Quality** | Gold/Amber | Good brewing happening — flavor development, proper conversion, clean ferment | Design points |
| **Technique** | Blue | Precision and process — correct temps, good efficiency, proper timing | Tech points |
| **Off-Flavor** | Red/Dark | Something going wrong — DMS, esters, fusel alcohols, infection risk | Bug points |

**Phase-by-phase bubble behavior:**

#### Phase 1: MASHING
Player has set: mash temp, water profile (if unlocked), grain bill

**Bubbles during mash phase:**
- Quality bubbles spawn based on: grain bill complexity, specialty malt character
- Technique bubbles spawn based on: mash temp accuracy (close to style ideal)
- Off-flavor bubbles: rare in mashing. Possible astringency if mash is extreme
- **Visual:** Character stirring a mash tun. Bubbles float up. Good mash = mostly gold/blue. Bad temp = some red

**The "close enough" zone:** If mash temp is within ±2°C of ideal (the Brulosophy finding), the technique bubble rate is the same as hitting it exactly. Player sees no difference. Only outside that zone do off-flavor bubbles increase.

**Between Phase 1→2:** Time pauses. Player sets hop schedule allocations (bittering/aroma/dry hop), adjusts boil length. Can see mashing results so far.

#### Phase 2: BOILING (+ Hop Schedule)
Player has set: boil length, hop allocations (if unlocked)

**Bubbles during boil phase:**
- Quality bubbles: from hop additions (each hop addition triggers a burst of quality bubbles)
- Technique bubbles: from boil vigor, proper timing
- Off-flavor bubbles: DMS risk (especially with pilsner malt + short boil). Visible as greenish "corn" bubbles
- **Visual:** Kettle boiling. Hop addition moments = burst of aromatic green/gold bubbles. DMS = yellow-green warning bubbles

**Hop addition animation:** When hop schedule reaches each timing point (60min, 15min, 5min, flameout), there's a visual moment — hops being thrown in, aromatic burst. This is the "event" within the phase.

**Between Phase 2→3:** Time pauses. Player adjusts fermentation temp. If yeast-dependent ranges are visible (equipment reveals), they can see the target zone.

#### Phase 3: FERMENTATION (The Big One)
Player has set: ferment temp, yeast already selected in recipe

**This is the LONGEST phase** (like GDT's Phase 3 which is the climax). Multiple weeks pass.

**Bubbles during fermentation:**
- Quality bubbles: yeast converting sugar to alcohol and CO2. Steady stream when ferment is healthy
- Technique bubbles: temp stability (steady stream if temp control equipment is good)
- Off-flavor bubbles: THE MAIN RISK ZONE
  - **Esters** (fruity) — warm ferment bubbles. Orange/pink. Could be good (wheat beer) or bad (lager)
  - **Fusel alcohols** (hot) — very warm ferment. Dark red. Always bad
  - **Diacetyl** (butter) — yellow. Appears if fermentation ends too abruptly
  - **Clean ferment** — all gold/blue, minimal red. The goal for most styles

**Temperature drift visualization:** If player lacks good temp control equipment, the ferment temp VISIBLY drifts on a thermometer UI element. Player watches helplessly as temp creeps up on a hot day, generating ester bubbles. This makes the fermentation chamber purchase feel ESSENTIAL.

**Staff assignment during fermentation:** In GDT, employees contribute to all phases. In brewing:
- Staff assigned to fermentation = better monitoring, catch issues earlier
- More experienced staff = fewer off-flavor bubbles (they notice and correct problems)
- Staff "effort" bubbles emerge from their avatar (like GDT employees at desks)

#### Phase 4: CONDITIONING (Optional — Equivalent to Bug Fixing)

**In GDT:** Bug fixing phase after development. Bugs get "popped" over time. Player can choose when to ship (more time = fewer bugs, but costs salary/time).

**In brewing:** Conditioning phase after fermentation. Off-flavors get "cleaned up" over time.

```
Conditioning effect over time:
Week 0: Raw beer. All off-flavors present at full strength
Week 1: -20% diacetyl (yeast reabsorbs it), -10% acetaldehyde
Week 2: -50% diacetyl, -30% acetaldehyde, slight clarity improvement
Week 3: -80% diacetyl, -60% acetaldehyde, noticeable smoothing
Week 4: -90% all minor off-flavors. Beer is "polished"

BUT: Each week of conditioning costs time (rent, staff salary ticking)
AND: Fermenter is occupied (can't start a new brew in it)
```

**The GDT parallel is perfect:** In GDT, you choose when to ship — leave bugs in to save time, or polish to perfection. In brewing, you choose when to package — release "green" beer quickly to pay rent, or condition for weeks for a better product.

**The discovery:** Early game, player doesn't know conditioning helps. They release immediately. Beer is "fine but rough." Later, they discover that waiting 2 weeks smooths everything out. The "patience pays" lesson — one of brewing's core truths.

**Visual:** Off-flavor bubbles visually "pop" and disappear during conditioning. Like GDT's bug fixing animation but with beer bubbles dissolving.

---

## 3. SCORING & REVIEW SYSTEM

### How GDT Does It

```
Game Score = (Design + Tech) / size_modifier * quality_modifiers

Quality Modifiers:
- Genre/Topic match (good combo vs bad combo)
- Tech/Design ratio vs genre ideal
- Platform audience match
- Bug ratio (fewer bugs = higher multiplier)
- Sequel penalty (-0.4 if same topic/genre as last game)
- Sequel timing penalty (-0.4 if sequel <40 weeks apart)
- Sequel engine bonus (+0.2 if better engine)
- Trend/timing bonuses

CRITICAL: Review Score = Game Score compared to PREVIOUS HIGH SCORE
- Must keep improving to maintain high reviews
- Score that was "amazing" early becomes "average" later
- This creates escalating difficulty
```

**The high score comparison mechanic is GDT's secret sauce.** You're always competing against your own best. A 9/10 game early might only get 7/10 later because your previous best was higher. This forces constant improvement.

### How BeerBrew Should Adapt This

**Current system:** Quality score 0-100 based on 6 weighted components. No comparison to previous brews (except novelty penalty for same recipe).

**Proposed high-score-ish mechanic for reviews/reputation:**

```
Beer Quality = absolute score (0-100) from brewing process
  This doesn't change — a well-brewed pale ale is a well-brewed pale ale

BUT: Market reception / reputation score DOES use relative comparison:
- First great beer: "WOW, this is amazing!" (high reception)
- Same quality next time: "Good, consistent" (lower reception)
- Slightly worse: "Not as good as their last one" (negative reception)

Per-style tracking:
- Your best Pale Ale was 85. New Pale Ale at 80 = "not their best work"
- BUT: First Stout at 75 = "great debut in a new style!" (no history to compare)
```

**Why this matters for the loop:**
- Encourages style variety (trying new styles = fresh comparison baseline)
- Rewards improvement over time (your 10th brew of a style should be better)
- Punishes stagnation (same recipe, same quality = boring, market yawns)
- Creates the GDT feeling of "I need to keep getting better"

**The review animation equivalent:**
- GDT: 4 reviewers give scores, one at a time, with anticipation
- BeerBrew: Tasting panel / friends / judges give reactions, one at a time
  - Garage: friends around a table, casual reactions ("not bad!", "I'd drink this again", "ehh...")
  - Micro: local beer critics, more specific ("nice hop balance", "slight diacetyl note")
  - Competition: formal judges with score cards
  - Late game: online reviews, magazine ratings, Untappd-style scores

---

## 4. EMPLOYEE/STAFF SYSTEM

### How GDT Does It

- **Garage:** Solo developer. YOU are the only employee. Limited by your own stats
- **Office:** Hire up to 4 employees. Each has: Design skill, Tech skill, Speed, Research stats
- **Specialization:** Employees specialize in one of the 9 slider categories (Engine, Gameplay, etc.)
- **During development:** ALL employees contribute to ALL phases, but specialists generate more points in their specialty
- **Salary:** Continuous monthly cost. Higher skill = higher salary ($10K-$40K+/month)
- **Training:** Between games, can send employees to courses to increase skills
- **Bug rate:** Employee level determines bug chance (31% L1 → 6% L4+). Manager role reduces team bug rate

**The key GDT staff insight:** Employees are assigned specializations but contribute to everything. The specialist just does their area better. You feel the team working together.

### How BeerBrew Should Adapt This

**Current system:** Staff assigned to specific phases (mashing/boiling/fermenting). Flat bonus to flavor/technique points. XP and leveling.

**Proposed enhanced staff model (aligned with GDT):**

```
STAFF ROLES (equivalent to GDT specializations):

Head Brewer (you, at garage stage):
  - Does everything
  - Limited by your equipment and knowledge
  - Gets better with experience (passive skill growth)

Brewing Roles (hired at micro stage):
  - Assistant Brewer: General help across all phases
    → Reduces off-flavor chance, adds technique points
  - Cellarman/Cellarwoman: Fermentation specialist
    → Monitors fermentation, catches temp drift, reduces ester/fusel risk
    → This is the "fermentation chamber" equivalent in human form
  - Head of Quality (QA): Tasting and consistency
    → Improves discovery chance, catches off-flavors early
    → Reduces diacetyl/acetaldehyde by catching them in conditioning
  - Packaging Specialist: Bottles/cans/kegs
    → Reduces oxidation risk, improves shelf stability

Non-Brewing Roles (hired at micro+ stage):
  - Taproom Manager: Runs the taproom → increases taproom revenue
  - Sales Rep: Manages wholesale accounts → opens distribution channels
  - Marketing: Brand awareness → demand multiplier boost

DURING A BREW (the GDT visual equivalent):
  - All assigned staff sit at their stations
  - Bubbles come from each person proportional to their skill + speed
  - Specialist roles: more quality/technique bubbles, fewer off-flavor
  - Senior staff: faster bubble rate, fewer red bubbles
  - Trainee: slow, more red bubbles (but cheap!)

BETWEEN BREWS:
  - Staff still cost salary (continuous time)
  - Can assign to: training, cleaning, recipe development, taproom shifts
  - Idle staff = wasted money (like GDT)
  - This creates the GDT pressure to keep brewing
```

**The GDT employee scaling challenge:**
In GDT, moving from garage to office is a financial cliff. Suddenly you're paying 4 salaries. If your games don't sell, you go bankrupt. BeerBrew should have the same feeling:

```
Garage: $0 staff costs. Relaxed. Brew when you want
→ Hire first employee: Suddenly $500/week salary
→ Must brew consistently to cover their wage
→ Each new hire increases pressure to produce and sell
→ But more staff = better beer = higher revenue (if managed well)
```

---

## 5. THE BUBBLE ANIMATION SYSTEM (Detailed Design)

### GDT's Bubble Visual Language

| Bubble | Color | Meaning | Player Feeling |
|--------|-------|---------|----------------|
| Design | Yellow | Creative work happening | "Good, my design is progressing" |
| Tech | Blue | Technical work happening | "Good, my tech is progressing" |
| Bug | Red | Something went wrong | "Ugh, more bugs to fix" |
| Research | Purple/Pink | Learning/discovering | "Getting smarter" |

Bubbles float up from employee heads. They're small, numerous, and create a visual stream of progress. The RATIO of colors tells the story — mostly yellow/blue is good. Too much red is worrying.

### BeerBrew's Bubble Visual Language

| Bubble | Color | Meaning | Example |
|--------|-------|---------|---------|
| **Quality** | Gold/Amber | Flavor development, good conversion | Malt sugars converting, hop oils extracting |
| **Technique** | Blue | Process precision, consistency | Correct temp, good timing, clean technique |
| **Discovery** | Green/Teal | Learning something new | First time using a specialty malt, new process insight |
| **Off-Flavor: Ester** | Orange/Pink | Fruity fermentation by-products | Could be good (wheat) or bad (lager). Context-dependent |
| **Off-Flavor: Fusel** | Dark Red | Hot alcohols from high temp | Always bad. Alarm color |
| **Off-Flavor: DMS** | Yellow-Green | Cooked corn from short boil | Pilsner malt specific. Warning color |
| **Off-Flavor: Diacetyl** | Butter Yellow | Incomplete fermentation | Fixable with conditioning |
| **Off-Flavor: Oxidation** | Brown/Grey | Oxygen exposure | Equipment-preventable |
| **Off-Flavor: Infection** | Sick Green | Contamination | Catastrophic. Sanitation failure |

### Phase-Specific Bubble Behavior

#### MASHING PHASE (2-3 minutes of animation)

```
Visual: Character/staff standing at mash tun, stirring
Thermometer visible (if equipment unlocked)

Bubble sources:
- Mash tun: quality bubbles (starch → sugar conversion)
- Player/staff: technique bubbles (temperature management)

Bubble rate tied to:
- Grain bill quality → more quality bubbles
- Mash temp accuracy → more technique bubbles
- Staff skill → faster bubble rate, fewer off-flavor

Special moments:
- Mash-in: burst of bubbles when grain meets water
- Temperature stability: steady stream = good. Erratic = bad temp control

Off-flavor bubbles (rare in mash):
- Astringency (if mash temp extreme): purple-brown bubbles
- Mostly this phase is "safe" — setting up for success

Player action: WATCH. Sliders already set. This is the "see your decisions play out" phase.
Time: accelerated. 60-minute mash = ~2 minutes of real animation.
```

#### BOILING PHASE (2-3 minutes of animation)

```
Visual: Kettle rolling boil. Steam rising. Timer counting down.

Bubble sources:
- Kettle: technique bubbles (sterilization, concentration)
- Hop additions: BURSTS of quality bubbles at scheduled times

Hop addition events (the BIG moments of this phase):
- 60-min addition: small burst of quality (bittering). Subtle
- 15-min addition: medium burst (flavor). Aromatic wisps
- 5-min addition: large burst (aroma). Visible hop cloud
- Flameout: massive burst. "THIS is where aroma comes from"
  → Discovery potential: "Late hop additions produce more aroma!"

Off-flavor bubbles:
- DMS (yellow-green): appear if boil is short + pilsner malt
  Amount increases as boil gets shorter
  → At 90 min: almost none
  → At 60 min: occasional
  → At 30 min with pilsner malt: frequent. Warning!
  → Discovery: "Pilsner malt needs a longer boil"

Player action: Watch hop additions land. See the difference between early/late hops.
The visual teaches hop scheduling without text.
```

#### FERMENTATION PHASE (3-5 minutes of animation — the LONGEST)

```
Visual: Fermenter bubbling. Airlock bubbling (audio: bloop bloop bloop).
Temperature display (if equipment). Yeast character bubbles.

This is the CRITICAL phase. Most off-flavor generation happens here.

Bubble sources:
- Fermenter: quality bubbles (yeast converting sugar → alcohol + CO2)
- Temperature controller (if present): technique bubbles (stability)
- Staff (cellarman): technique bubbles (monitoring)

Fermentation progression (visual story):
- Day 1-2: LAG PHASE. Few bubbles. Player worries "is it working?"
  → Discovery: "Lag phase is normal. Be patient."
- Day 2-5: ACTIVE FERMENTATION. Explosive bubbles. Quality and technique gushing.
  Airlock bubbling rapidly. Most points generated here.
  → Off-flavor risk is HIGHEST during this peak
- Day 5-10: SLOWDOWN. Fewer bubbles. Yeast cleaning up.
  → Diacetyl gets reabsorbed (if patient). Butter-yellow bubbles disappear
- Day 10+: COMPLETION. Minimal bubbles. Beer is "done" (but not conditioned)

Temperature drift animation:
- Without temp control: thermometer creeps up/down. Visual anxiety
  → If it drifts warm: ester (orange) bubbles increase
  → If it drifts very warm: fusel (dark red) bubbles appear
  → Player SEES the problem happening and can't stop it (no equipment)
  → This makes the fermentation chamber THE must-buy upgrade

- With temp control: thermometer stays rock solid. Clean bubble stream
  → Player FEELS the difference. "That's what $150 bought me"

Yeast-specific bubble behavior:
- Clean ale (US-05): mostly gold/blue. Clean. Boring but reliable
- English ale (S-04): some orange (fruity ester) bubbles mixed in. By design
- Wheat (WB-06): banana (yellow) and clove (brown) bubbles
  → Ratio shifts with temperature! Warm = more banana. Cool = more clove
  → Visual teaches the player this relationship
- Belgian: spicy (red-orange) and fruity (pink) bursts. Wild-looking
- Lager: very clean BUT takes much longer. Patience test
  → Player sees: "this is taking forever but it's so clean..."
- Saison: looks chaotic (lots of mixed bubbles) but finishes BONE DRY
  → High temp = MORE bubbles, not worse ones (unique among yeasts)
  → Discovery: "Saison yeast loves heat!"

Staff contribution during fermentation:
- Cellarman catches problems. If temp drifts, they reduce off-flavor bubble rate
- Experienced cellarman: their avatar shows them checking the fermenter,
  adjusting the temp, tasting samples. Technique bubbles flow from them
- Junior staff: slower to notice. More red bubbles slip through
```

#### CONDITIONING PHASE (1-2 minutes — equivalent to GDT bug fixing)

```
Visual: Bright tank or bottles/kegs. Beer clearing. Off-flavor bubbles "popping."

This is THE equivalent of GDT's bug-fixing phase:
- In GDT: red bug bubbles get eliminated over time
- In BeerBrew: off-flavor bubbles pop and disappear over time

Conditioning animation:
- Week 1: Off-flavor bubbles still present but starting to pop
  → Diacetyl (butter): first to go (yeast reabsorbs it)
  → Acetaldehyde (green apple): starts fading
- Week 2: Most minor off-flavors gone. Beer visually clearer
- Week 3: Beer looks clean. Almost all gold/blue remaining
- Week 4: Polished. Crystal clear (for styles that should be clear)

THE GDT CHOICE:
"When do you release?"
- Release now (Week 0): Fastest. Raw. All off-flavors present. Cheapest (no conditioning cost)
- Release at Week 1: Some cleanup. Quick turnaround
- Release at Week 2: Solid. Good balance of time vs quality
- Release at Week 4: Polished. Best quality. But 4 weeks of rent/salary burned

Player presses "Package" button at any point during conditioning.
Just like GDT's "ship game" decision during bug fixing.

The fermenter is OCCUPIED during conditioning.
→ Can't start a new brew until this one is packaged
→ Multiple fermenters = can stagger brews (equipment progression)
→ This creates the GDT-style pipeline management challenge
```

---

## 6. THE IDLE / BETWEEN-BREWS ECONOMY

### How GDT Handles Downtime

- Time keeps ticking. Costs keep accruing
- Player can: research, train staff, build engines, do contracts
- Contracts = small jobs for cash (grinding to stay afloat)
- The PRESSURE to start a new game increases with team size
- In garage: relaxed. Can idle without penalty (low costs)
- In office: must keep shipping to stay alive

### How BeerBrew Should Handle Downtime

```
BETWEEN BREWS (time keeps flowing):

Garage Phase (low pressure):
  - Day job covers living costs (implied, not simulated)
  - Ingredients cost money from brewing budget
  - Between brews: clean equipment, drink your beer, research
  - No urgency — brew at your own pace
  - Maybe: "side hustle" — sell homebrew at farmers market for small $

Micro Phase (medium pressure):
  - Rent + staff salaries tick weekly
  - Between brews: fermenters sit empty
  - Available activities during idle:
    1. Clean/maintain equipment (reduces infection chance next brew)
    2. Train staff (improves skills, costs time + $)
    3. Recipe development (test mini-batches, improves next brew slightly)
    4. Taproom management (earns revenue even when not brewing)
    5. Market research (reveals upcoming trends)
    6. Accept contract brew orders (brew for other brands = steady $)
  - The taproom keeps income flowing between brews (CRITICAL)
  - Contract work = the GDT equivalent of doing contracts in the garage

Artisan Phase (high pressure, quality focus):
  - Higher costs, but taproom + distribution = steady revenue
  - Barrel-aged beers tying up fermenters for months
  - Collaboration brews (joint projects with NPC breweries)
  - Hop farm maintenance (seasonal)
  - The TENSION: do I brew another quick ale to pay bills,
    or let my imperial stout condition for 3 more weeks?

Mass-Market Phase (high pressure, throughput focus):
  - Maximum costs. Multiple employees, multiple fermenters, pubs to stock
  - Pipeline management: stagger brews so you always have product
  - Never idle — if fermenters are empty, you're losing money
  - This is GDT at its most stressful (big team, must ship constantly)
```

---

## 7. SCALING: SOLO → TEAM

### GDT's Scaling Curve

| Phase | Team Size | Effect | Financial Pressure |
|-------|----------|--------|-------------------|
| Garage | 1 (you) | All decisions, all work. Limited quality ceiling | Low ($11K/month) |
| Small Office | 1-4 employees | Assign specializations. Higher quality possible. More design+tech points | Medium ($50-170K/month) |
| Large Office | 4-6 employees | Full specialist team. AAA games possible. Bug management critical | High ($200K+/month) |
| R&D Lab | Full team + R&D | Cutting edge. Maximum quality. Maximum cost | Very High |

**The cliff:** Going from garage to office is TERRIFYING. Suddenly you're burning $50K+/month. If your first game with the team flops, you can go bankrupt. This is one of GDT's most memorable moments.

### BeerBrew's Scaling Curve

```
Garage (solo):
  - You do everything: brew, clean, sell, drink
  - Quality limited by your skill and equipment
  - But costs are nearly zero. Safe to experiment and fail
  - THIS IS WHERE LEARNING HAPPENS (the Brulosophy phase)

First Hire (the GDT "office cliff"):
  - Suddenly paying $500+/week in salary
  - Must brew AND sell consistently to cover payroll
  - But: assistant brewer means better quality, fewer off-flavors
  - The GDT feeling: "I need to make this work or I'm broke"

Full Team (3-5 staff):
  - Specialists: head brewer, cellarman, QA, taproom, sales
  - Can run 2-3 brews in parallel with multiple fermenters
  - Quality ceiling much higher than solo
  - But: $2-5K/week in costs. Must keep pipeline full
  - Staff assignment during brew phases (like GDT specialization)
    → Cellarman assigned to fermentation = fewer off-flavor bubbles
    → QA assigned to conditioning = faster off-flavor cleanup
    → Head brewer on mash = more quality bubbles in Phase 1

Empire (Galway Bay model):
  - 10+ staff across brewery and pubs
  - Multiple brew lines, packaging, distribution
  - Pub managers generate revenue independently
  - The challenge shifts from "make good beer" to "manage a business"
  - Like GDT late game: it's about engine reuse, sequels, franchise management
```

---

## 8. THE "WHEN TO SHIP" DECISION

### GDT's Version
During bug fixing, a progress bar shows bugs being eliminated. Player can hit "Ship" at any time. More time = fewer bugs = better review. But time = money.

**The strategic dimension:** In GDT, you sometimes WANT to leave some bugs in. Why? Because your Game Score is compared to your high score. If you make a "perfect" game too early, you've set a bar that's hard to beat next time. Some players intentionally ship with bugs to manage the high score curve.

### BeerBrew's Version
During conditioning, off-flavors are eliminated over time. Player can hit "Package" at any time.

**The strategic dimension for brewing:**

```
When to package? Depends on context:

Scenario 1: "Cash emergency"
  - Rent due next week. Need revenue NOW
  - Package at Week 0. Beer is "green" but drinkable
  - Sell it. Pay rent. Survive
  - → Lower quality, lower price, but ALIVE

Scenario 2: "Competition in 3 weeks"
  - Your stout needs to be PERFECT for the competition
  - Condition for 3 weeks. Maximum quality
  - → Costs 3 weeks of fermenter space + salary
  - → But a gold medal = prize money + reputation + ingredient unlocks

Scenario 3: "Pipeline management"
  - You have 3 fermenters. 2 are full of conditioning beer.
  - Do you package one early to free the fermenter for a new batch?
  - → Balance quality vs throughput

Scenario 4: "The GDT high-score trick" (optional advanced mechanic)
  - Your reputation for Pale Ale is set by your best one
  - If you release a PERFECT pale ale (95 score), next one needs to match
  - Maybe sometimes "good enough" (85) is strategically better
  - Keeps expectations manageable for next time
  - → This mirrors the GDT high-score management strategy
```

---

## 9. OFF-FLAVOR BUBBLES AS "BUGS" — THE STYLE-CONTEXT TWIST

### GDT: Bugs Are Always Bad

In GDT, bugs are always negative. Red bubbles = bad. Simple.

### BeerBrew: Off-Flavors Are SOMETIMES Desired

This is where brewing diverges from game dev in a fascinating way:

```
ESTER bubbles (orange/pink):
  In a Lager: BAD. Lagers should be clean
  In a Hefeweizen: GOOD. Banana esters are the POINT
  In a Belgian: GOOD. Fruity complexity is desired
  In a Pale Ale: NEUTRAL-BAD. Unexpected fruit character

PHENOL bubbles (spicy brown):
  In a Lager: BAD. Off-flavor
  In a Hefeweizen: GOOD. Clove character is desired
  In a Saison: GOOD. Peppery complexity
  In an IPA: BAD. Medicinal

DIACETYL bubbles (butter yellow):
  In most beers: BAD. Buttery = flaw
  In some English Bitters: ACCEPTABLE. Traditional character
  → This is a real and controversial thing in brewing

ACIDITY bubbles (sour):
  In a Lager: BAD. Contamination
  In a Berliner Weisse: GOOD. Sourness is the style
  In a Sour IPA: GOOD. Intentional acidity
```

**The game design opportunity:**
Early game, ALL off-flavor bubbles appear red/negative. The player assumes they're all bad.

Later, with experience + style knowledge, the bubbles are RECOLORED based on style context:
- Ester bubbles during a Hefeweizen brew → gold (good!) instead of orange (warning)
- The player SEES that what was a "flaw" is actually a "feature" in the right context

**Discovery moment:** "Wait — those orange ester bubbles turned GOLD when I'm brewing wheat beer? The 'off-flavor' is actually GOOD here!"

This is the deepest Brulosophy insight applied to the game: context matters more than absolute rules.

---

## 10. SUMMARY: GDT → BEERBREW MAPPING TABLE

| GDT System | BeerBrew Equivalent | Key Difference |
|-----------|---------------------|----------------|
| Continuous weekly time | Continuous weekly time | Brew duration varies by style (ales fast, lagers slow) |
| Monthly costs (rent + salary) | Weekly costs (rent + salary + ingredients) | Taproom generates income between brews |
| 3 dev phases + bug fix | 3-4 brew phases + conditioning | Conditioning = GDT bug fixing (optional, quality vs time) |
| Design/Tech/Bug bubbles | Quality/Technique/Off-Flavor bubbles | Off-flavors can be GOOD in certain styles |
| Genre/Topic combos | Style/Ingredient combos | Based on real brewing science, not arbitrary |
| Employee specializations | Staff roles (brewer, cellarman, QA) | Cellarman = fermentation specialist. Huge impact |
| Engine building | Equipment upgrades | Equipment REVEALS information (progressive disclosure) |
| Research unlocks | Research tree unlocks | Unlocks ingredients, styles, techniques, knowledge |
| Bug rate (employee level) | Off-flavor rate (staff skill + equipment) | Fermentation chamber = biggest quality upgrade |
| High score comparison | Per-style reputation tracking | Market expects you to improve each style over time |
| Ship game (bug trade-off) | Package beer (conditioning trade-off) | Quality vs time vs fermenter availability |
| Contract work (idle $) | Contract brewing + taproom (idle $) | Taproom = passive income. Contracts = active |
| Garage → Office cliff | Garage → Micro cliff | First hire = financial pressure. Must produce to survive |
| Game size (small/medium/large/AAA) | Batch size (homebrew/nano/micro/production) | Larger batches = more revenue but more risk (oxidation) |
| Sequel mechanic | Signature beer (same recipe, refined) | Repeating a great recipe builds brand identity |
| Platform selection | Distribution channel selection | Taproom (4x margin) vs wholesale (volume) |

---

## Sources

- [Game Dev Tycoon Cheatsheet](https://www.dbbaldwin.com/game-dev-tycoon-cheatsheet/)
- [GDT Wiki - Game Development Mechanics](https://gamedevtycoon.fandom.com/wiki/Game_Development_Based_on_Experience/1.6.11)
- [GDT Wiki - Tech/Design Points Algorithm](https://gamedevtycoon.fandom.com/wiki/Tech_and_Design_Points_Generation_Algorithm)
- [GDT Wiki - Review Algorithm](https://gamedevtycoon.fandom.com/wiki/Review_Algorithm/1.4.4)
- [GDT Wiki - Bugs](https://gamedevtycoon.fandom.com/wiki/Bugs)
- [GDT Wiki - Staff](https://gamedevtycoon.fandom.com/wiki/Staff)
- [GDT Wiki - Garage Guide](https://gamedevtycoon.fandom.com/wiki/Garage_Guide)
- [GDT Wiki - Contracts](https://gamedevtycoon.fandom.com/wiki/Contracts)
- [GDT Steam Guide](https://steamcommunity.com/sharedfiles/filedetails/?id=216784744)
- [GDT Slider Guide](https://steamcommunity.com/sharedfiles/filedetails/?id=223616653)
- [GDT Slider Percentages by Genre](https://attackofthefanboy.com/guides/best-game-dev-tycoon-slider-percentages-for-each-genre/)
