class_name FloatingCrew
extends Area2D

@onready var sprite: Sprite2D = $Sprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var detection_area: Area2D = $DetectionArea

var direction: Vector2 = Vector2.ZERO
var swim_speed: float = 100.0
var friction: float = 30.0
var velocity: Vector2 = Vector2.ZERO
var _boarding_velocity: float = 0.0

# The target vessel the crew member should be swimming toward
var origin: CrewCabin
var _target: CrewCabin

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Set velocity
	velocity = direction * swim_speed
	
	# Pick a random crew sprite image
	var idx = randi_range(1, 6)
	sprite.texture = load("res://Crew/Sprites/crew_%d.png" % idx)
	sprite.scale = Vector2(2, 2)
	
	# Connect to area signals
	detection_area.body_entered.connect(_on_detection_area_body_entered)
	detection_area.body_exited.connect(_on_detection_area_body_exited)


func _physics_process(delta: float) -> void:
	if _target == null:
		# If the member is not actively swimming, then they should
		# slow to tred water.
		velocity -= velocity.normalized() * friction * delta
	else:
		# If the member sees a vessel, then actively swim towards it
		_boarding_velocity += swim_speed
		velocity = Vector2.RIGHT.rotated(get_angle_to(_target.global_position)) * _boarding_velocity * delta
		
	# Move the floating crew member by its velocity
	position += velocity * delta
	
	# Detect if we are colliding with a ship
	var cabin = _find_first_detected_crew_cabin(self)
	if cabin and cabin != origin:
		cabin.add_crew(1)
		queue_free()
		
	# If target becomes full, quit targetting
	if _target and !_target.has_space():
		_target = null
		
		
func _find_first_detected_crew_cabin(area: Area2D) -> CrewCabin:
	var bodies = area.get_overlapping_bodies()
	for body in bodies:
		var crew_cabin = body.get_node_or_null("CrewCabin")
		if crew_cabin and crew_cabin is CrewCabin and crew_cabin != origin and crew_cabin.has_space():
			return crew_cabin
	
	return null


func _on_drowning_timer_timeout() -> void:
	animation_player.play(&"drowning")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"drowning":
		queue_free()


func _on_detection_area_body_entered(body: Node2D) -> void:
	if !_target:
		var cabin = _has_crew_cabin(body)
		if cabin:
			_target = cabin
		
	
func _has_crew_cabin(body: Node2D) -> CrewCabin:
	var crew_cabin = body.get_node_or_null("CrewCabin")
	if crew_cabin and crew_cabin is CrewCabin and crew_cabin != origin and crew_cabin.has_space():
		return crew_cabin

	return null	

	
func _on_detection_area_body_exited(body: Node2D) -> void:
	var cabin = _has_crew_cabin(body)
	if _target == cabin:
		_target = null
