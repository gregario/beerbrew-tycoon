extends Node

## SpecialtyBeerManager — manages aging queue for specialty beers (sour/wild ales).
## Specialty beers ferment over multiple turns before producing results.

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var _aging_queue: Array = []
var _completed_beers: Array = []

# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------

func get_aging_queue() -> Array:
	return _aging_queue

func queue_beer(entry: Dictionary) -> void:
	_aging_queue.append(entry.duplicate(true))

func tick_aging() -> void:
	var still_aging: Array = []
	for entry in _aging_queue:
		entry["turns_remaining"] -= 1
		if entry["turns_remaining"] <= 0:
			entry["final_quality"] = _resolve_quality(entry)
			_completed_beers.append(entry)
		else:
			still_aging.append(entry)
	_aging_queue = still_aging

func get_completed_beers() -> Array:
	var result: Array = _completed_beers.duplicate()
	_completed_beers.clear()
	return result

# ---------------------------------------------------------------------------
# Quality resolution
# ---------------------------------------------------------------------------

func _resolve_quality(entry: Dictionary) -> float:
	var base: float = entry.get("quality_base", 50.0)
	var seed_val: int = entry.get("variance_seed", 0)

	# Seeded variance ±15
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var variance: float = rng.randf_range(-15.0, 15.0)

	# Ceiling boost for aged beers
	var ceiling_boost: float = 10.0

	var final_val: float = base + ceiling_boost + variance
	return clampf(final_val, 0.0, 100.0)

# ---------------------------------------------------------------------------
# Persistence
# ---------------------------------------------------------------------------

func save_state() -> Dictionary:
	var queue_copy: Array = []
	for entry in _aging_queue:
		queue_copy.append(entry.duplicate(true))
	return {"aging_queue": queue_copy}

func load_state(data: Dictionary) -> void:
	_aging_queue.clear()
	_completed_beers.clear()
	var loaded: Array = data.get("aging_queue", [])
	for entry in loaded:
		_aging_queue.append(entry.duplicate(true))

func reset() -> void:
	_aging_queue.clear()
	_completed_beers.clear()
