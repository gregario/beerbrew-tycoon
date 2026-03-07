extends GutTest

# --- Severity labels ---

func test_severity_subtle():
	assert_eq(FailureSystem.get_severity_label(0.1), "subtle")
	assert_eq(FailureSystem.get_severity_label(0.29), "subtle")

func test_severity_noticeable():
	assert_eq(FailureSystem.get_severity_label(0.3), "noticeable")
	assert_eq(FailureSystem.get_severity_label(0.6), "noticeable")

func test_severity_dominant():
	assert_eq(FailureSystem.get_severity_label(0.61), "dominant")
	assert_eq(FailureSystem.get_severity_label(1.0), "dominant")

# --- Context labels ---

func test_context_desired_within_threshold():
	var style := BeerStyle.new()
	style.acceptable_off_flavors = {"ester_banana": 0.8}
	assert_eq(FailureSystem.get_context_label("ester_banana", 0.5, style), "desired")

func test_context_flaw_above_threshold():
	var style := BeerStyle.new()
	style.acceptable_off_flavors = {}
	assert_eq(FailureSystem.get_context_label("fusel_alcohols", 0.5, style), "flaw")

func test_context_neutral_borderline():
	var style := BeerStyle.new()
	style.acceptable_off_flavors = {"diacetyl": 0.2}
	assert_eq(FailureSystem.get_context_label("diacetyl", 0.25, style), "neutral")

# --- Intensity generation ---

func test_generate_intensities_perfect_control():
	# With perfect temp control, should rarely produce off-flavors
	var clean_count := 0
	for i in range(20):
		var intensities := FailureSystem.generate_off_flavor_intensities(100)
		if intensities.is_empty():
			clean_count += 1
	assert_gt(clean_count, 15, "Perfect temp control should usually produce no off-flavors")

func test_generate_intensities_poor_control():
	# With terrible control, should often produce off-flavors
	var has_off_flavors := 0
	for i in range(20):
		var intensities := FailureSystem.generate_off_flavor_intensities(0)
		if not intensities.is_empty():
			has_off_flavors += 1
	assert_gt(has_off_flavors, 10, "Poor temp control should often produce off-flavors")

func test_generate_intensities_values_in_range():
	for i in range(50):
		var intensities := FailureSystem.generate_off_flavor_intensities(30)
		for key in intensities:
			assert_gte(intensities[key], 0.0, "Intensity should be >= 0")
			assert_lte(intensities[key], 1.0, "Intensity should be <= 1")

func test_oxidation_scales_with_batch_size():
	var high_batch_count := 0
	var low_batch_count := 0
	for i in range(100):
		var high := FailureSystem.generate_off_flavor_intensities(50, 2.0)
		if high.has("oxidation"):
			high_batch_count += 1
		var low := FailureSystem.generate_off_flavor_intensities(50, 1.0)
		if low.has("oxidation"):
			low_batch_count += 1
	assert_gt(high_batch_count, low_batch_count, "Higher batch size should produce more oxidation")

# --- Evaluate off-flavors ---

func test_evaluate_no_penalty_for_acceptable():
	var style := BeerStyle.new()
	style.acceptable_off_flavors = {"ester_banana": 0.8}
	var intensities := {"ester_banana": 0.5}
	var results := FailureSystem.evaluate_off_flavors(intensities, style)
	assert_eq(results.size(), 1)
	assert_eq(results[0]["context"], "desired")
	assert_eq(results[0]["penalty"], 0.0, "No penalty when within threshold")

func test_evaluate_penalty_for_excess():
	var style := BeerStyle.new()
	style.acceptable_off_flavors = {}
	var intensities := {"fusel_alcohols": 0.6}
	var results := FailureSystem.evaluate_off_flavors(intensities, style)
	assert_eq(results.size(), 1)
	assert_eq(results[0]["context"], "flaw")
	assert_gt(results[0]["penalty"], 0.0, "Should have penalty when above threshold")

func test_evaluate_includes_display_info():
	var style := BeerStyle.new()
	style.acceptable_off_flavors = {}
	var intensities := {"diacetyl": 0.4}
	var results := FailureSystem.evaluate_off_flavors(intensities, style)
	assert_eq(results[0]["display_name"], "Diacetyl")
	assert_eq(results[0]["severity"], "noticeable")
	assert_true(results[0]["description"].length() > 0)

# --- roll_failures backward compat ---

func test_roll_failures_returns_intensities_key():
	var result := FailureSystem.roll_failures(80.0, 80, 80)
	assert_has(result, "off_flavor_intensities", "Should include intensities in result")

func test_roll_failures_still_returns_legacy_keys():
	var result := FailureSystem.roll_failures(80.0, 80, 80)
	assert_has(result, "final_score")
	assert_has(result, "infected")
	assert_has(result, "off_flavor_tags")
	assert_has(result, "off_flavor_message")
	assert_has(result, "failure_messages")

# --- OFF_FLAVOR_INFO ---

func test_off_flavor_info_has_new_types():
	assert_true(FailureSystem.OFF_FLAVOR_INFO.has("diacetyl"))
	assert_true(FailureSystem.OFF_FLAVOR_INFO.has("oxidation"))
	assert_true(FailureSystem.OFF_FLAVOR_INFO.has("acetaldehyde"))
