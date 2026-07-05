extends ShipAbility


func activate(ship: Ship) -> void:
	ship.set_dutchman_mode(true)
	ship.set_collision_mask_value(2, false)
	ship.set_collision_layer_value(2, false)
	ship.sprint_modifier = 3.0
	ship.base_forward_speed = 650
	ship.max_forward_speed = 650
	ship.acceleration = 450


func deactivate(ship: Ship) -> void:
	ship.set_dutchman_mode(false)
	ship.set_collision_mask_value(2, true)
	ship.set_collision_layer_value(2, true)
	ship.sprint_modifier = BaseShip.SPRINT_MODIFIER
	ship.base_forward_speed = BaseShip.MAX_FORWARD_SPEED
	ship.max_forward_speed = BaseShip.MAX_FORWARD_SPEED
	ship.acceleration = BaseShip.ACCELERATION
