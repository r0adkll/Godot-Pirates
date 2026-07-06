class_name TouchControls
extends CanvasLayer
## On-screen controls for touch devices (mobile & mobile web).
##
## Visibility is driven by the Settings autoload (Auto/On/Off): AUTO shows the
## controls when a touchscreen is detected, with a runtime first-touch fallback
## for devices that misreport. The layer hides while the game is paused so it
## never draws over the pause menu.

@onready var left_joystick: TouchJoystick = $SafeArea/Layout/LeftJoystick
@onready var right_joystick: TouchJoystick = $SafeArea/Layout/RightJoystick
@onready var safe_area: MarginContainer = $SafeArea


func _ready() -> void:
	_update_visibility()
	Settings.touch_controls_mode_changed.connect(_on_touch_mode_changed)
	PauseMenu.state_changed.connect(_on_pause_changed)
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()


## Runtime fallback: a real touch while hidden in AUTO mode reveals the controls
func _input(event: InputEvent) -> void:
	if !visible and event is InputEventScreenTouch \
			and Settings.touch_controls_mode == Settings.TouchControlsMode.AUTO:
		visible = true


func _on_touch_mode_changed(_mode: Settings.TouchControlsMode) -> void:
	_update_visibility()


func _on_pause_changed(paused: bool) -> void:
	visible = !paused and Settings.is_touch_ui_enabled()


func _update_visibility() -> void:
	visible = Settings.is_touch_ui_enabled()


## Keep the controls out of notches/rounded corners on phones. Only applies on
## touch devices, where the window covers the whole screen — on desktop the
## screen-space safe area doesn't map onto the window.
func _apply_safe_area() -> void:
	if !DisplayServer.is_touchscreen_available():
		return
	var safe := DisplayServer.get_display_safe_area()
	var win_size := Vector2(get_window().size)
	if win_size.x <= 0 or win_size.y <= 0:
		return
	var canvas_scale := get_viewport().get_visible_rect().size / win_size
	safe_area.add_theme_constant_override("margin_left", int(safe.position.x * canvas_scale.x))
	safe_area.add_theme_constant_override("margin_top", int(safe.position.y * canvas_scale.y))
	safe_area.add_theme_constant_override("margin_right", int(maxf(0, win_size.x - safe.end.x) * canvas_scale.x))
	safe_area.add_theme_constant_override("margin_bottom", int(maxf(0, win_size.y - safe.end.y) * canvas_scale.y))
