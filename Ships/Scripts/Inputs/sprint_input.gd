extends PlayerInputNode

@export var sprint_drain_rate: float = 100.0
@export var sprint_gain_rate: float = 75.0

func process_input(ship: Ship, delta: float) -> void:
	# Apply Sprint - TODO POWER UP
	if Input.is_action_pressed("ui_sprint") and ship.sprint > 0:
		var ship_speed_rate = clampf(ship.ship_velocity / BaseShip.MAX_BEACHING_FORWARD_SPEED, 0, 1)
		ship.sprint = move_toward(ship.sprint, 0, sprint_drain_rate * ship_speed_rate * delta)
		ship.max_forward_speed = BaseShip.MAX_FORWARD_SPEED * ship.sprint_modifier
	else:
		ship.max_forward_speed = BaseShip.MAX_FORWARD_SPEED
		ship.sprint = move_toward(ship.sprint, ship.max_sprint, sprint_gain_rate * delta)
