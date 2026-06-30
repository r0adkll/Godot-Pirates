class_name TrailEmitter
extends Marker2D

const GROUP: String = "trail_emitters"

@export var point_velocity: Vector2 = Vector2.ZERO
@export var point_lifetime: float = 5 # seconds

@export var enabled: bool = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group(GROUP)
