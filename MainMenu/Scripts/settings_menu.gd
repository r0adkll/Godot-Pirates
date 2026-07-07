class_name SettingsMenu
extends CanvasLayer

@onready var touch_mode_option: OptionButton = $PanelContainer/VBoxContainer/TouchRow/TouchModeOption
@onready var master_volume_slider: HSlider = $PanelContainer/VBoxContainer/MasterVolumeRow/MasterVolumeSlider
@onready var sfx_volume_slider: HSlider = $PanelContainer/VBoxContainer/SfxVolumeRow/SfxVolumeSlider
@onready var music_volume_slider: HSlider = $PanelContainer/VBoxContainer/MusicVolumeRow/MusicVolumeSlider


func _ready() -> void:
	touch_mode_option.selected = Settings.touch_controls_mode
	master_volume_slider.value = Settings.master_volume
	sfx_volume_slider.value = Settings.sfx_volume
	music_volume_slider.value = Settings.music_volume


func _on_touch_mode_option_item_selected(index: int) -> void:
	Settings.touch_controls_mode = index as Settings.TouchControlsMode


func _on_master_volume_slider_value_changed(value: float) -> void:
	Settings.master_volume = value


func _on_sfx_volume_slider_value_changed(value: float) -> void:
	Settings.sfx_volume = value


func _on_music_volume_slider_value_changed(value: float) -> void:
	Settings.music_volume = value


func _on_back_button_pressed() -> void:
	visible = false
