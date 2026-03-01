class_name ResearchNode
extends Resource

## Research node resource — represents a single node in the research tree.

enum Category { TECHNIQUES, INGREDIENTS, EQUIPMENT, STYLES }

@export var node_id: String = ""
@export var node_name: String = ""
@export var description: String = ""
@export var category: Category = Category.TECHNIQUES
@export var rp_cost: int = 0
@export var prerequisites: Array[String] = []
@export var unlock_effect: Dictionary = {}
