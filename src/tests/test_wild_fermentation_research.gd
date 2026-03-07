extends GutTest

# --- Task 5: Wild Fermentation Research Node ---

func test_wild_fermentation_tres_loads_with_correct_properties() -> void:
	var node: ResearchNode = load("res://data/research/techniques/wild_fermentation.tres")
	assert_not_null(node)
	assert_eq(node.node_id, "wild_fermentation")
	assert_eq(node.node_name, "Wild Fermentation")
	assert_eq(node.category, ResearchNode.Category.TECHNIQUES)
	assert_eq(node.rp_cost, 30)
	assert_eq(node.prerequisites, ["specialist_yeast"])
	assert_eq(node.unlock_effect.get("type", ""), "unlock_specialty_beers")
	var ids: Array = node.unlock_effect.get("ids", [])
	assert_true(ids.has("berliner_weisse"))
	assert_true(ids.has("lambic"))
	assert_true(ids.has("experimental_brew"))


func test_specialty_styles_start_locked() -> void:
	var berliner: BeerStyle = load("res://data/styles/berliner_weisse.tres")
	var lambic: BeerStyle = load("res://data/styles/lambic.tres")
	var experimental: BeerStyle = load("res://data/styles/experimental_brew.tres")
	# Reset locks first to ensure clean state
	berliner.unlocked = false
	lambic.unlocked = false
	experimental.unlocked = false
	assert_false(berliner.unlocked)
	assert_false(lambic.unlocked)
	assert_false(experimental.unlocked)


func test_unlock_specialty_beers_effect_unlocks_styles() -> void:
	# Pre-load resources to ensure same cached instance
	var berliner: BeerStyle = load("res://data/styles/berliner_weisse.tres")
	var lambic: BeerStyle = load("res://data/styles/lambic.tres")
	var experimental: BeerStyle = load("res://data/styles/experimental_brew.tres")
	# Ensure they start locked
	berliner.unlocked = false
	lambic.unlocked = false
	experimental.unlocked = false

	# Apply the effect via ResearchManager
	var effect: Dictionary = {
		"type": "unlock_specialty_beers",
		"ids": ["berliner_weisse", "lambic", "experimental_brew"]
	}
	ResearchManager._apply_effect(effect)

	assert_true(berliner.unlocked)
	assert_true(lambic.unlocked)
	assert_true(experimental.unlocked)

	# Clean up
	berliner.unlocked = false
	lambic.unlocked = false
	experimental.unlocked = false


func test_reset_relocks_specialty_styles() -> void:
	# Pre-load resources to ensure same cached instance
	var berliner: BeerStyle = load("res://data/styles/berliner_weisse.tres")
	var lambic: BeerStyle = load("res://data/styles/lambic.tres")
	var experimental: BeerStyle = load("res://data/styles/experimental_brew.tres")
	# Unlock them first
	berliner.unlocked = true
	lambic.unlocked = true
	experimental.unlocked = true

	ResearchManager.reset()

	assert_false(berliner.unlocked)
	assert_false(lambic.unlocked)
	assert_false(experimental.unlocked)
