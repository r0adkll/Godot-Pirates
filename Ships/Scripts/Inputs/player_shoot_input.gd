extends PlayerInputNode


func process_input(ship: Ship, _delta: float) -> void:
	# Fire Cannon on input. Only replicate shots that actually fired
	# locally, and force them on remote peers so their magazine drift
	# can't drop the spawn.
	if Input.is_action_just_pressed("ui_shoot"):
		var did_fire = ship.fire_main_cannon()
		if did_fire:
			if ship.game_camera:
				ship.game_camera.add_trauma(0.18)
			if Lobby.active:
				ship.fire_main_cannon.rpc(true)
