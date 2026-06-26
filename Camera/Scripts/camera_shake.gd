class_name CameraShake
extends Node

@export var camera: Camera2D

@export var decay: float = 0.8  # How quickly the shaking stops [0, 1].
@export var max_offset: Vector2 = Vector2(100, 75)  # Maximum hor/ver shake in pixels.
@export var max_roll: float = 0.1  # Maximum rotation in radians (use sparingly).

var trauma = 0.0  # Current shake strength.
var trauma_power = 2  # Trauma exponent. Use [2, 3].

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	randomize()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		shake()


func shake() -> void:
	var amount = pow(trauma, trauma_power)
	camera.rotation = max_roll * amount * randi_range(-1, 1)
	camera.offset.x = max_offset.x * amount * randi_range(-1, 1)
	camera.offset.y = max_offset.y * amount * randi_range(-1, 1)


func add_trauma(amount: float) -> void:
	trauma = min(trauma + amount, 1.0)
