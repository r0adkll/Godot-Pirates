class_name TouchButton
extends Control
## An on-screen button that synthesizes a project input action while touched,
## so existing Input.is_action_*() readers (broadsides, ability, sprint, pause,
## etc.) work without any changes.

## The input action to press/release, e.g. &"ui_accept"
@export var action: StringName
@export var text: String = "":
	set(value):
		text = value
		if label:
			label.text = value

const IDLE_ALPHA := 0.6
const PRESSED_ALPHA := 1.0

var _touch_index: int = -1

@onready var label: Label = $Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = text
	modulate.a = IDLE_ALPHA
	visibility_changed.connect(_force_release)


func _input(event: InputEvent) -> void:
	if !is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1 and get_global_rect().has_point(event.position):
			_touch_index = event.index
			_send(true)
			modulate.a = PRESSED_ALPHA
			accept_event()
		elif !event.pressed and event.index == _touch_index:
			_touch_index = -1
			_send(false)
			modulate.a = IDLE_ALPHA
			accept_event()


func _notification(what: int) -> void:
	# A held action (e.g. sprint) must not stick when the app is backgrounded
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_force_release()


func _send(pressed: bool) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = pressed
	Input.parse_input_event(event)


func _force_release() -> void:
	if _touch_index != -1:
		_touch_index = -1
		_send(false)
		modulate.a = IDLE_ALPHA
