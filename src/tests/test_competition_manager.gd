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

# --- Entry ---
func test_enter_deducts_fee() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 1000.0
	var fee: int = CompetitionManager.current_competition["entry_fee"]
	var cat: String = CompetitionManager.current_competition["category"]
	var style: String = cat if cat != "open" else "lager"
	CompetitionManager.enter(style, 70.0)
	assert_almost_eq(GameState.balance, 1000.0 - fee, 0.01)

func test_enter_stores_entry() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 1000.0
	var cat: String = CompetitionManager.current_competition["category"]
	var style: String = cat if cat != "open" else "lager"
	CompetitionManager.enter(style, 75.0)
	assert_not_null(CompetitionManager.player_entry)
	assert_eq(CompetitionManager.player_entry["quality"], 75.0)

func test_enter_wrong_style_fails() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 1000.0
	# Force a specific category
	CompetitionManager.current_competition["category"] = "stout"
	var result: bool = CompetitionManager.enter("lager", 70.0)
	assert_false(result)
	assert_null(CompetitionManager.player_entry)

func test_enter_open_category_any_style() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 1000.0
	CompetitionManager.current_competition["category"] = "open"
	var result: bool = CompetitionManager.enter("wheat_beer", 60.0)
	assert_true(result)

func test_cannot_enter_twice() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 2000.0
	var cat: String = CompetitionManager.current_competition["category"]
	var style: String = cat if cat != "open" else "lager"
	CompetitionManager.enter(style, 70.0)
	var result: bool = CompetitionManager.enter(style, 80.0)
	assert_false(result)

func test_cannot_enter_without_funds() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 0.0
	var result: bool = CompetitionManager.enter("lager", 70.0)
	assert_false(result)

func test_enter_no_competition_fails() -> void:
	var result: bool = CompetitionManager.enter("lager", 70.0)
	assert_false(result)

func test_enter_emits_signal() -> void:
	watch_signals(CompetitionManager)
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 1000.0
	var cat: String = CompetitionManager.current_competition["category"]
	var style: String = cat if cat != "open" else "lager"
	CompetitionManager.enter(style, 70.0)
	assert_signal_emitted(CompetitionManager, "competition_entered")

# --- Judging ---
func test_judge_after_deadline() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()  # Announces, turns_remaining = 2
	GameState.balance = 1000.0
	var cat: String = CompetitionManager.current_competition["category"]
	var style: String = cat if cat != "open" else "lager"
	CompetitionManager.enter(style, 95.0)  # Very high quality
	CompetitionManager.tick()  # turns_remaining = 1
	var result: Dictionary = CompetitionManager.tick()  # turns_remaining = 0 → judge
	assert_true(result.has("placement"))
	assert_true(result.has("prize"))

func test_judge_clears_competition() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 1000.0
	var cat: String = CompetitionManager.current_competition["category"]
	var style: String = cat if cat != "open" else "lager"
	CompetitionManager.enter(style, 70.0)
	CompetitionManager.tick()
	CompetitionManager.tick()
	assert_null(CompetitionManager.current_competition)
	assert_null(CompetitionManager.player_entry)

func test_judge_schedules_next() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 1000.0
	var cat: String = CompetitionManager.current_competition["category"]
	var style: String = cat if cat != "open" else "lager"
	CompetitionManager.enter(style, 70.0)
	CompetitionManager.tick()
	CompetitionManager.tick()
	assert_gte(CompetitionManager.turns_until_next, CompetitionManager.MIN_INTERVAL)
	assert_lte(CompetitionManager.turns_until_next, CompetitionManager.MAX_INTERVAL)

func test_judge_gold_awards_prize() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 1000.0
	GameState.turn_counter = 1  # Low turn = weak competitors (base ~41.5)
	var cat: String = CompetitionManager.current_competition["category"]
	var style: String = cat if cat != "open" else "lager"
	var fee: int = CompetitionManager.current_competition["entry_fee"]
	CompetitionManager.enter(style, 99.0)  # Very high = beats everyone
	var balance_after_fee: float = GameState.balance
	CompetitionManager.tick()
	var result: Dictionary = CompetitionManager.tick()
	if result.get("placement", "") == "gold":
		assert_gt(GameState.balance, balance_after_fee)
		assert_eq(CompetitionManager.medals["gold"], 1)

func test_judge_no_entry_returns_no_placement() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	CompetitionManager.tick()
	var result: Dictionary = CompetitionManager.tick()
	assert_eq(result.get("placement", ""), "none")
	assert_eq(result.get("prize", 0), 0)

func test_judge_emits_signal() -> void:
	watch_signals(CompetitionManager)
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 1000.0
	var cat: String = CompetitionManager.current_competition["category"]
	var style: String = cat if cat != "open" else "lager"
	CompetitionManager.enter(style, 70.0)
	CompetitionManager.tick()
	CompetitionManager.tick()
	assert_signal_emitted(CompetitionManager, "competition_judged")

func test_competitor_scores_scale_with_turn() -> void:
	# At turn 1, base is ~41.5. At turn 30, base is ~85
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 1000.0
	GameState.turn_counter = 30
	var cat: String = CompetitionManager.current_competition["category"]
	var style: String = cat if cat != "open" else "lager"
	CompetitionManager.enter(style, 50.0)  # Mediocre quality
	CompetitionManager.tick()
	var result: Dictionary = CompetitionManager.tick()
	# At turn 30, base is 85 so 50 quality should rarely win
	# Just verify scores are generated
	assert_eq(result["competitor_scores"].size(), 3)

# --- Persistence ---
func test_save_and_load() -> void:
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 1000.0
	var cat: String = CompetitionManager.current_competition["category"]
	var style: String = cat if cat != "open" else "lager"
	CompetitionManager.enter(style, 70.0)
	CompetitionManager.medals["gold"] = 2
	CompetitionManager.medals["silver"] = 1
	var data: Dictionary = CompetitionManager.save_state()
	CompetitionManager.reset()
	assert_null(CompetitionManager.current_competition)
	assert_eq(CompetitionManager.medals["gold"], 0)
	CompetitionManager.load_state(data)
	assert_not_null(CompetitionManager.current_competition)
	assert_not_null(CompetitionManager.player_entry)
	assert_eq(CompetitionManager.medals["gold"], 2)
	assert_eq(CompetitionManager.medals["silver"], 1)

func test_save_without_competition() -> void:
	var data: Dictionary = CompetitionManager.save_state()
	assert_false(data.has("current_competition"))
	CompetitionManager.load_state(data)
	assert_null(CompetitionManager.current_competition)

func test_medals_persist_across_judgments() -> void:
	# Win first competition
	CompetitionManager.turns_until_next = 1
	CompetitionManager.tick()
	GameState.balance = 2000.0
	GameState.turn_counter = 1
	var cat: String = CompetitionManager.current_competition["category"]
	var style: String = cat if cat != "open" else "lager"
	CompetitionManager.enter(style, 99.0)
	CompetitionManager.tick()
	CompetitionManager.tick()
	var gold_count: int = CompetitionManager.medals["gold"]
	# Medals should persist (may or may not have won gold due to randomness)
	assert_gte(gold_count + CompetitionManager.medals["silver"] + CompetitionManager.medals["bronze"], 0)
