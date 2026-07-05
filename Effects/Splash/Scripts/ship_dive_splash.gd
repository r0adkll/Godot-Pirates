class_name ShipDiveSplash
extends Node2D
## Water burst played when a Dutchman-mode ship dives beneath the waves
## or breaks back through the surface. Spawns staggered foam rings and a
## droplet spray, then frees itself once everything has faded.

const RING_TEXTURE := preload("res://Effects/Splash/Sprites/splash_ring.png")

## Rings are elongated along local Y, the ship's forward axis
const RING_SCALE := Vector2(1.25, 1.9)
const RING_COUNT: int = 3
const RING_INTERVAL: float = 0.14
const RING_DURATION: float = 0.8
## Peak opacity of the first ring; kept low so the droplet spray reads on top
const RING_STRENGTH: float = 0.5

@onready var droplets: CPUParticles2D = $Droplets
@onready var foam: CPUParticles2D = $Foam


func _ready() -> void:
	droplets.emitting = true
	foam.emitting = true
	for i in RING_COUNT:
		_burst_ring(i * RING_INTERVAL, RING_SCALE * (1.0 - i * 0.22), RING_STRENGTH * (1.0 - i * 0.3))

	var lifetime: float = maxf(
		(RING_COUNT - 1) * RING_INTERVAL + RING_DURATION,
		maxf(droplets.lifetime, foam.lifetime)
	)
	await get_tree().create_timer(lifetime).timeout
	queue_free()


## Expand and fade a single foam ring after [param delay] seconds
func _burst_ring(delay: float, end_scale: Vector2, strength: float) -> void:
	var ring := Sprite2D.new()
	ring.texture = RING_TEXTURE
	ring.scale = Vector2.ZERO
	ring.modulate.a = 0.0
	add_child(ring)
	# Keep rings below the foam / droplet layers
	move_child(ring, 0)

	var tween := create_tween().set_parallel()
	tween.tween_property(ring, "scale", end_scale, RING_DURATION) \
		.from(Vector2.ZERO).set_delay(delay) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, RING_DURATION) \
		.from(strength).set_delay(delay)
