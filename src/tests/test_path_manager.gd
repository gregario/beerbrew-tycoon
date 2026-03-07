extends GutTest

## Tests for BreweryPath base class and path subclasses.

const BreweryPath = preload("res://scripts/paths/BreweryPath.gd")

func test_base_path_defaults():
	var path = BreweryPath.new()
	assert_eq(path.get_path_name(), "", "Base path has empty name")
	assert_eq(path.get_quality_bonus(), 1.0, "Base path has no quality bonus")
	assert_eq(path.get_batch_multiplier(), 1.0, "Base path has no batch multiplier")
	assert_eq(path.get_ingredient_discount(), 1.0, "Base path has no ingredient discount")
	assert_eq(path.get_competition_discount(), 1.0, "Base path has no competition discount")
	assert_eq(path.get_win_description(), "", "Base path has empty win description")

func test_base_path_serialize_roundtrip():
	var path = BreweryPath.new()
	var data: Dictionary = path.serialize()
	assert_true(data.has("path_type"), "Serialized data has path_type")
	var path2 = BreweryPath.new()
	path2.deserialize(data)
	assert_eq(path2.get_path_name(), path.get_path_name())
