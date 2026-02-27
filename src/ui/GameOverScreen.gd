extends Control

## GameOverScreen — end-of-run screen for both win and loss states.

@onready var title_label: Label = $CardPanel/MarginContainer/VBox/TitleLabel
@onready var message_label: Label = $CardPanel/MarginContainer/VBox/MessageLabel
@onready var turns_value: Label = $CardPanel/MarginContainer/VBox/StatsGrid/TurnsValueLabel
@onready var quality_value: Label = $CardPanel/MarginContainer/VBox/StatsGrid/QualityValueLabel
@onready var revenue_value: Label = $CardPanel/MarginContainer/VBox/StatsGrid/RevenueValueLabel
@onready var balance_value: Label = $CardPanel/MarginContainer/VBox/StatsGrid/BalanceValueLabel
@onready var new_run_button: Button = $CardPanel/MarginContainer/VBox/Buttons/NewRunButton
@onready var quit_button: Button = $CardPanel/MarginContainer/VBox/Buttons/QuitButton

func _ready() -> void:
	new_run_button.pressed.connect(_on_new_run_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

## Populate with end-of-run data from GameState. Call when overlay becomes visible.
func populate() -> void:
	if GameState.run_won:
		title_label.text = "BREWERY SUCCESS!"
		title_label.add_theme_color_override("font_color", Color("#5EE8A4"))
		message_label.text = "You saved $%d and built a thriving garage brewery!\nTime to upgrade..." % GameState.balance
	else:
		title_label.text = "GAME OVER"
		title_label.add_theme_color_override("font_color", Color("#FF7B7B"))
		message_label.text = "Bankrupt. The bills piled up and you ran out of cash.\nBetter luck next run."

	turns_value.text = str(GameState.turn_counter)
	quality_value.text = str(GameState.best_quality)
	revenue_value.text = "$%d" % GameState.total_revenue
	balance_value.text = "$%d" % GameState.balance

func _on_new_run_pressed() -> void:
	GameState.reset()

func _on_quit_pressed() -> void:
	get_tree().quit()
