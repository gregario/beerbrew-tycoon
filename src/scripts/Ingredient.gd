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

## Direct Flavor point contribution per 1% of slider effort in the relevant phase.
## Used to scale the ingredient's flavor output on top of phase contribution.
@export var flavor_bonus: float = 0.0

## Direct Technique point contribution per 1% of slider effort in the relevant phase.
@export var technique_bonus: float = 0.0

## Compatibility with each beer style. Key = style_id (String), Value = 0.0–1.0.
## 1.0 = perfect match, 0.0 = terrible match.
## Missing style_id defaults to 0.5 (neutral).
@export var style_compatibility: Dictionary = {}

func get_compatibility(style_id: String) -> float:
	return style_compatibility.get(style_id, 0.5)
