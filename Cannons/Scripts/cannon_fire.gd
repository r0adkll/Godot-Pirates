class_name CannonFire
extends Node2D

@onready var cannon_fire_animation: AnimationPlayer = $CannonFireAnimation

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cannon_fire_animation.play("fire")


func _on_cannon_fire_animation_animation_finished(_anim_name: StringName) -> void:
	queue_free()
