@abstract 
class_name BaseShip
extends CharacterBody2D
## The base ship class for both player and Bot controlled ships
##
## This handles the common states / updates for all ships including
## health management, state management, z-indexing, etc.

signal state_changed(ship: BaseShip, prev_state: State, new_state: State)
signal coin_changed(amount: int)
signal crew_returned(amount: int)

# The control mode
enum { LOCAL, REMOTE }

## The overall state that a ship can be in
enum State {
	ALIVE,   # Ship is alive and can move and interact
	SINKING, # Ship is dead and sinking
	DEAD,    # Ship is dead and has sunk beneath the waves
}

## The mapped z-index of the ship based on its state
const Z_INDEX: Dictionary = {
	State.ALIVE: 1,
	State.SINKING: 0,
	State.DEAD: -1 
}

const explosion := preload("res://Effects/Explosion/explosion.tscn")

# Shared Ship Constants
const ACCELERATION: float = 350.0
const FRICTION: float = 400.0
const TURN_ACCELERATION: float = 3.0
const TURN_FRICTION: float = 10.0
const MAX_TURN_SPEED: float = 5.0
const MAX_FORWARD_SPEED: float = 500.0
const MAX_PATROL_FORWARD_SPEED: float = 300.0
const MAX_BEACHING_FORWARD_SPEED: float = 450.0
const MAX_REVERSE_SPEED: float = 250.0
const SPRINT_MODIFIER: float = 2.0
const MAX_TRAIL_VELOCITY: float = 50
const TRAIL_ANGLE: float = 90

## Ship States
@export var faction: Faction
@export var boat_sprite: BoatSprite
@export var cannon: Cannon
@export var crew_cabin: CrewCabin
@export var left_trail: TrailEmitter
@export var right_trail: TrailEmitter
@export var max_health: float = 100
@onready var health: float = max_health

@export var coin: int = 0: set = _set_coin
func _set_coin(new_value: int) -> void:
	coin = new_value
	coin_changed.emit(coin)

## The state of the ship
var state: State = State.ALIVE: set = set_state
func set_state(new_state: State):
	var prev_state = state
	state = new_state
	state_changed.emit(self, prev_state, new_state)

# Whether or not this ship is locally, or remotely controlled 
# for this client
var control = LOCAL

## Tracks what island we are "beached" on
var beach_head: BeachHead

## The total velocity of the ship 
var ship_velocity: float = 0.0
var angular_velocity: float = 0.0
var max_forward_speed: float = MAX_FORWARD_SPEED

const DRIFT_OFFSET: float = 15
const DRIFT_ROTATION: float = 10
const DRIFT_SPEED: float = 50
var _idle_position: Vector2 = Vector2.INF
var _idle_rotation_degrees: float = 0
var _drift_tween: Tween
var can_drift: bool = true

func _ready() -> void:
	cannon.faction = faction
	boat_sprite.hulls = faction.boat

# Called every frame.
func _process(_delta: float) -> void:
	# Apply z-index based on state
	z_index = Z_INDEX[state]	
		
	# Check Health and apply visual states
	check_health()


func _physics_process(_delta: float) -> void:
	if state == State.ALIVE:
		# Set the idling position when ship is not moving, 
		# but only in local control smode
		if control == LOCAL:
			if ship_velocity == 0 and _idle_position == Vector2.INF and can_drift:
				_idle_position = position
				_idle_rotation_degrees = rotation_degrees
				_idle_ship()
			elif ship_velocity != 0 and _idle_position != Vector2.INF:
				_idle_position = Vector2.INF
				if _drift_tween:
					_drift_tween.kill()
				
	# Compute velocity based on raw velocity + rotation
	ship_velocity = clampf(ship_velocity, -MAX_REVERSE_SPEED, max_forward_speed)
	velocity = Vector2.DOWN.rotated(rotation) * ship_velocity
	
	# "Point" the TrailEmitter's in the right direction
	var ship_speed = abs(ship_velocity) / MAX_FORWARD_SPEED
	var trail_magnitude = ship_speed * MAX_TRAIL_VELOCITY
	var right_velocity = Vector2.DOWN.rotated(rotation - deg_to_rad(TRAIL_ANGLE)) * trail_magnitude
	var left_velocity = Vector2.DOWN.rotated(rotation + deg_to_rad(TRAIL_ANGLE)) * trail_magnitude
	left_trail.point_velocity = left_velocity
	right_trail.point_velocity = right_velocity
	if ship_speed < 0.1:
		left_trail.enabled = false
		right_trail.enabled = false
	else:
		left_trail.enabled = true
		right_trail.enabled = true
		

func _idle_ship() -> void:
	if state != State.ALIVE: return
	
	if _drift_tween:
		_drift_tween.kill()
		
	var drift_rotation: float = randf_range(-DRIFT_ROTATION, DRIFT_ROTATION)
	var drift_pos_rotation: float = randf() * (2*PI)
	var drift_pos: Vector2 = _idle_position + Vector2.DOWN.rotated(drift_pos_rotation) * DRIFT_OFFSET
	_drift_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	_drift_tween.parallel().tween_property(self, "position", drift_pos, 3)
	_drift_tween.parallel().tween_property(self, "rotation_degrees", _idle_rotation_degrees + drift_rotation, 3).from(rotation_degrees)
	_drift_tween.tween_callback(_idle_ship)


## Fire the ship's main cannons
func fire_main_cannon() -> void:
	cannon.fire()


## Check if the ship is currently colliding with land
func last_collision_as_beached() -> BeachHead:
	var last_collision = get_last_slide_collision()
	if last_collision:
		var collider = last_collision.get_collider()
		if collider is Land:
			var land = (collider as Land)
			var island = land.find_island_for_position(last_collision.get_position())
			if island:
				return BeachHead.new(island, last_collision.get_position())
			
	return null


## Apply the correct boat sprite for the ship's current health
func check_health() -> void:
	var health_pct = health / max_health
	if health_pct >= 0.75:
		boat_sprite.apply_state(BoatSprite.State.NEW)
	elif health_pct >= 0.35:
		boat_sprite.apply_state(BoatSprite.State.LIGHT_DMG)
	elif health_pct > 0:
		boat_sprite.apply_state(BoatSprite.State.HEAVY_DMG)
	else:
		boat_sprite.apply_state(BoatSprite.State.DEAD)

## Override this function to implement subclass specific behavior
## when the ship is killed.
func _on_die(source: Faction) -> void:
	pass

## "Kill" the ship and execute all eol functions
func die(source: Faction = null) -> void:
	# Set stats
	health = 0
	ship_velocity = 0
	state = State.SINKING
	
	# Call implementation on-die functions
	_on_die(source)
	
	# Generate floating crew
	crew_cabin.abandon_ship()
	
	## Generate Explosions!
	generate_explosions()
	
	# Tell FactionSystem that we died
	if source:
		FactionSystem.add_kill(source)

## Fade into nothingness and free this node from the tree
func fade_away() -> void:
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate", Color.TRANSPARENT, 10)
	await fade_tween.finished
	queue_free()

func generate_explosions() -> void:
	for i in range(15):
		var offset_rotation = randf() * (2*PI)
		var offset_magnitude = randf() * 75
		var offset = Vector2(1, 0).rotated(offset_rotation) * offset_magnitude
		var delay = randf() * 0.5
		
		var new_exp: Explosion = explosion.instantiate()
		new_exp.global_position = global_position + offset
		new_exp.delay = delay
		SceneSpawnerSystem.add_entity(new_exp)


## Return a crew member to this ship's cabin
func return_crew(amount: int = 1) -> void:
	crew_returned.emit(amount)


## Check if this ship is beached on an Island
func check_if_beached() -> void:
	# Check if we collided with land
	var last_beach = beach_head
	beach_head = last_collision_as_beached()
	if !beach_head and last_beach:
		last_beach.island.remove_beached_ship(self)
		_on_lost_beach_head(last_beach)
	elif beach_head and !last_beach:
		beach_head.island.add_beached_ship(self)

@abstract func _on_lost_beach_head(beach: BeachHead) -> void


## Class to track the island and position that this ship is "beached" upon
## so to orchestrate troop movement and island actions
class BeachHead:
	var island: Island
	var landing_pos: Vector2
	
	func _init(isl: Island, pos: Vector2):
		island = isl
		landing_pos = pos
		
	## Return the global position to spawn crew upon
	func get_landing_position() -> Vector2:
		var island_pos = island.get_inland_position(landing_pos)
		var dir = (landing_pos - island_pos).normalized()
		return island_pos + dir * 64 # one tile offset
