extends GutTest

## Tests for hop scheduling: GameState hop allocations and QualityCalculator hop schedule scoring.

# --- Helper: minimal BeerStyle with hop_schedule_expectations ---
func _make_style(id: String = "pale_ale", expectations: Dictionary = {}) -> BeerStyle:
	var s := BeerStyle.new()
	s.style_id = id
	s.style_name = id.capitalize()
	s.ideal_flavor_ratio = 0.5
	s.base_price = 100.0
	s.ideal_flavor_profile = {
		"bitterness": 0.5, "sweetness": 0.3,
		"roastiness": 0.1, "fruitiness": 0.3, "funkiness": 0.0
	}
	s.hop_schedule_expectations = expectations
	return s

# --- GameState tests ---

func test_gamestate_hop_allocations_defaults_to_empty():
	assert_eq(GameState.current_hop_allocations.size(), 0,
		"Hop allocations should default to empty dictionary")

func test_set_hop_allocations_persists():
	var allocs := {"cascade": "aroma", "centennial": "bittering"}
	GameState.set_hop_allocations(allocs)
	assert_eq(GameState.current_hop_allocations["cascade"], "aroma")
	assert_eq(GameState.current_hop_allocations["centennial"], "bittering")
	# Cleanup
	GameState.current_hop_allocations = {}

func test_reset_clears_hop_allocations():
	GameState.set_hop_allocations({"cascade": "aroma"})
	assert_eq(GameState.current_hop_allocations.size(), 1)
	GameState.reset()
	assert_eq(GameState.current_hop_allocations.size(), 0,
		"reset() should clear hop allocations to empty")

# --- QualityCalculator hop schedule scoring tests ---

func test_empty_allocations_scores_50():
	var style := _make_style("ipa", {"bittering": 0.3, "aroma": 0.5, "dry_hop": 0.2})
	var score: float = QualityCalculator._compute_hop_schedule_score(style, {})
	assert_eq(score, 50.0, "Empty hop allocations should score 50 (default)")

func test_matching_allocations_scores_higher():
	var style := _make_style("ipa", {"bittering": 0.3, "aroma": 0.5, "dry_hop": 0.2})
	# All hops assigned to slots that exist in expectations
	var good_allocs := {"cascade": "aroma", "centennial": "bittering"}
	var score: float = QualityCalculator._compute_hop_schedule_score(style, good_allocs)
	assert_gt(score, 50.0, "Matching hop allocations should score higher than empty")
	assert_eq(score, 100.0, "All hops matching expected slots should score 100")

func test_wrong_allocations_scores_differently():
	var style := _make_style("ipa", {"bittering": 0.3, "aroma": 0.5})
	# Assign hops to slot not in expectations
	var bad_allocs := {"cascade": "flavor", "centennial": "flavor"}
	var score: float = QualityCalculator._compute_hop_schedule_score(style, bad_allocs)
	assert_eq(score, 0.0, "No hops matching expected slots should score 0")

func test_partial_match_scores_proportionally():
	var style := _make_style("ipa", {"bittering": 0.3, "aroma": 0.5})
	# One matches, one doesn't
	var partial_allocs := {"cascade": "aroma", "centennial": "flavor"}
	var score: float = QualityCalculator._compute_hop_schedule_score(style, partial_allocs)
	assert_eq(score, 50.0, "Half matching should score 50")

func test_no_expectations_scores_70():
	var style := _make_style("basic_ale", {})
	var allocs := {"cascade": "aroma"}
	var score: float = QualityCalculator._compute_hop_schedule_score(style, allocs)
	assert_eq(score, 70.0, "Style with no hop expectations should default to 70")

func test_hop_allocations_affect_final_quality():
	var style := _make_style("ipa", {"bittering": 0.3, "aroma": 0.5, "dry_hop": 0.2})
	var recipe := {"malts": [], "hops": [], "yeast": null, "adjuncts": []}
	var sliders := {"mashing": 65.0, "boiling": 60.0, "fermenting": 20.0}
	# With empty allocations (default 50)
	var result_empty: Dictionary = QualityCalculator.calculate_quality(
		style, recipe, sliders, [], null, {})
	# With matching allocations (should score 100)
	var good_allocs := {"cascade": "aroma", "centennial": "bittering"}
	var result_good: Dictionary = QualityCalculator.calculate_quality(
		style, recipe, sliders, [], null, good_allocs)
	assert_gt(result_good["hop_schedule_score"], result_empty["hop_schedule_score"],
		"Good hop allocations should produce higher hop_schedule_score than empty")
	assert_gt(result_good["final_score"], result_empty["final_score"],
		"Good hop allocations should boost final score (10% weight)")
