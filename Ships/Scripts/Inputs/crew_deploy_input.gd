extends PlayerInputNode


func process_input(ship: Ship, _delta: float) -> void:
	if Input.is_action_just_pressed("ui_deploy"):
		# Validate on the initiating peer — remote peers never see this
		# ship's beach_head collision, so the full deployment spec has to
		# travel with the rpc
		if not ship.beach_head or ship.crew_cabin.crew <= 0:
			return
		var island_id: int = ship.beach_head.island.island_id
		var landing_pos: Vector2 = ship.beach_head.get_landing_position()
		var deploy_rotation: float = ship.rotation + (PI/2)
		if Lobby.active:
			deploy_crew.rpc(island_id, landing_pos, deploy_rotation)
		else:
			deploy_crew(island_id, landing_pos, deploy_rotation)


@rpc("any_peer", "call_local", "reliable")
func deploy_crew(island_id: int, landing_pos: Vector2, deploy_rotation: float) -> void:
	var ship: Ship = get_ship()
	var island := FactionSystem.get_island(island_id)
	if not island:
		return
	ship.crew_cabin.deploy(ship, island, landing_pos, deploy_rotation)
