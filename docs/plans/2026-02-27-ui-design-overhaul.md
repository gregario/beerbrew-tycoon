# BeerBrew Tycoon — UI Design Overhaul

**Date:** 2026-02-27
**Status:** Approved
**Scope:** Resolution change, theme system, screen redesigns, design stack gap remediation

---

## 1. Resolution & Viewport

**Change:** 320x180 native (4x stretch) → 1280x720 native.

- Stretch mode: `canvas_items`
- Texture filter: `nearest` (preserve pixel-art sprite rendering)
- Pixel-art aesthetic maintained via art assets, Kenney textures, and pixel-friendly fonts — not viewport downscaling
- Remove `window_width_override` and `window_height_override` (no longer needed)

**Rationale:** 320x180 caused buttons off-screen, unreadable text, and cramped layouts. Modern pixel-art games (Stardew Valley, Vampire Survivors) use full resolution with pixel-art styling.

---

## 2. Theme System

### 2.1 Godot Theme Resource

Create `res://assets/ui/theme.tres` — a single shared Theme resource referenced by all UI scenes.

**Primary Kenney color set:** Green

**Button state mapping:**
| State    | Kenney Asset                           |
|----------|----------------------------------------|
| Normal   | `button_rectangle_depth_line.png`      |
| Hover    | `button_rectangle_gloss.png`           |
| Pressed  | `button_rectangle_flat.png`            |
| Disabled | `button_rectangle_border.png` (Grey)   |

**Checkbox/radio mapping:**
| State     | Kenney Asset              |
|-----------|---------------------------|
| Unchecked | `check_round_grey.png`    |
| Checked   | `check_round_color.png`   |

**Slider mapping:**
| Part       | Kenney Asset                                |
|------------|---------------------------------------------|
| Track      | `slide_horizontal_grey_section_wide.png`    |
| Fill       | `slide_horizontal_color_section_wide.png`   |
| Handle     | `slide_hangle.png`                          |

**Star rating:**
| State  | Kenney Asset           |
|--------|------------------------|
| Filled | `star.png`             |
| Empty  | `star_outline_depth.png` |

### 2.2 Typography Scale (1280x720)

| Token | Size | Weight        | Usage                              |
|-------|------|---------------|------------------------------------|
| xs    | 16px | Inter-Regular | Captions, minor labels             |
| sm    | 20px | Inter-Regular | Body text, descriptions, stats     |
| md    | 24px | Inter-Regular | Section headers, button labels     |
| lg    | 32px | Display-Bold  | Page titles, hero numbers          |
| xl    | 40px | Display-Bold  | Score displays, game over titles   |

### 2.3 Spacing Scale

| Token | Value |
|-------|-------|
| xs    | 8px   |
| sm    | 16px  |
| md    | 24px  |
| lg    | 32px  |
| xl    | 48px  |

### 2.4 Color Palette (unchanged)

| Token      | Value    | Usage                          |
|------------|----------|--------------------------------|
| primary    | #5AA9FF  | Selected states, links         |
| accent     | #FFC857  | Demand badges, highlights      |
| background | #0F1724  | Dim overlay behind cards       |
| surface    | #0B1220  | Card backgrounds               |
| muted      | #8A9BB1  | Borders, secondary text        |
| success    | #5EE8A4  | Win state, positive indicators |
| danger     | #FF7B7B  | Loss state, rent warnings      |

---

## 3. Card Layout Pattern

All UI screens use a centered card over a dimmed brewery scene.

- **Dim overlay:** Full-screen ColorRect, `background` color at 60% opacity
- **Card size:** ~900x550px (centered)
- **Card background:** `surface` color at 95% opacity
- **Card border:** 2px `muted` color outline
- **Card corner radius:** 4px
- **Card inner padding:** 32px (lg spacing token)
- **Card anchors:** `CENTER` preset

---

## 4. Screen Redesigns

### 4.1 StylePicker

```
┌─────────────────────────────────────────┐
│                                         │
│   CHOOSE A BEER STYLE        $500      │
│   ─────────────────────────────────────  │
│                                         │
│   ┌─────────────────────────────────┐   │
│   │  Pale Ale          HIGH DEMAND  │   │
│   │  Light, hoppy, refreshing       │   │
│   └─────────────────────────────────┘   │
│   ┌─────────────────────────────────┐   │
│   │  Stout              NORMAL      │   │
│   │  Dark, roasty, full-bodied      │   │
│   └─────────────────────────────────┘   │
│   (... more styles ...)                 │
│                                         │
│                    [ Design Recipe → ]   │
└─────────────────────────────────────────┘
```

- Header bar: title (lg) + balance (md, right-aligned)
- Style buttons: cards-within-card with name (md), description (sm), demand badge
- Demand badge: `accent` color text for HIGH DEMAND
- Selected state: `primary` color border highlight
- CTA button: bottom-right, always visible

### 4.2 RecipeDesigner

```
┌─────────────────────────────────────────────┐
│                                             │
│   DESIGN YOUR RECIPE                        │
│   ─────────────────────────────────────────  │
│                                             │
│   MALT            HOPS           YEAST      │
│   ● Pale          ● Cascade      ● Ale      │
│   ○ Crystal       ○ Centennial   ○ Lager    │
│   ○ Munich        ○ Hallertau    ○ Wheat    │
│   ○ Roasted       ○ EKG                     │
│                                             │
│   ┌─────────────────────────────────────┐   │
│   │ Pale Malt  ·  Cascade  ·  Ale Yeast │   │
│   └─────────────────────────────────────┘   │
│                      [ Start Brewing → ]    │
└─────────────────────────────────────────────┘
```

- Three equal columns with bold category headers (md)
- Kenney radio buttons for selection (check_round assets)
- Summary bar: distinct styled panel at bottom
- CTA bottom-right

### 4.3 BrewingPhases

```
┌─────────────────────────────────────────┐
│                                         │
│   BREWING PHASES                        │
│   ─────────────────────────────────────  │
│   Adjust effort across brewing phases.  │
│                                         │
│   MASHING  (Technique-heavy)            │
│   ░░░░░░░░░████████░░░░░░░░░░░░        │
│                 50                       │
│                                         │
│   BOILING  (Balanced)                   │
│   ░░░░░░░░░████████░░░░░░░░░░░░        │
│                 50                       │
│                                         │
│   FERMENTING  (Flavor-heavy)            │
│   ░░░░░░░░░████████░░░░░░░░░░░░        │
│                 50                       │
│                                         │
│   ┌────────────────┬────────────────┐   │
│   │  Flavor: 75    │  Technique: 75 │   │
│   └────────────────┴────────────────┘   │
│                          [ Brew! ]      │
└─────────────────────────────────────────┘
```

- Kenney slider assets (wide variant) — larger hit targets
- Value label below each slider (sm)
- Phase labels: name (md) + description in `muted` color (sm)
- Preview scores in a 2-column footer bar
- Generous vertical spacing (lg between groups)

### 4.4 ResultsOverlay

```
┌─────────────────────────────────────────┐
│                                         │
│   BREW COMPLETE!                        │
│   ─────────────────────────────────────  │
│   Pale Ale                              │
│   Pale Malt · Cascade · Ale Yeast       │
│                                         │
│          ┌──────────────┐               │
│          │    78/100    │               │
│          │   ★★★★☆     │               │
│          └──────────────┘               │
│                                         │
│   Ratio ····· 18   Ingredients ·· 22   │
│   Novelty ··· 20   Effort ······ 18   │
│   ─────────────────────────────────────  │
│   Revenue:  +$145          Balance: $645│
│                                         │
│   ⚠ Rent due next turn: -$100          │
│                       [ Continue → ]    │
└─────────────────────────────────────────┘
```

- Quality score as hero element (xl size, centered)
- Star rating using Kenney star/star_outline assets
- Breakdown: 2x2 grid with dot leaders (sm)
- Revenue/balance single row with separator
- Rent warning: `danger` colored alert bar
- Score panel: `accent` border

### 4.5 GameOverScreen

```
┌─────────────────────────────────────────┐
│                                         │
│         BREWERY SUCCESS!                │
│                                         │
│   You saved $1,200 and built a          │
│   thriving garage brewery!              │
│   ─────────────────────────────────────  │
│                                         │
│   Turns Played ········· 12            │
│   Best Quality ········· 92            │
│   Total Revenue ········ $2,400        │
│   Final Balance ········ $1,200        │
│   ─────────────────────────────────────  │
│                                         │
│       [ New Run ]        [ Quit ]       │
└─────────────────────────────────────────┘
```

- Win: title in `success` color, subtle green tint on card
- Loss: title in `danger` color, subtle red tint on card
- Stats: structured list with dot leaders (sm)
- Buttons centered, Kenney styled

---

## 5. Design Stack Gap Analysis

### 5.1 Philosophical Gaps

| Gap | Description | Remediation |
|-----|-------------|-------------|
| No responsive layout system | Tokens define spacing but no guidance on overflow, scroll, or variable content amounts | Define overflow strategies per component (scroll, truncate, paginate) |
| No component patterns | Only raw tokens exist, no card/badge/header/alert specs | Create component pattern library with specs |
| No state design | No hover/pressed/disabled/selected/focused specs | Map Kenney variants to interaction states |
| No typography hierarchy | Five sizes but no usage rules (when title vs body vs caption) | Define type scale with semantic roles |
| No accessibility specs | No contrast ratios, min touch targets, keyboard nav patterns | Add WCAG AA checks, 44px min touch targets |
| No animation language | Zero motion guidance — how do screens transition? | Define fade/slide durations, easing curves |
| No information hierarchy | No primary/secondary/tertiary visual weight system | Define 3 levels of visual emphasis per screen |
| No error/empty/loading states | Undesigned states for missing data, failures, loading | Design fallback states for each screen |

### 5.2 UI Kit Gaps (Kenney doesn't provide)

| Missing Component | Needed For | Solution |
|-------------------|------------|----------|
| Panel/card backgrounds | Card containers on every screen | Create nine-slice from Kenney button assets or design custom |
| Progress bars | Future: brew progress, XP | Repurpose slider track assets |
| Tabs | Future: multi-section screens | Build from button assets |
| Tooltips | Ingredient/stat explanations | Custom: small panel + arrow |
| Scroll containers | Growing style lists | Godot ScrollContainer + custom scrollbar from slider assets |
| Dropdown/select | Settings, filters | Custom: input + panel + list |
| Modal chrome | Confirm dialogs | Smaller card variant |
| Toast/notification | "Rent paid!", achievements | Custom: small card, auto-dismiss |
| Game-concept icons | Beer, malt, hops, yeast, money, quality | Source or create pixel-art icon set |
| Toggle switch | Settings (sound on/off) | Repurpose checkbox assets or create custom |

### 5.3 Design Process Gaps

| Gap | Remediation |
|-----|-------------|
| No wireframe-to-implementation pipeline | Define format: ASCII wireframe in plan doc → Godot scene structure mapping |
| No token-to-Theme automation | Create GDScript or build script that reads theme.json → generates theme.tres |
| No design review checklist | Create checklist: spacing, colors, typography, states, accessibility |
| No scaling/aspect ratio strategy | Define behavior for window resize and fullscreen at non-16:9 ratios |

---

## 6. Out of Scope (Future Iterations)

- Brewery scene redesign (currently colored rectangles)
- Custom pixel-art sprites and animations
- Sound design system
- Settings/options screen
- Save/load UI
- Inventory/collection screens
- Meta-progression UI
