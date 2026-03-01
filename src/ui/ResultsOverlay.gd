extends Control

## ResultsOverlay — post-brew results: quality score, breakdown, revenue, balance.
## Revenue has already been added to balance by BrewingPhases before this screen shows.

const STAR_FILLED := preload("res://assets/ui/kenney/Green/Default/star.png")
const STAR_EMPTY := preload("res://assets/ui/kenney/Green/Default/star_outline_depth.png")

@onready var style_label: Label = $CardPanel/MarginContainer/OuterVBox/Scroll/VBox/StyleLabel
@onready var recipe_label: Label = $CardPanel/MarginContainer/OuterVBox/Scroll/VBox/RecipeLabel
@onready var score_label: Label = $CardPanel/MarginContainer/OuterVBox/Scroll/VBox/ScorePanel/ScoreVBox/ScoreLabel
@onready var stars_row: HBoxContainer = $CardPanel/MarginContainer/OuterVBox/Scroll/VBox/ScorePanel/ScoreVBox/StarsRow
@onready var ratio_label: Label = $CardPanel/MarginContainer/OuterVBox/Scroll/VBox/BreakdownGrid/RatioLabel
@onready var ingredients_label: Label = $CardPanel/MarginContainer/OuterVBox/Scroll/VBox/BreakdownGrid/IngredientsLabel
@onready var novelty_label: Label = $CardPanel/MarginContainer/OuterVBox/Scroll/VBox/BreakdownGrid/NoveltyLabel
@onready var effort_label: Label = $CardPanel/MarginContainer/OuterVBox/Scroll/VBox/BreakdownGrid/EffortLabel
@onready var science_label: Label = $CardPanel/MarginContainer/OuterVBox/Scroll/VBox/BreakdownGrid/ScienceLabel
@onready var tasting_notes: RichTextLabel = $CardPanel/MarginContainer/OuterVBox/Scroll/VBox/TastingNotes
@onready var palate_label: Label = $CardPanel/MarginContainer/OuterVBox/Scroll/VBox/PalateLabel
@onready var revenue_label: Label = $CardPanel/MarginContainer/OuterVBox/MoneyRow/RevenueLabel
@onready var balance_label: Label = $CardPanel/MarginContainer/OuterVBox/MoneyRow/BalanceLabel
@onready var rp_label: Label = $CardPanel/MarginContainer/OuterVBox/RPLabel
@onready var rent_label: Label = $CardPanel/MarginContainer/OuterVBox/RentLabel
@onready var continue_button: Button = $CardPanel/MarginContainer/OuterVBox/FooterRow/ContinueButton

var failure_container: VBoxContainer = null

func _ready() -> void:
	continue_button.pressed.connect(_on_continue_pressed)
	rent_label.visible = false

## Populate with the current brew result. Call this when the overlay becomes visible.
func populate() -> void:
	var result := GameState.last_brew_result
	var style := GameState.current_style
	var recipe := GameState.current_recipe

	# Style and recipe identity (Stage 1A: multi-ingredient)
	style_label.text = "Style: %s" % (style.style_name if style else "—")
	var malts: Array = recipe.get("malts", [])
	var hops: Array = recipe.get("hops", [])
	var yeast_ingredient = recipe.get("yeast", null)
	var malt_names: String = ", ".join(malts.map(func(m): return m.ingredient_name)) if malts.size() > 0 else "—"
	var hop_names: String = ", ".join(hops.map(func(h): return h.ingredient_name)) if hops.size() > 0 else "—"
	var yeast_name: String = yeast_ingredient.ingredient_name if yeast_ingredient else "—"
	recipe_label.text = "Recipe: %s / %s / %s" % [malt_names, hop_names, yeast_name]

	# Quality score and breakdown
	var final_score: float = result.get("final_score", 0.0)
	score_label.text = "Quality: %.1f / 100" % final_score
	_update_stars(final_score)
	ratio_label.text = "Ratio: %.0f" % result.get("ratio_score", 0.0)
	ingredients_label.text = "Ingredients: %.0f" % result.get("ingredient_score", 0.0)
	novelty_label.text = "Novelty: %.0f" % result.get("novelty_score", 0.0)
	effort_label.text = "Effort: %.0f" % result.get("base_score", 0.0)
	science_label.text = "Science: %.0f" % result.get("science_score", 0.0)

	# Failure panels (Stage 1C)
	_clear_failure_panels()
	var infected: bool = result.get("infected", false)
	var off_flavor_tags: Array = result.get("off_flavor_tags", [])

	if infected or off_flavor_tags.size() > 0:
		_create_failure_container()

	if infected:
		var infection_msg: String = result.get("infection_message", "Bacteria contaminated your batch.")
		_add_failure_panel("INFECTION DETECTED", infection_msg,
			"Upgrade your sanitation equipment to reduce infection risk.")

	if off_flavor_tags.size() > 0:
		var off_flavor_msg: String = result.get("off_flavor_message", "Off-flavors detected.")
		var tip: String = "Better temperature control during fermentation helps avoid off-flavors."
		if off_flavor_tags.has("dms"):
			tip = "A longer, more vigorous boil drives off DMS precursors."
		_add_failure_panel("OFF-FLAVORS DETECTED", off_flavor_msg, tip)

	# Revenue and current balance (revenue already in balance from BrewingPhases)
	var revenue: float = result.get("revenue", 0.0)
	revenue_label.text = "Revenue: +$%.0f" % revenue
	balance_label.text = "Balance: $%.0f" % GameState.balance

	# Research points earned
	var rp_earned: int = result.get("rp_earned", 0)
	rp_label.text = "+%d Research Points" % rp_earned

	# Rent warning: will rent be deducted when the player clicks Continue?
	var next_turn := GameState.turn_counter + 1
	var rent_upcoming := next_turn > 0 and next_turn % GameState.RENT_INTERVAL == 0
	rent_label.visible = rent_upcoming
	if rent_upcoming:
		rent_label.text = "Rent due: -$%.0f (charged when you continue)" % GameState.RENT_AMOUNT

	# Tasting notes
	var notes: String = result.get("tasting_notes", "")
	tasting_notes.text = "[i]%s[/i]" % notes if notes != "" else ""

	# Palate level
	palate_label.text = "Your palate: %s (Lv %d)" % [GameState.get_palate_name(), GameState.general_taste]

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

func _clear_failure_panels() -> void:
	if failure_container != null:
		failure_container.queue_free()
		failure_container = null


func _create_failure_container() -> void:
	failure_container = VBoxContainer.new()
	failure_container.name = "FailureContainer"
	failure_container.add_theme_constant_override("separation", 8)
	var scroll_vbox: VBoxContainer = $CardPanel/MarginContainer/OuterVBox/Scroll/VBox
	var score_panel_idx: int = score_label.get_parent().get_parent().get_index()
	scroll_vbox.add_child(failure_container)
	scroll_vbox.move_child(failure_container, score_panel_idx + 1)


func _add_failure_panel(title_text: String, description: String, tip: String) -> void:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#FF7B7B", 0.1)
	style.border_color = Color("#FF7B7B", 0.4)
	style.border_width_left = 4
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	panel.add_theme_stylebox_override("panel", style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 20)
	title.add_theme_color_override("font_color", Color("#FF7B7B"))
	vbox.add_child(title)

	var desc := Label.new()
	desc.text = description
	desc.add_theme_font_size_override("font_size", 16)
	desc.add_theme_color_override("font_color", Color("#8A9BB1"))
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc)

	var tip_label := Label.new()
	tip_label.text = "Tip: %s" % tip
	tip_label.add_theme_font_size_override("font_size", 16)
	tip_label.add_theme_color_override("font_color", Color("#5AA9FF"))
	tip_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(tip_label)

	panel.add_child(vbox)
	failure_container.add_child(panel)


func _on_continue_pressed() -> void:
	GameState.advance_state()
