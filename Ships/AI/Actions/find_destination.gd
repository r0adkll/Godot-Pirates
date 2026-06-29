@tool
extends ActionLeaf


func tick(actor: Node, blackboard: Blackboard) -> int:
	var ship = actor as BotShip
	
	# Check for cached value
	var destination: Vector2 = blackboard.get_value(ShipKeys.Key.DESTINATION, Vector2.INF, ship.name)
	if destination == Vector2.INF:
		destination = ship.ships_system.get_position_near_player()
		blackboard.set_value(ShipKeys.Key.DESTINATION, destination, ship.name)
	
	# Update nav agent with new destination, if different
	if ship.nav_agent.target_position != destination:
		ship.nav_agent.target_position = destination
	
	return SUCCESS
