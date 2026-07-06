class_name WalkingCrew
extends CharacterBody2D

enum State { IDLE, TARGET, WANDER }

const DEFAULT_WALK_SPEED: float = 200
const interaction_dist = 100

@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var detection_zone: Area2D = $DetectionZone
@onready var treasure_sprite: Sprite2D = $Treasure
@onready var coin_emitter: GPUParticles2D = $CoinEmitter
@onready var beehave_tree: BeehaveTree = $BeehaveTree

# The 'held' treasure of this crew member
@export var treasure: Treasure
@export var blackboard: Blackboard

var state: State = State.IDLE
var health: float = 100
var walk_speed: float = DEFAULT_WALK_SPEED
var deployment: Deployment

## The target position to move towards
var target: Vector2 = Vector2.INF

func _ready() -> void:
	sprite.frame = randi_range(0, 49)
	if blackboard:
		beehave_tree.blackboard = blackboard


func _process(_delta: float) -> void:
	treasure_sprite.visible = treasure != null


func _physics_process(delta: float) -> void:
	if state == State.TARGET and target != Vector2.INF:
		velocity = (target - position).normalized() * walk_speed
		rotation = velocity.angle()
	elif state == State.WANDER:
		rotation = velocity.angle()
	else:
		velocity = Vector2.ZERO
		
	# Move the crew and respect the physics
	var collision: KinematicCollision2D = move_and_collide(velocity * delta)
	if collision and state == State.WANDER:
		var reflect = collision.get_remainder().bounce(collision.get_normal())
		velocity = velocity.bounce(collision.get_normal())
		move_and_collide(reflect)

func set_target(new_target: Vector2) -> void:
	if state == State.TARGET and new_target == target:
		return
	
	target = new_target
	state = State.TARGET
	set_collision_layer_value(3, false)
	set_collision_mask_value(3, false)

func set_wander() -> void:
	if state == State.WANDER: return
	
	velocity = Vector2.RIGHT.rotated(randf() * (2*PI)) * walk_speed
	state = State.WANDER
	set_collision_layer_value(3, true)
	set_collision_mask_value(3, true)

func distance_squared_to_target() -> float:
	if target == Vector2.INF:
		return 0
	
	return position.distance_squared_to(target)

## Class to hold the deployment state of a crew.
class Deployment:
	var faction: Faction
	var island: Island
	var landing_pos: Vector2
	
	func _init(
		f: Faction, 
		isl: Island, 
		lpos: Vector2,
	) -> void:
		self.faction = f
		self.island = isl
		self.landing_pos = lpos
