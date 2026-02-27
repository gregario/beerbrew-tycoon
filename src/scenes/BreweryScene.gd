extends Node2D

## BreweryScene — isometric garage brewery view.
## Uses placeholder ColorRects until pixel art sprites are ready.

@onready var kettle_node: ColorRect = $Stations/Kettle
@onready var fermenter_node: ColorRect = $Stations/Fermenter
@onready var bottler_node: ColorRect = $Stations/Bottler
@onready var brew_animation: AnimationPlayer = $BrewAnimation
@onready var character_node: ColorRect = $Character

func _ready() -> void:
	set_brewing(false)

## Enable or disable the "brewing in progress" visual state.
func set_brewing(active: bool) -> void:
	if brew_animation == null:
		return
	if active:
		if brew_animation.has_animation("brewing"):
			brew_animation.play("brewing")
	else:
		brew_animation.stop()
		if kettle_node:
			kettle_node.color = Color(0.3, 0.5, 0.8, 1.0)  # Rest state color
