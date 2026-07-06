extends PlayerInputNode

## When enabled, and still alive, communicate its transform info
func process_input(ship: Ship, _delta: float) -> void:
	# Remote peers can't detect beaching (their copy of this ship never
	# moves via move_and_slide), so the beached state rides along with
	# the transform. Crew count rides along too so cabins stay reconciled.
	var island_id: int = -1
	var landing_pos: Vector2 = Vector2.ZERO
	if ship.beach_head:
		island_id = ship.beach_head.island.island_id
		landing_pos = ship.beach_head.landing_pos

	_update_transform.rpc(
		ship.position,
		ship.rotation,
		ship.ship_velocity,
		ship.cannon.global_rotation,
		island_id,
		landing_pos,
		ship.crew_cabin.crew,
	)

@rpc("any_peer", "call_remote", "unreliable_ordered")
func _update_transform(
	position: Vector2,
	rotation: float,
	velocity: float,
	cannon_rotation: float,
	beached_island_id: int,
	landing_pos: Vector2,
	crew_count: int,
) -> void:
	var ship: Ship = get_ship()
	ship.position = position
	ship.rotation = rotation
	ship.ship_velocity = velocity
	ship.cannon.global_rotation = cannon_rotation
	ship.set_remote_beach_head(beached_island_id, landing_pos)
	ship.crew_cabin.set_crew(crew_count)
