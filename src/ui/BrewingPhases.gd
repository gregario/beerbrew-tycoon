extends Control

## BrewingPhases — the core brewing interaction: three phase sliders.
## Emits brew_confirmed(sliders) when the player confirms. Has no direct
## No dependency on GameState. QualityCalculator is used only for the
## read-only slider preview (pure calculation, no state mutation).

signal brew_confirmed(sliders: Dictionary)

@onready var mashing_slider: HSlider = $CardPanel/MarginContainer/VBox/MashingRow/MashingSlider
@onready var boiling_slider: HSlider = $CardPanel/MarginContainer/VBox/BoilingRow/BoilingSlider
@onready var fermenting_slider: HSlider = $CardPanel/MarginContainer/VBox/FermentingRow/FermentingSlider
@onready var brew_button: Button = $CardPanel/MarginContainer/VBox/FooterRow/BrewButton
@onready var flavor_label: Label = $CardPanel/MarginContainer/VBox/PreviewPanel/PreviewHBox/FlavorLabel
@onready var technique_label: Label = $CardPanel/MarginContainer/VBox/PreviewPanel/PreviewHBox/TechniqueLabel
@onready var mashing_value: Label = $CardPanel/MarginContainer/VBox/MashingRow/MashingValue
@onready var boiling_value: Label = $CardPanel/MarginContainer/VBox/BoilingRow/BoilingValue
@onready var fermenting_value: Label = $CardPanel/MarginContainer/VBox/FermentingRow/FermentingValue

func _ready() -> void:
	_reset_sliders()
	mashing_slider.value_changed.connect(_on_slider_changed.unbind(1))
	boiling_slider.value_changed.connect(_on_slider_changed.unbind(1))
	fermenting_slider.value_changed.connect(_on_slider_changed.unbind(1))
	brew_button.pressed.connect(_on_brew_pressed)
	_update_preview()

func _reset_sliders() -> void:
	mashing_slider.value = 50.0
	boiling_slider.value = 50.0
	fermenting_slider.value = 50.0

func _get_sliders() -> Dictionary:
	return {
		"mashing": mashing_slider.value,
		"boiling": boiling_slider.value,
		"fermenting": fermenting_slider.value,
	}

func _on_slider_changed() -> void:
	mashing_value.text = str(int(mashing_slider.value))
	boiling_value.text = str(int(boiling_slider.value))
	fermenting_value.text = str(int(fermenting_slider.value))
	_update_preview()

func _update_preview() -> void:
	var pts: Dictionary = QualityCalculator.preview_points(_get_sliders())
	flavor_label.text = "Flavor: %d" % pts["flavor"]
	technique_label.text = "Technique: %d" % pts["technique"]

func _on_brew_pressed() -> void:
	brew_confirmed.emit(_get_sliders())

## Reset sliders when panel reopens.
func refresh() -> void:
	_reset_sliders()
	mashing_value.text = "50"
	boiling_value.text = "50"
	fermenting_value.text = "50"
	_update_preview()
