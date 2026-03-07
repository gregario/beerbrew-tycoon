extends "res://scenes/BreweryScene.gd"

## MassMarketBreweryScene — mass-market path brewery layout.
## Adds revenue tracker and channel status display.

var _revenue_bar: ProgressBar
var _revenue_label: Label
var _channel_label: Label

func _ready() -> void:
	super._ready()
	_add_revenue_display()

func _add_revenue_display() -> void:
	_revenue_bar = ProgressBar.new()
	_revenue_bar.min_value = 0
	_revenue_bar.max_value = 50000
	_revenue_bar.value = GameState.total_revenue
	_revenue_bar.custom_minimum_size = Vector2(150, 20)
	_revenue_bar.show_percentage = false

	_revenue_label = Label.new()
	_revenue_label.text = "$%d/$50K" % int(GameState.total_revenue)

	var channels_unlocked: int = MarketManager.get_unlocked_channels().size() if is_instance_valid(MarketManager) else 0
	_channel_label = Label.new()
	_channel_label.text = "Channels: %d/4" % channels_unlocked

	var hbox := HBoxContainer.new()
	hbox.name = "RevenueDisplay"
	hbox.add_theme_constant_override("separation", 8)
	hbox.add_child(_revenue_label)
	hbox.add_child(_revenue_bar)
	hbox.add_child(_channel_label)
	add_child(hbox)

func refresh_revenue() -> void:
	if _revenue_bar:
		_revenue_bar.value = GameState.total_revenue
	if _revenue_label:
		_revenue_label.text = "$%d/$50K" % int(GameState.total_revenue)
	if _channel_label:
		var channels_unlocked: int = MarketManager.get_unlocked_channels().size() if is_instance_valid(MarketManager) else 0
		_channel_label.text = "Channels: %d/4" % channels_unlocked
