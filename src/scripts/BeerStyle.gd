class_name BeerStyle
extends Resource

## Defines a beer style with its ideal Flavor/Technique balance and market properties.

@export var style_id: String = ""
@export var style_name: String = ""
@export var description: String = ""

## The ideal ratio of Flavor points to total points (Flavor + Technique).
## 0.0 = pure Technique, 1.0 = pure Flavor.
## Example: 0.35 means 35% Flavor / 65% Technique is ideal for this style.
@export_range(0.0, 1.0) var ideal_flavor_ratio: float = 0.5

## Base revenue per unit before quality and demand multipliers.
@export var base_price: float = 200.0

## Starting demand weight (1.0 = normal, used to weight random demand assignment).
@export var base_demand_weight: float = 1.0
