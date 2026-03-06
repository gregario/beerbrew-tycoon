extends Node

## CompetitionManager — manages competition scheduling, entry, judging,
## medals, and rare unlock rewards.

const ENTRY_WINDOW: int = 2
const MIN_INTERVAL: int = 8
const MAX_INTERVAL: int = 10

const STYLE_IDS: Array[String] = [
	"lager", "pale_ale", "stout", "wheat_beer",
]

const COMPETITION_NAMES: Array[String] = [
	"Oktoberfest Cup", "Craft Beer Classic", "Golden Pint Awards",
	"Brewmaster's Challenge", "Harvest Ale Festival", "International Lager Open",
	"Artisan Brew Derby", "Hop Forward Invitational",
]

const INGREDIENT_DIRS: Array[String] = [
	"res://data/ingredients/malts/",
	"res://data/ingredients/hops/",
	"res://data/ingredients/yeast/",
	"res://data/ingredients/adjuncts/",
]

signal competition_announced(competition: Dictionary)
signal competition_entered(competition_id: String)
signal competition_judged(result: Dictionary)

var current_competition = null  # Dictionary or null
var turns_until_next: int = 0
var medals: Dictionary = {"gold": 0, "silver": 0, "bronze": 0}
var player_entry = null  # Dictionary or null — {style_id, quality}
var _next_id: int = 0

# ---------------------------------------------------------------------------
# Scheduling
# ---------------------------------------------------------------------------
func tick() -> Dictionary:
	# If there's an active competition, tick its deadline
	if current_competition != null:
		current_competition["turns_remaining"] -= 1
		if current_competition["turns_remaining"] <= 0:
			return _judge()
		return {}

	# No active competition — tick countdown
	turns_until_next -= 1
	if turns_until_next <= 0:
		_announce()
	return {}

func _announce() -> void:
	var category: String = ""
	if randf() < 0.3:
		category = "open"
	else:
		category = STYLE_IDS[randi_range(0, STYLE_IDS.size() - 1)]

	var name_pick: String = COMPETITION_NAMES[randi_range(0, COMPETITION_NAMES.size() - 1)]
	var entry_fee: int = randi_range(100, 300)
	var gold_prize: int = entry_fee * 4 + randi_range(100, 300)
	var silver_prize: int = int(gold_prize * 0.5)
	var bronze_prize: int = int(gold_prize * 0.25)

	var comp_id: String = "comp_%d" % _next_id
	_next_id += 1

	current_competition = {
		"competition_id": comp_id,
		"name": name_pick,
		"category": category,
		"entry_fee": entry_fee,
		"prizes": {"gold": gold_prize, "silver": silver_prize, "bronze": bronze_prize},
		"turns_remaining": ENTRY_WINDOW,
	}
	player_entry = null
	competition_announced.emit(current_competition)

# ---------------------------------------------------------------------------
# Entry
# ---------------------------------------------------------------------------
func enter(style_id: String, quality: float) -> bool:
	if current_competition == null:
		return false
	if player_entry != null:
		return false  # Already entered
	var category: String = current_competition["category"]
	if category != "open" and category != style_id:
		return false  # Wrong style
	if not is_instance_valid(GameState):
		return false
	var fee: int = current_competition["entry_fee"]
	if GameState.balance < fee:
		return false  # Can't afford
	GameState.balance -= fee
	GameState.balance_changed.emit(GameState.balance)
	player_entry = {"style_id": style_id, "quality": quality}
	competition_entered.emit(current_competition["competition_id"])
	return true

# ---------------------------------------------------------------------------
# Judging
# ---------------------------------------------------------------------------
func _judge() -> Dictionary:
	var result: Dictionary = {
		"competition": current_competition.duplicate(),
		"placement": "none",
		"prize": 0,
		"competitor_scores": [],
		"player_quality": 0.0,
	}

	if player_entry == null:
		# Player didn't enter — just end the competition
		current_competition = null
		turns_until_next = randi_range(MIN_INTERVAL, MAX_INTERVAL)
		return result

	var player_quality: float = player_entry["quality"]
	result["player_quality"] = player_quality

	# Generate 3 competitor scores that scale with turn count
	var turn_count: int = 0
	if is_instance_valid(GameState):
		turn_count = GameState.turn_counter
	var base_score: float = minf(40.0 + turn_count * 1.5, 85.0)
	var competitor_scores: Array[float] = []
	for i in range(3):
		var score: float = base_score + float(randi_range(-10, 10))
		score = clampf(score, 10.0, 100.0)
		competitor_scores.append(score)
	result["competitor_scores"] = competitor_scores

	# Count how many competitors the player beat
	var beaten: int = 0
	for score in competitor_scores:
		if player_quality > score:
			beaten += 1

	var prizes: Dictionary = current_competition["prizes"]
	if beaten == 3:
		result["placement"] = "gold"
		result["prize"] = prizes["gold"]
		medals["gold"] += 1
	elif beaten == 2:
		result["placement"] = "silver"
		result["prize"] = prizes["silver"]
		medals["silver"] += 1
	elif beaten == 1:
		result["placement"] = "bronze"
		result["prize"] = prizes["bronze"]
		medals["bronze"] += 1
	else:
		result["placement"] = "none"
		result["prize"] = 0

	# Award prize money
	if result["prize"] > 0 and is_instance_valid(GameState):
		GameState.balance += result["prize"]
		GameState.balance_changed.emit(GameState.balance)

	# Rare ingredient unlock on gold (25% chance)
	result["rare_unlock"] = ""
	if result["placement"] == "gold" and randf() < 0.25:
		result["rare_unlock"] = _try_rare_unlock()

	competition_judged.emit(result)

	# Schedule next competition
	current_competition = null
	player_entry = null
	turns_until_next = randi_range(MIN_INTERVAL, MAX_INTERVAL)

	return result

func _try_rare_unlock() -> String:
	# Try to unlock a random locked ingredient by scanning ingredient directories
	var locked: Array[String] = []
	var locked_paths: Dictionary = {}
	for dir_path in INGREDIENT_DIRS:
		var dir: DirAccess = DirAccess.open(dir_path)
		if dir == null:
			continue
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				var full_path: String = dir_path + file_name
				if ResourceLoader.exists(full_path):
					var res: Resource = load(full_path)
					if res and "unlocked" in res and not res.unlocked:
						var ing_id: String = file_name.get_basename()
						locked.append(ing_id)
						locked_paths[ing_id] = full_path
			file_name = dir.get_next()
		dir.list_dir_end()
	if locked.size() == 0:
		return ""
	var pick: String = locked[randi_range(0, locked.size() - 1)]
	var ing: Resource = load(locked_paths[pick])
	if ing != null:
		ing.unlocked = true
		if "ingredient_name" in ing:
			return ing.ingredient_name
		return pick
	return ""

# ---------------------------------------------------------------------------
# Persistence
# ---------------------------------------------------------------------------
func save_state() -> Dictionary:
	var data: Dictionary = {
		"turns_until_next": turns_until_next,
		"medals": medals.duplicate(),
		"_next_id": _next_id,
	}
	if current_competition != null:
		data["current_competition"] = current_competition.duplicate()
		data["current_competition"]["prizes"] = current_competition["prizes"].duplicate()
	if player_entry != null:
		data["player_entry"] = player_entry.duplicate()
	return data

func load_state(data: Dictionary) -> void:
	turns_until_next = data.get("turns_until_next", randi_range(MIN_INTERVAL, MAX_INTERVAL))
	medals = data.get("medals", {"gold": 0, "silver": 0, "bronze": 0}).duplicate()
	_next_id = data.get("_next_id", 0)
	if data.has("current_competition"):
		current_competition = data["current_competition"].duplicate()
		current_competition["prizes"] = data["current_competition"]["prizes"].duplicate()
	else:
		current_competition = null
	if data.has("player_entry"):
		player_entry = data["player_entry"].duplicate()
	else:
		player_entry = null

# ---------------------------------------------------------------------------
# Reset
# ---------------------------------------------------------------------------
func reset() -> void:
	current_competition = null
	player_entry = null
	medals = {"gold": 0, "silver": 0, "bronze": 0}
	_next_id = 0
	turns_until_next = randi_range(MIN_INTERVAL, MAX_INTERVAL)
