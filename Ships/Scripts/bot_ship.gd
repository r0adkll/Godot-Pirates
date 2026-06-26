class_name BotShip
extends BaseShip
## The controlling class for Bot ships

const GROUP = &"BotShips"

const floating_crew := preload("res://Crew/floating_crew.tscn")

@onready var sprite: BoatSprite = $BoatSprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
@onready var shooting_timer: Timer = $ShootingTimer
@onready var detection_area: Area2D = $DetectionArea
@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

@export var shooting_rate: float = 0.5
@export var shooting_distance: float = 600
@export var ships_system: ShipsSystem

## The physical target that this ship is attacking
var target: Node2D


func _ready() -> void:
	super._ready()
	add_to_group(GROUP)
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)


func _exit_tree() -> void:
	pass


# Check health and other states of the ship that are not
# movement / frame critical
func _process(delta: float) -> void:
	super._process(delta)


# Update and move our ship
func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	
	if nav_agent.is_navigation_finished() and not target:
		ship_velocity = move_toward(ship_velocity, 0, FRICTION * delta)
		angular_velocity = move_toward(angular_velocity, 0, TURN_ACCELERATION)
	
	# Move the boat
	move_and_slide()


func _on_die(_source: Faction) -> void:
	collision_shape.disabled = true
	nav_agent.debug_enabled = false

	_clear_target()
	$Sfx/WoodBreaking.play()
	
	# Start "Sink" Animation
	animation_player.play(&"sinking")


func _generate_explosions() -> void:
	for i in range(15):
		var offset_rotation = randf() * (2*PI)
		var offset_magnitude = randf() * 75
		var offset = Vector2(1, 0).rotated(offset_rotation) * offset_magnitude
		var delay = randf() * 0.5
		
		var new_exp: Explosion = explosion.instantiate()
		new_exp.global_position = global_position + offset
		new_exp.delay = delay
		SceneSpawnerSystem.add_entity(new_exp)


func fire_main_cannons() -> void:
	if shooting_timer.is_stopped() && cannon.fire():
		shooting_timer.start(shooting_rate)

## Signals

## DamageTarget

func _on_damage_target_apply_damage(faction: Faction, amount: float) -> void:
	if state == BaseShip.State.ALIVE:
		# Play hit flash!
		animation_player.play(&"hit_flash", -1, 2.5)
		
		# Decrease health, and check death
		health -= amount
		if health <= 0:
			print("Killed by %s" % str(faction))
			die(faction)
		
	


## AnimationPlayer

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"sinking":
		state = State.DEAD
		fade_away()


## CrewCabin

func _on_crew_cabin_crew_updated(_count: int, _max: int) -> void:
	pass # Replace with function body.

## DetectionArea

const DEFAULT_DETECTION_RADIUS = 800 #px
const ATTACKING_DETECTION_RADIUS = 1600 #px

## Set the radius of the detection area
func _set_detection_radius(radius: float) -> void:
	var detection_shape: CircleShape2D = $DetectionArea/CollisionShape2D.shape as CircleShape2D
	detection_shape.radius = radius

func _on_detection_area_body_entered(body: Node2D) -> void:
	print("Body Entered: %s" % body.name)
	if body != self && !target and _can_target(body):
		print("--> Targetting [%s]" % body.name)
		target = body
		
		# Expand our detection area so we don't lose our target as fast
		_set_detection_radius(ATTACKING_DETECTION_RADIUS)
		
		# If the new target is of BaseShip, bind to its state signal
		if body is BaseShip:
			(body as BaseShip).state_changed.connect(_on_target_state_changed)

## Check whether or not a body is target-able
func _can_target(body: Node2D) -> bool:
	if state != BaseShip.State.ALIVE:
		return false
		
	var dmg_target = body.get_node_or_null("DamageTarget")
	if dmg_target:
		# Check if it is a base ship and has health (i.e. not ded)
		var is_alive = true
		var is_ally = false
		if is_instance_of(body, BaseShip):
			var ship = (body as BaseShip)
			is_alive = ship.state == BaseShip.State.ALIVE
			is_ally = ship.faction.equals(faction)
			
		# If, in fact, is alive then return it otherwise skip
		if is_alive and !is_ally:
			return true
	
	# If none of the prior conditions match, return false
	return false

func _on_detection_area_body_exited(body: Node2D) -> void:
	if target == body:
		print("<-- Lost target[%s]" % body.name)
		_clear_target()


## Target > BaseShip

func _on_target_state_changed(_ship: BaseShip, _prev_state: BaseShip.State, new_state: BaseShip.State):
	if new_state != BaseShip.State.ALIVE:
		print("<-- Target[%s] died" % target.name)
		_clear_target()

func _clear_target() -> void:
	_set_detection_radius(DEFAULT_DETECTION_RADIUS)
	
	# If exiting body is a base ship, disconnect its state signal
	# then set the target to null
	if target and target is BaseShip:
		(target as BaseShip).state_changed.disconnect(_on_target_state_changed)
		target = null
		
func _on_lost_beach_head(_beach: BaseShip.BeachHead) -> void:
	pass
