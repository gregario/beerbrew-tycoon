class_name Ingredient
extends Resource

## Defines a brewing ingredient with flavor/technique contributions and style compatibility.

enum Category { MALT, HOP, YEAST }

@export var ingredient_id: String = ""
@export var ingredient_name: String = ""
@export var description: String = ""
@export var category: Category = Category.MALT

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
