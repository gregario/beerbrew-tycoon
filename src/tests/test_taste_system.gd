## Tests for taste skill system.
extends GutTest

func before_each() -> void:
	GameState.reset()

func test_general_taste_starts_at_zero():
	assert_eq(GameState.general_taste, 0)

func test_style_taste_starts_empty():
	assert_eq(GameState.style_taste.size(), 0)

func test_discoveries_starts_empty():
	assert_eq(GameState.discoveries.size(), 0)

func test_general_taste_increments_after_brew():
	GameState.general_taste = 0
	GameState.increment_taste("IPA")
	assert_eq(GameState.general_taste, 1)

func test_style_taste_increments_after_brew():
	GameState.increment_taste("IPA")
	assert_eq(GameState.style_taste.get("IPA", 0), 1)

func test_style_taste_tracks_multiple_styles():
	GameState.increment_taste("IPA")
	GameState.increment_taste("IPA")
	GameState.increment_taste("Stout")
	assert_eq(GameState.style_taste.get("IPA", 0), 2)
	assert_eq(GameState.style_taste.get("Stout", 0), 1)

func test_reset_clears_taste():
	GameState.general_taste = 5
	GameState.style_taste = {"IPA": 3}
	GameState.discoveries = {"dry_body": {"discovered": true}}
	GameState.reset()
	assert_eq(GameState.general_taste, 0)
	assert_eq(GameState.style_taste.size(), 0)
	assert_eq(GameState.discoveries.size(), 0)

func test_palate_level_novice():
	GameState.general_taste = 0
	assert_eq(GameState.get_palate_name(), "Novice")
	GameState.general_taste = 1
	assert_eq(GameState.get_palate_name(), "Novice")

func test_palate_level_developing():
	GameState.general_taste = 2
	assert_eq(GameState.get_palate_name(), "Developing")
	GameState.general_taste = 3
	assert_eq(GameState.get_palate_name(), "Developing")

func test_palate_level_experienced():
	GameState.general_taste = 4
	assert_eq(GameState.get_palate_name(), "Experienced")

func test_palate_level_expert():
	GameState.general_taste = 6
	assert_eq(GameState.get_palate_name(), "Expert")

# ---------------------------------------------------------------------------
# Tasting notes generation
# ---------------------------------------------------------------------------

func test_taste_level_0_gives_vague_notes():
	GameState.general_taste = 0
	var attributes: Array[String] = ["dry_body", "citrus_aroma", "clean_ferment"]
	var notes: String = TasteSystem.generate_tasting_notes(attributes, "IPA", {})
	assert_true(notes.length() > 0, "Should generate some text")
	assert_false(notes.containsn("citrus"), "Level 0 should not reveal citrus")

func test_taste_level_3_reveals_some_attributes():
	GameState.general_taste = 3
	var attributes: Array[String] = ["dry_body", "citrus_aroma", "clean_ferment"]
	var notes: String = TasteSystem.generate_tasting_notes(attributes, "IPA", {})
	assert_true(notes.length() > 10, "Should generate meaningful text")

func test_taste_level_5_gives_detailed_breakdown():
	GameState.general_taste = 5
	var attributes: Array[String] = ["dry_body", "citrus_aroma", "clean_ferment"]
	var sliders := {"mashing": 63.0, "boiling": 40.0, "fermenting": 20.0}
	var notes: String = TasteSystem.generate_tasting_notes(attributes, "IPA", sliders)
	assert_true(notes.containsn("63") or notes.containsn("mash"), "Level 5 should reference process details")

func test_discovered_attributes_are_highlighted():
	GameState.general_taste = 4
	GameState.discoveries = {"citrus_aroma": {"discovered": true, "linked_to": "", "linked_detail": ""}}
	var attributes: Array[String] = ["citrus_aroma", "clean_ferment"]
	var notes: String = TasteSystem.generate_tasting_notes(attributes, "IPA", {})
	assert_true(notes.containsn("citrus") or notes.containsn("Citrus"), "Discovered attribute should appear in notes")

# ---------------------------------------------------------------------------
# Discovery system
# ---------------------------------------------------------------------------

func test_discovery_roll_can_discover_attribute():
	GameState.general_taste = 10
	GameState.discoveries = {}
	var attributes: Array[String] = ["dry_body", "citrus_aroma"]
	var discovered := false
	for i in range(50):
		var result: Dictionary = TasteSystem.roll_discoveries(attributes, "IPA")
		if result.get("attribute_discovered", "") != "":
			discovered = true
			break
	assert_true(discovered, "High taste should eventually discover an attribute")

func test_discovery_roll_stores_in_gamestate():
	GameState.general_taste = 10
	GameState.discoveries = {}
	var attributes: Array[String] = ["dry_body"]
	for i in range(100):
		TasteSystem.roll_discoveries(attributes, "IPA")
		if GameState.discoveries.has("dry_body"):
			break
	assert_true(GameState.discoveries.has("dry_body"), "Discovery should be stored in GameState")
	assert_true(GameState.discoveries["dry_body"]["discovered"], "discovered flag should be true")

func test_already_discovered_not_rediscovered():
	GameState.general_taste = 10
	GameState.discoveries = {"dry_body": {"discovered": true, "linked_to": "", "linked_detail": ""}}
	var attributes: Array[String] = ["dry_body"]
	var result: Dictionary = TasteSystem.roll_discoveries(attributes, "IPA")
	assert_ne(result.get("attribute_discovered", ""), "dry_body", "Should not re-discover existing attribute")

func test_process_link_roll():
	GameState.general_taste = 5
	GameState.style_taste = {"IPA": 10}
	GameState.discoveries = {"citrus_aroma": {"discovered": true, "linked_to": "", "linked_detail": ""}}
	var attributes: Array[String] = ["citrus_aroma"]
	var linked := false
	for i in range(100):
		TasteSystem.roll_discoveries(attributes, "IPA")
		if GameState.discoveries["citrus_aroma"]["linked_to"] != "":
			linked = true
			break
	assert_true(linked, "High style taste should eventually link an attribute")

func test_discovery_chance_scales_with_taste():
	var low_chance: float = TasteSystem.get_discovery_chance(0)
	var high_chance: float = TasteSystem.get_discovery_chance(8)
	assert_almost_eq(low_chance, 0.20, 0.01)
	assert_almost_eq(high_chance, 0.60, 0.01)

func test_link_chance_scales_with_style_taste():
	var low_chance: float = TasteSystem.get_link_chance(0)
	var high_chance: float = TasteSystem.get_link_chance(8)
	assert_almost_eq(low_chance, 0.10, 0.01)
	assert_almost_eq(high_chance, 0.50, 0.01)
