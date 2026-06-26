@tool
extends ActionLeaf


func tick(actor: Node, blackboard: Blackboard) -> int:
	var ship = actor as BotShip
	
	# Breakout of this action if we lost the target or we died
	if not ship.target or ship.state != BaseShip.State.ALIVE:
		return FAILURE
	
	# Check if still has target
	var last_update: float = blackboard.get_value(ShipKeys.Key.LAST_TARGET_UPDATE, 0)
	last_update += get_physics_process_delta_time()
	if ship.state == BaseShip.State.ALIVE and ship.target and last_update > 0.5:
		ship.nav_agent.target_position = ship.target.global_position
		last_update = 0
	blackboard.set_value(ShipKeys.Key.LAST_TARGET_UPDATE, last_update)
	
	# Update nav agent
	var next_position: Vector2 = ship.nav_agent.get_next_path_position()
	var target_angle: float = ship.global_position.angle_to_point(next_position) - (PI/2)
	
	ship.max_forward_speed = BaseShip.MAX_FORWARD_SPEED
	var dist = ship.position.distance_to(ship.target.position)
	if dist > ship.shooting_distance:
		# Accelerate the ship
		ship.ship_velocity += BaseShip.ACCELERATION * get_physics_process_delta_time()
	else:
		# Decelerate the ship
		ship.ship_velocity = move_toward(ship.ship_velocity, 0, BaseShip.FRICTION * get_physics_process_delta_time())
	
	var max_turning_strength: float = (abs(ship.ship_velocity) / BaseShip.MAX_FORWARD_SPEED) * BaseShip.TURN_ACCELERATION
	if abs(target_angle) > PI/2:
		ship.rotation = target_angle
	else:
		ship.rotation = move_toward(ship.rotation, target_angle, max_turning_strength * get_physics_process_delta_time())

	
	return RUNNING
