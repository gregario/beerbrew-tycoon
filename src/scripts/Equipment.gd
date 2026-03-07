class_name Equipment
extends Resource

## Equipment resource — represents a piece of brewery equipment.

enum Category { BREWING, FERMENTATION, PACKAGING, UTILITY, AUTOMATION, MEASUREMENT }

@export var equipment_id: String = ""
@export var equipment_name: String = ""
@export var description: String = ""
@export var tier: int = 1
@export var category: Category = Category.BREWING
@export var cost: int = 0
@export var sanitation_bonus: int = 0
@export var temp_control_bonus: int = 0
@export var efficiency_bonus: float = 0.0
@export var batch_size_multiplier: float = 1.0
@export var mash_bonus: int = 0
@export var boil_bonus: int = 0
@export var ferment_bonus: int = 0
@export var upgrades_to: String = ""
@export var upgrade_cost: int = 0
## Feature IDs this equipment reveals in the UI when equipped.
## Valid IDs: temp_numbers, water_selector, hop_schedule, dry_hop_rack,
## ferment_profile, conditioning_tank, ph_meter, gravity_readings.
@export var reveals: Array[String] = []
