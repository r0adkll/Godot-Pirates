extends PlayerInputNode


func process_input(ship: Ship, _delta: float) -> void:
	# Fire Cannon on input
	if Input.is_action_just_pressed("ui_shoot"):
		if Lobby.active:
			## Instruct the server to fire for us
			ship.fire_main_cannon()
			ship.fire_main_cannon.rpc()
		else:
			ship.fire_main_cannon()
