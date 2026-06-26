class_name PlayerCamera
extends Camera2D

@onready var camera_shake: CameraShake = %CameraShake

@export var follow: CameraHarness
@export var min_zoom: float = 0.2
@export var max_zoom: float = 1
@export var zoom_smoothing_rate: float = 3
@export var position_smoothing_rate: float = 2000

@onready var _target_zoom: Vector2 = zoom

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	get_viewport().size_changed.connect(_on_viewport_size_changed)
	if follow:
		set_following(follow)


func _physics_process(delta: float) -> void:
	if follow:
		position = position.move_toward(follow.global_position, position_smoothing_rate * delta)
		
	zoom = zoom.move_toward(_target_zoom, zoom_smoothing_rate * delta)


func set_following(harness: CameraHarness, snap: bool = false) -> void:
	if !follow: position = harness.global_position
	follow = harness
	_target_zoom = _compute_zoom(harness.viewport_rect)


func _compute_zoom(size: Vector2) -> Vector2:
	if !size: return Vector2.ONE
	var viewport = get_viewport_rect()
	var vp_scale = viewport.size / size
	var new_zoom = clampf(minf(vp_scale.x, vp_scale.y), min_zoom, max_zoom)
	return Vector2(new_zoom, new_zoom)

func shake() -> void:
	camera_shake.shake()


func add_trauma(amount: float) -> void:
	camera_shake.add_trauma(amount)


func _on_viewport_size_changed() -> void:
	if follow:
		_target_zoom = _compute_zoom(follow.viewport_rect)
