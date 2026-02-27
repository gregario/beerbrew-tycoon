extends Control

## BrewingPhases — the core brewing interaction: three phase sliders.

@onready var mashing_slider: HSlider = $Panel/VBox/MashingRow/MashingSlider
@onready var boiling_slider: HSlider = $Panel/VBox/BoilingRow/BoilingSlider
@onready var fermenting_slider: HSlider = $Panel/VBox/FermentingRow/FermentingSlider
@onready var preview_label: Label = $Panel/VBox/PreviewLabel
@onready var brew_button: Button = $Panel/VBox/BrewButton

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
	_update_preview()

func _update_preview() -> void:
	if preview_label == null:
		return
	var sliders := _get_sliders()
	var points := QualityCalculator.preview_points(sliders)
	preview_label.text = "Flavor: %.0f  |  Technique: %.0f" % [
		points["flavor"], points["technique"]
	]

func _on_brew_pressed() -> void:
	var sliders := _get_sliders()

	# Deduct cost before calculating (spec: deducted before brewing phases begin)
	if not GameState.deduct_ingredient_cost():
		# Shouldn't reach here if loss check is correct, but guard anyway
		return

	GameState.set_brewing(true)

	# Calculate quality
	var result := QualityCalculator.calculate_quality(
		GameState.current_style,
		GameState.current_recipe,
		sliders,
		GameState.recipe_history
	)

	# Calculate revenue and add to balance immediately
	var revenue := GameState.calculate_revenue(result["final_score"])
	GameState.add_revenue(revenue)
	result["revenue"] = revenue

	# Record brew history
	GameState.record_brew(result["final_score"])

	# Store result for results screen
	GameState.last_brew_result = result

	GameState.set_brewing(false)
	GameState.advance_state()

## Reset sliders when panel reopens.
func refresh() -> void:
	_reset_sliders()
	_update_preview()
