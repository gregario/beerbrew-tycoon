extends Node

## StaffManager — manages staff roster, hiring, firing, assignment, training,
## specialization, and salary deduction.

# ---------------------------------------------------------------------------
# Signals
# ---------------------------------------------------------------------------
signal staff_hired(staff_id: String)
signal staff_fired(staff_id: String)
signal staff_assigned(staff_id: String, phase: String)
signal staff_leveled_up(staff_id: String, new_level: int)
signal staff_training_started(staff_id: String)
signal staff_training_completed(staff_id: String)
signal staff_specialized(staff_id: String, specialization: String)
signal roster_changed()

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------
const MAX_STAFF_GARAGE: int = 0
const MAX_STAFF_MICRO: int = 2
const MAX_STAFF_ARTISAN: int = 4
const XP_PER_LEVEL: int = 100
const TRAINING_COST: int = 200
const TRAINING_STAT_GAIN_MIN: int = 5
const TRAINING_STAT_GAIN_MAX: int = 10
const LEVEL_UP_STAT_MIN: int = 2
const LEVEL_UP_STAT_MAX: int = 5
const SPECIALIZATION_LEVEL: int = 5
const BONUS_DIVISOR: float = 10.0

const BREWER_NAMES: Array[String] = [
	"Lars", "Eva", "Klaus", "Hilda", "Fritz",
	"Greta", "Otto", "Ingrid", "Hans", "Elsa",
	"Bruno", "Petra", "Dieter", "Helga", "Karl",
]

# ---------------------------------------------------------------------------
# State
# ---------------------------------------------------------------------------
var staff_roster: Array = []    # Array of Dictionary (staff data)
var candidates: Array = []      # Array of Dictionary
var _next_id: int = 0

# ---------------------------------------------------------------------------
# Reset
# ---------------------------------------------------------------------------
func reset() -> void:
	staff_roster = []
	candidates = []
	_next_id = 0
	generate_candidates(2)

# ---------------------------------------------------------------------------
# Candidate generation
# ---------------------------------------------------------------------------
func generate_candidates(count: int) -> void:
	candidates = []
	var used_names: Array[String] = []
	for staff in staff_roster:
		used_names.append(staff.get("staff_name", ""))
	var available_names: Array[String] = []
	for n in BREWER_NAMES:
		if n not in used_names:
			available_names.append(n)
	available_names.shuffle()
	for i in range(count):
		if available_names.is_empty():
			break
		var creativity: int = randi_range(25, 75)
		var precision: int = randi_range(25, 75)
		var salary: int = 40 + int((creativity + precision) / 4.0)
		var staff_id: String = "staff_%d" % _next_id
		_next_id += 1
		var staff_dict: Dictionary = {
			"staff_id": staff_id,
			"staff_name": available_names.pop_back(),
			"creativity": creativity,
			"precision": precision,
			"experience_points": 0,
			"level": 1,
			"salary_per_turn": salary,
			"assigned_phase": "",
			"specialization": "none",
			"is_training": false,
			"training_turns_remaining": 0,
			"training_stat": "",
		}
		candidates.append(staff_dict)

# ---------------------------------------------------------------------------
# Max staff (Stage 3B will gate by brewery stage)
# ---------------------------------------------------------------------------
func get_max_staff() -> int:
	if is_instance_valid(BreweryExpansion):
		return BreweryExpansion.get_max_staff()
	return MAX_STAFF_MICRO

# ---------------------------------------------------------------------------
# Hire / Fire
# ---------------------------------------------------------------------------
func hire(staff_id: String) -> bool:
	if staff_roster.size() >= get_max_staff():
		return false
	var candidate_index: int = -1
	for i in range(candidates.size()):
		if candidates[i].get("staff_id", "") == staff_id:
			candidate_index = i
			break
	if candidate_index < 0:
		return false
	var staff: Dictionary = candidates[candidate_index]
	candidates.remove_at(candidate_index)
	staff_roster.append(staff)
	staff_hired.emit(staff_id)
	roster_changed.emit()
	return true


func fire(staff_id: String) -> bool:
	var index: int = -1
	for i in range(staff_roster.size()):
		if staff_roster[i].get("staff_id", "") == staff_id:
			index = i
			break
	if index < 0:
		return false
	staff_roster.remove_at(index)
	staff_fired.emit(staff_id)
	roster_changed.emit()
	return true

# ---------------------------------------------------------------------------
# Phase assignment
# ---------------------------------------------------------------------------
func assign_to_phase(staff_id: String, phase: String) -> bool:
	if phase != "" and phase != "mashing" and phase != "boiling" and phase != "fermenting":
		return false
	var staff: Dictionary = _find_staff(staff_id)
	if staff.is_empty():
		return false
	if staff.get("is_training", false):
		return false
	# If assigning to a non-empty phase, unassign whoever is there
	if phase != "":
		for s in staff_roster:
			if s.get("assigned_phase", "") == phase and s.get("staff_id", "") != staff_id:
				s["assigned_phase"] = ""
				staff_assigned.emit(s["staff_id"], "")
	staff["assigned_phase"] = phase
	staff_assigned.emit(staff_id, phase)
	return true


func get_staff_assigned_to(phase: String) -> Dictionary:
	for staff in staff_roster:
		if staff.get("assigned_phase", "") == phase:
			return staff
	return {}

# ---------------------------------------------------------------------------
# Phase bonus
# ---------------------------------------------------------------------------
func get_phase_bonus(phase: String) -> Dictionary:
	var staff: Dictionary = get_staff_assigned_to(phase)
	if staff.is_empty():
		return {"flavor": 0.0, "technique": 0.0}
	var creativity: int = staff.get("creativity", 0)
	var precision: int = staff.get("precision", 0)
	var level: int = staff.get("level", 1)
	var specialization: String = staff.get("specialization", "none")
	var level_mult: float = 1.0 + (level - 1) * 0.1
	var spec_mult: float = 1.0
	if specialization != "none":
		if specialization == phase:
			spec_mult = 2.0
		else:
			spec_mult = 0.5
	var flavor: float = creativity * level_mult * spec_mult / BONUS_DIVISOR
	var technique: float = precision * level_mult * spec_mult / BONUS_DIVISOR
	return {"flavor": flavor, "technique": technique}

# ---------------------------------------------------------------------------
# XP and leveling
# ---------------------------------------------------------------------------
func award_xp(phase: String, amount: int) -> bool:
	var staff: Dictionary = get_staff_assigned_to(phase)
	if staff.is_empty():
		return false
	var xp: int = staff.get("experience_points", 0)
	xp += amount
	staff["experience_points"] = xp
	var level: int = staff.get("level", 1)
	var threshold: int = level * XP_PER_LEVEL
	if xp >= threshold:
		_level_up(staff)
		return true
	return false


func _level_up(staff: Dictionary) -> void:
	var new_level: int = staff.get("level", 1) + 1
	staff["level"] = new_level
	staff["experience_points"] = 0
	var creativity_gain: int = randi_range(LEVEL_UP_STAT_MIN, LEVEL_UP_STAT_MAX)
	var precision_gain: int = randi_range(LEVEL_UP_STAT_MIN, LEVEL_UP_STAT_MAX)
	var new_creativity: int = mini(staff.get("creativity", 0) + creativity_gain, 100)
	var new_precision: int = mini(staff.get("precision", 0) + precision_gain, 100)
	staff["creativity"] = new_creativity
	staff["precision"] = new_precision
	staff_leveled_up.emit(staff["staff_id"], new_level)

# ---------------------------------------------------------------------------
# Training
# ---------------------------------------------------------------------------
func start_training(staff_id: String, stat: String) -> bool:
	if stat != "creativity" and stat != "precision":
		return false
	var staff: Dictionary = _find_staff(staff_id)
	if staff.is_empty():
		return false
	if staff.get("is_training", false):
		return false
	if GameState.balance < TRAINING_COST:
		return false
	GameState.balance -= TRAINING_COST
	GameState.balance_changed.emit(GameState.balance)
	# Unassign from phase
	if staff.get("assigned_phase", "") != "":
		staff["assigned_phase"] = ""
		staff_assigned.emit(staff_id, "")
	staff["is_training"] = true
	staff["training_turns_remaining"] = 1
	staff["training_stat"] = stat
	staff_training_started.emit(staff_id)
	return true


func tick_training() -> void:
	for staff in staff_roster:
		if not staff.get("is_training", false):
			continue
		var remaining: int = staff.get("training_turns_remaining", 0) - 1
		staff["training_turns_remaining"] = remaining
		if remaining <= 0:
			var stat: String = staff.get("training_stat", "")
			var gain: int = randi_range(TRAINING_STAT_GAIN_MIN, TRAINING_STAT_GAIN_MAX)
			if stat != "":
				var current: int = staff.get(stat, 0)
				staff[stat] = mini(current + gain, 100)
			staff["is_training"] = false
			staff["training_turns_remaining"] = 0
			staff["training_stat"] = ""
			staff_training_completed.emit(staff["staff_id"])

# ---------------------------------------------------------------------------
# Specialization
# ---------------------------------------------------------------------------
func specialize(staff_id: String, specialization: String) -> bool:
	var staff: Dictionary = _find_staff(staff_id)
	if staff.is_empty():
		return false
	if staff.get("level", 1) < SPECIALIZATION_LEVEL:
		return false
	if staff.get("specialization", "none") != "none":
		return false
	staff["specialization"] = specialization
	staff_specialized.emit(staff_id, specialization)
	return true

# ---------------------------------------------------------------------------
# Salaries
# ---------------------------------------------------------------------------
func deduct_salaries() -> float:
	var total: float = 0.0
	for staff in staff_roster:
		total += staff.get("salary_per_turn", 0)
	GameState.balance -= total
	GameState.balance_changed.emit(GameState.balance)
	return total

# ---------------------------------------------------------------------------
# Refresh candidates
# ---------------------------------------------------------------------------
func refresh_candidates() -> void:
	generate_candidates(randi_range(2, 3))

# ---------------------------------------------------------------------------
# Persistence
# ---------------------------------------------------------------------------
func save_state() -> Dictionary:
	var roster_copy: Array = []
	for staff in staff_roster:
		roster_copy.append(staff.duplicate())
	var candidates_copy: Array = []
	for c in candidates:
		candidates_copy.append(c.duplicate())
	return {
		"staff_roster": roster_copy,
		"candidates": candidates_copy,
		"_next_id": _next_id,
	}


func load_state(data: Dictionary) -> void:
	staff_roster = []
	var saved_roster: Array = data.get("staff_roster", [])
	for staff in saved_roster:
		staff_roster.append(staff.duplicate())
	candidates = []
	var saved_candidates: Array = data.get("candidates", [])
	for c in saved_candidates:
		candidates.append(c.duplicate())
	_next_id = data.get("_next_id", 0)

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------
func _find_staff(staff_id: String) -> Dictionary:
	for staff in staff_roster:
		if staff.get("staff_id", "") == staff_id:
			return staff
	return {}
