extends PlayerInputNode
## Drives the ship from the on-screen virtual joysticks.
## Mirrors gamepad_player_movement_input.gd with the stick source swapped from
## joypad axes to the TouchControls joysticks (whose values are already
## deadzone-filtered).

@export var touch_controls: TouchControls


func process_input(ship: Ship, delta: float) -> void:
	_turn_ship(ship, touch_controls.left_joystick.value, delta)
	_aim_cannon(ship, touch_controls.right_joystick.value)


## Turn the ship by the left joystick
func _turn_ship(ship: Ship, stick: Vector2, delta: float) -> void:
	if stick != Vector2.ZERO:
		var current_angle = Vector2.DOWN.rotated(ship.rotation)

		# Based on how far the user is pushing the stick, drive the overall velocity
		ship.ship_velocity += ship.acceleration * stick.length() * delta

		# Rotate the ship based on the angle of the joystick vector
		var angle_to = current_angle.angle_to(stick)
		var turning_strength = (abs(ship.ship_velocity) / BaseShip.MAX_FORWARD_SPEED) * BaseShip.TURN_ACCELERATION
		ship.rotation = move_toward(ship.rotation, ship.rotation + angle_to, turning_strength * delta)
	else:
		ship.ship_velocity = move_toward(ship.ship_velocity, 0, BaseShip.FRICTION * delta)


func _aim_cannon(ship: Ship, stick: Vector2) -> void:
	if stick != Vector2.ZERO:
		var target_angle = stick.angle()
		ship.cannon.global_rotation = target_angle
		ship.aim_cursor.global_rotation = target_angle
		ship.aim_cursor.offset.x = stick.length() * 200
		if !ship.aim_cursor.visible:
			ship.aim_cursor.visible = true
	else:
		if ship.aim_cursor.visible:
			ship.aim_cursor.visible = false
