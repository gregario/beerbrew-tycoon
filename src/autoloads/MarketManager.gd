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

func tick() -> void:
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

func reset() -> void:
	initialize()
