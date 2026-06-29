@tool
extends ActionLeaf


func tick(actor: Node, blackboard: Blackboard) -> int:
	var ship = actor as BotShip
	
	# Validate that we still have a destination
	if not blackboard.has_value(ShipKeys.Key.DESTINATION, ship.name):
		return FAILURE
	
	# Check if we've finished our current patrol
	if ship.nav_agent.is_navigation_finished():
		# Clear current destination, as we've reached our target
		blackboard.erase_value(ShipKeys.Key.DESTINATION, ship.name)
		return SUCCESS
	
	# Process nav agent and movement
	var next_position: Vector2 = ship.nav_agent.get_next_path_position()
	var target_angle: float = ship.global_position.angle_to_point(next_position) - (PI/2)
	ship.max_forward_speed = BaseShip.MAX_PATROL_FORWARD_SPEED
	ship.ship_velocity += BaseShip.ACCELERATION * get_physics_process_delta_time()
	
	var max_turning_strength: float = (abs(ship.ship_velocity) / BaseShip.MAX_FORWARD_SPEED) * BaseShip.TURN_ACCELERATION
	if abs(target_angle) > PI/2:
		ship.rotation = target_angle
	else:
		ship.rotation = move_toward(ship.rotation, target_angle, max_turning_strength * get_physics_process_delta_time())
	
	return SUCCESS
