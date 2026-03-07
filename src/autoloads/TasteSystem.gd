extends Node

## TasteSystem — generates tasting notes and handles discovery rolls.
## Reads GameState.general_taste, GameState.style_taste, GameState.discoveries.
## All public methods are static.


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

const ATTRIBUTE_NAMES: Dictionary = {
	"dry_body": "Dry Body",
	"crisp_body": "Crisp Body",
	"medium_body": "Medium Body",
	"full_body": "Full Body",
	"sweet_body": "Sweet Body",
	"low_bitter": "Low Bitterness",
	"balanced_bitter": "Balanced Bitterness",
	"assertive_bitter": "Assertive Bitterness",
	"floral_aroma": "Floral Aroma",
	"citrus_aroma": "Citrus Aroma",
	"piney_aroma": "Piney Aroma",
	"earthy_aroma": "Earthy Aroma",
	"spicy_aroma": "Spicy Aroma",
	"clean_ferment": "Clean Fermentation",
	"fruity_esters": "Fruity Esters",
	"fusel_alcohols": "Fusel Alcohols",
	"stalled_ferment": "Stalled Fermentation",
	# Water-related discoveries (11.3)
	"water_match": "Good Water Match",
	"water_mismatch": "Poor Water Match",
	# Yeast-temp discoveries (11.4)
	"banana_esters": "Banana Esters",
	"clove_phenols": "Clove Phenols",
	"saison_spice": "Saison Spice",
	# Hop schedule discoveries (11.5)
	"late_hop_aroma": "Enhanced Hop Aroma",
	"dry_hop_character": "Dry Hop Character",
}

const ATTRIBUTE_LINKS: Dictionary = {
	"dry_body": {"phase": "mashing", "detail": "Low mash temperature produced a dry, fermentable wort."},
	"crisp_body": {"phase": "mashing", "detail": "Cool mash temperature yielded a crisp, light body."},
	"medium_body": {"phase": "mashing", "detail": "Moderate mash temperature created a balanced body."},
	"full_body": {"phase": "mashing", "detail": "Warm mash temperature left more unfermentable sugars."},
	"sweet_body": {"phase": "mashing", "detail": "High mash temperature preserved residual sweetness."},
	"low_bitter": {"phase": "boiling", "detail": "Short boil extracted minimal hop bitterness."},
	"balanced_bitter": {"phase": "boiling", "detail": "Moderate boil achieved balanced hop bitterness."},
	"assertive_bitter": {"phase": "boiling", "detail": "Long boil maximized hop alpha-acid extraction."},
	"floral_aroma": {"phase": "boiling", "detail": "Late-addition noble hops contributed floral notes."},
	"citrus_aroma": {"phase": "boiling", "detail": "American hop varieties delivered bright citrus aroma."},
	"piney_aroma": {"phase": "boiling", "detail": "Pacific hops imparted resinous pine character."},
	"earthy_aroma": {"phase": "boiling", "detail": "English hops provided earthy, herbal undertones."},
	"spicy_aroma": {"phase": "boiling", "detail": "Hop varieties added spicy, peppery aroma notes."},
	"clean_ferment": {"phase": "fermenting", "detail": "Yeast fermented cleanly within its ideal range."},
	"fruity_esters": {"phase": "fermenting", "detail": "Slightly warm fermentation produced fruity ester notes."},
	"fusel_alcohols": {"phase": "fermenting", "detail": "Too-warm fermentation created harsh fusel alcohols."},
	"stalled_ferment": {"phase": "fermenting", "detail": "Cold fermentation caused yeast to stall."},
	# Water-related discoveries (11.3)
	"water_match": {"phase": "recipe", "detail": "The water chemistry complemented this beer style perfectly."},
	"water_mismatch": {"phase": "recipe", "detail": "The water profile clashed with this beer style's needs."},
	# Yeast-temp discoveries (11.4)
	"banana_esters": {"phase": "fermenting", "detail": "Warm fermentation of wheat yeast produced banana-like esters."},
	"clove_phenols": {"phase": "fermenting", "detail": "Cool fermentation of wheat yeast brought out clove-like phenols."},
	"saison_spice": {"phase": "fermenting", "detail": "The saison yeast expressed peppery, spicy character at this temperature."},
	# Hop schedule discoveries (11.5)
	"late_hop_aroma": {"phase": "recipe", "detail": "Adding hops late in the boil preserved volatile aromatic compounds."},
	"dry_hop_character": {"phase": "recipe", "detail": "Dry hopping added intense hop aroma without additional bitterness."},
}


# ---------------------------------------------------------------------------
# Non-discovery tracking (11.1)
# ---------------------------------------------------------------------------

## Stores the last brew's slider values and quality per style for comparison.
var _last_brew_by_style: Dictionary = {}  # style_id → {sliders: Dictionary, quality: float}

## Tracks what the player learned doesn't matter.
var non_discoveries: Dictionary = {}  # discovery_id → true


## Compares this brew against the last brew of the same style.
## If one variable changed significantly but quality stayed similar, returns the
## non-discovery type ("mash_tolerance" or "boil_tolerance"). Otherwise returns "".
func check_non_discovery(style_id: String, current_sliders: Dictionary, current_quality: float) -> String:
	if not _last_brew_by_style.has(style_id):
		_last_brew_by_style[style_id] = {"sliders": current_sliders.duplicate(), "quality": current_quality}
		return ""

	var last: Dictionary = _last_brew_by_style[style_id]
	var last_sliders: Dictionary = last.get("sliders", {})
	var last_quality: float = last.get("quality", 0.0)
	var quality_diff: float = absf(current_quality - last_quality)

	var result: String = ""

	# Only trigger non-discovery if quality didn't change much
	if quality_diff < 5.0:
		var mash_diff: float = absf(current_sliders.get("mashing", 65.0) - last_sliders.get("mashing", 65.0))
		var boil_diff: float = absf(current_sliders.get("boiling", 60.0) - last_sliders.get("boiling", 60.0))

		if mash_diff >= 3.0 and not non_discoveries.has("mash_tolerance"):
			result = "mash_tolerance"
			non_discoveries["mash_tolerance"] = true
		elif boil_diff >= 15.0 and not non_discoveries.has("boil_tolerance"):
			result = "boil_tolerance"
			non_discoveries["boil_tolerance"] = true

	# Update last brew data for this style
	_last_brew_by_style[style_id] = {"sliders": current_sliders.duplicate(), "quality": current_quality}
	return result


# ---------------------------------------------------------------------------
# Tasting notes generation
# ---------------------------------------------------------------------------

## Generates tasting notes text based on taste level, brew attributes, and discoveries.
func generate_tasting_notes(
	attributes: Array[String],
	style_name: String,
	sliders: Dictionary
) -> String:
	var taste: int = GameState.general_taste
	var discoveries: Dictionary = GameState.discoveries

	if taste <= 0:
		return _level_0_notes()
	elif taste == 1:
		return _level_1_notes(attributes)
	elif taste == 2:
		return _level_2_notes(attributes)
	elif taste == 3:
		return _level_3_notes(attributes, discoveries)
	elif taste == 4:
		return _level_4_notes(attributes, style_name, discoveries)
	else:
		return _level_5_notes(attributes, style_name, discoveries, sliders)


func _level_0_notes() -> String:
	return "Your friends shrug. \"It's... beer? Tastes like beer.\""


func _level_1_notes(attributes: Array[String]) -> String:
	if attributes.size() == 0:
		return "You notice something, but can't quite place it."
	var key: String = attributes[0]
	var category: String = _get_category(key)
	return "You get a vague sense of the %s." % category


func _level_2_notes(attributes: Array[String]) -> String:
	var parts: Array[String] = []
	var body_note: String = ""
	for attr in attributes:
		var attr_name: String = ATTRIBUTE_NAMES.get(attr, attr)
		if attr.ends_with("_body"):
			body_note = attr_name
		elif parts.size() < 2:
			parts.append(attr_name)
	var text: String = ""
	if body_note != "":
		text = "The beer has a %s." % body_note
	if parts.size() > 0:
		text += " You detect %s." % " and ".join(parts)
	if text == "":
		text = "You're developing a sense for this beer."
	return text.strip_edges()


func _level_3_notes(
	attributes: Array[String],
	discoveries: Dictionary
) -> String:
	var tags: Array[String] = []
	for attr in attributes:
		var attr_name: String = ATTRIBUTE_NAMES.get(attr, attr)
		if discoveries.has(attr) and discoveries[attr].get("discovered", false):
			attr_name = "[color=#FFC857]%s[/color]" % attr_name
		tags.append(attr_name)

	var text: String = "Flavor profile: %s." % ", ".join(tags)

	# Add one process hint for a linked attribute
	for attr in attributes:
		if discoveries.has(attr):
			var linked: String = discoveries[attr].get("linked_to", "")
			if linked != "":
				var detail: String = discoveries[attr].get("linked_detail", "")
				text += " Hint: %s" % detail
				break

	return text


func _level_4_notes(
	attributes: Array[String],
	style_name: String,
	discoveries: Dictionary
) -> String:
	var tags: Array[String] = []
	for attr in attributes:
		var attr_name: String = ATTRIBUTE_NAMES.get(attr, attr)
		if discoveries.has(attr) and discoveries[attr].get("discovered", false):
			attr_name = "[color=#FFC857]%s[/color]" % attr_name
		tags.append(attr_name)

	var text: String = "Full tasting notes for this %s:\n" % style_name
	text += "Attributes: %s.\n" % ", ".join(tags)

	# Process attributions for linked discoveries
	for attr in attributes:
		if discoveries.has(attr):
			var linked: String = discoveries[attr].get("linked_to", "")
			if linked != "":
				var detail: String = discoveries[attr].get("linked_detail", "")
				var attr_name: String = ATTRIBUTE_NAMES.get(attr, attr)
				text += "  - %s: %s\n" % [attr_name, detail]

	var style_level: int = GameState.style_taste.get(style_name, 0)
	if style_level >= 3:
		text += "Your expertise with %s is showing." % style_name
	else:
		text += "Keep brewing %s to deepen your understanding." % style_name

	return text


func _level_5_notes(
	attributes: Array[String],
	style_name: String,
	discoveries: Dictionary,
	sliders: Dictionary
) -> String:
	var text: String = _level_4_notes(attributes, style_name, discoveries)

	if sliders.size() > 0:
		text += "\n\nProcess details:"
		for key in sliders:
			text += "\n  %s: %.1f" % [key, sliders[key]]

	return text


func _get_category(attr_key: String) -> String:
	if attr_key.ends_with("_body"):
		return "body"
	elif attr_key.ends_with("_bitter"):
		return "bitterness"
	elif attr_key.ends_with("_aroma"):
		return "aroma"
	else:
		return "fermentation character"


# ---------------------------------------------------------------------------
# Discovery system
# ---------------------------------------------------------------------------

## Returns the chance of discovering a new attribute (0.0 - 0.80).
func get_discovery_chance(general_taste: int) -> float:
	return minf(0.20 + general_taste * 0.05, 0.80)


## Returns the chance of linking an attribute to its process (0.0 - 0.80).
func get_link_chance(style_taste_level: int) -> float:
	return minf(0.10 + style_taste_level * 0.05, 0.80)


## Rolls for attribute discovery and process linking.
## Returns {"attribute_discovered": "key_or_empty", "process_linked": "key_or_empty"}.
func roll_discoveries(
	brew_attributes: Array[String],
	style_name: String
) -> Dictionary:
	var result: Dictionary = {"attribute_discovered": "", "process_linked": ""}

	# Roll 1: attribute discovery
	var disc_chance: float = get_discovery_chance(GameState.general_taste)
	if randf() < disc_chance:
		var undiscovered: Array[String] = []
		for attr in brew_attributes:
			if not GameState.discoveries.has(attr):
				undiscovered.append(attr)
		if undiscovered.size() > 0:
			var pick: String = undiscovered[randi() % undiscovered.size()]
			GameState.discoveries[pick] = {
				"discovered": true,
				"linked_to": "",
				"linked_detail": "",
			}
			result["attribute_discovered"] = pick

	# Roll 2: process attribution
	var style_level: int = GameState.style_taste.get(style_name, 0)
	var link_chance: float = get_link_chance(style_level)
	if randf() < link_chance:
		var unlinked: Array[String] = []
		for attr in brew_attributes:
			if GameState.discoveries.has(attr):
				var entry: Dictionary = GameState.discoveries[attr]
				if entry.get("discovered", false) and entry.get("linked_to", "") == "":
					unlinked.append(attr)
		if unlinked.size() > 0:
			var pick: String = unlinked[randi() % unlinked.size()]
			var link_info: Dictionary = ATTRIBUTE_LINKS.get(pick, {})
			GameState.discoveries[pick]["linked_to"] = link_info.get("phase", "")
			GameState.discoveries[pick]["linked_detail"] = link_info.get("detail", "")
			result["process_linked"] = pick

	return result
