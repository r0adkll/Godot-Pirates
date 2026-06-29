@tool
extends ActionLeaf


func tick(actor: Node, blackboard: Blackboard) -> int:
	var ship = actor as BotShip
	
	## Check for existing island
	if blackboard.has_value(ShipKeys.Key.ISLAND, ship.name):
		return SUCCESS
		
	var detected_bodies: Array[Node2D] = ship.detection_area.get_overlapping_bodies()
	for body in detected_bodies:
		if is_instance_of(body, Fort) and _is_occupiable(ship, body as Fort):
			var fort = body as Fort
			blackboard.set_value(ShipKeys.Key.ISLAND, fort.island.get_path(), ship.name)
			return SUCCESS
	
	## Clear out any previous existing keys
	blackboard.erase_value(ShipKeys.Key.ISLAND, ship.name)
	
	return FAILURE


func _get_islands() -> Array[Island]:
	var islands: Array[Island] = []
	for node in get_tree().get_nodes_in_group(Island.GROUP):
		islands.append(node as Island)
	return islands


func _is_any_occupiable(ship: BotShip, forts: Array[Fort]) -> bool:
	for fort in forts:
		if _is_occupiable(ship, fort):
			return true
			
	return false


func _is_occupiable(ship: BotShip, fort: Fort) -> bool:
	return CrewKeys.is_fort_available(ship.crew_cabin.blackboard, ship.faction, fort)


func _is_any_fort_close(ship: BotShip, forts: Array[Fort]) -> bool:
	for fort in forts:
		var dist = ship.global_position.distance_to(fort.center)
		if dist < ship.get_detection_radius():
			return true
	return false
