extends PlayerInputNode


func process_input(_delta: float) -> void:
	var ship = get_ship()
	
	# Apply Sprint - TODO POWER UP
	if Input.is_action_pressed("ui_sprint"):
		ship.max_forward_speed = BaseShip.MAX_FORWARD_SPEED * BaseShip.SPRINT_MODIFIER
	else:
		ship.max_forward_speed = BaseShip.MAX_FORWARD_SPEED
