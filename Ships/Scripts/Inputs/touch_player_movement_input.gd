class_name TouchPlayerMovementInput
extends PlayerInputNode
## Drives the ship from the on-screen virtual joysticks.
## Mirrors gamepad_player_movement_input.gd with the stick source swapped from
## joypad axes to the TouchControls joysticks (whose values are already
## deadzone-filtered). While the aim (right) stick is held, the main cannon
## auto-fires — touch players can't aim a stick and press a button with the
## same thumb.

@export var touch_controls: TouchControls
## Seconds between auto-fired shots while aiming (ammo is still gated by the magazine)
@export var auto_fire_interval: float = 0.6

var _fire_cooldown: float = 0.0


func process_input(ship: Ship, delta: float) -> void:
	_turn_ship(ship, touch_controls.left_joystick.value, delta)
	_aim_cannon(ship, touch_controls.right_joystick.value)
	_auto_fire(ship, touch_controls.right_joystick.value, delta)


## Whether the player currently has a finger on either joystick
func is_engaged() -> bool:
	return is_instance_valid(touch_controls) \
			and (touch_controls.left_joystick.is_engaged() or touch_controls.right_joystick.is_engaged())


## Fire the main cannon at a fixed cadence while the aim stick is held.
## Same multiplayer-aware path as player_shoot_input.gd.
func _auto_fire(ship: Ship, stick: Vector2, delta: float) -> void:
	_fire_cooldown = maxf(0.0, _fire_cooldown - delta)
	if stick != Vector2.ZERO:
		if _fire_cooldown == 0.0:
			_fire_cooldown = auto_fire_interval
			ship.fire_main_cannon()
			if Lobby.active:
				ship.fire_main_cannon.rpc()
	else:
		# First shot fires the moment aiming starts
		_fire_cooldown = 0.0


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
