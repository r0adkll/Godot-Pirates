class_name SplashEffect
extends Node2D

## Signal to capture when this effect finishes
signal splash_finished

## Remove the splash node when finished
func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	splash_finished.emit()
