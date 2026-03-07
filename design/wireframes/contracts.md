# Wireframe: Stage 4A — Contracts UI

## 1. Brewery Hub — Contracts Button

The brewery hub gains a "Contracts" button in the bottom bar.

```
┌──────────────────────────────────────────────────────────────────────┐
│  Balance: $4,200                      Beers: 14/25                   │
│  MICROBREWERY                                                        │
│                                                                      │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐  │
│  │  Kettle  │  │Fermenter│  │ Bottler │  │  Slot 4  │  │  Slot 5  │  │
│  │ Premium  │  │  Basic  │  │ [Empty] │  │ [Empty]  │  │ [Empty]  │  │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘  └─────────┘  │
│                                                                      │
│  [ Start Brewing > ]  [ Research ]  [ Staff ]  [ Contracts ]         │
└──────────────────────────────────────────────────────────────────────┘
```

- "Contracts" button: right of Staff button
- Style: primary (#5AA9FF bg, dark text, 160x48)
- Badge indicator: if active contracts exist, show count badge (e.g., "Contracts (1)")

### Layout Detail
```
HBoxContainer (bottom bar, centered)
├── Button "Start Brewing >"  (accent #FFC857, 240x48)
├── Button "Research"         (primary #5AA9FF, 160x48)
├── Button "Staff"            (primary #5AA9FF, 160x48)
└── Button "Contracts"        (primary #5AA9FF, 160x48)
```

---

## 2. Contract Board Screen (Overlay)

Full-screen overlay (same pattern as Staff/Research/Equipment overlays).

```
┌──────────────────────────────────────────────────────────────────────┐
│ ░░░░░░░░░░░░░░░░░░░░░░░ dim bg (0.6 alpha) ░░░░░░░░░░░░░░░░░░░░░░ │
│ ░░ ┌────────────────────────────────────────────────────────┐ ░░░░░ │
│ ░░ │  CONTRACT BOARD                Active: 1/2          [X] │ ░░░░░ │
│ ░░ │  ─────────────────────────────────────────────────────  │ ░░░░░ │
│ ░░ │                                                         │ ░░░░░ │
│ ░░ │  ACTIVE CONTRACTS                                       │ ░░░░░ │
│ ░░ │  ┌─────────────────────────────────────────────────┐   │ ░░░░░ │
│ ░░ │  │ Hofbrau Munich — Wants: Lager                    │   │ ░░░░░ │
│ ░░ │  │ Min Quality: 65    Reward: $400 (+$100 bonus)    │   │ ░░░░░ │
│ ░░ │  │ Deadline: 3 turns remaining                      │   │ ░░░░░ │
│ ░░ │  │ Penalty: -$150                                   │   │ ░░░░░ │
│ ░░ │  └─────────────────────────────────────────────────┘   │ ░░░░░ │
│ ░░ │                                                         │ ░░░░░ │
│ ░░ │  ─────────────────────────────────────────────────────  │ ░░░░░ │
│ ░░ │  AVAILABLE CONTRACTS              Refresh: 2 turns      │ ░░░░░ │
│ ░░ │  ┌──────────────────┐ ┌──────────────────┐            │ ░░░░░ │
│ ░░ │  │ Biergarten Co.   │ │ Craft Collective │            │ ░░░░░ │
│ ░░ │  │ Style: IPA       │ │ Style: Stout     │            │ ░░░░░ │
│ ░░ │  │ Quality: 50+     │ │ Quality: 70+     │            │ ░░░░░ │
│ ░░ │  │ Reward: $300     │ │ Reward: $550     │            │ ░░░░░ │
│ ░░ │  │ Deadline: 5 turns│ │ Deadline: 4 turns│            │ ░░░░░ │
│ ░░ │  │ Penalty: -$100   │ │ Penalty: -$200   │            │ ░░░░░ │
│ ░░ │  │   [ Accept ]     │ │   [ Accept ]     │            │ ░░░░░ │
│ ░░ │  └──────────────────┘ └──────────────────┘            │ ░░░░░ │
│ ░░ └────────────────────────────────────────────────────────┘ ░░░░░ │
└──────────────────────────────────────────────────────────────────────┘
```

### Panel: 900x550 (matches card tokens)
- Background: surface (#0B1220), border: muted (#8A9BB1), corner_radius: 4

### Header Row
```
HBoxContainer
├── Label "CONTRACT BOARD"   (lg/32px, white)
├── Label "Active: 1/2"     (sm/20px, muted — shows current/max)
└── Button "X"               (close, danger hover)
```

### Active Contracts Section
Each active contract is a PanelContainer:
```
PanelContainer (surface bg, accent border #FFC857, 4px radius)
├── VBoxContainer (separation: 4, padding: 12)
│   ├── HBoxContainer
│   │   ├── Label "Client Name"      (md/24px, white)
│   │   ├── Label "— Wants: Style"   (md/24px, accent #FFC857)
│   ├── HBoxContainer
│   │   ├── Label "Min Quality: 65"  (sm/20px, muted)
│   │   ├── Label "Reward: $400 (+$100 bonus)" (sm/20px, success #5EE8A4)
│   ├── HBoxContainer
│   │   ├── Label "Deadline: 3 turns remaining" (sm/20px, warning or danger)
│   │   ├── Label "Penalty: -$150"   (sm/20px, danger #FF7B7B)
```

- Deadline color: warning (#FFB347) if > 1 turn, danger (#FF7B7B) if 1 turn remaining
- If no active contracts: show "(No active contracts)" in muted text

### Available Contracts Section
```
HBoxContainer (separation: 16)
├── PanelContainer (contract card, 250x200)
│   ├── VBoxContainer
│   │   ├── Label "Client Name"      (sm/20px, white)
│   │   ├── Label "Style: IPA"       (xs/16px, accent)
│   │   ├── Label "Quality: 50+"     (xs/16px, muted)
│   │   ├── Label "Reward: $300"     (xs/16px, success)
│   │   ├── Label "Deadline: 5 turns" (xs/16px, muted)
│   │   ├── Label "Penalty: -$100"   (xs/16px, danger)
│   │   └── Button "Accept"          (primary #5AA9FF, sm)
└── ... (2-3 contracts)
```

- "Accept" disabled if already at max active contracts (2)
- "Refresh: N turns" label shows turns until new contracts appear
- Available contract cards: surface bg, muted border, 4px radius

---

## 3. Contract Fulfillment Toast

When a brew matches an active contract's style and meets quality threshold:

### Success (quality >= minimum)
```
Toast: "Contract fulfilled! Hofbrau Munich: +$400"
```
- Success color (#5EE8A4)

### Success with Bonus (quality >= minimum + 20)
```
Toast: "Contract fulfilled with bonus! Hofbrau Munich: +$400 (+$100)"
```
- Success color (#5EE8A4)

### Deadline Expiry
```
Toast: "Contract expired! Biergarten Co.: -$100 penalty"
```
- Danger color (#FF7B7B)

---

## 4. Brew Screen — Active Contract Indicator

During style selection (STYLE_SELECT state), show which styles have active contracts:

```
┌──────────────────────────────────────────────────────────┐
│  SELECT BEER STYLE                                        │
│  ─────────────────────────────────────────────────────    │
│                                                          │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────┐   │
│  │  Lager  │  │   IPA   │  │  Stout  │  │  Wheat  │   │
│  │  $120   │  │  $150   │  │  $180   │  │  $130   │   │
│  │         │  │ 📋 x1   │  │         │  │         │   │
│  └─────────┘  └─────────┘  └─────────┘  └─────────┘   │
│                                                          │
└──────────────────────────────────────────────────────────┘
```

- Contract indicator on style cards that match active contracts
- Small badge or icon showing the number of active contracts for that style
- Helps player know which brews will fulfill contracts

---

## 5. Results Overlay — Contract Status

After brewing, the results overlay shows contract fulfillment status if applicable.

```
┌─────────────────────────────────────────────────────┐
│  BREW RESULTS                                        │
│  ─────────────────────────────────────────────       │
│  Quality: 78                  Revenue: $245          │
│  ─────────────────────────────────────────────       │
│                                                      │
│  CONTRACT FULFILLED!                                 │
│  ┌─────────────────────────────────────────────┐    │
│  │ Hofbrau Munich — Lager (Quality 65+)         │    │
│  │ Your quality: 78 — Bonus earned!             │    │
│  │ Reward: $400 + $100 bonus = $500             │    │
│  └─────────────────────────────────────────────┘    │
│                                                      │
│                            [ Continue ]              │
└─────────────────────────────────────────────────────┘
```

- Green border (#5EE8A4) for fulfilled contracts
- Shows quality comparison and total reward
- Only appears if the brew matched an active contract

---

## Color Usage Summary

| Element | Color | Token |
|---------|-------|-------|
| Active contract border | #FFC857 | accent |
| Available contract border | #8A9BB1 | muted |
| Required style text | #FFC857 | accent |
| Reward amount | #5EE8A4 | success |
| Penalty amount | #FF7B7B | danger |
| Deadline (safe) | #FFB347 | warning |
| Deadline (urgent, 1 turn) | #FF7B7B | danger |
| Fulfillment success | #5EE8A4 | success |
| Contract expired | #FF7B7B | danger |
| Button "Accept" | #5AA9FF | primary |
| Refresh counter | #8A9BB1 | muted |

No new theme tokens needed — existing palette covers all states.

---

## Interaction Spec

### Accept Contract Flow
1. Player clicks "Contracts" button on brewery hub
2. Contract board overlay opens (fade-in 0.2s)
3. Player sees available contracts (bottom) and active contracts (top)
4. Player clicks "Accept" on a contract
5. Contract moves from available to active, count updates (e.g., "Active: 1/2")
6. If active contracts at max (2), remaining Accept buttons disable
7. Toast: "Contract accepted: Client Name — Style"

### Fulfillment Flow
1. Player brews a beer (normal flow through style select → recipe → brew)
2. After `execute_brew()`, ContractManager checks active contracts:
   - Style must match the brewed style
   - Quality must be >= minimum_quality
3. If matched: contract marked fulfilled, reward added to balance
   - If quality >= minimum + 20: bonus_reward also added
4. Results overlay shows contract fulfillment panel
5. Toast notification with reward amount

### Deadline Expiry Flow
1. At turn advancement (in `_on_results_continue`), ContractManager ticks deadlines
2. Active contracts with remaining_turns > 0 get decremented
3. If remaining_turns reaches 0 without fulfillment:
   - Contract marked failed
   - Penalty deducted from balance
   - Toast: "Contract expired! Penalty: -$N"
4. Failed contract removed from active list

### Contract Refresh Flow
1. Every 3 turns, ContractManager generates new available contracts
2. Old unfulfilled available contracts are replaced
3. Active contracts are NOT affected by refresh
4. "Refresh: N turns" counter updates

### Save/Load
- `active_contracts` and `available_contracts` persisted in ContractManager.save_state()
- `refresh_counter` persisted (tracks turns until next refresh)
- Contract fulfillment state derived from active contracts (not saved separately)
