extends GutTest

func test_resource_loads_with_correct_fields():
	var node := ResearchNode.new()
	node.node_id = "test_node"
	node.node_name = "Test Node"
	node.description = "A test research node"
	node.category = ResearchNode.Category.TECHNIQUES
	node.rp_cost = 15
	node.prerequisites = ["prereq_1"]
	node.unlock_effect = {"type": "brewing_bonus", "bonuses": {"mash_score_bonus": 0.05}}

	assert_eq(node.node_id, "test_node")
	assert_eq(node.node_name, "Test Node")
	assert_eq(node.category, ResearchNode.Category.TECHNIQUES)
	assert_eq(node.rp_cost, 15)
	assert_eq(node.prerequisites.size(), 1)
	assert_eq(node.prerequisites[0], "prereq_1")
	assert_eq(node.unlock_effect["type"], "brewing_bonus")

func test_default_values():
	var node := ResearchNode.new()
	assert_eq(node.node_id, "")
	assert_eq(node.rp_cost, 0)
	assert_eq(node.prerequisites.size(), 0)
	assert_true(node.unlock_effect.is_empty())
