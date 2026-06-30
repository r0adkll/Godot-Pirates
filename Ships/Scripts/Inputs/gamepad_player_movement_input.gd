extends PlayerInputNode

@export var deadzone: float = 0.2

var left_joystick_vector: Vector2 = Vector2()
var right_joystick_vector: Vector2 = Vector2()

func process_input(delta: float) -> void:
	var ship = get_ship()
	
	left_joystick_vector.x = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	left_joystick_vector.y = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	right_joystick_vector.x = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	right_joystick_vector.y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)

	_turn_ship(ship, delta)
	_aim_cannon(ship)
	

## Turn the ship by the left joystick
func _turn_ship(ship: Ship, delta: float) -> void:
	var length = left_joystick_vector.length()
	if length > deadzone:
		var current_angle = Vector2.DOWN.rotated(ship.rotation)
		var target_angle = left_joystick_vector.angle() - (PI/2)
		
		# Based on how far the user is pushing the sticks, drive the overall velocity
		var magnitude = abs(left_joystick_vector.length())
		ship.ship_velocity += BaseShip.ACCELERATION * magnitude * delta
		
		# Rotate the ship based on the angle of the joystick vector
		var angle_to = current_angle.angle_to(left_joystick_vector)
		var turning_strength = (abs(ship.ship_velocity) / BaseShip.MAX_FORWARD_SPEED) * BaseShip.TURN_ACCELERATION
		ship.rotation = move_toward(ship.rotation, ship.rotation + angle_to, turning_strength * delta)
	else:
		ship.ship_velocity = move_toward(ship.ship_velocity, 0, BaseShip.FRICTION * delta)

func _aim_cannon(ship: Ship) -> void:
	var length = right_joystick_vector.length()
	if length > deadzone:
		var target_angle = right_joystick_vector.angle()
		var magnitude = right_joystick_vector.length()
		ship.cannon.global_rotation = target_angle
		ship.aim_cursor.global_rotation = target_angle
		ship.aim_cursor.offset.x = magnitude * 200
		if !ship.aim_cursor.visible:
			ship.aim_cursor.visible = true
	else:
		if ship.aim_cursor.visible:
			ship.aim_cursor.visible = false
		
func position_cursor_from_angle(ship: Ship, angle_rad: float, x_pixels: float) -> void:
	var center_viewport := ship.to_global(ship.position) # center in viewport/screen coords
	
	# screen-space offset: (right, down) axes
	var offset := Vector2.RIGHT.rotated(angle_rad) * x_pixels
	
	var target := center_viewport# + offset
	Input.warp_mouse(target)
