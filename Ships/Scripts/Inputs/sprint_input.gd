extends PlayerInputNode

@export var sprint_drain_rate: float = 100.0
@export var sprint_gain_rate: float = 50.0

func process_input(ship: Ship, delta: float) -> void:
	# Apply Sprint - TODO POWER UP
	if Input.is_action_pressed("ui_sprint") and ship.sprint > 0:
		ship.sprint = move_toward(ship.sprint, 0, sprint_drain_rate * delta)
		ship.max_forward_speed = BaseShip.MAX_FORWARD_SPEED * BaseShip.SPRINT_MODIFIER
	else:
		ship.max_forward_speed = BaseShip.MAX_FORWARD_SPEED
		ship.sprint = move_toward(ship.sprint, ship.max_sprint, sprint_gain_rate * delta)
