class_name CannonBall
extends Node2D

const explosion := preload("res://Effects/Explosion/explosion.tscn")
const splash := preload("res://Effects/Splash/splash_effect.tscn")

const FRICTION: float = 300

@onready var sprite: Sprite2D = $Sprite
@onready var ray_cast: RayCast2D = $RayCast
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var trail: Sprite2D = $Trail

# Set by the firing cannon
var origin: Node2D
var faction: Faction
var is_remote: bool = false

# The amount of damage this cannon ball will inflict on colliding targets
var damage: float = 15.0
var velocity: Vector2 = Vector2.RIGHT

var _initial_velocity: Vector2 = velocity
var _trail_scale_y: float = 0.224
var _is_sinking: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_initial_velocity = velocity


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	# Apply friction
	velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
	if velocity.length() <= 2 and !_is_sinking:
		_splash()
		
	# Make the cannon ball visually sink
	if _is_sinking:
		sprite.offset += Vector2.DOWN.rotated(-rotation) * 5 * delta
	
	# Move the cannon ball
	position += velocity * delta
	
	# If not animating scale tail by velocity power
	if !animation_player.is_playing():
		var power = velocity.length() / _initial_velocity.length()
		trail.scale.y = _trail_scale_y * power
		
	
	# Check collisions
	if not is_remote and ray_cast.is_colliding():
		var collider: Node2D = ray_cast.get_collider()
		
		# Apply damage, if colliding subject can take damage
		if collider != null and collider != origin:
			var target = collider.get_node_or_null("DamageTarget")
			if target != null and target is DamageTarget:
				(target as DamageTarget).damage(faction, damage)
				
			# Explode
			explode()


func explode() -> void:
	if multiplayer.has_multiplayer_peer() and multiplayer.is_server():
		_explode.rpc()
	else:
		_explode()


@rpc("any_peer", "call_local", "reliable")
func _explode() -> void:
	var new_exp: Explosion = explosion.instantiate()
	new_exp.global_position = global_position
	get_parent().add_child(new_exp)
	queue_free()


func _splash() -> void:
	_is_sinking = true
	z_index = -1
	animation_player.play("sink")
	
	var new_splash: SplashEffect = splash.instantiate()
	new_splash.splash_finished.connect(_on_splash_finished, Node2D.CONNECT_ONE_SHOT)
	new_splash.z_index = 0
	add_child(new_splash)

func _on_splash_finished() -> void:
	queue_free()
