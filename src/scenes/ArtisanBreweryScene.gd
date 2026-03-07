extends "res://scenes/BreweryScene.gd"

## ArtisanBreweryScene — artisan path brewery layout.
## Adds reputation bar and medal display to the base brewery scene.

var _reputation_bar: ProgressBar
var _reputation_label: Label

func _ready() -> void:
	super._ready()
	_add_reputation_display()

func _add_reputation_display() -> void:
	_reputation_bar = ProgressBar.new()
	_reputation_bar.min_value = 0
	_reputation_bar.max_value = 100
	_reputation_bar.value = PathManager.get_reputation()
	_reputation_bar.custom_minimum_size = Vector2(150, 20)
	_reputation_bar.show_percentage = false

	_reputation_label = Label.new()
	_reputation_label.text = "Rep: %d/100" % PathManager.get_reputation()

	var hbox := HBoxContainer.new()
	hbox.name = "ReputationDisplay"
	hbox.add_theme_constant_override("separation", 8)
	hbox.add_child(_reputation_label)
	hbox.add_child(_reputation_bar)
	add_child(hbox)

func refresh_reputation() -> void:
	if _reputation_bar:
		_reputation_bar.value = PathManager.get_reputation()
	if _reputation_label:
		_reputation_label.text = "Rep: %d/100" % PathManager.get_reputation()
