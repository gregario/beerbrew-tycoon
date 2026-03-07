extends GutTest

## Tests for BreweryPath base class and path subclasses.

const BreweryPath = preload("res://scripts/paths/BreweryPath.gd")
const ArtisanPath = preload("res://scripts/paths/ArtisanPath.gd")
const MassMarketPath = preload("res://scripts/paths/MassMarketPath.gd")

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

# --- ArtisanPath ---

func test_artisan_path_name():
	var path = ArtisanPath.new()
	assert_eq(path.get_path_name(), "Artisan Brewery")
	assert_eq(path.get_path_type(), "artisan")

func test_artisan_quality_bonus():
	var path = ArtisanPath.new()
	assert_almost_eq(path.get_quality_bonus(), 1.2, 0.001)

func test_artisan_competition_discount():
	var path = ArtisanPath.new()
	assert_almost_eq(path.get_competition_discount(), 0.5, 0.001)

func test_artisan_no_batch_or_ingredient_bonus():
	var path = ArtisanPath.new()
	assert_almost_eq(path.get_batch_multiplier(), 1.0, 0.001)
	assert_almost_eq(path.get_ingredient_discount(), 1.0, 0.001)

func test_artisan_reputation_starts_at_zero():
	var path = ArtisanPath.new()
	assert_eq(path.reputation, 0)

func test_artisan_add_reputation():
	var path = ArtisanPath.new()
	path.add_reputation(5)
	assert_eq(path.reputation, 5)
	path.add_reputation(3)
	assert_eq(path.reputation, 8)

func test_artisan_serialize_roundtrip():
	var path = ArtisanPath.new()
	path.add_reputation(42)
	var data: Dictionary = path.serialize()
	assert_eq(data["path_type"], "artisan")
	assert_eq(data["reputation"], 42)
	var path2 = ArtisanPath.new()
	path2.deserialize(data)
	assert_eq(path2.reputation, 42)

func test_artisan_win_description():
	var path = ArtisanPath.new()
	assert_true(path.get_win_description().length() > 0)

# --- MassMarketPath ---

func test_mass_market_path_name():
	var path = MassMarketPath.new()
	assert_eq(path.get_path_name(), "Mass-Market Brewery")
	assert_eq(path.get_path_type(), "mass_market")

func test_mass_market_batch_multiplier():
	var path = MassMarketPath.new()
	assert_almost_eq(path.get_batch_multiplier(), 2.0, 0.001)

func test_mass_market_ingredient_discount():
	var path = MassMarketPath.new()
	assert_almost_eq(path.get_ingredient_discount(), 0.8, 0.001)

func test_mass_market_no_quality_or_competition_bonus():
	var path = MassMarketPath.new()
	assert_almost_eq(path.get_quality_bonus(), 1.0, 0.001)
	assert_almost_eq(path.get_competition_discount(), 1.0, 0.001)

func test_mass_market_serialize_roundtrip():
	var path = MassMarketPath.new()
	var data: Dictionary = path.serialize()
	assert_eq(data["path_type"], "mass_market")
	var path2 = MassMarketPath.new()
	path2.deserialize(data)
	assert_eq(path2.get_path_name(), "Mass-Market Brewery")

func test_mass_market_win_description():
	var path = MassMarketPath.new()
	assert_true(path.get_win_description().length() > 0)
