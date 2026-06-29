@tool
extends ActionLeaf

func tick(actor: Node, blackboard: Blackboard) -> int:
	var ship = actor as BotShip
	
	var island_node_path = blackboard.get_value(ShipKeys.Key.ISLAND, null, ship.name)
	if not island_node_path:
		print("Island NodePath: %s" % island_node_path)
		return FAILURE
	
	var island: Island = get_node_or_null(island_node_path)
	if not island:
		print("Island Node: %s" % island_node_path)
		blackboard.erase_value(ShipKeys.Key.ISLAND, ship.name)
		return FAILURE
		
		
	var closest_fort = _get_cached_closest_fort(blackboard, ship, island)
	ship.max_forward_speed = BaseShip.MAX_BEACHING_FORWARD_SPEED
	ship.ship_velocity += BaseShip.ACCELERATION * get_physics_process_delta_time()
	ship.rotation = ship.global_position.angle_to_point(closest_fort.center) - (PI/2)
	
	return SUCCESS


func _get_cached_closest_fort(blackboard: Blackboard, ship: BotShip, island: Island) -> Fort:
	# Pull from cache if available
	var cache_key = "island_navigation_%s" % island.get_instance_id()
	var _cached_node_path = blackboard.get_value(cache_key, null)
	if _cached_node_path:
		var _cached_fort: Fort = get_node_or_null(_cached_node_path)
		if _cached_fort:
			return _cached_fort
	
	var closest_fort: Fort
	var closest_dist: float = float(INT64_MAX)
	for fort in island.get_fortifications():
		var dist = ship.global_position.distance_squared_to(fort.center)
		if dist < closest_dist:
			closest_fort = fort
			closest_dist = dist
			
	# Cache our find
	if closest_fort:
		blackboard.set_value(cache_key, closest_fort.get_path())
	
	return closest_fort
