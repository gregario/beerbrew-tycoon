## Tests for MarketSystem autoload.
extends GutTest

const STYLE_IDS := ["lager", "pale_ale", "wheat_beer", "stout"]

func before_each():
	MarketSystem.register_styles(STYLE_IDS)
	MarketSystem.initialize_demand()

# ---------------------------------------------------------------------------
# Tests: initial state
# ---------------------------------------------------------------------------

func test_all_styles_have_demand_after_init():
	for sid in STYLE_IDS:
		var w := MarketSystem.get_demand_weight(sid)
		assert_gte(w, MarketSystem.DEMAND_NORMAL,
			"%s should have at least normal demand" % sid)

func test_at_least_one_style_elevated_after_init():
	var elevated_count := 0
	for sid in STYLE_IDS:
		if MarketSystem.get_demand_weight(sid) == MarketSystem.DEMAND_HIGH:
			elevated_count += 1
	assert_gte(elevated_count, 1, "At least one style should be elevated at init")

func test_elevated_demand_is_correct_value():
	for sid in STYLE_IDS:
		var w := MarketSystem.get_demand_weight(sid)
		assert_true(
			w == MarketSystem.DEMAND_NORMAL or w == MarketSystem.DEMAND_HIGH,
			"Demand must be either NORMAL or HIGH"
		)

# ---------------------------------------------------------------------------
# Tests: demand rotation
# ---------------------------------------------------------------------------

func test_rotate_changes_demand():
	# Record the initial elevated set, then rotate multiple times and verify it changes.
	var initial := _get_elevated_styles()
	var changed := false
	for _i in range(10):
		MarketSystem.rotate_demand()
		if _get_elevated_styles() != initial:
			changed = true
			break
	assert_true(changed, "rotate_demand() should change elevated styles over multiple rotations")

func test_rotation_does_not_repeat_previous_set():
	# Rotate once, record the set, rotate again, ensure different.
	MarketSystem.rotate_demand()
	var first_rotation := _get_elevated_styles()
	MarketSystem.rotate_demand()
	var second_rotation := _get_elevated_styles()
	assert_ne(first_rotation, second_rotation,
		"Consecutive rotations should not produce the same elevated set")

func test_rotation_keeps_valid_demand_values():
	MarketSystem.rotate_demand()
	for sid in STYLE_IDS:
		var w := MarketSystem.get_demand_weight(sid)
		assert_true(
			w == MarketSystem.DEMAND_NORMAL or w == MarketSystem.DEMAND_HIGH,
			"Post-rotation demand must be NORMAL or HIGH"
		)

# ---------------------------------------------------------------------------
# Tests: demand multiplier usage
# ---------------------------------------------------------------------------

func test_get_demand_weight_unknown_style_returns_normal():
	var w := MarketSystem.get_demand_weight("unknown_style")
	assert_eq(w, MarketSystem.DEMAND_NORMAL,
		"Unknown style should return DEMAND_NORMAL")

func test_should_rotate_turn_interval():
	assert_false(MarketSystem.should_rotate(0), "Turn 0 should not rotate")
	assert_false(MarketSystem.should_rotate(1), "Turn 1 should not rotate (interval=3)")
	assert_false(MarketSystem.should_rotate(2), "Turn 2 should not rotate")
	assert_true(MarketSystem.should_rotate(3),  "Turn 3 should rotate")
	assert_false(MarketSystem.should_rotate(4), "Turn 4 should not rotate")
	assert_true(MarketSystem.should_rotate(6),  "Turn 6 should rotate")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

func _get_elevated_styles() -> Array:
	var elevated := []
	for sid in STYLE_IDS:
		if MarketSystem.get_demand_weight(sid) == MarketSystem.DEMAND_HIGH:
			elevated.append(sid)
	elevated.sort()
	return elevated
