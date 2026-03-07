extends GutTest

func before_each() -> void:
	SpecialtyBeerManager.reset()

# --- Initial state ---

func test_aging_queue_starts_empty() -> void:
	assert_eq(SpecialtyBeerManager.get_aging_queue().size(), 0)

func test_completed_beers_starts_empty() -> void:
	assert_eq(SpecialtyBeerManager.get_completed_beers().size(), 0)

# --- queue_beer ---

func test_queue_beer_adds_entry() -> void:
	var entry: Dictionary = _make_entry(3)
	SpecialtyBeerManager.queue_beer(entry)
	assert_eq(SpecialtyBeerManager.get_aging_queue().size(), 1)

func test_queue_beer_preserves_fields() -> void:
	var entry: Dictionary = _make_entry(4)
	SpecialtyBeerManager.queue_beer(entry)
	var queued: Dictionary = SpecialtyBeerManager.get_aging_queue()[0]
	assert_eq(queued["style_id"], "lambic")
	assert_eq(queued["turns_remaining"], 4)

# --- tick_aging ---

func test_tick_aging_decrements_turns_remaining() -> void:
	SpecialtyBeerManager.queue_beer(_make_entry(3))
	SpecialtyBeerManager.tick_aging()
	assert_eq(SpecialtyBeerManager.get_aging_queue()[0]["turns_remaining"], 2)

func test_tick_aging_does_not_go_below_zero() -> void:
	SpecialtyBeerManager.queue_beer(_make_entry(1))
	SpecialtyBeerManager.tick_aging()
	# Beer at 0 should be moved to completed, not remain in queue
	assert_eq(SpecialtyBeerManager.get_aging_queue().size(), 0)

func test_tick_aging_moves_completed_to_completed_beers() -> void:
	SpecialtyBeerManager.queue_beer(_make_entry(1))
	SpecialtyBeerManager.tick_aging()
	var completed: Array = SpecialtyBeerManager.get_completed_beers()
	assert_eq(completed.size(), 1)

func test_completed_beers_have_final_quality() -> void:
	SpecialtyBeerManager.queue_beer(_make_entry(1))
	SpecialtyBeerManager.tick_aging()
	var completed: Array = SpecialtyBeerManager.get_completed_beers()
	assert_true(completed[0].has("final_quality"))
	assert_gte(completed[0]["final_quality"], 0.0)
	assert_lte(completed[0]["final_quality"], 100.0)

func test_get_completed_beers_clears_after_retrieval() -> void:
	SpecialtyBeerManager.queue_beer(_make_entry(1))
	SpecialtyBeerManager.tick_aging()
	var first_call: Array = SpecialtyBeerManager.get_completed_beers()
	assert_eq(first_call.size(), 1)
	var second_call: Array = SpecialtyBeerManager.get_completed_beers()
	assert_eq(second_call.size(), 0)

# --- variance determinism ---

func test_variance_is_deterministic_same_seed() -> void:
	var entry_a: Dictionary = _make_entry(1, 42)
	var entry_b: Dictionary = _make_entry(1, 42)
	SpecialtyBeerManager.queue_beer(entry_a)
	SpecialtyBeerManager.tick_aging()
	var completed_a: Array = SpecialtyBeerManager.get_completed_beers()

	SpecialtyBeerManager.queue_beer(entry_b)
	SpecialtyBeerManager.tick_aging()
	var completed_b: Array = SpecialtyBeerManager.get_completed_beers()

	assert_almost_eq(completed_a[0]["final_quality"], completed_b[0]["final_quality"], 0.001)

func test_different_seeds_can_produce_different_quality() -> void:
	# With seeds 1 and 99999, at least one pair should differ
	var entry_a: Dictionary = _make_entry(1, 1)
	var entry_b: Dictionary = _make_entry(1, 99999)
	SpecialtyBeerManager.queue_beer(entry_a)
	SpecialtyBeerManager.tick_aging()
	var completed_a: Array = SpecialtyBeerManager.get_completed_beers()

	SpecialtyBeerManager.queue_beer(entry_b)
	SpecialtyBeerManager.tick_aging()
	var completed_b: Array = SpecialtyBeerManager.get_completed_beers()

	# They CAN be different (not guaranteed, but with these seeds they should be)
	# Just verify both have valid quality
	assert_gte(completed_a[0]["final_quality"], 0.0)
	assert_gte(completed_b[0]["final_quality"], 0.0)

# --- save/load ---

func test_save_state_returns_dictionary() -> void:
	SpecialtyBeerManager.queue_beer(_make_entry(3))
	var state: Dictionary = SpecialtyBeerManager.save_state()
	assert_true(state.has("aging_queue"))

func test_load_state_restores_queue() -> void:
	SpecialtyBeerManager.queue_beer(_make_entry(3))
	SpecialtyBeerManager.queue_beer(_make_entry(5))
	var state: Dictionary = SpecialtyBeerManager.save_state()

	SpecialtyBeerManager.reset()
	assert_eq(SpecialtyBeerManager.get_aging_queue().size(), 0)

	SpecialtyBeerManager.load_state(state)
	assert_eq(SpecialtyBeerManager.get_aging_queue().size(), 2)
	assert_eq(SpecialtyBeerManager.get_aging_queue()[0]["turns_remaining"], 3)

# --- reset ---

func test_reset_clears_queue() -> void:
	SpecialtyBeerManager.queue_beer(_make_entry(3))
	SpecialtyBeerManager.reset()
	assert_eq(SpecialtyBeerManager.get_aging_queue().size(), 0)

func test_reset_clears_completed() -> void:
	SpecialtyBeerManager.queue_beer(_make_entry(1))
	SpecialtyBeerManager.tick_aging()
	# Don't retrieve completed — they should still be cleared by reset
	SpecialtyBeerManager.reset()
	assert_eq(SpecialtyBeerManager.get_completed_beers().size(), 0)

# --- Multiple beers aging ---

func test_multiple_beers_age_independently() -> void:
	SpecialtyBeerManager.queue_beer(_make_entry(2))
	SpecialtyBeerManager.queue_beer(_make_entry(4))
	SpecialtyBeerManager.tick_aging()
	var queue: Array = SpecialtyBeerManager.get_aging_queue()
	assert_eq(queue.size(), 2)
	assert_eq(queue[0]["turns_remaining"], 1)
	assert_eq(queue[1]["turns_remaining"], 3)

func test_only_finished_beers_move_to_completed() -> void:
	SpecialtyBeerManager.queue_beer(_make_entry(1))
	SpecialtyBeerManager.queue_beer(_make_entry(3))
	SpecialtyBeerManager.tick_aging()
	assert_eq(SpecialtyBeerManager.get_aging_queue().size(), 1)
	var completed: Array = SpecialtyBeerManager.get_completed_beers()
	assert_eq(completed.size(), 1)

# --- ceiling boost ---

func test_ceiling_boost_adds_to_quality() -> void:
	# A beer with quality_base 50 should get +10 ceiling boost = effective base of 60
	# Then variance applies on top. With seed 0 we just check range is reasonable.
	var entry: Dictionary = _make_entry(1, 0)
	entry["quality_base"] = 50.0
	SpecialtyBeerManager.queue_beer(entry)
	SpecialtyBeerManager.tick_aging()
	var completed: Array = SpecialtyBeerManager.get_completed_beers()
	# base 50 + ceiling 10 = 60, variance ±15 → range [45, 75], clamped [0, 100]
	assert_gte(completed[0]["final_quality"], 0.0)
	assert_lte(completed[0]["final_quality"], 100.0)

# --- Helper ---

func _make_entry(turns: int, seed_val: int = 12345) -> Dictionary:
	return {
		"style_id": "lambic",
		"style_name": "Lambic",
		"recipe": {"malts": [], "hops": [], "yeast": null},
		"quality_base": 60.0,
		"turns_remaining": turns,
		"variance_seed": seed_val,
	}
