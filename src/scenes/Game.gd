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

var _managed_overlays: Array = []
var equipment_popup: CanvasLayer = null
var equipment_shop: CanvasLayer = null
var research_tree: CanvasLayer = null
var staff_screen: CanvasLayer = null
var _conditioning_overlay: CanvasLayer = null
var _sell_overlay: CanvasLayer = null
var _fork_overlay: CanvasLayer = null
var _run_summary: CanvasLayer = null
var _unlock_shop: CanvasLayer = null
var _run_start: CanvasLayer = null
var _main_menu: CanvasLayer = null
var _achievements: CanvasLayer = null

func _ready() -> void:
	# Register styles with the market manager before any demand init
	MarketManager.register_styles(STYLE_IDS)

	# Create equipment popup and shop (programmatic UI, no .tscn)
	var popup_script = preload("res://ui/EquipmentPopup.gd")
	equipment_popup = CanvasLayer.new()
	equipment_popup.set_script(popup_script)
	equipment_popup.name = "EquipmentPopup"
	add_child(equipment_popup)

	var shop_script = preload("res://ui/EquipmentShop.gd")
	equipment_shop = CanvasLayer.new()
	equipment_shop.set_script(shop_script)
	equipment_shop.name = "EquipmentShop"
	add_child(equipment_shop)

	var research_script = preload("res://ui/ResearchTree.gd")
	research_tree = CanvasLayer.new()
	research_tree.set_script(research_script)
	research_tree.name = "ResearchTree"
	add_child(research_tree)

	var staff_script = preload("res://ui/StaffScreen.gd")
	staff_screen = CanvasLayer.new()
	staff_screen.set_script(staff_script)
	staff_screen.name = "StaffScreen"
	add_child(staff_screen)

	# Collect all overlay references (Control scene-tree overlays + CanvasLayer programmatic ones)
	_managed_overlays = [style_picker, recipe_designer, brewing_phases,
		results_overlay, game_over_screen, equipment_popup, equipment_shop,
		research_tree, staff_screen]

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
	brewery_scene.research_requested.connect(_on_research_requested)
	research_tree.closed.connect(_on_research_tree_closed)
	brewery_scene.staff_requested.connect(_on_staff_requested)
	staff_screen.closed.connect(_on_staff_screen_closed)

	# Meta-progression flow: GameOver → RunSummary → UnlockShop → RunStart → reset()
	game_over_screen.new_run_requested.connect(_on_new_run_requested)

	# Fork choice overlay (Stage 5A)
	if is_instance_valid(BreweryExpansion):
		BreweryExpansion.fork_threshold_reached.connect(_on_fork_threshold_reached)
	if is_instance_valid(PathManager):
		PathManager.path_chosen.connect(_on_path_chosen)

	# Connect market toast signals
	MarketManager.trend_started.connect(_on_trend_started)
	MarketManager.trend_ended.connect(_on_trend_ended)
	MarketManager.season_changed.connect(_on_season_changed)

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

		GameState.State.CONDITIONING:
			_show_conditioning_overlay()

		GameState.State.SELL:
			_show_sell_overlay()

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

func _show_overlay(overlay) -> void:
	if overlay is Control:
		overlay.modulate.a = 0.0
		overlay.visible = true
		var tween := create_tween()
		tween.tween_property(overlay, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
	else:
		overlay.visible = true

func _close_all_managed_overlays() -> void:
	for overlay in _managed_overlays:
		if overlay:
			overlay.visible = false

func _hide_all_overlays() -> void:
	for overlay in _managed_overlays:
		if overlay:
			overlay.visible = false
			if overlay is Control:
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
	_close_all_managed_overlays()
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
	_close_all_managed_overlays()
	equipment_shop.show_shop()

func _on_popup_closed() -> void:
	equipment_popup.visible = false

func _on_shop_closed() -> void:
	equipment_shop.visible = false
	brewery_scene.refresh_slots()

func _on_research_requested() -> void:
	_close_all_managed_overlays()
	research_tree.show_tree()

func _on_research_tree_closed() -> void:
	pass  # Stay in equipment mode, research is just an overlay

func _on_staff_requested() -> void:
	_close_all_managed_overlays()
	staff_screen.show_screen()

func _on_staff_screen_closed() -> void:
	pass  # Stay in equipment mode, staff screen is just an overlay

# ---------------------------------------------------------------------------
# Conditioning overlay handlers
# ---------------------------------------------------------------------------

func _show_conditioning_overlay() -> void:
	_close_all_managed_overlays()
	if _conditioning_overlay == null:
		_conditioning_overlay = preload("res://ui/ConditioningOverlay.gd").new()
		add_child(_conditioning_overlay)
		_managed_overlays.append(_conditioning_overlay)
		_conditioning_overlay.conditioning_confirmed.connect(_on_conditioning_confirmed)
	_conditioning_overlay.show_overlay()

func _on_conditioning_confirmed(weeks: int) -> void:
	if weeks > 0:
		GameState.execute_conditioning(weeks)
	GameState.advance_state()  # CONDITIONING -> SELL

# ---------------------------------------------------------------------------
# Sell overlay handlers
# ---------------------------------------------------------------------------

func _show_sell_overlay() -> void:
	_close_all_managed_overlays()
	if _sell_overlay == null:
		_sell_overlay = preload("res://ui/SellOverlay.gd").new()
		add_child(_sell_overlay)
		_managed_overlays.append(_sell_overlay)
		_sell_overlay.sale_confirmed.connect(_on_sale_confirmed)
		_sell_overlay.closed.connect(_on_sell_closed)
	var style_name: String = GameState.current_style.style_name if GameState.current_style else "Unknown"
	var base_price: float = GameState.current_style.base_price if GameState.current_style else 10.0
	var quality: float = GameState.last_brew_result.get("final_score", 50.0)
	var batch_mult: float = 1.0
	if is_instance_valid(EquipmentManager):
		batch_mult = EquipmentManager.active_bonuses.get("batch_size", 1.0)
	var batch_size: int = int(10 * batch_mult)
	var demand: float = 1.0
	if is_instance_valid(MarketManager) and GameState.current_style:
		demand = MarketManager.get_demand_multiplier(GameState.current_style.style_id)
	_sell_overlay.show_overlay(style_name, base_price, quality, batch_size, demand)

func _on_sale_confirmed(allocations: Array, price_offset: float) -> void:
	GameState.execute_sell(allocations, price_offset)
	GameState.advance_state()

func _on_sell_closed() -> void:
	# Close button acts the same as confirm with current allocations
	# (player can't skip selling — just confirm with defaults)
	_on_sale_confirmed([], 0.0)

# ---------------------------------------------------------------------------
# Market toast handlers
# ---------------------------------------------------------------------------

func _on_trend_started(style_id: String) -> void:
	var display_name: String = _get_style_display_name(style_id)
	if is_instance_valid(ToastManager):
		ToastManager.show_toast("%s is trending! (+50%% demand)" % display_name)

func _on_trend_ended(style_id: String) -> void:
	var display_name: String = _get_style_display_name(style_id)
	if is_instance_valid(ToastManager):
		ToastManager.show_toast("%s trend ended" % display_name)

func _on_season_changed(season_name: String) -> void:
	if is_instance_valid(ToastManager):
		ToastManager.show_toast("Season changed to %s" % season_name)

func _get_style_display_name(style_id: String) -> String:
	# Fallback: convert style_id to display name
	return style_id.replace("_", " ").capitalize()

# ---------------------------------------------------------------------------
# Fork choice handlers (Stage 5A)
# ---------------------------------------------------------------------------

func _on_fork_threshold_reached() -> void:
	_show_fork_overlay()

func _show_fork_overlay() -> void:
	_close_all_managed_overlays()
	if _fork_overlay == null:
		_fork_overlay = preload("res://ui/ForkChoiceOverlay.gd").new()
		add_child(_fork_overlay)
		_managed_overlays.append(_fork_overlay)
		_fork_overlay.path_selected.connect(_on_fork_path_selected)
	_fork_overlay.show_overlay()

func _on_fork_path_selected(path_type: String) -> void:
	PathManager.choose_path(path_type)
	var target_stage: BreweryExpansion.Stage
	if path_type == "artisan":
		target_stage = BreweryExpansion.Stage.ARTISAN
	else:
		target_stage = BreweryExpansion.Stage.MASS_MARKET
	BreweryExpansion.expand_to_path(target_stage)
	_swap_brewery_scene(path_type)
	if is_instance_valid(ToastManager):
		ToastManager.show_toast("You've chosen the %s path!" % PathManager.get_path_name())

func _on_path_chosen(path_type: String) -> void:
	# Swap brewery scene when path is restored from save
	if path_type != "" and not brewery_scene is preload("res://scenes/ArtisanBreweryScene.gd") and not brewery_scene is preload("res://scenes/MassMarketBreweryScene.gd"):
		_swap_brewery_scene(path_type)

func _swap_brewery_scene(path_type: String) -> void:
	var scene_path: String
	if path_type == "artisan":
		scene_path = "res://scenes/ArtisanBreweryScene.tscn"
	else:
		scene_path = "res://scenes/MassMarketBreweryScene.tscn"

	# Disconnect signals from old brewery scene
	if brewery_scene.slot_clicked.is_connected(_on_slot_clicked):
		brewery_scene.slot_clicked.disconnect(_on_slot_clicked)
	if brewery_scene.start_brewing_pressed.is_connected(_on_start_brewing):
		brewery_scene.start_brewing_pressed.disconnect(_on_start_brewing)
	if brewery_scene.research_requested.is_connected(_on_research_requested):
		brewery_scene.research_requested.disconnect(_on_research_requested)
	if brewery_scene.staff_requested.is_connected(_on_staff_requested):
		brewery_scene.staff_requested.disconnect(_on_staff_requested)

	# Remember position in tree and remove old scene
	var idx := brewery_scene.get_index()
	remove_child(brewery_scene)
	brewery_scene.queue_free()

	# Instantiate new path-specific scene
	var new_scene: Node2D = load(scene_path).instantiate()
	new_scene.name = "BreweryScene"
	add_child(new_scene)
	move_child(new_scene, idx)
	brewery_scene = new_scene

	# Reconnect signals
	brewery_scene.slot_clicked.connect(_on_slot_clicked)
	brewery_scene.start_brewing_pressed.connect(_on_start_brewing)
	brewery_scene.research_requested.connect(_on_research_requested)
	brewery_scene.staff_requested.connect(_on_staff_requested)

	# Refresh the new scene's slots to match current equipment state
	brewery_scene.set_equipment_mode(true)

# ---------------------------------------------------------------------------
# Meta-progression flow: GameOver → RunSummary → UnlockShop → RunStart → reset()
# ---------------------------------------------------------------------------

func _on_new_run_requested() -> void:
	_hide_all_overlays()
	var metrics: Dictionary = _gather_run_metrics()
	var points: int = MetaProgressionManager.end_run(metrics)
	_show_run_summary(metrics, points)

func _gather_run_metrics() -> Dictionary:
	var medals: int = 0
	if is_instance_valid(CompetitionManager):
		medals = CompetitionManager.get_total_medals()
	var channels: int = 0
	if is_instance_valid(MarketManager):
		channels = MarketManager.get_unlocked_channels().size()
	return {
		"turns": GameState.turn_counter,
		"revenue": GameState.total_revenue,
		"best_quality": GameState.best_quality,
		"medals": medals,
		"won": GameState.run_won,
		"equipment_spend": GameState.equipment_spend,
		"channels_unlocked": channels,
		"unique_ingredients": GameState.unique_ingredients_used,
		"path": PathManager.get_path_type() if is_instance_valid(PathManager) else "",
	}

func _show_run_summary(metrics: Dictionary, points: int) -> void:
	if _run_summary == null:
		_run_summary = preload("res://ui/RunSummaryOverlay.gd").new()
		add_child(_run_summary)
		_managed_overlays.append(_run_summary)
		_run_summary.continue_pressed.connect(_on_run_summary_continue)
	_run_summary.show_summary(metrics, points)

func _on_run_summary_continue() -> void:
	_hide_all_overlays()
	_show_meta_unlock_shop()

func _show_meta_unlock_shop() -> void:
	if _unlock_shop == null:
		_unlock_shop = preload("res://ui/UnlockShopOverlay.gd").new()
		add_child(_unlock_shop)
		_managed_overlays.append(_unlock_shop)
		_unlock_shop.done_pressed.connect(_on_unlock_shop_done)
	_unlock_shop.show_shop(MetaProgressionManager)

func _on_unlock_shop_done() -> void:
	_hide_all_overlays()
	_show_run_start()

func _show_run_start() -> void:
	if _run_start == null:
		_run_start = preload("res://ui/RunStartOverlay.gd").new()
		add_child(_run_start)
		_managed_overlays.append(_run_start)
		_run_start.run_started.connect(_on_run_start_confirmed)
	_run_start.show_setup(MetaProgressionManager)

func _on_run_start_confirmed() -> void:
	_hide_all_overlays()
	GameState.reset()
