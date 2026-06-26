extends PlayerInputNode


func process_input(delta: float) -> void:
	var ship = get_ship()
	
	# Apply Speed Input
	if Input.is_action_pressed("ui_up"):
		ship.ship_velocity += BaseShip.ACCELERATION * delta
	elif Input.is_action_pressed("ui_down"):
		ship.ship_velocity -= BaseShip.ACCELERATION * delta
	else:
		ship.ship_velocity = move_toward(ship.ship_velocity, 0, BaseShip.FRICTION * delta)
		
	# Apply Rotational Input
	var turning_strength = (abs(ship.ship_velocity) / BaseShip.MAX_FORWARD_SPEED) * BaseShip.TURN_ACCELERATION
	if Input.is_action_pressed("ui_right"):
		if ship.angular_velocity < 0:
			ship.angular_velocity = 0
		ship.angular_velocity += turning_strength * delta
	elif Input.is_action_pressed("ui_left"):
		if ship.angular_velocity > 0:
			ship.angular_velocity = 0
		ship.angular_velocity -= turning_strength * delta
	else:
		ship.angular_velocity = move_toward(ship.angular_velocity, 0, BaseShip.TURN_FRICTION * delta)
		
	# Apply Sprint - TODO POWER UP
	if Input.is_action_pressed("ui_sprint"):
		ship.max_forward_speed = BaseShip.MAX_FORWARD_SPEED * BaseShip.SPRINT_MODIFIER
	else:
		ship.max_forward_speed = BaseShip.MAX_FORWARD_SPEED
