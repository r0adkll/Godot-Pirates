extends Node

signal state_changed(paused: bool)


func pause() -> void:
	get_tree().paused = true
	state_changed.emit(true)


func resume() -> void:
	state_changed.emit(false)
	get_tree().paused = false
