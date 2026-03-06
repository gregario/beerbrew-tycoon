# Stage 4C — Market & Distribution Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the simple MarketSystem with a full MarketManager featuring seasonal demand cycles, trending styles, market saturation, distribution channels, player pricing, and market research — plus a SELL step in the brew flow and Market Forecast UI.

**Architecture:** MarketManager autoload replaces MarketSystem. New SELL state between RESULTS and EQUIPMENT_MANAGE. SellOverlay handles distribution allocation and pricing. MarketForecast overlay (tabbed) provides informational view from the hub.

**Tech Stack:** Godot 4 / GDScript, GUT testing framework, programmatic UI (no .tscn for overlays)

**Design Doc:** `docs/plans/2026-03-06-stage4c-market-distribution-design.md`

**Stack Profile:** Read `stacks/godot/STACK.md` before writing any code.

---

## Task 1: MarketManager Core — Seasonal Cycles

Replace MarketSystem with MarketManager. Implement seasonal demand cycles (4 seasons × 6 turns).

**Files:**
- Create: `src/autoloads/MarketManager.gd`
- Create: `src/tests/test_market_manager.gd`
- Modify: `src/autoloads/MarketSystem.gd` (will be deleted after migration)
- Modify: `src/project.godot` (swap autoload registration)

**Step 1: Write failing tests for seasonal cycles**

```gdscript
# src/tests/test_market_manager.gd
extends GutTest

var manager: Node

func before_each() -> void:
	manager = load("res://autoloads/MarketManager.gd").new()
	add_child_autofree(manager)
	manager.register_styles(["pale_ale", "stout", "ipa", "wheat_beer"])

func after_each() -> void:
	manager = null

# -- Seasonal cycles --

func test_initial_season_is_spring() -> void:
	manager.initialize()
	assert_eq(manager.current_season, 0, "Should start in Spring (season 0)")

func test_season_names() -> void:
	assert_eq(manager.SEASON_NAMES, ["Spring", "Summer", "Fall", "Winter"])

func test_season_advances_after_6_turns() -> void:
	manager.initialize()
	for i in range(6):
		manager.tick()
	assert_eq(manager.current_season, 1, "Should be Summer after 6 ticks")

func test_season_wraps_after_24_turns() -> void:
	manager.initialize()
	for i in range(24):
		manager.tick()
	assert_eq(manager.current_season, 0, "Should wrap back to Spring")

func test_seasonal_modifier_returns_float() -> void:
	manager.initialize()
	var mod: float = manager.get_seasonal_modifier("stout")
	assert_typeof(mod, TYPE_FLOAT)

func test_stout_has_positive_winter_modifier() -> void:
	manager.initialize()
	# Advance to Winter (season 3 = turns 18-23)
	for i in range(18):
		manager.tick()
	assert_eq(manager.current_season, 3, "Should be Winter")
	var mod: float = manager.get_seasonal_modifier("stout")
	assert_gt(mod, 0.0, "Stout should have positive modifier in Winter")

func test_seasonal_modifier_for_unknown_style_is_zero() -> void:
	manager.initialize()
	assert_eq(manager.get_seasonal_modifier("nonexistent"), 0.0)

func test_get_season_turn_returns_position_within_season() -> void:
	manager.initialize()
	manager.tick()
	manager.tick()
	assert_eq(manager.season_turn, 2)

func test_get_season_name() -> void:
	manager.initialize()
	assert_eq(manager.get_season_name(), "Spring")

# -- Demand multiplier (basic, no trends/saturation yet) --

func test_get_demand_multiplier_includes_seasonal() -> void:
	manager.initialize()
	# In Spring, pale_ale should have its Spring modifier applied
	var demand: float = manager.get_demand_multiplier("pale_ale")
	var expected: float = 1.0 + manager.get_seasonal_modifier("pale_ale")
	assert_almost_eq(demand, expected, 0.001)

func test_demand_multiplier_clamped_minimum() -> void:
	manager.initialize()
	# Even with worst modifiers, demand >= 0.3
	var demand: float = manager.get_demand_multiplier("pale_ale")
	assert_gte(demand, 0.3)

func test_demand_multiplier_clamped_maximum() -> void:
	manager.initialize()
	var demand: float = manager.get_demand_multiplier("pale_ale")
	assert_lte(demand, 2.5)
```

**Step 2: Run tests to verify they fail**

Run: `make test` (or the GUT runner command)
Expected: FAIL — `MarketManager.gd` doesn't exist yet

**Step 3: Implement MarketManager with seasonal cycles**

```gdscript
# src/autoloads/MarketManager.gd
extends Node

## MarketManager — manages seasonal demand, trends, saturation, channels, pricing.
## Replaces MarketSystem.

signal demand_changed()
signal season_changed(season_name: String)
signal trend_started(style_id: String)
signal trend_ended(style_id: String)

# -- Constants --
const SEASON_NAMES: Array[String] = ["Spring", "Summer", "Fall", "Winter"]
const TURNS_PER_SEASON: int = 6
const DEMAND_MIN: float = 0.3
const DEMAND_MAX: float = 2.5

# Seasonal modifiers: {style_id: [spring, summer, fall, winter]}
const SEASONAL_MODIFIERS: Dictionary = {
	"pale_ale":   [0.1, 0.2, 0.0, -0.1],
	"ipa":        [0.0, 0.1, 0.2, 0.0],
	"stout":      [-0.1, -0.2, 0.1, 0.3],
	"wheat_beer": [0.2, 0.3, 0.0, -0.2],
	"lager":      [0.1, 0.3, 0.1, -0.1],
	"porter":     [-0.1, -0.2, 0.2, 0.2],
	"saison":     [0.3, 0.1, -0.1, -0.2],
}

# -- State --
var _style_ids: Array = []
var current_season: int = 0
var season_turn: int = 0
var _market_turn: int = 0

func register_styles(style_ids: Array) -> void:
	_style_ids = style_ids.duplicate()

func initialize() -> void:
	current_season = 0
	season_turn = 0
	_market_turn = 0

func tick() -> void:
	_market_turn += 1
	season_turn += 1
	if season_turn >= TURNS_PER_SEASON:
		season_turn = 0
		current_season = (current_season + 1) % 4
		season_changed.emit(get_season_name())

func get_season_name() -> String:
	return SEASON_NAMES[current_season]

func get_seasonal_modifier(style_id: String) -> float:
	var mods: Array = SEASONAL_MODIFIERS.get(style_id, [])
	if mods.is_empty():
		return 0.0
	return mods[current_season]

func get_demand_multiplier(style_id: String) -> float:
	var base: float = 1.0
	base += get_seasonal_modifier(style_id)
	return clampf(base, DEMAND_MIN, DEMAND_MAX)

# -- Backward compatibility (MarketSystem API) --
func get_demand_weight(style_id: String) -> float:
	return get_demand_multiplier(style_id)

func get_all_demand_weights() -> Dictionary:
	var weights: Dictionary = {}
	for sid in _style_ids:
		weights[sid] = get_demand_multiplier(sid)
	return weights

func reset() -> void:
	initialize()
```

**Step 4: Run tests to verify they pass**

Run: `make test`
Expected: All new seasonal cycle tests PASS

**Step 5: Commit**

```bash
git add src/autoloads/MarketManager.gd src/tests/test_market_manager.gd
git commit -m "feat: add MarketManager with seasonal demand cycles (Stage 4C task 1)"
```

---

## Task 2: MarketManager — Trending Styles

Add trending style system: random style spike every 8-12 turns, lasts 4-6 turns, +0.5 bonus.

**Files:**
- Modify: `src/autoloads/MarketManager.gd`
- Modify: `src/tests/test_market_manager.gd`

**Step 1: Write failing tests for trending styles**

Add to `test_market_manager.gd`:

```gdscript
# -- Trending styles --

func test_no_trend_initially() -> void:
	manager.initialize()
	assert_eq(manager.active_trend_style, "", "No trend at start")

func test_trend_bonus_constant() -> void:
	assert_eq(manager.TREND_BONUS, 0.5)

func test_get_trend_bonus_zero_when_no_trend() -> void:
	manager.initialize()
	assert_eq(manager.get_trend_bonus("pale_ale"), 0.0)

func test_get_trend_bonus_when_trending() -> void:
	manager.initialize()
	manager.active_trend_style = "pale_ale"
	manager.trend_remaining_turns = 4
	assert_eq(manager.get_trend_bonus("pale_ale"), 0.5)

func test_trend_bonus_zero_for_non_trending_style() -> void:
	manager.initialize()
	manager.active_trend_style = "stout"
	manager.trend_remaining_turns = 4
	assert_eq(manager.get_trend_bonus("pale_ale"), 0.0)

func test_trend_expires_after_duration() -> void:
	manager.initialize()
	manager.active_trend_style = "pale_ale"
	manager.trend_remaining_turns = 2
	manager.tick()
	assert_eq(manager.trend_remaining_turns, 1)
	manager.tick()
	assert_eq(manager.active_trend_style, "", "Trend should expire")

func test_trend_included_in_demand_multiplier() -> void:
	manager.initialize()
	manager.active_trend_style = "pale_ale"
	manager.trend_remaining_turns = 4
	var demand: float = manager.get_demand_multiplier("pale_ale")
	var seasonal: float = manager.get_seasonal_modifier("pale_ale")
	var expected: float = clampf(1.0 + seasonal + 0.5, 0.3, 2.5)
	assert_almost_eq(demand, expected, 0.001)

func test_new_trend_starts_within_range() -> void:
	manager.initialize()
	# Force next_trend_in to 1 so a trend triggers on next tick
	manager._next_trend_in = 1
	manager.tick()
	if manager.active_trend_style != "":
		assert_true(manager._style_ids.has(manager.active_trend_style))
		assert_gte(manager.trend_remaining_turns, 4)
		assert_lte(manager.trend_remaining_turns, 6)
```

**Step 2: Run tests — expect FAIL**

**Step 3: Implement trending styles in MarketManager**

Add to `MarketManager.gd`:

```gdscript
# -- Trend constants --
const TREND_BONUS: float = 0.5
const TREND_MIN_INTERVAL: int = 8
const TREND_MAX_INTERVAL: int = 12
const TREND_MIN_DURATION: int = 4
const TREND_MAX_DURATION: int = 6

# -- Trend state --
var active_trend_style: String = ""
var trend_remaining_turns: int = 0
var _next_trend_in: int = 0
```

Update `initialize()`:
```gdscript
func initialize() -> void:
	current_season = 0
	season_turn = 0
	_market_turn = 0
	active_trend_style = ""
	trend_remaining_turns = 0
	_next_trend_in = randi_range(TREND_MIN_INTERVAL, TREND_MAX_INTERVAL)
```

Update `tick()`:
```gdscript
func tick() -> void:
	_market_turn += 1
	season_turn += 1
	if season_turn >= TURNS_PER_SEASON:
		season_turn = 0
		current_season = (current_season + 1) % 4
		season_changed.emit(get_season_name())
	# Trend tick
	if trend_remaining_turns > 0:
		trend_remaining_turns -= 1
		if trend_remaining_turns <= 0:
			var old_style := active_trend_style
			active_trend_style = ""
			trend_ended.emit(old_style)
	_next_trend_in -= 1
	if _next_trend_in <= 0 and active_trend_style == "":
		_start_new_trend()
```

Add trend methods:
```gdscript
func get_trend_bonus(style_id: String) -> float:
	if style_id == active_trend_style and trend_remaining_turns > 0:
		return TREND_BONUS
	return 0.0

func _start_new_trend() -> void:
	if _style_ids.is_empty():
		return
	var candidates := _style_ids.duplicate()
	candidates.shuffle()
	active_trend_style = candidates[0]
	trend_remaining_turns = randi_range(TREND_MIN_DURATION, TREND_MAX_DURATION)
	_next_trend_in = randi_range(TREND_MIN_INTERVAL, TREND_MAX_INTERVAL)
	trend_started.emit(active_trend_style)
```

Update `get_demand_multiplier()`:
```gdscript
func get_demand_multiplier(style_id: String) -> float:
	var base: float = 1.0
	base += get_seasonal_modifier(style_id)
	base += get_trend_bonus(style_id)
	return clampf(base, DEMAND_MIN, DEMAND_MAX)
```

Update `reset()` to call `initialize()`.

**Step 4: Run tests — expect PASS**

**Step 5: Commit**

```bash
git add src/autoloads/MarketManager.gd src/tests/test_market_manager.gd
git commit -m "feat: add trending style system to MarketManager (Stage 4C task 2)"
```

---

## Task 3: MarketManager — Market Saturation

Per-style saturation: +0.1 per brew, recovers -0.05 per turn when not brewing, floor 0.5 penalty.

**Files:**
- Modify: `src/autoloads/MarketManager.gd`
- Modify: `src/tests/test_market_manager.gd`

**Step 1: Write failing tests**

```gdscript
# -- Market saturation --

func test_initial_saturation_is_zero() -> void:
	manager.initialize()
	assert_eq(manager.get_saturation_penalty("pale_ale"), 0.0)

func test_record_brew_increases_saturation() -> void:
	manager.initialize()
	manager.record_brew("pale_ale")
	assert_almost_eq(manager.get_saturation_penalty("pale_ale"), 0.1, 0.001)

func test_multiple_brews_stack_saturation() -> void:
	manager.initialize()
	manager.record_brew("pale_ale")
	manager.record_brew("pale_ale")
	manager.record_brew("pale_ale")
	assert_almost_eq(manager.get_saturation_penalty("pale_ale"), 0.3, 0.001)

func test_saturation_capped_at_floor() -> void:
	manager.initialize()
	for i in range(10):
		manager.record_brew("pale_ale")
	assert_almost_eq(manager.get_saturation_penalty("pale_ale"), 0.5, 0.001)

func test_saturation_recovers_on_tick() -> void:
	manager.initialize()
	manager.record_brew("pale_ale")
	manager.record_brew("pale_ale")  # 0.2 saturation
	manager.tick()  # recovers 0.05 → 0.15
	assert_almost_eq(manager.get_saturation_penalty("pale_ale"), 0.15, 0.001)

func test_saturation_does_not_go_below_zero() -> void:
	manager.initialize()
	manager.record_brew("pale_ale")  # 0.1
	manager.tick()  # 0.05
	manager.tick()  # 0.0
	manager.tick()  # still 0.0
	assert_almost_eq(manager.get_saturation_penalty("pale_ale"), 0.0, 0.001)

func test_saturation_only_recovers_for_styles_not_brewed_this_turn() -> void:
	manager.initialize()
	manager.record_brew("pale_ale")
	manager.record_brew("stout")
	# pale_ale: 0.1, stout: 0.1
	# Now tick — both should recover since record_brew is called separately from tick
	manager.tick()
	assert_almost_eq(manager.get_saturation_penalty("pale_ale"), 0.05, 0.001)

func test_saturation_subtracted_from_demand() -> void:
	manager.initialize()
	manager.record_brew("pale_ale")
	manager.record_brew("pale_ale")  # 0.2 saturation
	var demand: float = manager.get_demand_multiplier("pale_ale")
	var seasonal: float = manager.get_seasonal_modifier("pale_ale")
	var expected: float = clampf(1.0 + seasonal - 0.2, 0.3, 2.5)
	assert_almost_eq(demand, expected, 0.001)

func test_saturation_reset_on_initialize() -> void:
	manager.initialize()
	manager.record_brew("pale_ale")
	manager.initialize()
	assert_eq(manager.get_saturation_penalty("pale_ale"), 0.0)
```

**Step 2: Run tests — expect FAIL**

**Step 3: Implement saturation**

Add to `MarketManager.gd`:

```gdscript
# -- Saturation constants --
const SATURATION_PER_BREW: float = 0.1
const SATURATION_RECOVERY: float = 0.05
const SATURATION_MAX_PENALTY: float = 0.5

# -- Saturation state --
var _saturation: Dictionary = {}  # {style_id: float}
```

Add methods:
```gdscript
func record_brew(style_id: String) -> void:
	var current: float = _saturation.get(style_id, 0.0)
	_saturation[style_id] = minf(current + SATURATION_PER_BREW, SATURATION_MAX_PENALTY)

func get_saturation_penalty(style_id: String) -> float:
	return _saturation.get(style_id, 0.0)

func get_all_saturation() -> Dictionary:
	return _saturation.duplicate()
```

Update `tick()` to add saturation recovery:
```gdscript
# Saturation recovery (all styles decay each turn)
for sid in _saturation.keys():
	_saturation[sid] = maxf(_saturation[sid] - SATURATION_RECOVERY, 0.0)
	if _saturation[sid] == 0.0:
		_saturation.erase(sid)
```

Update `get_demand_multiplier()`:
```gdscript
func get_demand_multiplier(style_id: String) -> float:
	var base: float = 1.0
	base += get_seasonal_modifier(style_id)
	base += get_trend_bonus(style_id)
	base -= get_saturation_penalty(style_id)
	return clampf(base, DEMAND_MIN, DEMAND_MAX)
```

Update `initialize()` to clear `_saturation = {}`.

**Step 4: Run tests — expect PASS**

**Step 5: Commit**

```bash
git add src/autoloads/MarketManager.gd src/tests/test_market_manager.gd
git commit -m "feat: add market saturation to MarketManager (Stage 4C task 3)"
```

---

## Task 4: Distribution Channels

Data model for 4 distribution channels with margin, volume limits, and unlock conditions.

**Files:**
- Modify: `src/autoloads/MarketManager.gd`
- Modify: `src/tests/test_market_manager.gd`

**Step 1: Write failing tests**

```gdscript
# -- Distribution channels --

func test_channel_count() -> void:
	assert_eq(manager.CHANNELS.size(), 4)

func test_taproom_always_unlocked() -> void:
	manager.initialize()
	var unlocked := manager.get_unlocked_channels()
	assert_true(unlocked.any(func(c): return c.id == "taproom"))

func test_channel_has_required_fields() -> void:
	var ch: Dictionary = manager.CHANNELS[0]
	assert_has(ch, "id")
	assert_has(ch, "name")
	assert_has(ch, "margin")
	assert_has(ch, "volume_pct")
	assert_has(ch, "unlock_type")

func test_taproom_margin_is_1() -> void:
	var taproom: Dictionary = manager.get_channel("taproom")
	assert_eq(taproom.margin, 1.0)

func test_local_bars_margin_is_07() -> void:
	var bars: Dictionary = manager.get_channel("local_bars")
	assert_almost_eq(bars.margin, 0.7, 0.001)

func test_retail_margin_is_05() -> void:
	var retail: Dictionary = manager.get_channel("retail")
	assert_almost_eq(retail.margin, 0.5, 0.001)

func test_events_margin_is_15() -> void:
	var events: Dictionary = manager.get_channel("events")
	assert_almost_eq(events.margin, 1.5, 0.001)

func test_is_channel_unlocked_taproom() -> void:
	manager.initialize()
	assert_true(manager.is_channel_unlocked("taproom"))

func test_local_bars_locked_in_garage() -> void:
	manager.initialize()
	# Without BreweryExpansion, treat as garage — bars locked
	assert_false(manager.is_channel_unlocked("local_bars"))

func test_get_max_units_for_channel() -> void:
	manager.initialize()
	# Taproom: 30% of batch_size. With batch_size=1.0 (10 base units), max = 3
	var max_units: int = manager.get_max_units("taproom", 10)
	assert_eq(max_units, 3)

func test_get_max_units_local_bars() -> void:
	var max_units: int = manager.get_max_units("local_bars", 10)
	assert_eq(max_units, 5)

func test_get_max_units_retail() -> void:
	var max_units: int = manager.get_max_units("retail", 10)
	assert_eq(max_units, 10)

func test_get_max_units_events() -> void:
	var max_units: int = manager.get_max_units("events", 10)
	assert_eq(max_units, 2)
```

**Step 2: Run tests — expect FAIL**

**Step 3: Implement distribution channels**

Add to `MarketManager.gd`:

```gdscript
# -- Distribution channels --
# unlock_type: "always", "brewery_stage", "research", "events"
const CHANNELS: Array[Dictionary] = [
	{"id": "taproom", "name": "Taproom", "margin": 1.0, "volume_pct": 0.3, "unlock_type": "always"},
	{"id": "local_bars", "name": "Local Bars", "margin": 0.7, "volume_pct": 0.5, "unlock_type": "brewery_stage"},
	{"id": "retail", "name": "Retail", "margin": 0.5, "volume_pct": 1.0, "unlock_type": "research"},
	{"id": "events", "name": "Events", "margin": 1.5, "volume_pct": 0.2, "unlock_type": "events"},
]

func get_channel(channel_id: String) -> Dictionary:
	for ch in CHANNELS:
		if ch.id == channel_id:
			return ch
	return {}

func get_unlocked_channels() -> Array:
	var result: Array = []
	for ch in CHANNELS:
		if is_channel_unlocked(ch.id):
			result.append(ch)
	return result

func is_channel_unlocked(channel_id: String) -> bool:
	var ch: Dictionary = get_channel(channel_id)
	if ch.is_empty():
		return false
	match ch.unlock_type:
		"always":
			return true
		"brewery_stage":
			if is_instance_valid(BreweryExpansion):
				return BreweryExpansion.current_stage >= BreweryExpansion.Stage.MICROBREWERY
			return false
		"research":
			if is_instance_valid(ResearchManager):
				return ResearchManager.is_unlocked("distribution_retail")
			return false
		"events":
			# Events unlock when a competition has been entered
			if is_instance_valid(CompetitionManager):
				return CompetitionManager.medals_earned.size() > 0
			return false
	return false

func get_max_units(channel_id: String, batch_size: int) -> int:
	var ch: Dictionary = get_channel(channel_id)
	if ch.is_empty():
		return 0
	return int(floor(batch_size * ch.volume_pct))
```

**Step 4: Run tests — expect PASS**

**Step 5: Commit**

```bash
git add src/autoloads/MarketManager.gd src/tests/test_market_manager.gd
git commit -m "feat: add distribution channels to MarketManager (Stage 4C task 4)"
```

---

## Task 5: Player Pricing Logic

Price slider from -30% to +50% of base price. Volume modifier based on price and quality.

**Files:**
- Modify: `src/autoloads/MarketManager.gd`
- Modify: `src/tests/test_market_manager.gd`

**Step 1: Write failing tests**

```gdscript
# -- Player pricing --

func test_default_price_offset_is_zero() -> void:
	manager.initialize()
	assert_eq(manager.get_price_offset(), 0.0)

func test_set_price_offset_stores_value() -> void:
	manager.initialize()
	manager.set_price_offset(0.2)
	assert_almost_eq(manager.get_price_offset(), 0.2, 0.001)

func test_price_offset_clamped_min() -> void:
	manager.initialize()
	manager.set_price_offset(-0.5)
	assert_almost_eq(manager.get_price_offset(), -0.3, 0.001)

func test_price_offset_clamped_max() -> void:
	manager.initialize()
	manager.set_price_offset(0.8)
	assert_almost_eq(manager.get_price_offset(), 0.5, 0.001)

func test_volume_modifier_at_base_price() -> void:
	# offset=0 → volume_modifier=1.0
	var vol: float = manager.calculate_volume_modifier(0.0, 70.0)
	assert_almost_eq(vol, 1.0, 0.001)

func test_volume_modifier_premium_pricing() -> void:
	# offset=+0.5 → volume_modifier = 1.0 + (0 - 0.5) * 0.5 = 0.75
	var vol: float = manager.calculate_volume_modifier(0.5, 70.0)
	assert_almost_eq(vol, 0.75, 0.001)

func test_volume_modifier_discount_pricing() -> void:
	# offset=-0.3 → volume_modifier = 1.0 + (0 - (-0.3)) * 0.5 = 1.15
	var vol: float = manager.calculate_volume_modifier(-0.3, 70.0)
	assert_almost_eq(vol, 1.15, 0.001)

func test_volume_modifier_clamped_min() -> void:
	var vol: float = manager.calculate_volume_modifier(0.5, 20.0)
	assert_gte(vol, 0.3)

func test_volume_modifier_clamped_max() -> void:
	var vol: float = manager.calculate_volume_modifier(-0.3, 90.0)
	assert_lte(vol, 1.5)

func test_low_quality_harsh_premium_penalty() -> void:
	# Quality 40 at +40% should penalize more than quality 90
	var vol_low: float = manager.calculate_volume_modifier(0.4, 40.0)
	var vol_high: float = manager.calculate_volume_modifier(0.4, 90.0)
	assert_lt(vol_low, vol_high, "Low quality should suffer more from premium pricing")

func test_price_offset_resets() -> void:
	manager.initialize()
	manager.set_price_offset(0.3)
	manager.initialize()
	assert_eq(manager.get_price_offset(), 0.0)
```

**Step 2: Run tests — expect FAIL**

**Step 3: Implement pricing logic**

Add to `MarketManager.gd`:

```gdscript
# -- Pricing constants --
const PRICE_OFFSET_MIN: float = -0.3
const PRICE_OFFSET_MAX: float = 0.5
const VOLUME_MOD_MIN: float = 0.3
const VOLUME_MOD_MAX: float = 1.5

# -- Pricing state --
var _price_offset: float = 0.0  # Per-brew, reset each brew

func set_price_offset(offset: float) -> void:
	_price_offset = clampf(offset, PRICE_OFFSET_MIN, PRICE_OFFSET_MAX)

func get_price_offset() -> float:
	return _price_offset

func calculate_volume_modifier(price_offset: float, quality_score: float) -> float:
	# Base volume effect from pricing
	var base_vol: float = 1.0 - price_offset * 0.5
	# Quality adjustment: low quality (< 50) penalizes premium pricing more
	if price_offset > 0.0:
		var quality_factor: float = quality_score / 100.0
		var penalty: float = price_offset * 0.5 * (1.0 - quality_factor)
		base_vol -= penalty
	return clampf(base_vol, VOLUME_MOD_MIN, VOLUME_MOD_MAX)

func get_adjusted_price(base_price: float) -> float:
	return base_price * (1.0 + _price_offset)
```

Update `initialize()` to set `_price_offset = 0.0`.

**Step 4: Run tests — expect PASS**

**Step 5: Commit**

```bash
git add src/autoloads/MarketManager.gd src/tests/test_market_manager.gd
git commit -m "feat: add player pricing to MarketManager (Stage 4C task 5)"
```

---

## Task 6: Market Research + Save/Load

Market research purchase ($100) reveals upcoming trends. Plus save/load for all MarketManager state.

**Files:**
- Modify: `src/autoloads/MarketManager.gd`
- Modify: `src/tests/test_market_manager.gd`

**Step 1: Write failing tests**

```gdscript
# -- Market research --

func test_research_not_purchased_initially() -> void:
	manager.initialize()
	assert_false(manager.research_purchased)

func test_research_cost() -> void:
	assert_eq(manager.RESEARCH_COST, 100)

func test_buy_research_returns_true() -> void:
	manager.initialize()
	# We can't check GameState balance in unit test, so test the flag
	var result: bool = manager.buy_research()
	assert_true(result)
	assert_true(manager.research_purchased)

func test_buy_research_twice_returns_false() -> void:
	manager.initialize()
	manager.buy_research()
	assert_false(manager.buy_research(), "Can only buy once per turn")

func test_research_resets_each_turn() -> void:
	manager.initialize()
	manager.buy_research()
	manager.tick()
	assert_false(manager.research_purchased, "Research resets after tick")

func test_get_trend_forecast_without_research() -> void:
	manager.initialize()
	var forecast: Dictionary = manager.get_trend_forecast()
	assert_false(forecast.has("upcoming_trend"))

func test_get_trend_forecast_with_research() -> void:
	manager.initialize()
	manager._next_trend_in = 2
	manager.buy_research()
	var forecast: Dictionary = manager.get_trend_forecast()
	assert_true(forecast.has("next_trend_in"))

# -- Save/Load --

func test_save_data_returns_dictionary() -> void:
	manager.initialize()
	var data: Dictionary = manager.save_data()
	assert_typeof(data, TYPE_DICTIONARY)

func test_save_load_preserves_season() -> void:
	manager.initialize()
	for i in range(8):
		manager.tick()
	var data: Dictionary = manager.save_data()
	manager.initialize()
	manager.load_data(data)
	assert_eq(manager.current_season, 1)
	assert_eq(manager.season_turn, 2)

func test_save_load_preserves_saturation() -> void:
	manager.initialize()
	manager.record_brew("pale_ale")
	manager.record_brew("pale_ale")
	var data: Dictionary = manager.save_data()
	manager.initialize()
	manager.load_data(data)
	assert_almost_eq(manager.get_saturation_penalty("pale_ale"), 0.2, 0.001)

func test_save_load_preserves_trend() -> void:
	manager.initialize()
	manager.active_trend_style = "stout"
	manager.trend_remaining_turns = 3
	var data: Dictionary = manager.save_data()
	manager.initialize()
	manager.load_data(data)
	assert_eq(manager.active_trend_style, "stout")
	assert_eq(manager.trend_remaining_turns, 3)
```

**Step 2: Run tests — expect FAIL**

**Step 3: Implement research and save/load**

Add to `MarketManager.gd`:

```gdscript
# -- Research --
const RESEARCH_COST: int = 100
var research_purchased: bool = false

func buy_research() -> bool:
	if research_purchased:
		return false
	research_purchased = true
	return true

func get_trend_forecast() -> Dictionary:
	var forecast: Dictionary = {
		"current_season": current_season,
		"season_turn": season_turn,
		"next_season": (current_season + 1) % 4,
		"turns_until_next_season": TURNS_PER_SEASON - season_turn,
	}
	if research_purchased:
		forecast["next_trend_in"] = _next_trend_in
		if active_trend_style != "":
			forecast["active_trend"] = active_trend_style
			forecast["trend_remaining"] = trend_remaining_turns
	return forecast
```

Update `tick()` to reset research: `research_purchased = false` (at the start).

Add save/load:

```gdscript
func save_data() -> Dictionary:
	return {
		"current_season": current_season,
		"season_turn": season_turn,
		"market_turn": _market_turn,
		"active_trend_style": active_trend_style,
		"trend_remaining_turns": trend_remaining_turns,
		"next_trend_in": _next_trend_in,
		"saturation": _saturation.duplicate(),
		"price_offset": _price_offset,
		"research_purchased": research_purchased,
	}

func load_data(data: Dictionary) -> void:
	current_season = data.get("current_season", 0)
	season_turn = data.get("season_turn", 0)
	_market_turn = data.get("market_turn", 0)
	active_trend_style = data.get("active_trend_style", "")
	trend_remaining_turns = data.get("trend_remaining_turns", 0)
	_next_trend_in = data.get("next_trend_in", randi_range(TREND_MIN_INTERVAL, TREND_MAX_INTERVAL))
	_saturation = data.get("saturation", {}).duplicate()
	_price_offset = data.get("price_offset", 0.0)
	research_purchased = data.get("research_purchased", false)
```

**Step 4: Run tests — expect PASS**

**Step 5: Commit**

```bash
git add src/autoloads/MarketManager.gd src/tests/test_market_manager.gd
git commit -m "feat: add market research and save/load to MarketManager (Stage 4C task 6)"
```

---

## Task 7: GameState Integration — SELL State + Revenue Formula

Add SELL state to GameState. Update revenue calculation for multi-channel distribution. Swap MarketSystem → MarketManager references. Update `_on_results_continue` flow.

**Files:**
- Modify: `src/autoloads/GameState.gd` (State enum, calculate_revenue, execute_brew, _on_results_continue, reset)
- Modify: `src/project.godot` (swap MarketSystem autoload for MarketManager)
- Modify: `src/tests/test_economy.gd`
- Modify: `src/tests/test_market_system.gd` → rename to `src/tests/test_market_manager.gd` if not already done

**Step 1: Write failing tests for new revenue formula**

Add to `src/tests/test_economy.gd` (or create new test file):

```gdscript
# -- Multi-channel revenue --

func test_calculate_channel_revenue() -> void:
	# channel_revenue = units × adjusted_price × margin × quality_mult × demand_mult
	var revenue: float = GameState.calculate_channel_revenue(
		5,      # units
		220.0,  # adjusted_price
		1.0,    # margin
		1.5,    # quality_mult
		1.2     # demand_mult
	)
	# 5 × 220 × 1.0 × 1.5 × 1.2 = 1980
	assert_almost_eq(revenue, 1980.0, 0.01)

func test_calculate_total_revenue_single_channel() -> void:
	var allocations: Array = [
		{"channel_id": "taproom", "units": 3}
	]
	var result: Dictionary = GameState.calculate_total_revenue(
		200.0,  # base_price
		0.0,    # price_offset
		70.0,   # quality_score
		1.0,    # demand_mult
		allocations
	)
	assert_has(result, "total")
	assert_has(result, "breakdown")
	assert_gt(result.total, 0.0)

func test_calculate_total_revenue_multi_channel() -> void:
	var allocations: Array = [
		{"channel_id": "taproom", "units": 3},
		{"channel_id": "local_bars", "units": 5}
	]
	var result: Dictionary = GameState.calculate_total_revenue(
		200.0, 0.0, 70.0, 1.0, allocations
	)
	assert_eq(result.breakdown.size(), 2)
	var taproom_rev: float = result.breakdown[0].revenue
	var bars_rev: float = result.breakdown[1].revenue
	assert_gt(taproom_rev, bars_rev / 5 * 3, "Taproom has higher margin")

func test_sell_state_exists() -> void:
	assert_true(GameState.State.has("SELL"))
```

**Step 2: Run tests — expect FAIL**

**Step 3: Implement GameState changes**

Update State enum in `GameState.gd`:
```gdscript
enum State {
	MARKET_CHECK,
	STYLE_SELECT,
	RECIPE_DESIGN,
	BREWING_PHASES,
	RESULTS,
	SELL,             # NEW — between RESULTS and EQUIPMENT_MANAGE
	EQUIPMENT_MANAGE,
	RESEARCH_MANAGE,
	GAME_OVER
}
```

Add static revenue calculation methods:
```gdscript
static func calculate_channel_revenue(
	units: int, adjusted_price: float, margin: float,
	quality_mult: float, demand_mult: float
) -> float:
	return units * adjusted_price * margin * quality_mult * demand_mult

static func calculate_total_revenue(
	base_price: float, price_offset: float, quality_score: float,
	demand_mult: float, allocations: Array
) -> Dictionary:
	var quality_mult: float = quality_to_multiplier(quality_score)
	var adjusted_price: float = base_price * (1.0 + price_offset)
	var total: float = 0.0
	var breakdown: Array = []
	for alloc in allocations:
		var ch: Dictionary = MarketManager.get_channel(alloc.channel_id)
		if ch.is_empty():
			continue
		var rev: float = calculate_channel_revenue(
			alloc.units, adjusted_price, ch.margin, quality_mult, demand_mult
		)
		breakdown.append({
			"channel_id": alloc.channel_id,
			"channel_name": ch.name,
			"units": alloc.units,
			"price": adjusted_price,
			"margin": ch.margin,
			"revenue": rev,
		})
		total += rev
	return {"total": total, "breakdown": breakdown}
```

Update `execute_brew()` to NOT call `calculate_revenue` / `add_revenue` — revenue is now deferred to the SELL step. Store quality result but don't compute revenue yet:
```gdscript
# Line ~303: Remove the old revenue calculation
# OLD: var revenue := calculate_revenue(result["final_score"])
# OLD: add_revenue(revenue)
# NEW: Revenue is calculated in the SELL step
# Still store the result for the SELL overlay to use
```

Add a new function for the SELL step:
```gdscript
func execute_sell(allocations: Array, price_offset: float) -> Dictionary:
	if current_style == null or last_brew_result.is_empty():
		return {}
	var quality_score: float = last_brew_result.get("final_score", 0.0)
	var demand_mult: float = MarketManager.get_demand_multiplier(current_style.style_id)
	var volume_mod: float = MarketManager.calculate_volume_modifier(price_offset, quality_score)
	var result: Dictionary = calculate_total_revenue(
		current_style.base_price, price_offset, quality_score, demand_mult, allocations
	)
	# Apply volume modifier to total
	result.total *= volume_mod
	for i in range(result.breakdown.size()):
		result.breakdown[i].revenue *= volume_mod
	add_revenue(result.total)
	last_brew_result["revenue"] = result.total
	last_brew_result["revenue_breakdown"] = result.breakdown
	last_brew_result["price_offset"] = price_offset
	# Record saturation
	MarketManager.record_brew(current_style.style_id)
	return result
```

Update `_on_results_continue()` — this now triggers from SELL state instead:
- Rename or adjust so it's called after SELL completes
- The `advance_state()` from RESULTS should go to SELL
- The `advance_state()` from SELL should call `_on_results_continue()` then go to EQUIPMENT_MANAGE

Update all `MarketSystem` references to `MarketManager`:
- `MarketSystem.get_demand_weight()` → `MarketManager.get_demand_multiplier()`
- `MarketSystem.should_rotate()` / `rotate_demand()` → `MarketManager.tick()`
- `MarketSystem.initialize_demand()` → `MarketManager.initialize()`

Update `reset()`:
```gdscript
# Replace: MarketSystem.initialize_demand()
# With: MarketManager.initialize()
if is_instance_valid(MarketManager):
	MarketManager.register_styles(_get_style_ids())
	MarketManager.initialize()
```

**Step 4: Run tests — expect PASS**

Also run full test suite to check for regressions:
```bash
make test
```

**Step 5: Update project.godot autoloads**

In `src/project.godot`, replace the MarketSystem autoload line with:
```
[autoload]
MarketManager="*res://autoloads/MarketManager.gd"
```
Remove the MarketSystem line. Delete or keep `MarketSystem.gd` as backup.

**Step 6: Fix any remaining MarketSystem references**

Search all `.gd` files for `MarketSystem` and update to `MarketManager`:
- `src/ui/MarketCheck.gd` (if it exists) — update `get_demand_weight` calls
- `src/tests/test_market_system.gd` — can be deleted (replaced by test_market_manager.gd)
- Any other references

**Step 7: Run full tests — expect all PASS**

**Step 8: Commit**

```bash
git add -A
git commit -m "feat: add SELL state and multi-channel revenue to GameState (Stage 4C task 7)"
```

---

## Task 8: SellOverlay UI

Post-brew overlay where player allocates batch to channels and sets price.

**Files:**
- Create: `src/ui/SellOverlay.gd`
- Modify: `src/scenes/BreweryScene.gd` (wire up SELL state to show overlay)

**Step 1: Implement SellOverlay**

Follow the established overlay pattern (ContractBoard as reference):
- `extends CanvasLayer`
- `signal closed()`
- `signal sale_confirmed(allocations: Array, price_offset: float)`
- Lazy-init, `_build_ui()` rebuilds each time
- 900×550 centered panel, dim background

```gdscript
# src/ui/SellOverlay.gd
extends CanvasLayer

signal closed()
signal sale_confirmed(allocations: Array, price_offset: float)

var _style_name: String = ""
var _base_price: float = 200.0
var _quality_score: float = 0.0
var _batch_size: int = 10
var _demand_mult: float = 1.0

# Allocation state
var _channel_units: Dictionary = {}  # {channel_id: int}
var _price_offset: float = 0.0

# UI refs
var _price_slider: HSlider
var _price_label: Label
var _volume_label: Label
var _projected_label: Label
var _allocated_label: Label
var _channel_rows: Dictionary = {}  # {channel_id: {slider, units_label, revenue_label}}

func _ready() -> void:
	layer = 6
	visible = false

func show_overlay(style_name: String, base_price: float, quality_score: float,
		batch_size: int, demand_mult: float) -> void:
	_style_name = style_name
	_base_price = base_price
	_quality_score = quality_score
	_batch_size = batch_size
	_demand_mult = demand_mult
	_price_offset = 0.0
	_channel_units = {}
	# Default: put everything in taproom
	var taproom_max: int = MarketManager.get_max_units("taproom", _batch_size)
	_channel_units["taproom"] = taproom_max
	_build_ui()
	visible = true
```

The `_build_ui()` method should create:
1. Header: "SELL: {style_name}" + "Demand: {demand_mult}x" + close button
2. Pricing section: base price label, price slider (-30% to +50% in 5% steps), volume effect label
3. Distribution section: one row per unlocked channel with +/- buttons, units label, estimated revenue
4. Projected total revenue panel
5. "Confirm Sale" button

Key interaction: when slider or allocation changes, call `_update_projections()` to recalculate all estimated revenues in real-time.

```gdscript
func _update_projections() -> void:
	var adjusted_price: float = _base_price * (1.0 + _price_offset)
	var quality_mult: float = GameState.quality_to_multiplier(_quality_score)
	var volume_mod: float = MarketManager.calculate_volume_modifier(_price_offset, _quality_score)
	var total_allocated: int = 0
	var total_revenue: float = 0.0
	for channel_id in _channel_units:
		var units: int = _channel_units[channel_id]
		total_allocated += units
		var ch: Dictionary = MarketManager.get_channel(channel_id)
		var rev: float = units * adjusted_price * ch.margin * quality_mult * _demand_mult * volume_mod
		total_revenue += rev
		if _channel_rows.has(channel_id):
			_channel_rows[channel_id].units_label.text = "%d units" % units
			_channel_rows[channel_id].revenue_label.text = "→ $%.0f est." % rev
	_allocated_label.text = "Allocated: %d/%d" % [total_allocated, _batch_size]
	_projected_label.text = "$%.0f" % total_revenue
	var unsold: int = _batch_size - total_allocated
	if unsold > 0:
		_projected_label.text += "\n(%d unsold units wasted)" % unsold
	_price_label.text = "$%.0f (%+d%%)" % [adjusted_price, int(_price_offset * 100)]
	_volume_label.text = "Volume Effect: %.2fx" % volume_mod

func _on_confirm() -> void:
	var allocations: Array = []
	for channel_id in _channel_units:
		if _channel_units[channel_id] > 0:
			allocations.append({"channel_id": channel_id, "units": _channel_units[channel_id]})
	sale_confirmed.emit(allocations, _price_offset)
	visible = false
	closed.emit()

func _on_close() -> void:
	# Auto-sell at defaults if closed without confirming
	_on_confirm()
```

**Step 2: Wire up in BreweryScene**

In `BreweryScene.gd`, add SELL state handling. When `GameState.state_changed` fires with `State.SELL`:

```gdscript
var _sell_overlay: CanvasLayer = null

func _on_state_changed(new_state: int) -> void:
	# ... existing state handling ...
	if new_state == GameState.State.SELL:
		_show_sell_overlay()

func _show_sell_overlay() -> void:
	if _sell_overlay == null:
		_sell_overlay = preload("res://ui/SellOverlay.gd").new()
		add_child(_sell_overlay)
		_sell_overlay.sale_confirmed.connect(_on_sale_confirmed)
		_sell_overlay.closed.connect(func(): pass)
	var style_name: String = GameState.current_style.style_name if GameState.current_style else "Unknown"
	var base_price: float = GameState.current_style.base_price if GameState.current_style else 200.0
	var quality: float = GameState.last_brew_result.get("final_score", 50.0)
	var batch_size: int = int(10 * EquipmentManager.active_bonuses.get("batch_size", 1.0))
	var demand: float = MarketManager.get_demand_multiplier(GameState.current_style.style_id)
	_sell_overlay.show_overlay(style_name, base_price, quality, batch_size, demand)

func _on_sale_confirmed(allocations: Array, price_offset: float) -> void:
	GameState.execute_sell(allocations, price_offset)
	GameState.advance_state()  # SELL → EQUIPMENT_MANAGE (via _on_results_continue)
```

**Step 3: Run full tests**

**Step 4: Manual test** — Brew a beer and verify the SellOverlay appears after RESULTS

**Step 5: Commit**

```bash
git add src/ui/SellOverlay.gd src/scenes/BreweryScene.gd src/autoloads/GameState.gd
git commit -m "feat: add SellOverlay UI for post-brew distribution (Stage 4C task 8)"
```

---

## Task 9: MarketForecast Overlay

Tabbed overlay (Forecast / Channels / Research) accessible from hub "Market" button.

**Files:**
- Create: `src/ui/MarketForecast.gd`
- Modify: `src/scenes/BreweryScene.gd` (add Market button + overlay wiring)

**Step 1: Implement MarketForecast overlay**

Follow established overlay pattern. Three tabs:

**Forecast tab:**
- Season info (name, turn X/6)
- Seasonal modifier table (grid: styles × seasons, highlight current)
- Active trend display (style + bonus + remaining turns)
- Saturation bars per style
- Combined demand summary per style

**Channels tab:**
- 2×2 grid of channel cards
- Each shows: name, margin, volume %, unlock status, preference description
- Locked channels show unlock requirement

**Research tab:**
- "Buy Market Research — $100" button (disabled if already purchased or can't afford)
- If purchased: show trend forecast, upcoming season details
- If not: show "Purchase research to reveal upcoming market trends"

```gdscript
# src/ui/MarketForecast.gd
extends CanvasLayer

signal closed()

var _current_tab: String = "forecast"

func _ready() -> void:
	layer = 6
	visible = false

func show_screen() -> void:
	_current_tab = "forecast"
	_build_ui()
	visible = true
```

The `_build_ui()` method should:
1. Clear children, create dim + panel (900×550)
2. Header: "MARKET FORECAST" + season info + close button
3. Tab buttons row: [Forecast] [Channels] [Research]
4. Content area based on `_current_tab`

Tab switching:
```gdscript
func _on_tab_pressed(tab_name: String) -> void:
	_current_tab = tab_name
	_build_ui()
```

**Step 2: Add Market button to BreweryScene**

In `_build_equipment_ui()`, add a Market button after the Compete button:

```gdscript
# Market button — next position after Compete
var _market_button := Button.new()
_market_button.name = "MarketButton"
_market_button.text = "Market"
_market_button.custom_minimum_size = Vector2(160, 48)
# Position to the right of Compete button
_market_button.position = Vector2(1500, 620)  # Adjust x based on layout
_market_button.pressed.connect(func(): _on_market_pressed())
# Style it blue like other buttons
```

Wire up overlay:
```gdscript
var _market_forecast: CanvasLayer = null

func _on_market_pressed() -> void:
	if _market_forecast == null:
		_market_forecast = preload("res://ui/MarketForecast.gd").new()
		add_child(_market_forecast)
		_market_forecast.closed.connect(_on_market_forecast_closed)
	_market_forecast.show_screen()

func _on_market_forecast_closed() -> void:
	pass  # No badge updates needed
```

**Step 3: Run full tests**

**Step 4: Manual test** — Open Market from hub, switch tabs, buy research

**Step 5: Commit**

```bash
git add src/ui/MarketForecast.gd src/scenes/BreweryScene.gd
git commit -m "feat: add MarketForecast overlay with tabs (Stage 4C task 9)"
```

---

## Task 10: ResultsOverlay Update + Polish + Final Tests

Update ResultsOverlay to show revenue breakdown by channel. Add trend/season toast notifications. Final integration test.

**Files:**
- Modify: `src/ui/ResultsOverlay.gd` (revenue breakdown display)
- Modify: `src/autoloads/GameState.gd` (trend/season toasts)
- Modify: `src/tests/test_market_manager.gd` (add any missing edge case tests)
- Delete: `src/autoloads/MarketSystem.gd` (fully replaced)
- Delete: `src/tests/test_market_system.gd` (fully replaced)

**Step 1: Update ResultsOverlay revenue section**

In `ResultsOverlay.gd`, update `populate()` to show per-channel breakdown when `revenue_breakdown` exists in the result:

```gdscript
var breakdown: Array = result.get("revenue_breakdown", [])
if breakdown.size() > 0:
	# Show per-channel breakdown instead of single revenue line
	for entry in breakdown:
		var line: Label = Label.new()
		line.text = "%s (%d × $%.0f × %.1f×)  +$%.0f" % [
			entry.channel_name, entry.units, entry.price, entry.margin, entry.revenue
		]
		line.add_theme_color_override("font_color", Color("#5EE8A4"))
		line.add_theme_font_size_override("font_size", 18)
		# Add to the money section
else:
	# Fallback: show single revenue line (backward compat)
	revenue_label.text = "Revenue: +$%.0f" % result.get("revenue", 0.0)
```

**Step 2: Add toast notifications for trends and seasons**

In `GameState._on_results_continue()` (or wherever `MarketManager.tick()` is called), connect to MarketManager signals:

```gdscript
# In GameState._ready() or initialization:
MarketManager.trend_started.connect(func(style_id):
	ToastManager.show_toast("📈 %s is trending! (+50%% demand)" % _get_style_name(style_id), 1)
)
MarketManager.trend_ended.connect(func(style_id):
	ToastManager.show_toast("📉 %s trend ended" % _get_style_name(style_id), 0)
)
MarketManager.season_changed.connect(func(season_name):
	ToastManager.show_toast("🌤 Season changed to %s" % season_name, 0)
)
```

**Step 3: Write final integration tests**

Add to `test_market_manager.gd`:

```gdscript
# -- Integration / edge cases --

func test_full_cycle_24_turns() -> void:
	manager.initialize()
	for i in range(24):
		manager.tick()
	assert_eq(manager.current_season, 0, "Should complete full year cycle")

func test_demand_with_all_modifiers() -> void:
	manager.initialize()
	# Set up: Winter stout (+0.3 seasonal) + trending (+0.5) + saturated (-0.2)
	for i in range(18):
		manager.tick()  # Advance to Winter
	manager.active_trend_style = "stout"
	manager.trend_remaining_turns = 4
	manager.record_brew("stout")
	manager.record_brew("stout")
	# demand = 1.0 + 0.3 + 0.5 - 0.2 = 1.6
	var demand: float = manager.get_demand_multiplier("stout")
	assert_almost_eq(demand, 1.6, 0.05)

func test_all_channels_defined() -> void:
	for ch in manager.CHANNELS:
		assert_gt(ch.margin, 0.0, "%s margin > 0" % ch.id)
		assert_gt(ch.volume_pct, 0.0, "%s volume > 0" % ch.id)
```

**Step 4: Clean up old files**

Delete `src/autoloads/MarketSystem.gd` and `src/tests/test_market_system.gd`.

**Step 5: Run full test suite**

```bash
make test
```
Expected: ALL tests pass with no regressions.

**Step 6: Commit**

```bash
git add -A
git commit -m "feat: complete Stage 4C Market & Distribution (revenue breakdown, toasts, cleanup)"
```

---

## Summary

| Task | What | Files |
|------|------|-------|
| 1 | MarketManager + seasonal cycles | MarketManager.gd, test_market_manager.gd |
| 2 | Trending styles | MarketManager.gd, test_market_manager.gd |
| 3 | Market saturation | MarketManager.gd, test_market_manager.gd |
| 4 | Distribution channels | MarketManager.gd, test_market_manager.gd |
| 5 | Player pricing | MarketManager.gd, test_market_manager.gd |
| 6 | Market research + save/load | MarketManager.gd, test_market_manager.gd |
| 7 | GameState SELL state + revenue | GameState.gd, project.godot, test_economy.gd |
| 8 | SellOverlay UI | SellOverlay.gd, BreweryScene.gd |
| 9 | MarketForecast overlay | MarketForecast.gd, BreweryScene.gd |
| 10 | ResultsOverlay + toasts + cleanup | ResultsOverlay.gd, GameState.gd, cleanup |

Tasks 1-6 are pure backend (MarketManager), testable in isolation.
Tasks 7-10 are integration and UI.
