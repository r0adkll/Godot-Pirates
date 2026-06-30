extends Node2D

const MAX_TRAIL_VELOCITY: float = 50
const TRAIL_ANGLE: float = 160

@export var path_follow: ShipPathFollower
@export var boat_texture: Texture2D

@onready var boat_sprite: Sprite2D = $BoatSprite
@onready var right_trail: TrailEmitter = $Trails/Right
@onready var left_trail: TrailEmitter = $Trails/Left


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	boat_sprite.texture = boat_texture
	
func _physics_process(delta: float) -> void:
	var ship_speed = 200 * delta
	var trail_magnitude = ship_speed * MAX_TRAIL_VELOCITY
	var right_velocity = Vector2.RIGHT.rotated(path_follow.rotation - deg_to_rad(TRAIL_ANGLE)) * trail_magnitude
	var left_velocity = Vector2.RIGHT.rotated(path_follow.rotation + deg_to_rad(TRAIL_ANGLE)) * trail_magnitude
	left_trail.point_velocity = left_velocity
	right_trail.point_velocity = right_velocity
