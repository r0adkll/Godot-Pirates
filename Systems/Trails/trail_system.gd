class_name TrailSystem
extends Node2D

@export var tick_rate: float = 1
@export var trail_width_curve: Curve
@export var trail_gradient: Gradient
@export var trail_width: float = 20

# Internal trail tracker
var trails: Dictionary = {}
var elapsed: float = 0

var _dead_trails: PackedInt64Array = PackedInt64Array()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	# Accumulate and tick our trail system based on the tick rate
	elapsed += delta
	if elapsed > tick_rate:
		elapsed = elapsed - tick_rate
		_tick()


func _tick() -> void:
	var emitters: Array[Node] = get_tree().get_nodes_in_group(TrailEmitter.GROUP)
	for e in emitters:
		var emitter = e as TrailEmitter
		if !emitter.enabled: 
			continue
			
		var emitter_id = emitter.get_instance_id()
		
		## Check if we have a trail
		var trail = trails.get(emitter_id) as Trail
		if trail:
			trail.add_point(emitter)
		else:
			# Create the visual line configuration for trails
			var line = Line2D.new()
			line.gradient = trail_gradient
			line.width = trail_width
			line.width_curve = trail_width_curve
			line.end_cap_mode = Line2D.LINE_CAP_ROUND
			line.joint_mode = Line2D.LINE_JOINT_ROUND
			
			# Create our new trail 
			var new_trail = Trail.new(emitter_id, emitter.point_lifetime, line)
			new_trail.add_point(emitter)
			trails.set(emitter_id, new_trail)
			add_child(new_trail.line)


## So on every physics pass we should grab all trail_emitter
## nodes and using their unique id, start a procedural line for their
## tail. 
##
## At every 'tick' each emitter should add a point to their line,
## each existing point in a light should apply its emitter velocity
## Then each point should track its own lifetime, and when expired 
## be removed from it's line
func _physics_process(delta: float) -> void:
	# Iterate and update all trails
	for k in trails.keys():
		var trail: Trail = trails[k]
		trail.tick(delta)
		
		if trail.points.is_empty():
			_dead_trails.append(k)
			
	# Clean up any trails that no longer have points
	if !_dead_trails.is_empty():
		for key in _dead_trails:
			var trail: Trail = trails.get(key)
			remove_child(trail.line)
			trails.erase(key)
		_dead_trails.clear()


class Trail:
	var id: float
	var lifetime: float
	var points: Array[TrailPoint] = []
	var dead_points: Array[TrailPoint] = []
	
	var line: Line2D
	
	func _init(trail_id: float, life: float, trail_line: Line2D) -> void:
		self.id = trail_id
		self.lifetime = life
		self.line = trail_line
	
	
	func tick(delta: float) -> void:
		# Update all points position / lifetime
		for idx in points.size():
			var p = points[idx]
			p.position += p.velocity * delta
			p.elapsed += delta
			line.set_point_position(idx, p.position)
			
			if p.elapsed > lifetime:
				dead_points.append(p)
				
		# Clean out any "dead" points from our trail
		if !dead_points.is_empty():
			for idx in dead_points.size():
				var p = dead_points[idx]
				var p_idx = points.find(p)
				points.erase(p)
				line.remove_point(p_idx)
			dead_points.clear()
			
	
	
	func add_point(emitter: TrailEmitter) -> void:
		var new_point = TrailPoint.new(emitter.global_position, emitter.point_velocity)
		points.append(new_point)
		line.add_point(new_point.position)


## Responsible for tracking one point in a line over time
class TrailPoint:
	var position: Vector2  # Position globally
	var velocity: Vector2  # Movement velocity
	var elapsed: float = 0 # The amount of time its been alive (seconds)
	
	func _init(p: Vector2, v: Vector2) -> void:
		self.position = p
		self.velocity = v
