class_name Treasure
extends StaticBody2D
## Generic class / descriptor for any treasure in the game. Used
## to dynamically organize any resource that entities can collect and 
## action in the game

const splash := preload("res://Effects/Splash/splash_effect.tscn")

enum { HEALTH, COIN, EMPTY }

@export var coin_texture: Texture2D
@export var health_texture: Texture2D
@export var empty_texture: Texture2D

@export var coin: int = 0
@export var health: int = 0
@export var state = EMPTY

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var death_timer: Timer = $DeathTimer
@onready var detection_area: Area2D = $DetectionArea

## How quickly the treasure gains speed while drifting toward a ship
const ATTRACT_ACCELERATION: float = 100.0

var velocity: Vector2
var friction: float

# The ship this treasure is drifting toward, if any
var _target: BaseShip
var _attract_speed: float = 0.0
var _sinking: bool = false

func _ready() -> void:
	match state:
		HEALTH: sprite.texture = health_texture
		COIN: sprite.texture = coin_texture
		EMPTY: sprite.texture = empty_texture

	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)

func _physics_process(delta: float) -> void:
	# Drop the target if it sank or left the game
	if _target and (!is_instance_valid(_target) or _target.state != BaseShip.State.ALIVE):
		_target = null
		_attract_speed = 0.0

	if _target == null or _sinking:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	else:
		_attract_speed += ATTRACT_ACCELERATION * delta
		velocity = (_target.global_position - global_position).normalized() * _attract_speed

	position += velocity * delta


func _on_detection_area_body_entered(body: Node2D) -> void:
	if !_target and body is BaseShip and body.state == BaseShip.State.ALIVE:
		_target = body


func _on_detection_area_body_exited(body: Node2D) -> void:
	if _target == body:
		_target = null
		_attract_speed = 0.0


func _on_death_timer_timeout() -> void:
	_sinking = true
	animation_player.play("appear", -1, -.05, true)
	_splash()


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	pass

func _splash() -> void:
	z_index = -1
	
	var new_splash: SplashEffect = splash.instantiate()
	new_splash.splash_finished.connect(_on_splash_finished, Node2D.CONNECT_ONE_SHOT)
	new_splash.z_index = 0
	add_child(new_splash)
	
func _on_splash_finished() -> void:
	queue_free()
