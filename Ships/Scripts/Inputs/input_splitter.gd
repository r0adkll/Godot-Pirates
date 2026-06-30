class_name InputSplitter
extends PlayerInputNode

@export var keyboard_input_node: PlayerInputNode
@export var gamepad_input_node: PlayerInputNode

var is_gamepad: bool = false

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if !is_gamepad: 
			print("Gamepad Detected")
		is_gamepad = true
	else: 
		if is_gamepad: 
			print("Keyboard Detected")
		is_gamepad = false

func process_input(delta: float) -> void:
	if is_gamepad:
		gamepad_input_node.process_input(delta)
	else:
		keyboard_input_node.process_input(delta)
