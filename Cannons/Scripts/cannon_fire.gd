class_name CannonFire
extends Node2D
## Muzzle blast for a firing cannon: a quick additive fire flash followed by
## a puff of powder smoke that drifts off. Particles emit in world space
## (local_coords off), so the smoke lingers behind a moving ship instead of
## riding along with the cannon. Frees itself once the smoke has faded.

@onready var flash: CPUParticles2D = $Flash
@onready var smoke: CPUParticles2D = $Smoke


func _ready() -> void:
	flash.emitting = true
	smoke.emitting = true
	# Smoke is the longest-lived emitter; explosiveness < 1 staggers its
	# spawns across part of the lifetime, so pad the wait to cover the tail
	var total: float = smoke.lifetime * (2.0 - smoke.explosiveness)
	await get_tree().create_timer(total).timeout
	queue_free()
