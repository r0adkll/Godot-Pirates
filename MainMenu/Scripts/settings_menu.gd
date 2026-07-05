class_name SettingsMenu
extends CanvasLayer

@onready var touch_mode_option: OptionButton = $PanelContainer/VBoxContainer/TouchRow/TouchModeOption


func _ready() -> void:
	touch_mode_option.selected = Settings.touch_controls_mode


func _on_touch_mode_option_item_selected(index: int) -> void:
	Settings.touch_controls_mode = index as Settings.TouchControlsMode


func _on_back_button_pressed() -> void:
	visible = false
