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
const TREND_BONUS: float = 0.5
const TREND_MIN_INTERVAL: int = 8
const TREND_MAX_INTERVAL: int = 12
const TREND_MIN_DURATION: int = 4
const TREND_MAX_DURATION: int = 6
const SATURATION_PER_BREW: float = 0.1
const SATURATION_RECOVERY: float = 0.05
const SATURATION_MAX_PENALTY: float = 0.5
const PRICE_OFFSET_MIN: float = -0.3
const PRICE_OFFSET_MAX: float = 0.5
const RESEARCH_COST: int = 100
const VOLUME_MOD_MIN: float = 0.3
const VOLUME_MOD_MAX: float = 1.5

# -- Distribution channels --
const CHANNELS: Array = [
	{"id": "taproom", "name": "Taproom", "margin": 1.0, "volume_pct": 0.3, "unlock_type": "always"},
	{"id": "local_bars", "name": "Local Bars", "margin": 0.7, "volume_pct": 0.5, "unlock_type": "brewery_stage"},
	{"id": "retail", "name": "Retail", "margin": 0.5, "volume_pct": 1.0, "unlock_type": "research"},
	{"id": "events", "name": "Events", "margin": 1.5, "volume_pct": 0.2, "unlock_type": "events"},
]

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
var active_trend_style: String = ""
var trend_remaining_turns: int = 0
var _next_trend_in: int = 0
var _saturation: Dictionary = {}  # {style_id: float}
var _price_offset: float = 0.0
var research_purchased: bool = false

func register_styles(style_ids: Array) -> void:
	_style_ids = style_ids.duplicate()

func initialize() -> void:
	current_season = 0
	season_turn = 0
	_market_turn = 0
	active_trend_style = ""
	trend_remaining_turns = 0
	_next_trend_in = randi_range(TREND_MIN_INTERVAL, TREND_MAX_INTERVAL)
	_saturation = {}
	_price_offset = 0.0
	research_purchased = false

func tick() -> void:
	research_purchased = false
	_market_turn += 1
	# Saturation recovery (all styles decay each turn)
	for sid in _saturation.keys():
		_saturation[sid] = maxf(_saturation[sid] - SATURATION_RECOVERY, 0.0)
		if _saturation[sid] == 0.0:
			_saturation.erase(sid)
	# Trend tick — BEFORE season tick (order matters for signal timing)
	if trend_remaining_turns > 0:
		trend_remaining_turns -= 1
		if trend_remaining_turns <= 0:
			var old_style := active_trend_style
			active_trend_style = ""
			trend_ended.emit(old_style)
	_next_trend_in -= 1
	if _next_trend_in <= 0 and active_trend_style == "":
		_start_new_trend()
	# Season tick
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

func record_brew(style_id: String) -> void:
	var current: float = _saturation.get(style_id, 0.0)
	_saturation[style_id] = minf(current + SATURATION_PER_BREW, SATURATION_MAX_PENALTY)

func get_saturation_penalty(style_id: String) -> float:
	return _saturation.get(style_id, 0.0)

func get_all_saturation() -> Dictionary:
	return _saturation.duplicate()

func get_demand_multiplier(style_id: String) -> float:
	var base: float = 1.0
	base += get_seasonal_modifier(style_id)
	base += get_trend_bonus(style_id)
	base -= get_saturation_penalty(style_id)
	return clampf(base, DEMAND_MIN, DEMAND_MAX)

# -- Backward compatibility (MarketSystem API) --
func get_demand_weight(style_id: String) -> float:
	return get_demand_multiplier(style_id)

func get_all_demand_weights() -> Dictionary:
	var weights: Dictionary = {}
	for sid in _style_ids:
		weights[sid] = get_demand_multiplier(sid)
	return weights

# -- Distribution channel methods --

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
			if is_instance_valid(CompetitionManager):
				var m: Dictionary = CompetitionManager.medals
				return (m.get("gold", 0) + m.get("silver", 0) + m.get("bronze", 0)) > 0
			return false
	return false

func get_max_units(channel_id: String, batch_size: int) -> int:
	var ch: Dictionary = get_channel(channel_id)
	if ch.is_empty():
		return 0
	return int(floor(batch_size * ch.volume_pct))

# -- Player pricing --

func set_price_offset(offset: float) -> void:
	_price_offset = clampf(offset, PRICE_OFFSET_MIN, PRICE_OFFSET_MAX)

func get_price_offset() -> float:
	return _price_offset

func calculate_volume_modifier(price_offset: float, quality_score: float) -> float:
	var base_vol: float = 1.0 - price_offset * 0.5
	if price_offset > 0.0:
		var quality_factor: float = quality_score / 100.0
		var penalty: float = price_offset * 0.5 * (1.0 - quality_factor)
		base_vol -= penalty
	return clampf(base_vol, VOLUME_MOD_MIN, VOLUME_MOD_MAX)

func get_adjusted_price(base_price: float) -> float:
	return base_price * (1.0 + _price_offset)

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

func reset() -> void:
	initialize()
