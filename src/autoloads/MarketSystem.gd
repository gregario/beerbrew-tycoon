extends Node

## MarketSystem — manages per-style demand weights and scheduled rotation.

const DEMAND_HIGH: float = 1.5
const DEMAND_NORMAL: float = 1.0

## How many turns between demand rotations (matches GameState.RENT_INTERVAL is separate).
const DEMAND_ROTATION_INTERVAL: int = 3

## Demand weights per style_id. Updated by initialize_demand() and rotate_demand().
var _demand_weights: Dictionary = {}

## The set of style_ids with elevated demand in the previous rotation.
## Used to prevent identical consecutive elevated sets.
var _previous_elevated: Array = []

## All registered style IDs. Populated when styles are loaded.
var _style_ids: Array = []

# ---------------------------------------------------------------------------
# Setup
# ---------------------------------------------------------------------------

## Register all style IDs that the market system will track.
## Called once at game startup by Game.gd before initialize_demand().
func register_styles(style_ids: Array) -> void:
	_style_ids = style_ids.duplicate()
	for sid in _style_ids:
		_demand_weights[sid] = DEMAND_NORMAL

## Initialize demand at the start of a run.
## Randomly assigns elevated demand to 1–2 styles.
func initialize_demand() -> void:
	if _style_ids.is_empty():
		return
	_previous_elevated = []
	_apply_random_elevation(1)

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

## Returns the current demand multiplier for a given style_id.
func get_demand_weight(style_id: String) -> float:
	return _demand_weights.get(style_id, DEMAND_NORMAL)

## Rotate demand to a new set of elevated styles.
## Called by Game.gd on the correct turn interval.
func rotate_demand() -> void:
	if _style_ids.is_empty():
		return
	# Choose 1 or 2 styles to elevate (random)
	var count := randi_range(1, min(2, _style_ids.size()))
	_apply_random_elevation(count)

## Check if the turn counter triggers a rotation.
func should_rotate(turn_counter: int) -> bool:
	return turn_counter > 0 and turn_counter % DEMAND_ROTATION_INTERVAL == 0

## Returns a copy of the current demand weights (read-only access for UI).
func get_all_demand_weights() -> Dictionary:
	return _demand_weights.duplicate()

# ---------------------------------------------------------------------------
# Private helpers
# ---------------------------------------------------------------------------

func _apply_random_elevation(count: int) -> void:
	# Reset all to normal first
	for sid in _style_ids:
		_demand_weights[sid] = DEMAND_NORMAL

	# Pick styles to elevate, avoiding the exact same set as last rotation
	var available := _style_ids.duplicate()
	available.shuffle()

	var elevated: Array = []
	var attempts := 0
	while elevated.size() < count and attempts < 20:
		attempts += 1
		var candidate: Array = []
		var shuffled := _style_ids.duplicate()
		shuffled.shuffle()
		for i in range(count):
			if i < shuffled.size():
				candidate.append(shuffled[i])
		candidate.sort()
		if candidate != _previous_elevated:
			elevated = candidate
			break

	# If we couldn't find a different set (e.g., only 1 style), just pick randomly
	if elevated.is_empty():
		elevated = available.slice(0, count)

	_previous_elevated = elevated.duplicate()
	_previous_elevated.sort()

	for sid in elevated:
		_demand_weights[sid] = DEMAND_HIGH
