extends Node2D
## Sonar-style highlight: a white ring that expands outward and fades,
## then repeats. Replaces the old PointLight2D glow — 2D lights force
## lit shader variants to compile in the Compatibility renderer, which
## hard-freezes the tab on web the first time one spawns.

@export var min_radius: float = 14
@export var max_radius: float = 100
@export var period: float = 2
@export var min_width: float = 8
@export var max_width: float = 16
@export var color: Color = Color.WHITE
@export var curve: Curve

var _time: float = 0.0

func _process(delta: float) -> void:
	_time = fmod(_time + delta, period)
	queue_redraw()

func _width(progress: float) -> float:
	var curved_progress = curve.sample(progress)
	return min_width + ((max_width - min_width) * curved_progress)

func _draw() -> void:
	var t = _time / period
	var radius = lerpf(min_radius, max_radius, t)
	var ring_color = color
	
	ring_color.a *= curve.sample(t)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, ring_color, _width(t), true)
