extends GutTest

# Pre-load style resources to ensure we get the same cached instances
# that ResearchManager operates on (Godot resource caching pitfall).
var _lager: Resource = preload("res://data/styles/lager.tres")
var _stout: Resource = preload("res://data/styles/stout.tres")
var _wheat: Resource = preload("res://data/styles/wheat_beer.tres")


func before_each() -> void:
	if is_instance_valid(MetaProgressionManager):
		MetaProgressionManager.reset_meta()
	GameState.reset()


func after_each() -> void:
	# Clean up: re-lock any styles we unlocked via meta so other tests aren't affected
	_lager.unlocked = false
	_stout.unlocked = false
	_wheat.unlocked = false


func test_meta_unlocked_style_available_after_reset() -> void:
	MetaProgressionManager.unlocked_styles = ["lager"] as Array[String]
	GameState.reset()
	assert_true(_lager.unlocked)


func test_non_meta_style_still_locked_after_reset() -> void:
	MetaProgressionManager.unlocked_styles = ["lager"] as Array[String]
	GameState.reset()
	assert_false(_stout.unlocked)


func test_no_crash_with_empty_meta_styles() -> void:
	MetaProgressionManager.unlocked_styles.clear()
	GameState.reset()
	assert_true(true)


func test_multiple_meta_styles_unlocked() -> void:
	MetaProgressionManager.unlocked_styles = ["lager", "stout"] as Array[String]
	GameState.reset()
	assert_true(_lager.unlocked)
	assert_true(_stout.unlocked)
	assert_false(_wheat.unlocked)
