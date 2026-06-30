@tool
class_name ShipPathFollower
extends PathFollow2D

@export var editor_enabled: bool = true
@export var speed: float = 300

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Engine.is_editor_hint() and not editor_enabled:
		return
		
	progress += speed * delta
