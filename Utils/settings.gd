extends Node
## Persisted user settings, stored at user://settings.cfg

signal touch_controls_mode_changed(mode: TouchControlsMode)

enum TouchControlsMode { AUTO, ON, OFF }

const _PATH := "user://settings.cfg"

var touch_controls_mode: TouchControlsMode = TouchControlsMode.AUTO:
	set(value):
		touch_controls_mode = value
		_save()
		touch_controls_mode_changed.emit(value)

var master_volume: float = 1.0:
	set(value):
		master_volume = clampf(value, 0.0, 1.0)
		_apply_bus_volume(&"Master", master_volume)
		_save()

var sfx_volume: float = 1.0:
	set(value):
		sfx_volume = clampf(value, 0.0, 1.0)
		_apply_bus_volume(&"SFX", sfx_volume)
		_save()

var music_volume: float = 1.0:
	set(value):
		music_volume = clampf(value, 0.0, 1.0)
		_apply_bus_volume(&"Music", music_volume)
		_save()


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(_PATH) == OK:
		touch_controls_mode = config.get_value("input", "touch_controls_mode", TouchControlsMode.AUTO)
		master_volume = config.get_value("audio", "master_volume", 1.0)
		sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
		music_volume = config.get_value("audio", "music_volume", 1.0)


## Single source of truth for whether the on-screen touch controls should show
func is_touch_ui_enabled() -> bool:
	match touch_controls_mode:
		TouchControlsMode.ON:
			return true
		TouchControlsMode.OFF:
			return false
		_:
			return DisplayServer.is_touchscreen_available()


func _save() -> void:
	var config := ConfigFile.new()
	config.set_value("input", "touch_controls_mode", touch_controls_mode)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("audio", "music_volume", music_volume)
	config.save(_PATH)


func _apply_bus_volume(bus_name: StringName, value: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx < 0:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(maxf(value, 0.0001)))
	AudioServer.set_bus_mute(idx, value <= 0.0)
