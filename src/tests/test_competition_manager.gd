extends GutTest

func before_each() -> void:
	GameState.reset()
	CompetitionManager.reset()

# --- Initial state ---
func test_starts_with_no_active_competition() -> void:
	assert_null(CompetitionManager.current_competition)

func test_starts_with_turns_until_next() -> void:
	assert_gte(CompetitionManager.turns_until_next, 8)
	assert_lte(CompetitionManager.turns_until_next, 10)

func test_starts_with_no_medals() -> void:
	assert_eq(CompetitionManager.medals["gold"], 0)
	assert_eq(CompetitionManager.medals["silver"], 0)
	assert_eq(CompetitionManager.medals["bronze"], 0)

# --- Scheduling ---
func test_tick_decrements_turns_until_next() -> void:
	var initial: int = CompetitionManager.turns_until_next
	CompetitionManager.tick()
	if CompetitionManager.current_competition == null:
		assert_eq(CompetitionManager.turns_until_next, initial - 1)

func test_competition_announced_when_counter_reaches_zero() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	assert_not_null(CompetitionManager.current_competition)

func test_announced_competition_has_required_fields() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	var comp: Dictionary = CompetitionManager.current_competition
	assert_has(comp, "competition_id")
	assert_has(comp, "name")
	assert_has(comp, "category")
	assert_has(comp, "entry_fee")
	assert_has(comp, "prizes")
	assert_has(comp, "turns_remaining")

func test_competition_has_2_turn_entry_window() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	assert_eq(CompetitionManager.current_competition["turns_remaining"], 2)

func test_competition_category_valid() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	var cat: String = CompetitionManager.current_competition["category"]
	assert_true(cat in CompetitionManager.STYLE_IDS or cat == "open",
		"Category '%s' should be valid style or 'open'" % cat)

func test_competition_has_prize_tiers() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	var prizes: Dictionary = CompetitionManager.current_competition["prizes"]
	assert_gt(prizes["gold"], prizes["silver"])
	assert_gt(prizes["silver"], prizes["bronze"])
	assert_gt(prizes["bronze"], 0)

func test_entry_fee_positive() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	assert_gt(CompetitionManager.current_competition["entry_fee"], 0)

func test_announced_signal_emitted() -> void:
	watch_signals(CompetitionManager)
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	assert_signal_emitted(CompetitionManager, "competition_announced")
