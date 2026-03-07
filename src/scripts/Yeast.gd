class_name Yeast
extends Ingredient

## Yeast ingredient with fermentation-specific properties.

@export var attenuation_pct: float = 0.0
@export var ideal_temp_min_c: float = 0.0
@export var ideal_temp_max_c: float = 0.0
@export var flocculation: String = ""

## Flavor compounds produced at different temperature ranges.
## Keys: temp range labels (e.g. "below_16", "16_to_20", "above_20").
## Values: Dictionary of compound → intensity (0.0-1.0).
## Compounds: ester_banana, ester_fruit, phenol_clove, phenol_pepper, fusel, clean.
@export var yeast_flavor_profile: Dictionary = {}
