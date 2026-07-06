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
signal sprint_changed(percent: float)

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
const dive_splash := preload("res://Effects/Splash/ship_dive_splash.tscn")
const treasure := preload("res://Resources/treasure.tscn")

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
@export var max_sprint: float = 500

@onready var health: float = max_health:
	set(new_value):
		health = clampf(new_value, 0, max_health)
		
@onready var sprint: float = max_sprint:
	set(new_value):
		sprint = new_value
		sprint_changed.emit(sprint / max_sprint)

@export var coin: int = 0:
	set(new_value):
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
var sprint_modifier: float = SPRINT_MODIFIER
var angular_velocity: float = 0.0
## The un-sprinted cruise speed. Abilities may raise this (e.g. Dutchman);
## SprintInput multiplies it while sprint is held.
var base_forward_speed: float = MAX_FORWARD_SPEED
var max_forward_speed: float = MAX_FORWARD_SPEED
var acceleration: float = ACCELERATION
var is_sprinting: bool:
	get(): return max_forward_speed > base_forward_speed

## Is the ship in "Dutchman" mode
var is_dutchman: bool = false

## How long the submerged state must hold before the visuals commit.
## Guards against single-frame is_sprinting flickers caused by ability
## and input nodes adjusting speeds at different points in the frame.
const SUBMERGE_DEBOUNCE: float = 0.1
var _is_submerged: bool = false
var _submerged_candidate: bool = false
var _submerged_candidate_time: float = 0.0

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
func _process(delta: float) -> void:
	_update_submerged(delta)

	# Apply z-index based on state. A dutchman ship that is "sprinting"
	# shows the boat as going below the surface of the water
	z_index = -1 if _is_submerged else Z_INDEX[state]

	# Check Health and apply visual states
	check_health()


## Track when a dutchman ship crosses the water's surface, kicking up a
## splash on each dive / resurface transition
func _update_submerged(delta: float) -> void:
	var submerged := is_dutchman and is_sprinting and state == State.ALIVE
	if submerged == _is_submerged:
		_submerged_candidate = submerged
		return

	# Debounce: only commit once the new state has held long enough
	if submerged != _submerged_candidate:
		_submerged_candidate = submerged
		_submerged_candidate_time = 0.0
		return

	_submerged_candidate_time += delta
	if _submerged_candidate_time < SUBMERGE_DEBOUNCE:
		return

	_is_submerged = submerged
	if state == State.ALIVE:
		_splash_water()


## Kick up water where the ship broke the surface (diving or resurfacing)
func _splash_water() -> void:
	var splash: ShipDiveSplash = dive_splash.instantiate()
	splash.global_position = global_position
	splash.global_rotation = global_rotation
	SceneSpawnerSystem.add_entity(splash)


func _physics_process(_delta: float) -> void:
	if state == State.ALIVE:
		# Set the idling position when ship is not moving, 
		# but only in local control smode
		if control == LOCAL:
			if ship_velocity == 0 and _idle_position == Vector2.INF and can_drift:
				_idle_position = position
				_idle_rotation_degrees = rotation_degrees
				_idle_ship()
				_on_idle_ship()
			elif ship_velocity != 0 and _idle_position != Vector2.INF:
				_idle_position = Vector2.INF
				_on_stop_idle_ship()
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
	if ship_speed < 0.1 or (is_dutchman and is_sprinting):
		left_trail.enabled = false
		right_trail.enabled = false
	else:
		left_trail.enabled = true
		right_trail.enabled = true


## Override to implement functionality when a ship starts to idle
func _on_idle_ship() -> void:
	pass

func _on_stop_idle_ship() -> void:
	pass

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


## Fire the ship's main cannons. Returns whether a shot actually fired.
## Remote peers pass force=true since the controlling peer already
## validated the shot against its magazine.
@rpc("any_peer", "call_remote", "reliable")
func fire_main_cannon(force: bool = false) -> bool:
	return cannon.fire(force)


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


func check_last_collision_for_treasure() -> void:
	var last_collision = get_last_slide_collision()
	if last_collision:
		var collider = last_collision.get_collider()
		if collider is Treasure:
			if Lobby.active:
				# Only the peer controlling this ship reports the pickup;
				# every peer then applies it so coin/health stay in sync
				if control == LOCAL:
					_collect_treasure.rpc(collider.name)
			else:
				_collect_treasure(collider.name)


@rpc("any_peer", "call_local", "reliable")
func _collect_treasure(treasure_name: String) -> void:
	var collected := SceneSpawnerSystem.entity_owner.get_node_or_null(NodePath(treasure_name))
	if collected == null or not collected is Treasure:
		return
	if collected.is_queued_for_deletion():
		return
	coin += collected.coin
	health += collected.health
	collected.queue_free()


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
@rpc("any_peer", "call_local", "reliable")
func die(source: Faction = null) -> void:
	# Set stats
	health = 0
	ship_velocity = 0
	state = State.SINKING
	
	# Call implementation on-die functions
	_on_die(source)
	
	# Generate floating crew
	crew_cabin.abandon_ship()
	
	# Generate Explosions!
	generate_explosions()
	
	# Drop Treasure!
	drop_treasure()
	
	# Tell FactionSystem that we died
	if source:
		FactionSystem.add_kill(source)

## Fade into nothingness and free this node from the tree
func fade_away() -> void:
	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate", Color.TRANSPARENT, 10)
	await fade_tween.finished
	queue_free()
	
	
## Set the dutchman mode for this ship
func set_dutchman_mode(enabled: bool) -> void:
	is_dutchman = enabled
	var mat := boat_sprite.material as ShaderMaterial
	var tween := create_tween()
	tween.tween_method(
		func(v: float): mat.set_shader_parameter("dutchman_strength", v),
		mat.get_shader_parameter("dutchman_strength"),
		1.0 if enabled else 0.0,
		0.6
	)

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


## Monotonic counter the server uses to give dropped treasure a unique
## name that is identical on every peer
static var _treasure_counter: int = 0

func drop_treasure() -> void:
	# In multiplayer only the server rolls the drops; every peer spawns
	# from the same broadcast spec so positions and contents match
	if Lobby.active and not multiplayer.is_server():
		return

	var specs: Array = []
	for i in 5:
		var offset_rotation = randf() * (2*PI)
		var offset_magnitude = randf() * 75
		var spec: Dictionary = {
			"name": "treasure_%d" % _treasure_counter,
			"position": global_position,
			"rotation": randf_range(-(PI/4), PI / 4),
			"velocity": Vector2.RIGHT.rotated(offset_rotation) * offset_magnitude,
			"friction": randf_range(5, 10),
			"coin": 0,
			"health": 0,
			"state": Treasure.EMPTY,
		}
		if randf() > 0.5:
			spec["coin"] = coin
			spec["state"] = Treasure.COIN
		else:
			spec["health"] = 25
			spec["state"] = Treasure.HEALTH
		_treasure_counter += 1
		specs.append(spec)

	if Lobby.active:
		_spawn_treasure.rpc(specs)
	else:
		_spawn_treasure(specs)


@rpc("authority", "call_local", "reliable")
func _spawn_treasure(specs: Array) -> void:
	for spec in specs:
		var new_treasure: Treasure = treasure.instantiate()
		new_treasure.name = spec["name"]
		new_treasure.coin = spec["coin"]
		new_treasure.health = spec["health"]
		new_treasure.state = spec["state"]
		new_treasure.global_position = spec["position"]
		new_treasure.rotation = spec["rotation"]
		new_treasure.velocity = spec["velocity"]
		new_treasure.friction = spec["friction"]
		SceneSpawnerSystem.add_entity(new_treasure)

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


## Apply the sprint state replicated from this ship's controlling peer.
## is_sprinting derives from max_forward_speed, which only the local
## SprintInput node updates — remote copies need it mirrored so
## sprint-dependent visuals (Dutchman dive, trails) render correctly.
func set_remote_sprinting(sprinting: bool) -> void:
	max_forward_speed = base_forward_speed * (sprint_modifier if sprinting else 1.0)


## Apply the beached state replicated from this ship's controlling peer.
## Remote copies of a ship never move via move_and_slide, so they can't
## detect beaching through collisions like the local simulation does.
func set_remote_beach_head(island_id: int, landing_pos: Vector2) -> void:
	# Clear a stale beach head (left the island, or switched islands)
	if beach_head and (island_id == -1 or beach_head.island.island_id != island_id):
		var last_beach = beach_head
		beach_head = null
		last_beach.island.remove_beached_ship(self)
		_on_lost_beach_head(last_beach)

	if island_id != -1 and not beach_head:
		var island := FactionSystem.get_island(island_id)
		if island:
			beach_head = BeachHead.new(island, landing_pos)
			island.add_beached_ship(self)


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
