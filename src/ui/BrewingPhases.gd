extends Control

## BrewingPhases — the core brewing interaction: three phase sliders.
## Emits brew_confirmed(sliders) when the player confirms. Has no direct
## No dependency on GameState. QualityCalculator is used only for the
## read-only slider preview (pure calculation, no state mutation).

signal brew_confirmed(sliders: Dictionary)

@onready var mashing_slider: HSlider = $CardPanel/MarginContainer/VBox/MashingRow/MashingSliderRow/MashingSlider
@onready var boiling_slider: HSlider = $CardPanel/MarginContainer/VBox/BoilingRow/BoilingSliderRow/BoilingSlider
@onready var fermenting_slider: HSlider = $CardPanel/MarginContainer/VBox/FermentingRow/FermentingSliderRow/FermentingSlider
@onready var brew_button: Button = $CardPanel/MarginContainer/VBox/FooterRow/BrewButton
@onready var flavor_label: Label = $CardPanel/MarginContainer/VBox/PreviewPanel/PreviewHBox/FlavorLabel
@onready var technique_label: Label = $CardPanel/MarginContainer/VBox/PreviewPanel/PreviewHBox/TechniqueLabel
@onready var mashing_value: Label = $CardPanel/MarginContainer/VBox/MashingRow/MashingValue
@onready var boiling_value: Label = $CardPanel/MarginContainer/VBox/BoilingRow/BoilingValue
@onready var fermenting_value: Label = $CardPanel/MarginContainer/VBox/FermentingRow/FermentingValue

var _bonus_label: Label = null
var _staff_labels: Dictionary = {}  # phase_name -> Label

func _ready() -> void:
	_reset_sliders()
	mashing_slider.value_changed.connect(_on_slider_changed.unbind(1))
	boiling_slider.value_changed.connect(_on_slider_changed.unbind(1))
	fermenting_slider.value_changed.connect(_on_slider_changed.unbind(1))
	brew_button.pressed.connect(_on_brew_pressed)
	_create_staff_labels()
	_update_preview()

func _reset_sliders() -> void:
	mashing_slider.value = 65.0
	boiling_slider.value = 60.0
	# Use midpoint of current fermenting range (may change with yeast)
	fermenting_slider.value = round((fermenting_slider.min_value + fermenting_slider.max_value) / 2.0)

func _get_sliders() -> Dictionary:
	return {
		"mashing": mashing_slider.value,
		"boiling": boiling_slider.value,
		"fermenting": fermenting_slider.value,
	}

func _on_slider_changed() -> void:
	if _is_temp_numbers_revealed():
		mashing_value.text = "%d°C" % int(mashing_slider.value)
		boiling_value.text = "%d min" % int(boiling_slider.value)
		fermenting_value.text = "%d°C" % int(fermenting_slider.value)
	else:
		mashing_value.text = _get_vague_mashing(int(mashing_slider.value))
		boiling_value.text = _get_vague_boiling(int(boiling_slider.value))
		fermenting_value.text = _get_vague_fermenting(int(fermenting_slider.value))
	_update_preview()

func _update_preview() -> void:
	var pts: Dictionary = QualityCalculator.preview_points(_get_sliders())
	flavor_label.text = "Flavor: %d" % pts["flavor"]
	technique_label.text = "Technique: %d" % pts["technique"]

func _on_brew_pressed() -> void:
	brew_confirmed.emit(_get_sliders())

## Reset sliders when panel reopens.
func refresh() -> void:
	_adjust_ferment_slider_for_yeast()
	_reset_sliders()
	if _is_temp_numbers_revealed():
		mashing_value.text = "65°C"
		boiling_value.text = "60 min"
		fermenting_value.text = "%d°C" % int(fermenting_slider.value)
	else:
		mashing_value.text = _get_vague_mashing(65)
		boiling_value.text = _get_vague_boiling(60)
		fermenting_value.text = _get_vague_fermenting(int(fermenting_slider.value))
	_update_preview()
	_update_bonus_label()
	_update_staff_labels()

func _update_bonus_label() -> void:
	if not is_instance_valid(EquipmentManager):
		return
	# Create label on first use
	if _bonus_label == null:
		_bonus_label = Label.new()
		_bonus_label.add_theme_color_override("font_color", Color("#8A9BB1"))
		_bonus_label.add_theme_font_size_override("font_size", 16)
		_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		# Insert above the sliders (after header)
		var vbox: VBoxContainer = $CardPanel/MarginContainer/VBox
		vbox.add_child(_bonus_label)
		vbox.move_child(_bonus_label, 0)
	var bonuses := EquipmentManager.active_bonuses
	var parts: Array[String] = []
	var san: int = bonuses.get("sanitation", 0)
	var temp: int = bonuses.get("temp_control", 0)
	var eff: float = bonuses.get("efficiency", 0.0)
	if san > 0:
		parts.append("+%d sanitation" % san)
	if temp > 0:
		parts.append("+%d temp control" % temp)
	if eff > 0.0:
		parts.append("+%d%% efficiency" % int(eff * 100))
	if parts.size() > 0:
		_bonus_label.text = "Equipment: " + ", ".join(parts)
		_bonus_label.visible = true
	else:
		_bonus_label.visible = false


func _create_staff_labels() -> void:
	var rows: Dictionary = {
		"mashing": $CardPanel/MarginContainer/VBox/MashingRow,
		"boiling": $CardPanel/MarginContainer/VBox/BoilingRow,
		"fermenting": $CardPanel/MarginContainer/VBox/FermentingRow,
	}
	for phase_name in rows:
		var row: VBoxContainer = rows[phase_name]
		var staff_label := Label.new()
		staff_label.add_theme_font_size_override("font_size", 16)
		staff_label.add_theme_color_override("font_color", Color("#8A9BB1"))
		staff_label.text = "(no staff assigned)"
		row.add_child(staff_label)
		_staff_labels[phase_name] = staff_label


func _update_staff_labels() -> void:
	for phase in ["mashing", "boiling", "fermenting"]:
		var label: Label = _staff_labels.get(phase, null)
		if label == null:
			continue

		var staff_bonus: int = 0
		var auto_bonus: int = 0
		var has_staff: bool = false
		var has_auto: bool = false

		# Staff bonus
		if is_instance_valid(StaffManager):
			var staff: Dictionary = StaffManager.get_staff_assigned_to(phase)
			if not staff.is_empty():
				has_staff = true
				var bonus: Dictionary = StaffManager.get_phase_bonus(phase)
				staff_bonus = int(bonus.get("flavor", 0.0)) + int(bonus.get("technique", 0.0))

		# Automation bonus
		if is_instance_valid(EquipmentManager):
			match phase:
				"mashing":
					auto_bonus = EquipmentManager.get_automation_mash_bonus()
				"boiling":
					auto_bonus = EquipmentManager.get_automation_boil_bonus()
				"fermenting":
					auto_bonus = EquipmentManager.get_automation_ferment_bonus()
			if auto_bonus > 0:
				has_auto = true

		# Display logic: three states
		if has_staff and has_auto:
			var staff_active: bool = staff_bonus >= auto_bonus
			var staff_part: String = "Staff +%d" % staff_bonus
			var auto_part: String = "Auto +%d" % auto_bonus
			if staff_active:
				label.text = "Bonus: %s (active) | %s" % [staff_part, auto_part]
			else:
				label.text = "Bonus: %s | %s (active)" % [staff_part, auto_part]
			# Use RichTextLabel-like coloring via bbcode isn't available, so set based on dominant
			label.add_theme_color_override("font_color", Color.WHITE)
		elif has_staff:
			label.text = "Bonus: Staff +%d" % staff_bonus
			label.add_theme_color_override("font_color", Color.WHITE)
		elif has_auto:
			label.text = "Bonus: Auto +%d" % auto_bonus
			label.add_theme_color_override("font_color", Color.WHITE)
		else:
			label.text = "(no staff assigned)"
			label.add_theme_color_override("font_color", Color("#8A9BB1"))

# ---------------------------------------------------------------------------
# Progressive Revelation helpers
# ---------------------------------------------------------------------------

func _is_temp_numbers_revealed() -> bool:
	if not is_instance_valid(EquipmentManager):
		return false
	return EquipmentManager.is_revealed("temp_numbers")

func _get_vague_mashing(temp_c: int) -> String:
	if temp_c <= 64:
		return "Low"
	elif temp_c <= 67:
		return "Medium"
	else:
		return "High"

func _get_vague_boiling(minutes: int) -> String:
	if minutes <= 50:
		return "Short"
	elif minutes <= 70:
		return "Medium"
	else:
		return "Long"

func _get_vague_fermenting(temp_c: int) -> String:
	if temp_c <= 18:
		return "Cool"
	elif temp_c <= 22:
		return "Moderate"
	else:
		return "Warm"

# ---------------------------------------------------------------------------
# Yeast-dependent ferment slider range
# ---------------------------------------------------------------------------

## Yeast-type ferment temperature ranges (with buffer).
const YEAST_FERMENT_RANGES: Dictionary = {
	"lager": {"min": 4, "max": 12},
	"saison": {"min": 20, "max": 35},
	"wheat": {"min": 16, "max": 26},
	"ale": {"min": 15, "max": 24},
}

func _adjust_ferment_slider_for_yeast() -> void:
	var yeast: Yeast = GameState.current_recipe.get("yeast", null) as Yeast
	if yeast == null:
		fermenting_slider.min_value = 15
		fermenting_slider.max_value = 25
		return
	var yeast_type: String = _classify_yeast(yeast)
	var range_data: Dictionary = YEAST_FERMENT_RANGES.get(yeast_type, {"min": 15, "max": 25})
	fermenting_slider.min_value = range_data["min"]
	fermenting_slider.max_value = range_data["max"]

func _classify_yeast(yeast: Yeast) -> String:
	var name_lower: String = yeast.ingredient_name.to_lower()
	if "lager" in name_lower:
		return "lager"
	if "saison" in name_lower:
		return "saison"
	if "wheat" in name_lower:
		return "wheat"
	# Default: use temp ranges to classify
	if yeast.ideal_temp_max_c <= 15.0:
		return "lager"
	if yeast.ideal_temp_min_c >= 20.0:
		return "saison"
	return "ale"
