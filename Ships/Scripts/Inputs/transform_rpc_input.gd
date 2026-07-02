extends PlayerInputNode

## When enabled, and still alive, communicate its transform info
func process_input(_delta: float) -> void:
	var ship: Ship = get_ship()
	_update_transform.rpc(
		ship.position,
		ship.rotation,
		ship.ship_velocity,
		ship.cannon.global_rotation
	)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func _update_transform(
	position: Vector2,
	rotation: float,
	velocity: float, 
	cannon_rotation: float,
) -> void:
	var ship: Ship = get_ship()
	ship.position = position
	ship.rotation = rotation
	ship.ship_velocity = velocity
	ship.cannon.global_rotation = cannon_rotation
