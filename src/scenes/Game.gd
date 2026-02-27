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
var equipment_popup: Control = null
var equipment_shop: Control = null

func _ready() -> void:
	# Register styles with the market system before any demand init
	MarketSystem.register_styles(STYLE_IDS)

	# Create equipment popup and shop (programmatic UI, no .tscn)
	var popup_script = preload("res://ui/EquipmentPopup.gd")
	equipment_popup = Control.new()
	equipment_popup.set_script(popup_script)
	equipment_popup.name = "EquipmentPopup"
	add_child(equipment_popup)

	var shop_script = preload("res://ui/EquipmentShop.gd")
	equipment_shop = Control.new()
	equipment_shop.set_script(shop_script)
	equipment_shop.name = "EquipmentShop"
	add_child(equipment_shop)

	# Collect all overlay references
	_all_overlays = [style_picker, recipe_designer, brewing_phases,
		results_overlay, game_over_screen, equipment_popup, equipment_shop]

	# Connect GameState signals
	GameState.state_changed.connect(_on_state_changed)

	# Wire brew confirmation: BrewingPhases emits → GameState executes
	brewing_phases.brew_confirmed.connect(GameState.execute_brew)

	# Wire equipment signals
	brewery_scene.slot_clicked.connect(_on_slot_clicked)
	brewery_scene.start_brewing_pressed.connect(_on_start_brewing)
	equipment_popup.item_assigned.connect(_on_equipment_assigned)
	equipment_popup.browse_shop_requested.connect(_on_browse_shop)
	equipment_popup.upgrade_requested.connect(_on_equipment_upgrade)
	equipment_popup.closed.connect(_on_popup_closed)
	equipment_shop.closed.connect(_on_shop_closed)

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
	brewery_scene.set_equipment_mode(false)

	match new_state:
		GameState.State.MARKET_CHECK:
			# Auto-advance: market check is handled inside StylePicker refresh
			style_picker.refresh()
			_show_overlay(style_picker)
			GameState.advance_state()  # MARKET_CHECK → STYLE_SELECT
			return

		GameState.State.STYLE_SELECT:
			style_picker.refresh()
			_show_overlay(style_picker)

		GameState.State.RECIPE_DESIGN:
			recipe_designer.refresh()
			_show_overlay(recipe_designer)

		GameState.State.BREWING_PHASES:
			brewing_phases.refresh()
			_show_overlay(brewing_phases)
			brewery_scene.set_brewing(true)
			_play_sfx(sfx_brew)

		GameState.State.RESULTS:
			results_overlay.populate()
			_show_overlay(results_overlay)
			_play_sfx(sfx_results)

		GameState.State.EQUIPMENT_MANAGE:
			brewery_scene.set_brewing(false)
			brewery_scene.set_equipment_mode(true)

		GameState.State.GAME_OVER:
			game_over_screen.populate()
			_show_overlay(game_over_screen)
			if GameState.run_won:
				_play_sfx(sfx_win)
			else:
				_play_sfx(sfx_lose)

func _show_overlay(overlay: Control) -> void:
	overlay.modulate.a = 0.0
	overlay.visible = true
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)

func _hide_all_overlays() -> void:
	for overlay in _all_overlays:
		if overlay:
			overlay.visible = false
			overlay.modulate.a = 0.0

# ---------------------------------------------------------------------------
# Audio helpers
# ---------------------------------------------------------------------------

func _play_music() -> void:
	if music_player and music_player.stream != null:
		music_player.play()

func _play_sfx(player: AudioStreamPlayer) -> void:
	if player and player.stream != null:
		player.play()

# ---------------------------------------------------------------------------
# Equipment management handlers
# ---------------------------------------------------------------------------

func _on_slot_clicked(slot_index: int) -> void:
	equipment_popup.show_for_slot(slot_index)

func _on_start_brewing() -> void:
	brewery_scene.set_equipment_mode(false)
	GameState.advance_state()

func _on_equipment_assigned(slot_index: int, equipment_id: String) -> void:
	EquipmentManager.assign_to_slot(slot_index, equipment_id)
	equipment_popup.visible = false
	brewery_scene.refresh_slots()

func _on_equipment_upgrade(equipment_id: String) -> void:
	EquipmentManager.upgrade(equipment_id)
	equipment_popup.visible = false
	brewery_scene.refresh_slots()

func _on_browse_shop() -> void:
	equipment_popup.visible = false
	equipment_shop.show_shop()

func _on_popup_closed() -> void:
	equipment_popup.visible = false

func _on_shop_closed() -> void:
	equipment_shop.visible = false
	brewery_scene.refresh_slots()
