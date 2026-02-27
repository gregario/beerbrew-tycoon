# Product Spec

## Product Name

BeerBrew Tycoon

## One-Line Description

A brewery management sim where you build a beer empire from your garage, with roguelite meta-progression between runs.

## Problem Statement

Tycoon/management sim fans love the "build from nothing" fantasy but most brewery-themed games are either too casual (idle clickers) or too sim-heavy (spreadsheet simulators). There's no Game Dev Tycoon-style experience for the craft beer theme — something that's approachable, satisfying to optimize, and has real replayability through meta-progression.

## Target Users

**Primary persona — "The Optimizer"**
Mid-core PC gamers (Steam audience) who enjoy management sims and tycoon games. They like systems they can learn, min-max, and master over multiple playthroughs. They've played games like Game Dev Tycoon, Brew Pub Simulator, or Idle Miner Tycoon and want something with more depth than an idle game but less overhead than a full sim.

**Secondary persona — "The Beer Nerd"**
Craft beer enthusiasts who are curious about the brewing process and enjoy the theme even if they're casual gamers.

## User Goals

- Build a brewery from a garage operation to a thriving business
- Experiment with recipes and discover what the market wants
- Make strategic decisions about growth direction (artisan vs. mass-market)
- Unlock new capabilities between runs to tackle harder challenges
- See their brewery come to life visually as they upgrade and grow

## Core Concept

### Inspiration: Game Dev Tycoon

The primary mechanical inspiration is [Game Dev Tycoon](https://store.steampowered.com/app/239820/Game_Dev_Tycoon/). The following elements are adapted from GDT:

| GDT Mechanic | BeerBrew Equivalent |
|---|---|
| Choose topic + genre | Choose beer style + recipe ingredients |
| 3-phase development with sliders | Brewing phases (mashing, boiling, fermenting) with sliders |
| Tech vs. Design balance per genre | Flavor vs. Technique balance per beer style |
| Game gets reviewed and scored | Beer gets rated by market, critics, and competitions |
| Don't repeat same combo | Market saturation — same recipe loses novelty |
| Garage → Office → Upgraded office → AAA | Garage → Microbrewery → Artisan Brewery OR Mass-Market Brewery |
| Research new features and engines | Research new ingredients, equipment, and techniques |
| Hire and assign employees to fields | Hire and assign brewers to stations |

### Brewery Progression Stages

1. **Garage** — Solo homebrewer. Small batches, limited equipment, one station. Learn the basics.
2. **Microbrewery** — First real space. Hire 1–2 staff. More stations, medium batches. Sell to local bars and taprooms.
3. **Fork — Choose your path:**
   - **Artisan Brewery** — Focus on quality, reputation, and competition wins. Smaller batches, premium pricing, niche market. High skill ceiling.
   - **Mass-Market Brewery** — Focus on volume, distribution, and brand recognition. Large batches, lower margins, mass appeal. Efficiency game.

### Roguelite Meta-Progression

Each "run" is a full brewery lifecycle from garage to endgame. Between runs, players unlock permanent progression:

- **New beer styles** — Unlock styles you can brew in future runs (like GDT unlocking genres)
- **Equipment blueprints** — Start with knowledge of advanced equipment
- **Ingredient access** — Rare hops, specialty malts available earlier
- **Staff traits** — New employee archetypes with unique bonuses
- **Brewery perks** — Passive bonuses that shape future run strategies

Runs end when the player reaches a win condition (e.g., brewery valuation target, competition grand prize) or goes bankrupt.

### Visual Concept

- **Pixel art** with a fixed isometric camera showing the brewery interior
- The room has a **fixed number of station slots** where equipment upgrades are placed
- Employees stand at assigned stations; thought bubbles show flavor notes, ideas, or status
- As the brewery grows, the visible room expands or changes entirely (garage → industrial space)
- No free-placement building — upgrades snap to predefined positions
- Clean, readable UI overlays for management decisions

### Core Brewing Loop

1. **Choose a beer style** — Select from unlocked styles (Lager, IPA, Stout, etc.)
2. **Design the recipe** — Pick ingredients (malts, hops, yeast, adjuncts) that affect flavor profile
3. **Brew through phases** — Allocate effort via sliders across brewing stages:
   - **Mashing** — Grain selection, temperature control (affects body and sweetness)
   - **Boiling** — Hop additions, timing (affects bitterness and aroma)
   - **Fermenting** — Yeast management, duration (affects alcohol, clarity, complexity)
4. **Beer is scored** — Quality is calculated from slider allocation, recipe-style match, ingredient quality, and staff skill
5. **Sell and evaluate** — Revenue depends on quality score, market demand, pricing, and reputation

### Key Quality Mechanics

- Each beer style has an ideal **Flavor vs. Technique balance** (like GDT's Design vs. Tech per genre)
- Slider allocation in each phase produces "flavor points" and "technique points"
- The closer the ratio matches the style's ideal, the higher the quality multiplier
- Repeating the exact same recipe reduces novelty score (market gets bored)
- Staff assigned to stations generate bonus points based on their specialization

## Value Proposition

- **The Game Dev Tycoon feel** applied to a beloved, universally relatable theme (beer)
- **Meaningful replayability** through roguelite meta-progression — no two runs play the same
- **Strategic forking** — the artisan vs. mass-market split creates genuinely different play experiences
- **Approachable depth** — easy to start brewing in the garage, deep enough to optimize over many runs

## Out of Scope

- Multiplayer or online features
- Real-time brewery building / free-placement construction (this is not a city builder)
- Realistic brewing simulation (fun and systems-depth over realism)
- Story mode or narrative campaign
- Microtransactions or free-to-play economy

## Platform and Distribution

- **Engine:** Godot 4
- **Primary platform:** PC (Windows, Mac, Linux) via Steam
- **Future portability:** Godot exports to Android/iOS natively. Design with resolution-independent UI and reasonable touch targets from the start so mobile porting is a UI adaptation pass, not a rewrite.

## Success Metrics

- Steam wishlist conversions and positive review ratio (>80% positive)
- Average playtime per user above 8 hours (indicates depth and replayability)
- Multiple runs per player (indicates meta-progression is working)
- Community engagement — recipe sharing, strategy discussions

## References and Inspiration

- [Game Dev Tycoon](https://store.steampowered.com/app/239820/Game_Dev_Tycoon/) — Primary mechanical inspiration (progression stages, slider-based development, quality scoring)
- [Brew Pub Simulator](https://store.steampowered.com/) — Theme reference
- [Hades](https://store.steampowered.com/app/1145360/Hades/) / [Slay the Spire](https://store.steampowered.com/app/646570/Slay_the_Spire/) — Roguelite meta-progression models
- [Kairosoft games](https://kairosoft.net/) (Game Dev Story, Cafeteria Nipponica) — Pixel art management sim aesthetic
