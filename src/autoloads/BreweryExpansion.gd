extends Node

## BreweryExpansion — manages brewery stage, expansion thresholds, and
## stage-dependent configuration (slots, staff cap, rent, equipment tier).

enum Stage { GARAGE, MICROBREWERY, ARTISAN, MASS_MARKET }

# ---------------------------------------------------------------------------
# Thresholds and costs
# ---------------------------------------------------------------------------
const EXPAND_BALANCE_THRESHOLD: float = 5000.0
const EXPAND_BEERS_THRESHOLD: int = 10
const EXPAND_COST: float = 3000.0

var SLOTS_PER_STAGE: Dictionary = {
	Stage.GARAGE: 3,
	Stage.MICROBREWERY: 5,
	Stage.ARTISAN: 7,
	Stage.MASS_MARKET: 7,
}

var STAFF_PER_STAGE: Dictionary = {
	Stage.GARAGE: 0,
	Stage.MICROBREWERY: 2,
	Stage.ARTISAN: 3,
	Stage.MASS_MARKET: 4,
}

var RENT_PER_STAGE: Dictionary = {
	Stage.GARAGE: 150.0,
	Stage.MICROBREWERY: 400.0,
	Stage.ARTISAN: 600.0,
	Stage.MASS_MARKET: 800.0,
}

var TIER_CAP_PER_STAGE: Dictionary = {
	Stage.GARAGE: 2,
	Stage.MICROBREWERY: 4,
	Stage.ARTISAN: 4,
	Stage.MASS_MARKET: 4,
}

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal brewery_expanded(new_stage: int)
signal threshold_reached()
signal fork_threshold_reached()

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var current_stage: Stage = Stage.GARAGE
var beers_brewed: int = 0

# ---------------------------------------------------------------------------
# Threshold checks
# ---------------------------------------------------------------------------
func can_expand() -> bool:
	if current_stage != Stage.GARAGE:
		return false
	return GameState.balance >= EXPAND_BALANCE_THRESHOLD and beers_brewed >= EXPAND_BEERS_THRESHOLD

func can_afford_expansion() -> bool:
	return GameState.balance >= EXPAND_COST

# ---------------------------------------------------------------------------
# Expansion
# ---------------------------------------------------------------------------
func expand() -> bool:
	if not can_expand():
		return false
	if not can_afford_expansion():
		return false
	GameState.balance -= EXPAND_COST
	GameState.balance_changed.emit(GameState.balance)
	current_stage = Stage.MICROBREWERY
	brewery_expanded.emit(Stage.MICROBREWERY)
	return true

## Expand to a specific path stage (ARTISAN or MASS_MARKET).
## Only valid from MICROBREWERY stage. No cost — fork is free.
func expand_to_path(target_stage: Stage) -> bool:
	if current_stage != Stage.MICROBREWERY:
		return false
	if target_stage != Stage.ARTISAN and target_stage != Stage.MASS_MARKET:
		return false
	current_stage = target_stage
	if is_instance_valid(EquipmentManager):
		EquipmentManager.resize_slots()
	brewery_expanded.emit(target_stage)
	return true

# ---------------------------------------------------------------------------
# Stage-dependent getters
# ---------------------------------------------------------------------------
func get_max_slots() -> int:
	return SLOTS_PER_STAGE.get(current_stage, 3)

func get_max_staff() -> int:
	return STAFF_PER_STAGE.get(current_stage, 0)

func get_rent_amount() -> float:
	return RENT_PER_STAGE.get(current_stage, 150.0)

func get_equipment_tier_cap() -> int:
	return TIER_CAP_PER_STAGE.get(current_stage, 2)

func get_stage_name() -> String:
	match current_stage:
		Stage.GARAGE:
			return "EQUIPMENT MANAGEMENT"
		Stage.MICROBREWERY:
			return "MICROBREWERY"
		Stage.ARTISAN:
			return "ARTISAN BREWERY"
		Stage.MASS_MARKET:
			return "MASS-MARKET BREWERY"
	return "BREWERY"

# ---------------------------------------------------------------------------
# Beer counter
# ---------------------------------------------------------------------------
func record_brew() -> void:
	beers_brewed += 1
	if current_stage == Stage.GARAGE and can_expand():
		threshold_reached.emit()
	elif current_stage == Stage.MICROBREWERY and is_instance_valid(PathManager):
		if PathManager.can_choose_path():
			fork_threshold_reached.emit()

# ---------------------------------------------------------------------------
# Persistence
# ---------------------------------------------------------------------------
func save_state() -> Dictionary:
	return {
		"current_stage": current_stage,
		"beers_brewed": beers_brewed,
	}

func load_state(data: Dictionary) -> void:
	current_stage = data.get("current_stage", Stage.GARAGE) as Stage
	beers_brewed = data.get("beers_brewed", 0)

# ---------------------------------------------------------------------------
# Reset
# ---------------------------------------------------------------------------
func reset() -> void:
	current_stage = Stage.GARAGE
	beers_brewed = 0
