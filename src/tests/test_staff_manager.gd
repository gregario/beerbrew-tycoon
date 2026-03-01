extends GutTest

func test_staff_resource_has_all_properties() -> void:
	var s := Staff.new()
	assert_eq(s.staff_id, "")
	assert_eq(s.staff_name, "")
	assert_eq(s.creativity, 50)
	assert_eq(s.precision, 50)
	assert_eq(s.experience_points, 0)
	assert_eq(s.level, 1)
	assert_eq(s.salary_per_turn, 60)
	assert_eq(s.assigned_phase, "")
	assert_eq(s.specialization, "none")
	assert_eq(s.is_training, false)
	assert_eq(s.training_turns_remaining, 0)

func before_each() -> void:
	GameState.reset()
	StaffManager.reset()

# --- Candidate generation ---
func test_generate_candidates_creates_correct_count() -> void:
	StaffManager.generate_candidates(3)
	assert_eq(StaffManager.candidates.size(), 3)

func test_candidates_have_valid_stats() -> void:
	StaffManager.generate_candidates(2)
	for c in StaffManager.candidates:
		assert_gte(c.get("creativity", 0), 25)
		assert_lte(c.get("creativity", 0), 75)
		assert_gte(c.get("precision", 0), 25)
		assert_lte(c.get("precision", 0), 75)

func test_candidate_salary_scales_with_stats() -> void:
	StaffManager.generate_candidates(2)
	for c in StaffManager.candidates:
		var expected_salary: int = 40 + (c.get("creativity", 0) + c.get("precision", 0)) / 4
		assert_eq(c.get("salary_per_turn", 0), expected_salary)

# --- Hiring ---
func test_hire_adds_to_roster() -> void:
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	assert_eq(StaffManager.staff_roster.size(), 1)

func test_hire_removes_from_candidates() -> void:
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	assert_eq(StaffManager.candidates.size(), 1)

func test_hire_emits_signal() -> void:
	StaffManager.generate_candidates(2)
	watch_signals(StaffManager)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	assert_signal_emitted(StaffManager, "staff_hired")

# --- Firing ---
func test_fire_removes_from_roster() -> void:
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	StaffManager.fire(cid)
	assert_eq(StaffManager.staff_roster.size(), 0)

func test_fire_clears_phase_assignment() -> void:
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	StaffManager.assign_to_phase(cid, "mashing")
	StaffManager.fire(cid)
	var assigned: Dictionary = StaffManager.get_staff_assigned_to("mashing")
	assert_true(assigned.is_empty())

func test_fire_emits_signal() -> void:
	StaffManager.generate_candidates(2)
	watch_signals(StaffManager)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	StaffManager.fire(cid)
	assert_signal_emitted(StaffManager, "staff_fired")

# --- Phase assignment ---
func test_assign_to_phase() -> void:
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	StaffManager.assign_to_phase(cid, "mashing")
	var assigned: Dictionary = StaffManager.get_staff_assigned_to("mashing")
	assert_eq(assigned.get("staff_id", ""), cid)

func test_assign_swaps_existing() -> void:
	StaffManager.generate_candidates(3)
	var c1: String = StaffManager.candidates[0].get("staff_id", "")
	var c2: String = StaffManager.candidates[1].get("staff_id", "")
	StaffManager.hire(c1)
	StaffManager.hire(c2)
	StaffManager.assign_to_phase(c1, "mashing")
	StaffManager.assign_to_phase(c2, "mashing")
	var assigned: Dictionary = StaffManager.get_staff_assigned_to("mashing")
	assert_eq(assigned.get("staff_id", ""), c2)
	for s in StaffManager.staff_roster:
		if s.get("staff_id", "") == c1:
			assert_eq(s.get("assigned_phase", ""), "")

func test_unassign_with_empty_string() -> void:
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	StaffManager.assign_to_phase(cid, "mashing")
	StaffManager.assign_to_phase(cid, "")
	var assigned: Dictionary = StaffManager.get_staff_assigned_to("mashing")
	assert_true(assigned.is_empty())

# --- Bonus calculation ---
func test_phase_bonus_unassigned_is_zero() -> void:
	var bonus: Dictionary = StaffManager.get_phase_bonus("mashing")
	assert_eq(bonus.get("flavor", -1.0), 0.0)
	assert_eq(bonus.get("technique", -1.0), 0.0)

func test_phase_bonus_scales_with_creativity() -> void:
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	StaffManager.staff_roster[0]["creativity"] = 60
	StaffManager.staff_roster[0]["precision"] = 0
	StaffManager.staff_roster[0]["level"] = 1
	StaffManager.assign_to_phase(cid, "mashing")
	var bonus: Dictionary = StaffManager.get_phase_bonus("mashing")
	assert_almost_eq(bonus.get("flavor", 0.0), 6.0, 0.01)

func test_phase_bonus_scales_with_precision() -> void:
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	StaffManager.staff_roster[0]["creativity"] = 0
	StaffManager.staff_roster[0]["precision"] = 80
	StaffManager.staff_roster[0]["level"] = 1
	StaffManager.assign_to_phase(cid, "boiling")
	var bonus: Dictionary = StaffManager.get_phase_bonus("boiling")
	assert_almost_eq(bonus.get("technique", 0.0), 8.0, 0.01)

func test_specialization_doubles_bonus_in_own_phase() -> void:
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	StaffManager.staff_roster[0]["creativity"] = 50
	StaffManager.staff_roster[0]["precision"] = 50
	StaffManager.staff_roster[0]["level"] = 5
	StaffManager.staff_roster[0]["specialization"] = "mashing"
	StaffManager.assign_to_phase(cid, "mashing")
	var bonus: Dictionary = StaffManager.get_phase_bonus("mashing")
	# creativity(50) * level_mult(1.4) * spec_mult(2.0) / 10 = 14.0
	assert_almost_eq(bonus.get("flavor", 0.0), 14.0, 0.01)

func test_specialization_halves_bonus_in_other_phases() -> void:
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	StaffManager.staff_roster[0]["creativity"] = 50
	StaffManager.staff_roster[0]["precision"] = 50
	StaffManager.staff_roster[0]["level"] = 5
	StaffManager.staff_roster[0]["specialization"] = "mashing"
	StaffManager.assign_to_phase(cid, "boiling")
	var bonus: Dictionary = StaffManager.get_phase_bonus("boiling")
	# creativity(50) * level_mult(1.4) * spec_mult(0.5) / 10 = 3.5
	assert_almost_eq(bonus.get("flavor", 0.0), 3.5, 0.01)

# --- XP and leveling ---
func test_award_xp_accumulates() -> void:
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	StaffManager.assign_to_phase(cid, "mashing")
	StaffManager.award_xp("mashing", 30)
	assert_eq(StaffManager.staff_roster[0].get("experience_points", 0), 30)

func test_level_up_on_threshold() -> void:
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	StaffManager.assign_to_phase(cid, "mashing")
	StaffManager.award_xp("mashing", 100)
	assert_eq(StaffManager.staff_roster[0].get("level", 1), 2)

func test_level_up_increases_stats() -> void:
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	var old_c: int = StaffManager.staff_roster[0].get("creativity", 0)
	var old_p: int = StaffManager.staff_roster[0].get("precision", 0)
	StaffManager.assign_to_phase(cid, "mashing")
	StaffManager.award_xp("mashing", 100)
	assert_gt(StaffManager.staff_roster[0].get("creativity", 0), old_c)
	assert_gt(StaffManager.staff_roster[0].get("precision", 0), old_p)

func test_level_up_emits_signal() -> void:
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	StaffManager.assign_to_phase(cid, "mashing")
	watch_signals(StaffManager)
	StaffManager.award_xp("mashing", 100)
	assert_signal_emitted(StaffManager, "staff_leveled_up")

func test_no_level_up_below_threshold() -> void:
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	StaffManager.assign_to_phase(cid, "mashing")
	StaffManager.award_xp("mashing", 50)
	assert_eq(StaffManager.staff_roster[0].get("level", 1), 1)

# --- Training ---
func test_training_deducts_balance() -> void:
	GameState.balance = 500.0
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	StaffManager.start_training(cid, "creativity")
	assert_almost_eq(GameState.balance, 300.0, 0.01)

func test_training_marks_staff_unavailable() -> void:
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	StaffManager.start_training(cid, "creativity")
	assert_true(StaffManager.staff_roster[0].get("is_training", false))

func test_training_fails_insufficient_balance() -> void:
	GameState.balance = 100.0
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	var result: bool = StaffManager.start_training(cid, "creativity")
	assert_false(result)

func test_training_completes_after_one_turn() -> void:
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	StaffManager.start_training(cid, "creativity")
	StaffManager.tick_training()
	assert_false(StaffManager.staff_roster[0].get("is_training", false))

func test_training_boosts_stat() -> void:
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	var old_c: int = StaffManager.staff_roster[0].get("creativity", 0)
	StaffManager.start_training(cid, "creativity")
	StaffManager.tick_training()
	assert_gt(StaffManager.staff_roster[0].get("creativity", 0), old_c)

# --- Specialization ---
func test_specialization_requires_level_5() -> void:
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	StaffManager.staff_roster[0]["level"] = 4
	var result: bool = StaffManager.specialize(cid, "mashing")
	assert_false(result)

func test_specialization_sets_field() -> void:
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	StaffManager.staff_roster[0]["level"] = 5
	StaffManager.specialize(cid, "mashing")
	assert_eq(StaffManager.staff_roster[0].get("specialization", "none"), "mashing")

func test_specialization_cannot_change_once_set() -> void:
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	StaffManager.staff_roster[0]["level"] = 5
	StaffManager.specialize(cid, "mashing")
	var result: bool = StaffManager.specialize(cid, "boiling")
	assert_false(result)

# --- Salary ---
func test_salary_deduction() -> void:
	GameState.balance = 1000.0
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	StaffManager.staff_roster[0]["salary_per_turn"] = 80
	var deducted: float = StaffManager.deduct_salaries()
	assert_almost_eq(deducted, 80.0, 0.01)
	assert_almost_eq(GameState.balance, 920.0, 0.01)

func test_salary_deduction_two_staff() -> void:
	GameState.balance = 1000.0
	StaffManager.generate_candidates(3)
	var c1: String = StaffManager.candidates[0].get("staff_id", "")
	var c2: String = StaffManager.candidates[1].get("staff_id", "")
	StaffManager.hire(c1)
	StaffManager.hire(c2)
	StaffManager.staff_roster[0]["salary_per_turn"] = 80
	StaffManager.staff_roster[1]["salary_per_turn"] = 60
	var deducted: float = StaffManager.deduct_salaries()
	assert_almost_eq(deducted, 140.0, 0.01)

# --- Save/load ---
func test_save_and_load_state() -> void:
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	StaffManager.assign_to_phase(cid, "mashing")
	var saved: Dictionary = StaffManager.save_state()
	StaffManager.reset()
	assert_eq(StaffManager.staff_roster.size(), 0)
	StaffManager.load_state(saved)
	assert_eq(StaffManager.staff_roster.size(), 1)
	assert_eq(StaffManager.staff_roster[0].get("assigned_phase", ""), "mashing")

# --- Reset ---
func test_reset_clears_roster() -> void:
	StaffManager.generate_candidates(2)
	var cid: String = StaffManager.candidates[0].get("staff_id", "")
	StaffManager.hire(cid)
	StaffManager.reset()
	assert_eq(StaffManager.staff_roster.size(), 0)

func test_reset_regenerates_candidates() -> void:
	StaffManager.reset()
	assert_gte(StaffManager.candidates.size(), 2)
