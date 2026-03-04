extends Node

## ContractManager — manages contract generation, acceptance, fulfillment,
## deadline tracking, and rewards/penalties.

const MAX_ACTIVE: int = 2
const REFRESH_INTERVAL: int = 3
const QUALITY_BONUS_THRESHOLD: float = 20.0

const CLIENT_NAMES: Array[String] = [
	"Hofbrau Munich", "Biergarten Co.", "Craft Collective",
	"The Copper Kettle", "Brewmaster's Guild", "Golden Tap",
	"Barrel & Hops", "Prost Pub", "Ales & Tales",
	"The Thirsty Monk", "Suds & Stories", "Hops & Dreams",
]

const STYLE_IDS: Array[String] = [
	"lager", "pale_ale", "stout", "wheat_beer",
]

signal contract_accepted(contract_id: String)
signal contract_fulfilled(contract_id: String, reward: int, bonus: int)
signal contract_failed(contract_id: String, penalty: int)
signal contracts_refreshed()

var available_contracts: Array = []
var active_contracts: Array = []
var refresh_counter: int = REFRESH_INTERVAL
var _next_id: int = 0

# ---------------------------------------------------------------------------
# Generation
# ---------------------------------------------------------------------------
func generate_contracts() -> void:
	available_contracts = []
	var count: int = randi_range(2, 3)
	var used_clients: Array[String] = []
	for c in active_contracts:
		used_clients.append(c.get("client_name", ""))
	var shuffled_clients: Array[String] = CLIENT_NAMES.duplicate()
	shuffled_clients.shuffle()
	for i in range(count):
		var client_name: String = ""
		for n in shuffled_clients:
			if n not in used_clients:
				client_name = n
				used_clients.append(n)
				break
		if client_name == "":
			client_name = "Client %d" % _next_id
		var style_id: String = STYLE_IDS[randi_range(0, STYLE_IDS.size() - 1)]
		var min_quality: float = float(randi_range(30, 80))
		var deadline: int = randi_range(3, 6)
		var base_reward: int = int(min_quality * 4.0) + randi_range(50, 150)
		var bonus_reward: int = int(base_reward * 0.25)
		var penalty: int = int(base_reward * 0.4)
		var contract_id: String = "contract_%d" % _next_id
		_next_id += 1
		available_contracts.append({
			"contract_id": contract_id,
			"client_name": client_name,
			"required_style": style_id,
			"minimum_quality": min_quality,
			"reward": base_reward,
			"bonus_reward": bonus_reward,
			"deadline_turns": deadline,
			"remaining_turns": deadline,
			"reputation_penalty": penalty,
		})

# ---------------------------------------------------------------------------
# Accept
# ---------------------------------------------------------------------------
func accept(contract_id: String) -> bool:
	if active_contracts.size() >= MAX_ACTIVE:
		return false
	var index: int = -1
	for i in range(available_contracts.size()):
		if available_contracts[i].get("contract_id", "") == contract_id:
			index = i
			break
	if index < 0:
		return false
	var contract: Dictionary = available_contracts[index]
	available_contracts.remove_at(index)
	active_contracts.append(contract)
	contract_accepted.emit(contract_id)
	return true

# ---------------------------------------------------------------------------
# Fulfillment check
# ---------------------------------------------------------------------------
func check_fulfillment(brewed_style_id: String, quality: float) -> Dictionary:
	for i in range(active_contracts.size() - 1, -1, -1):
		var contract: Dictionary = active_contracts[i]
		if contract["required_style"] != brewed_style_id:
			continue
		if quality < contract["minimum_quality"]:
			continue
		active_contracts.remove_at(i)
		var reward: int = contract["reward"]
		var bonus: int = 0
		if quality >= contract["minimum_quality"] + QUALITY_BONUS_THRESHOLD:
			bonus = contract["bonus_reward"]
		var total: int = reward + bonus
		GameState.balance += total
		GameState.balance_changed.emit(GameState.balance)
		contract_fulfilled.emit(contract["contract_id"], reward, bonus)
		return {
			"fulfilled": true,
			"contract": contract,
			"reward": reward,
			"bonus": bonus,
			"total": total,
		}
	return {"fulfilled": false}

# ---------------------------------------------------------------------------
# Deadline tick
# ---------------------------------------------------------------------------
func tick_deadlines() -> Array:
	var expired: Array = []
	for i in range(active_contracts.size() - 1, -1, -1):
		var contract: Dictionary = active_contracts[i]
		var remaining: int = contract.get("remaining_turns", 0) - 1
		contract["remaining_turns"] = remaining
		if remaining <= 0:
			active_contracts.remove_at(i)
			var penalty: int = contract["reputation_penalty"]
			GameState.balance -= penalty
			GameState.balance_changed.emit(GameState.balance)
			contract_failed.emit(contract["contract_id"], penalty)
			expired.append(contract)
	refresh_counter -= 1
	if refresh_counter <= 0:
		generate_contracts()
		refresh_counter = REFRESH_INTERVAL
		contracts_refreshed.emit()
	return expired

# ---------------------------------------------------------------------------
# Persistence
# ---------------------------------------------------------------------------
func save_state() -> Dictionary:
	var avail_copy: Array = []
	for c in available_contracts:
		avail_copy.append(c.duplicate())
	var active_copy: Array = []
	for c in active_contracts:
		active_copy.append(c.duplicate())
	return {
		"available_contracts": avail_copy,
		"active_contracts": active_copy,
		"refresh_counter": refresh_counter,
		"_next_id": _next_id,
	}

func load_state(data: Dictionary) -> void:
	available_contracts = []
	for c in data.get("available_contracts", []):
		available_contracts.append(c.duplicate())
	active_contracts = []
	for c in data.get("active_contracts", []):
		active_contracts.append(c.duplicate())
	refresh_counter = data.get("refresh_counter", REFRESH_INTERVAL)
	_next_id = data.get("_next_id", 0)

# ---------------------------------------------------------------------------
# Reset
# ---------------------------------------------------------------------------
func reset() -> void:
	active_contracts = []
	_next_id = 0
	refresh_counter = REFRESH_INTERVAL
	generate_contracts()
