@tool
class_name HealthBar
extends Control

@onready var background: NinePatchRect = $Background
@onready var low: NinePatchRect = $Low
@onready var full: NinePatchRect = $Full

@export_range(0, 1, 0.1) var progress: float = 1.0:
	set(new_value):
		progress = new_value
		if is_visible_in_tree():
			_update_bar_width()
			
@export_range(0, 1, 0.1) var low_threshold: float = 0.3

@export var low_texture: Texture2D
@export var full_texture: Texture2D


func _ready() -> void:
	low.texture = low_texture
	full.texture = full_texture

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Keep the width of the progress bars 
	_update_bar_width()
	
	# Switch texture visibility based on threshold
	low.visible = progress <= low_threshold && progress > 0
	full.visible = progress > low_threshold


func _update_bar_width() -> void:
	# Keep the width of the progress bars 
	low.size.x = _progress_width()
	full.size.x = _progress_width()
	background.size.x = size.x

## Compute the progress width size of child elements
func _progress_width() -> float:
	var margin = (2 * low.patch_margin_left)
	var width = size.x - margin
	return width * progress + margin
