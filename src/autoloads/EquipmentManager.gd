extends Node

## EquipmentManager — handles equipment purchasing, upgrading, slot assignment,
## and bonus aggregation.

const BASE_SANITATION: int = 50
const BASE_TEMP_CONTROL: int = 50
const MAX_SLOTS_GARAGE: int = 3

const TIER1_IDS: Array[String] = [
	"extract_kit", "bucket_fermenter", "bottles_capper", "cleaning_bucket"
]

signal equipment_purchased(equipment_id: String)
signal equipment_slotted(slot_index: int, equipment_id: String)
signal bonuses_updated(bonuses: Dictionary)

var owned_equipment: Array[String] = []
var station_slots: Array[String] = ["", "", ""]
var active_bonuses: Dictionary = {
	"sanitation": 0,
	"temp_control": 0,
	"efficiency": 0.0,
	"batch_size": 1.0,
}

var _catalog: Dictionary = {}  # equipment_id → Equipment resource

const EQUIPMENT_PATHS: Array[String] = [
	"res://data/equipment/brewing/extract_kit.tres",
	"res://data/equipment/brewing/biab_setup.tres",
	"res://data/equipment/brewing/mash_tun.tres",
	"res://data/equipment/brewing/three_vessel.tres",
	"res://data/equipment/fermentation/bucket_fermenter.tres",
	"res://data/equipment/fermentation/glass_carboy.tres",
	"res://data/equipment/fermentation/temp_chamber.tres",
	"res://data/equipment/fermentation/ss_conical.tres",
	"res://data/equipment/packaging/bottles_capper.tres",
	"res://data/equipment/packaging/bench_capper.tres",
	"res://data/equipment/packaging/kegging_kit.tres",
	"res://data/equipment/packaging/counter_pressure.tres",
	"res://data/equipment/utility/cleaning_bucket.tres",
	"res://data/equipment/utility/star_san_kit.tres",
	"res://data/equipment/utility/cip_pump.tres",
]

func _ready() -> void:
	_load_catalog()

func _load_catalog() -> void:
	for path in EQUIPMENT_PATHS:
		var equip = load(path) as Equipment
		if equip:
			_catalog[equip.equipment_id] = equip

func get_equipment(equipment_id: String) -> Equipment:
	return _catalog.get(equipment_id, null)

func get_all_equipment() -> Array:
	return _catalog.values()

func get_equipment_by_category(category: Equipment.Category) -> Array:
	var result: Array = []
	for equip in _catalog.values():
		if equip.category == category:
			result.append(equip)
	result.sort_custom(func(a, b): return a.tier < b.tier)
	return result

# --- Purchase ---
func purchase(equipment_id: String) -> bool:
	if equipment_id in owned_equipment:
		return false
	var equip := get_equipment(equipment_id)
	if equip == null:
		return false
	if GameState.balance < equip.cost:
		return false
	GameState.balance -= equip.cost
	GameState.balance_changed.emit(GameState.balance)
	owned_equipment.append(equipment_id)
	equipment_purchased.emit(equipment_id)
	return true

# --- Upgrade ---
func upgrade(equipment_id: String) -> bool:
	if equipment_id not in owned_equipment:
		return false
	var equip := get_equipment(equipment_id)
	if equip == null or equip.upgrades_to == "":
		return false
	if GameState.balance < equip.upgrade_cost:
		return false
	var target_id := equip.upgrades_to
	GameState.balance -= equip.upgrade_cost
	GameState.balance_changed.emit(GameState.balance)
	var slot_idx := _find_slot(equipment_id)
	owned_equipment.erase(equipment_id)
	owned_equipment.append(target_id)
	if slot_idx >= 0:
		station_slots[slot_idx] = target_id
		recalculate_bonuses()
		equipment_slotted.emit(slot_idx, target_id)
	equipment_purchased.emit(target_id)
	return true

# --- Slot management ---
func assign_to_slot(slot_index: int, equipment_id: String) -> bool:
	if slot_index < 0 or slot_index >= MAX_SLOTS_GARAGE:
		return false
	if equipment_id not in owned_equipment:
		return false
	var old_slot := _find_slot(equipment_id)
	if old_slot >= 0:
		station_slots[old_slot] = ""
	station_slots[slot_index] = equipment_id
	recalculate_bonuses()
	equipment_slotted.emit(slot_index, equipment_id)
	return true

func unassign_slot(slot_index: int) -> void:
	if slot_index < 0 or slot_index >= MAX_SLOTS_GARAGE:
		return
	station_slots[slot_index] = ""
	recalculate_bonuses()
	equipment_slotted.emit(slot_index, "")

func _find_slot(equipment_id: String) -> int:
	for i in range(station_slots.size()):
		if station_slots[i] == equipment_id:
			return i
	return -1

func get_unslotted_owned() -> Array:
	var result: Array = []
	for id in owned_equipment:
		if id not in station_slots:
			result.append(id)
	return result

# --- Bonus aggregation ---
func recalculate_bonuses() -> void:
	var san := 0
	var temp := 0
	var eff := 0.0
	var batch := 1.0
	for id in station_slots:
		if id == "":
			continue
		var equip := get_equipment(id)
		if equip == null:
			continue
		san += equip.sanitation_bonus
		temp += equip.temp_control_bonus
		eff += equip.efficiency_bonus
		batch *= equip.batch_size_multiplier
	active_bonuses = {
		"sanitation": san,
		"temp_control": temp,
		"efficiency": eff,
		"batch_size": batch,
	}
	GameState.sanitation_quality = BASE_SANITATION + san
	GameState.temp_control_quality = BASE_TEMP_CONTROL + temp
	bonuses_updated.emit(active_bonuses)

# --- Initialization ---
func initialize_starting_equipment() -> void:
	for id in TIER1_IDS:
		if id not in owned_equipment:
			owned_equipment.append(id)

# --- Persistence ---
func save_state() -> Dictionary:
	return {
		"owned_equipment": owned_equipment.duplicate(),
		"station_slots": station_slots.duplicate(),
	}

func load_state(data: Dictionary) -> void:
	owned_equipment = data.get("owned_equipment", [])
	station_slots = data.get("station_slots", ["", "", ""])
	recalculate_bonuses()

# --- Reset ---
func reset() -> void:
	owned_equipment = []
	station_slots = ["", "", ""]
	active_bonuses = {
		"sanitation": 0,
		"temp_control": 0,
		"efficiency": 0.0,
		"batch_size": 1.0,
	}
	GameState.sanitation_quality = BASE_SANITATION
	GameState.temp_control_quality = BASE_TEMP_CONTROL
