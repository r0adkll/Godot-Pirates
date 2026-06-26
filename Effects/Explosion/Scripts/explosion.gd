class_name Explosion
extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var delay_timer: Timer = $DelayTimer
@onready var sfx: ExplosionSfx = $Sfx

var delay: float = 0.0

func _ready() -> void:
	if delay > 0:
		visible = false
		delay_timer.start(delay)
	else:
		sprite.play()
		sfx.play_random()


func _on_animated_sprite_2d_animation_finished() -> void:
	if !sfx.is_playing:
		queue_free()
	else:
		visible = false


func _on_delay_timer_timeout() -> void:
	visible = true
	sprite.play()


func _on_sfx_finished() -> void:
	queue_free()
