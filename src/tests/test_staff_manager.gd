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
