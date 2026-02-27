extends Node

## Game — root scene controller.
## Owns the brewery background and all UI overlays.
## Responds to GameState.state_changed to show/hide the correct overlay.

const STYLE_IDS := ["lager", "pale_ale", "wheat_beer", "stout"]

@onready var brewery_scene: Node2D = $BreweryScene
@onready var style_picker: Control = $StylePicker
@onready var recipe_designer: Control = $RecipeDesigner
@onready var brewing_phases: Control = $BrewingPhases
@onready var results_overlay: Control = $ResultsOverlay
@onready var game_over_screen: Control = $GameOverScreen
@onready var music_player: AudioStreamPlayer = $MusicPlayer
@onready var sfx_brew: AudioStreamPlayer = $SFX/BrewSFX
@onready var sfx_results: AudioStreamPlayer = $SFX/ResultsSFX
@onready var sfx_win: AudioStreamPlayer = $SFX/WinSFX
@onready var sfx_lose: AudioStreamPlayer = $SFX/LoseSFX

var _all_overlays: Array[Control] = []

func _ready() -> void:
	# Register styles with the market system before any demand init
	MarketSystem.register_styles(STYLE_IDS)

	# Collect all overlay references
	_all_overlays = [style_picker, recipe_designer, brewing_phases,
		results_overlay, game_over_screen]

	# Connect GameState signals
	GameState.state_changed.connect(_on_state_changed)

	# Wire brew confirmation: BrewingPhases emits → GameState executes
	brewing_phases.brew_confirmed.connect(GameState.execute_brew)

	# Start a fresh run
	GameState.reset()

	# Start background music
	_play_music()

# ---------------------------------------------------------------------------
# State → overlay mapping
# ---------------------------------------------------------------------------

func _on_state_changed(new_state: GameState.State) -> void:
	_hide_all_overlays()
	brewery_scene.set_brewing(false)

	match new_state:
		GameState.State.MARKET_CHECK:
			# Auto-advance: market check is handled inside StylePicker refresh
			style_picker.refresh()
			style_picker.visible = true
			GameState.advance_state()  # MARKET_CHECK → STYLE_SELECT
			return

		GameState.State.STYLE_SELECT:
			style_picker.refresh()
			style_picker.visible = true

		GameState.State.RECIPE_DESIGN:
			recipe_designer.refresh()
			recipe_designer.visible = true

		GameState.State.BREWING_PHASES:
			brewing_phases.refresh()
			brewing_phases.visible = true
			brewery_scene.set_brewing(true)
			_play_sfx(sfx_brew)

		GameState.State.RESULTS:
			results_overlay.populate()
			results_overlay.visible = true
			_play_sfx(sfx_results)

		GameState.State.GAME_OVER:
			game_over_screen.populate()
			game_over_screen.visible = true
			if GameState.run_won:
				_play_sfx(sfx_win)
			else:
				_play_sfx(sfx_lose)

func _hide_all_overlays() -> void:
	for overlay in _all_overlays:
		if overlay:
			overlay.visible = false

# ---------------------------------------------------------------------------
# Audio helpers
# ---------------------------------------------------------------------------

func _play_music() -> void:
	if music_player and music_player.stream != null:
		music_player.play()

func _play_sfx(player: AudioStreamPlayer) -> void:
	if player and player.stream != null:
		player.play()
