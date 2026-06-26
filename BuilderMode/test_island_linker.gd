extends Node

@onready var treasure_map: TreasureMap = $".."
@onready var player_camera: PlayerCamera = $"../../PlayerCamera"

var island: Island

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_treasure_map_islands_updated() -> void:
	for child in treasure_map.get_children():
		if is_instance_of(child, Island):
			island = child as Island
	
	if island:
		player_camera.set_following(island.camera_harness)
	
	
