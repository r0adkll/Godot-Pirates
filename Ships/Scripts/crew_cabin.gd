class_name CrewCabin
extends Node2D

signal crew_updated(count: int, max: int)

const floating_crew := preload("res://Crew/floating_crew.tscn")
const walking_crew := preload("res://Crew/walking_crew.tscn")

# The amount of crew above the vessel/structure this is attached to
@export var crew: int = 6
@export var max_crew: int = 20
@export var blackboard: Blackboard = Blackboard.new()

func _ready() -> void:
	add_child(blackboard)
	crew_updated.emit(crew, max_crew)


func has_space() -> bool:
	return crew < max_crew


func add_crew(amount: int) -> void:
	crew += amount
	crew = clampi(crew, 0, max_crew)
	crew_updated.emit(crew, max_crew)


func deploy(
	ship: BaseShip, 
	island: Island, 
	landing_pos: Vector2, 
	deploy_rotation: float,
) -> void:
	# Create a new crew entity to deploy
	var new_crew: WalkingCrew = walking_crew.instantiate()
	new_crew.global_position = landing_pos
	new_crew.rotation = deploy_rotation
	#new_crew.add_collision_exception_with(ship)
	new_crew.deployment = WalkingCrew.Deployment.new(ship.faction, island, landing_pos)
	new_crew.blackboard = blackboard
	SceneSpawnerSystem.add_entity(new_crew)
	
	# Decrease our crew count and update signal watchers
	crew -= 1
	crew = clampi(crew, 0, max_crew)
	crew_updated.emit(crew, max_crew)


# Dump all crew member's into the 'Water' to be picked up by any vessel
func abandon_ship() -> void:
	for i in range(crew):
		# Evenly disperse the crew
		var rotation_jitter_amt = deg_to_rad(20)
		var rotation_jitter = randf_range(-rotation_jitter_amt, rotation_jitter_amt)
		var offset_rotation = ((2*PI) / crew) * i + rotation_jitter
		
		var new_crew: FloatingCrew = floating_crew.instantiate()
		new_crew.position = global_position
		new_crew.direction = Vector2(1, 0).rotated(offset_rotation)
		new_crew.swim_speed = randf_range(80, 120)
		new_crew.friction = randf_range(28, 32)
		new_crew.origin = self
		SceneSpawnerSystem.add_entity(new_crew)
	
	# Set crew to 0, and emit an update to the state
	crew = 0
	crew_updated.emit(0, max_crew)
	
