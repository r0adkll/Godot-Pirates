class_name HealthBar
extends Control

@onready var background: NinePatchRect = $Background
@onready var low: NinePatchRect = $Low
@onready var full: NinePatchRect = $Full

@export_range(0, 1, 0.1) var progress: float = 1.0
@export_range(0, 1, 0.1) var low_threshold: float = 0.3


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Keep the width of the progress bars 
	low.size.x = _progress_width()
	full.size.x = _progress_width()
	
	# Switch texture visibility based on threshold
	low.visible = progress <= low_threshold && progress > 0
	full.visible = progress > low_threshold


## Compute the progress width size of child elements
func _progress_width() -> float:
	var margin = (2 * low.patch_margin_left)
	var width = size.x - margin
	return width * progress + margin
