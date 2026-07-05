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


func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(_PATH) == OK:
		touch_controls_mode = config.get_value("input", "touch_controls_mode", TouchControlsMode.AUTO)


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
	config.save(_PATH)
