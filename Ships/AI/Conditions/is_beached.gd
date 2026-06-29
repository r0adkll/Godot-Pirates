@tool
extends ConditionLeaf


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var ship = actor as BotShip
	if ship.beach_head:
		# If we are beached, as an action, then stop the ship so we don't slide around
		ship.ship_velocity = 0
		return SUCCESS
	else:
		return FAILURE
