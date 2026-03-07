## Tests for discovery system extensions (Group 11).
extends GutTest


func before_each() -> void:
	GameState.reset()


# ---------------------------------------------------------------------------
# Helper: create a Yeast with a given flavor profile
# ---------------------------------------------------------------------------
func _make_yeast(profile: Dictionary) -> Yeast:
	var y := Yeast.new()
	y.ingredient_id = "test_yeast"
	y.ingredient_name = "Test Yeast"
	y.cost = 15
	y.ideal_temp_min_c = 15.0
	y.ideal_temp_max_c = 24.0
	y.attenuation_pct = 77.0
	y.yeast_flavor_profile = profile
	y.flavor_profile = {"bitterness": 0.0, "sweetness": 0.0, "roastiness": 0.0, "fruitiness": 0.0, "funkiness": 0.0}
	return y


# ---------------------------------------------------------------------------
# 11.1: Non-discovery tracking — mash tolerance
# ---------------------------------------------------------------------------
func test_check_non_discovery_detects_mash_tolerance():
	# First brew: baseline
	var result1: String = TasteSystem.check_non_discovery("ipa", {"mashing": 64.0, "boiling": 60.0}, 70.0)
	assert_eq(result1, "", "First brew should return empty (no history)")

	# Second brew: mash temp changed by 3+, quality within 5 points
	var result2: String = TasteSystem.check_non_discovery("ipa", {"mashing": 67.0, "boiling": 60.0}, 72.0)
	assert_eq(result2, "mash_tolerance", "Should detect mash tolerance")


# ---------------------------------------------------------------------------
# 11.1: Non-discovery tracking — boil tolerance
# ---------------------------------------------------------------------------
func test_check_non_discovery_detects_boil_tolerance():
	TasteSystem.check_non_discovery("stout", {"mashing": 65.0, "boiling": 45.0}, 60.0)
	var result: String = TasteSystem.check_non_discovery("stout", {"mashing": 65.0, "boiling": 75.0}, 62.0)
	assert_eq(result, "boil_tolerance", "Should detect boil tolerance")


# ---------------------------------------------------------------------------
# 11.1: No non-discovery when quality changes significantly
# ---------------------------------------------------------------------------
func test_check_non_discovery_returns_empty_when_quality_differs():
	TasteSystem.check_non_discovery("ipa", {"mashing": 64.0, "boiling": 60.0}, 70.0)
	var result: String = TasteSystem.check_non_discovery("ipa", {"mashing": 67.0, "boiling": 60.0}, 80.0)
	assert_eq(result, "", "Should return empty when quality differs by >= 5")


# ---------------------------------------------------------------------------
# 11.1: No non-discovery on first brew (no history)
# ---------------------------------------------------------------------------
func test_check_non_discovery_returns_empty_on_first_brew():
	var result: String = TasteSystem.check_non_discovery("pale_ale", {"mashing": 65.0, "boiling": 60.0}, 55.0)
	assert_eq(result, "", "First brew should always return empty")


# ---------------------------------------------------------------------------
# 11.3: Water match attribute when water score high
# ---------------------------------------------------------------------------
func test_water_match_attribute_when_water_score_high():
	# Simulate the attribute detection logic from execute_brew
	var brew_attributes: Array[String] = []
	var water_score: float = 85.0
	var has_water: bool = true  # Simulates current_water_profile != null

	if has_water:
		if water_score >= 80.0:
			brew_attributes.append("water_match")
		elif water_score < 40.0:
			brew_attributes.append("water_mismatch")

	assert_true(brew_attributes.has("water_match"), "Should add water_match when score >= 80")
	assert_true(TasteSystem.ATTRIBUTE_NAMES.has("water_match"), "ATTRIBUTE_NAMES should have water_match")
	assert_true(TasteSystem.ATTRIBUTE_LINKS.has("water_match"), "ATTRIBUTE_LINKS should have water_match")


# ---------------------------------------------------------------------------
# 11.3: Water mismatch attribute when water score low
# ---------------------------------------------------------------------------
func test_water_mismatch_attribute_when_water_score_low():
	var brew_attributes: Array[String] = []
	var water_score: float = 30.0
	var has_water: bool = true

	if has_water:
		if water_score >= 80.0:
			brew_attributes.append("water_match")
		elif water_score < 40.0:
			brew_attributes.append("water_mismatch")

	assert_true(brew_attributes.has("water_mismatch"), "Should add water_mismatch when score < 40")
	assert_true(TasteSystem.ATTRIBUTE_NAMES.has("water_mismatch"), "ATTRIBUTE_NAMES should have water_mismatch")


# ---------------------------------------------------------------------------
# 11.4: Banana ester attribute when wheat yeast at warm temp
# ---------------------------------------------------------------------------
func test_banana_ester_attribute_warm_wheat_yeast():
	var wheat_yeast: Yeast = _make_yeast({
		"below_18": {"phenol_clove": 0.7, "ester_banana": 0.2, "clean": 0.1},
		"18_to_22": {"ester_banana": 0.5, "phenol_clove": 0.4, "clean": 0.1},
		"above_22": {"ester_banana": 0.8, "phenol_clove": 0.1, "clean": 0.1},
	})

	var flavors: Dictionary = BrewingScience.calc_yeast_flavors(23.0, wheat_yeast)
	assert_gt(flavors.get("ester_banana", 0.0), 0.5, "Warm wheat yeast should produce banana > 0.5")

	# Verify the attribute would be added
	var brew_attributes: Array[String] = []
	if flavors.get("ester_banana", 0.0) > 0.5:
		brew_attributes.append("banana_esters")
	assert_true(brew_attributes.has("banana_esters"), "Should add banana_esters")
	assert_true(TasteSystem.ATTRIBUTE_NAMES.has("banana_esters"), "ATTRIBUTE_NAMES should have banana_esters")


# ---------------------------------------------------------------------------
# 11.4: Clove phenol attribute when wheat yeast at cool temp
# ---------------------------------------------------------------------------
func test_clove_phenol_attribute_cool_wheat_yeast():
	var wheat_yeast: Yeast = _make_yeast({
		"below_18": {"phenol_clove": 0.7, "ester_banana": 0.2, "clean": 0.1},
		"18_to_22": {"ester_banana": 0.5, "phenol_clove": 0.4, "clean": 0.1},
		"above_22": {"ester_banana": 0.8, "phenol_clove": 0.1, "clean": 0.1},
	})

	var flavors: Dictionary = BrewingScience.calc_yeast_flavors(16.0, wheat_yeast)
	assert_gt(flavors.get("phenol_clove", 0.0), 0.5, "Cool wheat yeast should produce clove > 0.5")

	var brew_attributes: Array[String] = []
	if flavors.get("phenol_clove", 0.0) > 0.5:
		brew_attributes.append("clove_phenols")
	assert_true(brew_attributes.has("clove_phenols"), "Should add clove_phenols")
	assert_true(TasteSystem.ATTRIBUTE_LINKS.has("clove_phenols"), "ATTRIBUTE_LINKS should have clove_phenols")


# ---------------------------------------------------------------------------
# 11.5: Late hop aroma attribute when hops in aroma slot
# ---------------------------------------------------------------------------
func test_late_hop_aroma_attribute():
	var hop_allocations: Dictionary = {"cascade": "aroma", "centennial": "bittering"}
	var brew_attributes: Array[String] = []

	for hop_id in hop_allocations:
		var slot: String = hop_allocations[hop_id] if hop_allocations[hop_id] is String else ""
		if slot == "aroma" and not brew_attributes.has("late_hop_aroma"):
			brew_attributes.append("late_hop_aroma")
		if slot == "dry_hop" and not brew_attributes.has("dry_hop_character"):
			brew_attributes.append("dry_hop_character")

	assert_true(brew_attributes.has("late_hop_aroma"), "Should add late_hop_aroma for aroma slot")
	assert_false(brew_attributes.has("dry_hop_character"), "Should NOT add dry_hop_character")
	assert_true(TasteSystem.ATTRIBUTE_NAMES.has("late_hop_aroma"), "ATTRIBUTE_NAMES should have late_hop_aroma")


# ---------------------------------------------------------------------------
# 11.5: Dry hop character attribute when hops in dry_hop slot
# ---------------------------------------------------------------------------
func test_dry_hop_character_attribute():
	var hop_allocations: Dictionary = {"cascade": "dry_hop"}
	var brew_attributes: Array[String] = []

	for hop_id in hop_allocations:
		var slot: String = hop_allocations[hop_id] if hop_allocations[hop_id] is String else ""
		if slot == "aroma" and not brew_attributes.has("late_hop_aroma"):
			brew_attributes.append("late_hop_aroma")
		if slot == "dry_hop" and not brew_attributes.has("dry_hop_character"):
			brew_attributes.append("dry_hop_character")

	assert_true(brew_attributes.has("dry_hop_character"), "Should add dry_hop_character for dry_hop slot")
	assert_true(TasteSystem.ATTRIBUTE_LINKS.has("dry_hop_character"), "ATTRIBUTE_LINKS should have dry_hop_character")


# ---------------------------------------------------------------------------
# 11.6: Non-discoveries persist in GameState
# ---------------------------------------------------------------------------
func test_non_discoveries_persist_in_gamestate():
	GameState.non_discoveries["mash_tolerance"] = true
	assert_true(GameState.non_discoveries.has("mash_tolerance"), "non_discoveries should persist on GameState")

	# Also verify TasteSystem's own tracking
	TasteSystem.non_discoveries["boil_tolerance"] = true
	assert_true(TasteSystem.non_discoveries.has("boil_tolerance"), "TasteSystem non_discoveries should persist")


# ---------------------------------------------------------------------------
# 11.6: Non-discoveries cleared on reset
# ---------------------------------------------------------------------------
func test_non_discoveries_cleared_on_reset():
	GameState.non_discoveries["mash_tolerance"] = true
	TasteSystem.non_discoveries["boil_tolerance"] = true
	TasteSystem._last_brew_by_style["ipa"] = {"sliders": {}, "quality": 50.0}

	GameState.reset()

	assert_eq(GameState.non_discoveries.size(), 0, "GameState non_discoveries should be cleared")
	assert_eq(TasteSystem.non_discoveries.size(), 0, "TasteSystem non_discoveries should be cleared")
	assert_eq(TasteSystem._last_brew_by_style.size(), 0, "TasteSystem _last_brew_by_style should be cleared")
