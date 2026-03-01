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

# --- .tres load tests ---

const RESEARCH_PATHS: Array[String] = [
	"res://data/research/techniques/mash_basics.tres",
	"res://data/research/techniques/advanced_mashing.tres",
	"res://data/research/techniques/decoction_technique.tres",
	"res://data/research/techniques/hop_timing.tres",
	"res://data/research/techniques/dry_hopping.tres",
	"res://data/research/techniques/water_chemistry.tres",
	"res://data/research/ingredients/specialty_malts.tres",
	"res://data/research/ingredients/american_hops.tres",
	"res://data/research/ingredients/premium_hops.tres",
	"res://data/research/ingredients/specialist_yeast.tres",
	"res://data/research/equipment/homebrew_upgrades.tres",
	"res://data/research/equipment/semi_pro_equipment.tres",
	"res://data/research/equipment/pro_equipment.tres",
	"res://data/research/equipment/adjunct_brewing.tres",
	"res://data/research/styles/ale_fundamentals.tres",
	"res://data/research/styles/lager_brewing.tres",
	"res://data/research/styles/wheat_traditions.tres",
	"res://data/research/styles/dark_styles.tres",
	"res://data/research/styles/ipa_mastery.tres",
	"res://data/research/styles/belgian_arts.tres",
]

func test_all_tres_files_load():
	for path in RESEARCH_PATHS:
		var res := load(path)
		assert_not_null(res, "Failed to load: %s" % path)
		assert_true(res is ResearchNode, "Not a ResearchNode: %s" % path)

func test_total_node_count():
	assert_eq(RESEARCH_PATHS.size(), 20)

func test_root_nodes_have_zero_cost():
	var root_ids := ["mash_basics", "hop_timing", "homebrew_upgrades", "ale_fundamentals"]
	for path in RESEARCH_PATHS:
		var node := load(path) as ResearchNode
		if node.node_id in root_ids:
			assert_eq(node.rp_cost, 0, "%s should be free" % node.node_id)
			assert_eq(node.prerequisites.size(), 0, "%s should have no prereqs" % node.node_id)
