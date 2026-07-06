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


var velocity: Vector2
var friction: float

func _ready() -> void:
	match state:
		HEALTH: sprite.texture = health_texture
		COIN: sprite.texture = coin_texture
		EMPTY: sprite.texture = empty_texture

func _physics_process(delta: float) -> void:
	velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	position += velocity * delta


func _on_death_timer_timeout() -> void:
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
