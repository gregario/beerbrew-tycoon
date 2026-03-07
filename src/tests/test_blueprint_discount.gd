extends GutTest

func before_each() -> void:
	if is_instance_valid(ResearchManager):
		ResearchManager.reset()
	if is_instance_valid(MetaProgressionManager):
		MetaProgressionManager.reset_meta()


func test_default_research_cost_no_discount() -> void:
	var cost: int = ResearchManager._get_effective_rp_cost("semi_pro_equipment")
	assert_eq(cost, 20)


func test_blueprint_discount_halves_cost() -> void:
	MetaProgressionManager.add_points(10)
	MetaProgressionManager.unlock_blueprint("mash_tun", 5)
	var cost: int = ResearchManager._get_effective_rp_cost("semi_pro_equipment")
	assert_eq(cost, 10)


func test_no_discount_for_unrelated_node() -> void:
	MetaProgressionManager.add_points(10)
	MetaProgressionManager.unlock_blueprint("mash_tun", 5)
	var cost: int = ResearchManager._get_effective_rp_cost("advanced_mashing")
	assert_eq(cost, 15)


func test_pro_equipment_discount() -> void:
	MetaProgressionManager.add_points(10)
	MetaProgressionManager.unlock_blueprint("three_vessel", 5)
	var cost: int = ResearchManager._get_effective_rp_cost("pro_equipment")
	assert_eq(cost, 17)  # 35 * 0.5 = 17 (int truncation)


func test_can_unlock_uses_discounted_cost() -> void:
	MetaProgressionManager.add_points(10)
	MetaProgressionManager.unlock_blueprint("mash_tun", 5)
	# semi_pro_equipment requires homebrew_upgrades prerequisite
	ResearchManager.add_rp(10)
	ResearchManager.unlocked_nodes.append("homebrew_upgrades")
	assert_true(ResearchManager.can_unlock("semi_pro_equipment"))


func test_unlock_deducts_discounted_cost() -> void:
	MetaProgressionManager.add_points(10)
	MetaProgressionManager.unlock_blueprint("mash_tun", 5)
	ResearchManager.add_rp(10)
	ResearchManager.unlocked_nodes.append("homebrew_upgrades")
	var result: bool = ResearchManager.unlock("semi_pro_equipment")
	assert_true(result)
	assert_eq(ResearchManager.research_points, 0)  # 10 - 10 = 0
