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
