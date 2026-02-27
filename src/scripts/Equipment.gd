class_name Equipment
extends Resource

## Equipment resource — represents a piece of brewery equipment.

enum Category { BREWING, FERMENTATION, PACKAGING, UTILITY }

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
@export var upgrades_to: String = ""
@export var upgrade_cost: int = 0
