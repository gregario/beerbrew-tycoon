extends Control
## Reusable centered card with dim overlay background.
## Add children to the inner VBox via get_content_container().

@onready var dim_overlay: ColorRect = $DimOverlay
@onready var card_panel: PanelContainer = $CardPanel
@onready var content_vbox: VBoxContainer = $CardPanel/MarginContainer/VBox

func get_content_container() -> VBoxContainer:
	return content_vbox
