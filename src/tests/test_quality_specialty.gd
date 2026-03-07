extends GutTest

# --- apply_specialty_variance ---

func test_apply_specialty_variance_returns_in_range() -> void:
	for s in [1, 42, 100, 9999, 77777]:
		var result: float = QualityCalculator.apply_specialty_variance(50.0, s)
		assert_gte(result, 0.0)
		assert_lte(result, 100.0)

func test_apply_specialty_variance_deterministic() -> void:
	var result_a: float = QualityCalculator.apply_specialty_variance(60.0, 42)
	var result_b: float = QualityCalculator.apply_specialty_variance(60.0, 42)
	assert_almost_eq(result_a, result_b, 0.001)

func test_apply_specialty_variance_clamped_at_100() -> void:
	# base 95 + ceiling boost 10 = 105 before variance; even with negative variance
	# the ceiling boost alone pushes past 100, so clamping should kick in
	var result: float = QualityCalculator.apply_specialty_variance(95.0, 42)
	assert_lte(result, 100.0)

func test_apply_specialty_variance_clamped_at_0() -> void:
	# base 0 + ceiling boost 10 = 10, variance can be -15 → -5 → clamped to 0
	# Use multiple seeds to find one that gives negative variance
	var found_zero := false
	for s in range(0, 200):
		var result: float = QualityCalculator.apply_specialty_variance(0.0, s)
		assert_gte(result, 0.0)
		if result == 0.0:
			found_zero = true
	# With base 0, ceiling 10, variance range [-15, 15], values from -5 to 25
	# Clamped: 0 to 25. Some seeds should hit 0.
	assert_true(found_zero, "Expected at least one seed to produce 0.0 with base 0")
