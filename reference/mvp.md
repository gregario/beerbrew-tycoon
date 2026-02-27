# MVP Spec

## MVP Goal

Deliver a single complete run of the garage stage — the player can brew beers, get scored, earn money, and either hit a milestone goal or go bankrupt. The core brewing loop must feel satisfying on its own before any progression systems are layered on top.

## MVP Scope

### Included Features

- [ ] **Garage brewery view** — Pixel art isometric room with a single fixed layout. One brewer (the player character), 2–3 station slots for equipment.
- [ ] **Starting equipment** — Basic kettle, fermenter, and bottling station pre-placed in the garage. No equipment purchasing yet (that comes with the microbrewery stage).
- [ ] **Beer style selection** — 4 starting styles available: Lager, Pale Ale, Wheat Beer, Stout. Each has a defined ideal Flavor/Technique ratio.
- [ ] **Recipe design** — Pick from a base set of ingredients per category:
  - Malts (3–4 options): affect body, sweetness, color
  - Hops (3–4 options): affect bitterness, aroma
  - Yeast (2–3 options): affect fermentation character
- [ ] **Brewing phase sliders** — 3 phases (Mashing, Boiling, Fermenting), each with a slider that distributes effort and generates Flavor and Technique points.
- [ ] **Quality scoring** — Score calculated from: Flavor/Technique ratio vs. style ideal, ingredient-style compatibility, and a novelty modifier (repeating exact recipes scores lower).
- [ ] **Market and selling** — After brewing, the beer is sold. Revenue depends on quality score and a simple demand system (some styles are more popular in the current market window).
- [ ] **Money and turns** — Player has a cash balance. Each brew costs ingredients. The game advances in turns (each brew = 1 turn). Rent is due every N turns.
- [ ] **Win/lose conditions** — Win: reach a cash milestone (e.g., $10,000 saved). Lose: go bankrupt (can't afford rent or next brew).
- [ ] **Market rotation** — Simple demand shifts every few turns. One or two styles get a demand bonus, others are neutral. Displayed to the player before they choose what to brew.
- [ ] **Results screen** — After each brew, show: beer name, style, quality score breakdown, revenue earned, current balance.
- [ ] **Game over screen** — Show final stats: total beers brewed, best score, total revenue, turns survived. Win or loss message.
- [ ] **Basic UI** — Style picker, ingredient picker, phase sliders, brew button, balance display, market demand indicator, results overlay.
- [ ] **Basic audio** — Background music loop, brewing sound effects (bubbling, pouring, clinking).

### Explicitly Excluded

- [ ] Microbrewery stage and beyond (no stage transitions in MVP)
- [ ] Employees and staff management
- [ ] Equipment purchasing or upgrading
- [ ] Roguelite meta-progression (no between-run unlocks)
- [ ] Artisan vs. mass-market fork
- [ ] Beer competitions or critic reviews
- [ ] Research system
- [ ] Thought bubbles above characters
- [ ] Multiple rooms or room expansion
- [ ] Save/load system (runs are short enough to complete in one session)
- [ ] Tutorials or guided onboarding (tooltip hints are acceptable)
- [ ] Settings menu (resolution, audio, keybinds)
- [ ] Steam integration (achievements, cloud saves)

## User Flow

1. **Start game** — Player sees the garage brewery. A simple prompt or tooltip explains the goal: brew great beer and save $10,000.
2. **Check market** — Player sees which beer styles are currently in demand.
3. **Choose a beer style** — Select from 4 available styles.
4. **Design recipe** — Pick one malt, one hop, one yeast from available ingredients.
5. **Brew** — Adjust sliders across 3 brewing phases (Mashing, Boiling, Fermenting). Each slider distributes effort that generates Flavor and Technique points.
6. **See results** — Quality score is calculated and displayed with a breakdown. Revenue is added to balance.
7. **Pay rent** — Every few turns, rent is deducted automatically.
8. **Repeat** — Go back to step 2. Market demand may have shifted.
9. **End** — Game ends when the player hits the cash milestone (win) or can't afford to continue (lose).

## Acceptance Criteria

- [ ] Player can complete a full run from start to win condition in 15–30 minutes
- [ ] Player can go bankrupt and see a game over screen
- [ ] All 4 beer styles produce meaningfully different optimal slider positions
- [ ] Repeating the same recipe produces diminishing quality scores
- [ ] Market demand visibly shifts and affects revenue
- [ ] Quality score breakdown is clear — player understands why they scored high or low
- [ ] The game runs at 60fps on a mid-range PC in Godot 4
- [ ] Pixel art garage scene renders correctly with character and station sprites
- [ ] All UI elements are functional and readable
- [ ] Background music and core sound effects play correctly

## MVP Constraints

- **Solo developer** — All art, code, and design by one person with AI assistance. Scope must stay ruthlessly small.
- **Godot 4** — Use GDScript for simplicity and fast iteration. Avoid C# or GDExtension unless a clear need arises.
- **Pixel art pipeline** — Art must be producible by a solo dev or AI tools. Keep sprite counts low. Reuse palettes.
- **No server** — Entirely offline, single-player. No networking code.
- **Short play sessions** — A single run must be completable in one sitting (15–30 minutes). This keeps the MVP tight and testable.

## Open Questions

- What is the exact cash milestone for the win condition? $10,000 is a placeholder — needs playtesting.
- How many turns between rent payments? Needs to create tension without being punishing in the first few turns.
- Should ingredient costs vary, or all cost the same in MVP? Variable costs add strategy but also complexity.
- How aggressively should the novelty penalty scale? Needs to discourage spam without punishing players who found a good recipe.
- What resolution and aspect ratio should the garage scene target? 16:9 at what base resolution for pixel art?
