class_name WaterProfile
extends Resource

## Water chemistry profile — defines mineral composition and style affinities.

@export var profile_id: String = ""
@export var display_name: String = ""
@export var mineral_description: String = ""
@export var style_affinities: Dictionary = {}

func get_affinity(style_id: String) -> float:
	return style_affinities.get(style_id, 0.6)
