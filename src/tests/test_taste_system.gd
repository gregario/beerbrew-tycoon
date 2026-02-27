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
