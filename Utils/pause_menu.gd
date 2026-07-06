extends Node

signal state_changed(paused: bool)


func pause() -> void:
	# Never halt the simulation in multiplayer; the world keeps moving
	# for every other peer, so just overlay the menu
	if not Lobby.active:
		get_tree().paused = true
	state_changed.emit(true)


func resume() -> void:
	state_changed.emit(false)
	get_tree().paused = false
