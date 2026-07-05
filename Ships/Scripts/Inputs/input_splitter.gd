class_name InputSplitter
extends PlayerInputNode

enum Mode { KEYBOARD, GAMEPAD, TOUCH }

@export var keyboard_input_node: PlayerInputNode
@export var gamepad_input_node: PlayerInputNode
@export var touch_input_node: PlayerInputNode

var mode: Mode = Mode.KEYBOARD

func _ready() -> void:
	# Avoid a first-frame mouse-aim on touch devices
	if DisplayServer.is_touchscreen_available():
		mode = Mode.TOUCH

func _input(event: InputEvent) -> void:
	# Synthesized InputEventActions (from TouchButton) are intentionally ignored:
	# an on-screen button press must not flip aiming back to mouse mode. The
	# joypad deadzone guard keeps drifting analog sticks from stealing the mode.
	if event is InputEventJoypadButton \
			or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.2):
		_set_mode(Mode.GAMEPAD)
	elif event is InputEventScreenTouch or event is InputEventScreenDrag:
		_set_mode(Mode.TOUCH)
	elif (event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion) \
			and event.device != InputEvent.DEVICE_ID_EMULATION:
		_set_mode(Mode.KEYBOARD)

func _set_mode(new_mode: Mode) -> void:
	if mode != new_mode:
		print("%s Detected" % Mode.keys()[new_mode].capitalize())
	mode = new_mode

func process_input(ship: Ship, delta: float) -> void:
	match mode:
		Mode.GAMEPAD:
			gamepad_input_node.process_input(ship, delta)
		Mode.TOUCH:
			touch_input_node.process_input(ship, delta)
		_:
			keyboard_input_node.process_input(ship, delta)
