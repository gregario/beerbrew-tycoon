extends Control

## ResultsOverlay — post-brew results: quality score, breakdown, revenue, balance.
## Revenue has already been added to balance by BrewingPhases before this screen shows.

const STAR_FILLED := preload("res://assets/ui/kenney/Green/Default/star.png")
const STAR_EMPTY := preload("res://assets/ui/kenney/Green/Default/star_outline_depth.png")

@onready var style_label: Label = $CardPanel/MarginContainer/VBox/StyleLabel
@onready var recipe_label: Label = $CardPanel/MarginContainer/VBox/RecipeLabel
@onready var score_label: Label = $CardPanel/MarginContainer/VBox/ScorePanel/ScoreVBox/ScoreLabel
@onready var stars_row: HBoxContainer = $CardPanel/MarginContainer/VBox/ScorePanel/ScoreVBox/StarsRow
@onready var ratio_label: Label = $CardPanel/MarginContainer/VBox/BreakdownGrid/RatioLabel
@onready var ingredients_label: Label = $CardPanel/MarginContainer/VBox/BreakdownGrid/IngredientsLabel
@onready var novelty_label: Label = $CardPanel/MarginContainer/VBox/BreakdownGrid/NoveltyLabel
@onready var effort_label: Label = $CardPanel/MarginContainer/VBox/BreakdownGrid/EffortLabel
@onready var revenue_label: Label = $CardPanel/MarginContainer/VBox/MoneyRow/RevenueLabel
@onready var balance_label: Label = $CardPanel/MarginContainer/VBox/MoneyRow/BalanceLabel
@onready var rent_label: Label = $CardPanel/MarginContainer/VBox/RentLabel
@onready var continue_button: Button = $CardPanel/MarginContainer/VBox/FooterRow/ContinueButton

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	rent_label.visible = false

## Populate with the current brew result. Call this when the overlay becomes visible.
func populate() -> void:
	var result := GameState.last_brew_result
	var style := GameState.current_style
	var recipe := GameState.current_recipe

	# Style and recipe identity
	style_label.text = "Style: %s" % (style.style_name if style else "—")
	var malt  := recipe.get("malt",  null) as Ingredient
	var hop   := recipe.get("hop",   null) as Ingredient
	var yeast := recipe.get("yeast", null) as Ingredient
	recipe_label.text = "Recipe: %s / %s / %s" % [
		malt.ingredient_name  if malt  else "—",
		hop.ingredient_name   if hop   else "—",
		yeast.ingredient_name if yeast else "—",
	]

	# Quality score and breakdown
	var final_score: float = result.get("final_score", 0.0)
	score_label.text = "Quality: %.1f / 100" % final_score
	_update_stars(final_score)
	ratio_label.text = "Ratio: %.0f" % result.get("ratio_score", 0.0)
	ingredients_label.text = "Ingredients: %.0f" % result.get("ingredient_score", 0.0)
	novelty_label.text = "Novelty: %.0f" % result.get("novelty_score", 0.0)
	effort_label.text = "Effort: %.0f" % result.get("base_score", 0.0)

	# Revenue and current balance (revenue already in balance from BrewingPhases)
	var revenue: float = result.get("revenue", 0.0)
	revenue_label.text = "Revenue: +$%.0f" % revenue
	balance_label.text = "Balance: $%.0f" % GameState.balance

	# Rent warning: will rent be deducted when the player clicks Continue?
	var next_turn := GameState.turn_counter + 1
	var rent_upcoming := next_turn > 0 and next_turn % GameState.RENT_INTERVAL == 0
	rent_label.visible = rent_upcoming
	if rent_upcoming:
		rent_label.text = "Rent due: -$%.0f (charged when you continue)" % GameState.RENT_AMOUNT

func _update_stars(score: float) -> void:
	for child in stars_row.get_children():
		child.queue_free()
	var filled_count: int = int(round(score / 20.0))
	for i in range(5):
		var star := TextureRect.new()
		star.texture = STAR_FILLED if i < filled_count else STAR_EMPTY
		star.custom_minimum_size = Vector2(28, 28)
		star.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		stars_row.add_child(star)

func _on_continue_pressed() -> void:
	GameState.advance_state()
