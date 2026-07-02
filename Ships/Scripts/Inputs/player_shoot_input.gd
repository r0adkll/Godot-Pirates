extends PlayerInputNode


func process_input(_delta: float) -> void:
	# Fire Cannon on input
	if Input.is_action_just_pressed("ui_shoot"):
		if multiplayer.has_multiplayer_peer():
			## Instruct the server to fire for us
			get_ship().fire_main_cannon()
			fire_cannons.rpc()
		else:
			get_ship().fire_main_cannon()


@rpc("any_peer", "call_remote", "reliable")
func fire_cannons() -> void:
	get_ship().fire_main_cannon()
