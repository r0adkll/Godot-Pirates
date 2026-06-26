@tool
extends ActionLeaf


func tick(actor: Node, blackboard: Blackboard) -> int:
	var ship = actor as BotShip
	
	# Breakout of this action if we lost the target or we died
	if not ship.target or ship.state != BaseShip.State.ALIVE:
		return FAILURE
	
	var dist = ship.position.distance_to(ship.target.position)
	if dist > ship.shooting_distance:
		# Accelerate the ship
		ship.ship_velocity += BaseShip.ACCELERATION * get_physics_process_delta_time()
	else:
		# Decelerate the ship
		ship.ship_velocity = move_toward(ship.ship_velocity, 0, BaseShip.FRICTION * get_physics_process_delta_time())
	
	# Apply Rotational Input
	#ship.rotation = ship.rotation + ship.get_angle_to(ship.target.position) - (PI/2)
	var rotation_to_target = ship.rotation + ship.get_angle_to(ship.target.global_position) - (PI/2)
	var turning_strength = (abs(ship.ship_velocity) / BaseShip.MAX_FORWARD_SPEED) * BaseShip.TURN_ACCELERATION
	#if rotation_to_target < 0:
		#ship.angular_velocity += turning_strength * get_physics_process_delta_time()
	#elif rotation_to_target > 0:
		#ship.angular_velocity -= turning_strength * get_physics_process_delta_time()
	#else:
		#ship.angular_velocity = move_toward(ship.angular_velocity, 0, BaseShip.TURN_ACCELERATION)
		
	var max_turning_strength = (abs(ship.ship_velocity) / BaseShip.MAX_FORWARD_SPEED) * BaseShip.TURN_ACCELERATION
	#ship.angular_velocity = clampf(ship.angular_velocity, -max_turning_strength, max_turning_strength)
	#ship.rotation += ship.angular_velocity * get_physics_process_delta_time()

	ship.rotation = move_toward(ship.rotation, rotation_to_target, max_turning_strength * get_physics_process_delta_time())

	return RUNNING
