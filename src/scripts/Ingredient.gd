class_name Ingredient
extends Resource

## Base ingredient class. Extended by Malt, Hop, Yeast, Adjunct.

enum Category { MALT, HOP, YEAST, ADJUNCT }

@export var ingredient_id: String = ""
@export var ingredient_name: String = ""
@export var description: String = ""
@export var category: Category = Category.MALT
@export var cost: int = 0
@export var flavor_tags: Array[String] = []
@export var flavor_profile: Dictionary = {
	"bitterness": 0.0,
	"sweetness": 0.0,
	"roastiness": 0.0,
	"fruitiness": 0.0,
	"funkiness": 0.0,
}
@export var unlocked: bool = true
