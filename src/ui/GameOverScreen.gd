extends Control

## GameOverScreen — end-of-run screen for both win and loss states.

@onready var title_label: Label = $Panel/VBox/TitleLabel
@onready var message_label: Label = $Panel/VBox/MessageLabel
@onready var stats_label: Label = $Panel/VBox/StatsLabel
@onready var new_run_button: Button = $Panel/VBox/Buttons/NewRunButton
@onready var quit_button: Button = $Panel/VBox/Buttons/QuitButton
@onready var background_panel: Panel = $Panel

func _ready() -> void:
	new_run_button.pressed.connect(_on_new_run_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

## Populate with end-of-run data from GameState. Call when overlay becomes visible.
func populate() -> void:
	var won := GameState.run_won

	# Win/loss title and message
	if won:
		title_label.text = "Brewery Success!"
		message_label.text = (
			"You saved $%.0f and built a thriving garage brewery!\nTime to upgrade..." % GameState.balance
		)
	else:
		title_label.text = "Bankrupt"
		message_label.text = "The bills piled up and you ran out of cash.\nBetter luck next run."

	# Final run statistics
	stats_label.text = (
		"Brews completed: %d\n" % GameState.turn_counter +
		"Best quality: %.1f / 100\n" % GameState.best_quality +
		"Total revenue: $%.0f\n" % GameState.total_revenue +
		"Final balance: $%.0f" % GameState.balance
	)

func _on_new_run_pressed() -> void:
	GameState.reset()

func _on_quit_pressed() -> void:
	get_tree().quit()
