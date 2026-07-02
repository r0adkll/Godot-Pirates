extends PlayerInputNode


func process_input(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_deploy"):
		if multiplayer.has_multiplayer_peer():
			deploy_crew.rpc()
		else:
			deploy_crew()


@rpc("any_peer", "call_local", "reliable")
func deploy_crew() -> void:
	var ship: Ship = get_ship()
	if ship.beach_head and ship.crew_cabin.crew > 0:
		ship.crew_cabin.deploy(
			ship, 
			ship.beach_head.island, 
			ship.beach_head.get_landing_position(), 
			ship.rotation + (PI/2),
		)
