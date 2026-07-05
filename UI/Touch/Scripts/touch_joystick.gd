class_name TouchJoystick
extends Control
## An on-screen joystick for touch devices.
##
## The control's rect is the touch zone that can claim a finger; once claimed,
## drags are tracked by touch index even outside the rect so fast flicks don't
## drop the stick.

## Emitted whenever the stick vector changes. The vector is deadzone-filtered
## with a length of 0..1, matching the shape of a gamepad stick axis pair.
signal vector_changed(vector: Vector2)
## Emitted when the claimed finger lifts off the screen
signal released

@export var deadzone: float = 0.2
## How far (in canvas px) the knob may travel from the base center
@export var clamp_radius: float = 150.0
## When true the base re-centers wherever the touch lands in the zone
@export var floating: bool = true

## Deadzone-filtered stick vector, length 0..1
var value: Vector2 = Vector2.ZERO

var _touch_index: int = -1

@onready var base: Control = $Base
@onready var knob: Control = $Base/Knob


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visibility_changed.connect(_on_visibility_changed)
	resized.connect(_center_base)
	_center_base.call_deferred()


func _input(event: InputEvent) -> void:
	if !is_visible_in_tree():
		return
	if event is InputEventScreenTouch:
		if event.pressed and _touch_index == -1 and get_global_rect().has_point(event.position):
			_touch_index = event.index
			if floating:
				base.global_position = event.position - base.size / 2.0
			_update(event.position)
			accept_event()
		elif !event.pressed and event.index == _touch_index:
			_release()
			accept_event()
	elif event is InputEventScreenDrag and event.index == _touch_index:
		_update(event.position)
		accept_event()


func _update(screen_pos: Vector2) -> void:
	var center := base.global_position + base.size / 2.0
	var offset := screen_pos - center
	if offset.length() > clamp_radius:
		offset = offset.normalized() * clamp_radius
	knob.global_position = center + offset - knob.size / 2.0
	var raw := offset / clamp_radius
	value = Vector2.ZERO if raw.length() < deadzone else raw
	vector_changed.emit(value)


func _release() -> void:
	_touch_index = -1
	value = Vector2.ZERO
	_center_base()
	vector_changed.emit(value)
	released.emit()


## Rest the base in the middle of the touch zone (also re-applied on layout
## resizes, e.g. rotating a phone)
func _center_base() -> void:
	if _touch_index == -1:
		base.position = (size - base.size) / 2.0
		knob.position = (base.size - knob.size) / 2.0


## Never leave the stick engaged when the controls get hidden (e.g. pausing)
func _on_visibility_changed() -> void:
	if !is_visible_in_tree() and _touch_index != -1:
		_release()
