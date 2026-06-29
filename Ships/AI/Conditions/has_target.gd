@tool
extends ConditionLeaf


func tick(actor: Node, blackboard: Blackboard) -> int:
	var ship = actor as BotShip
	if ship.target:
		# Clear any old destinations so when we stop attacking, or w/e
		# other action we can then patrol to a new dest
		blackboard.erase_value(ShipKeys.Key.DESTINATION, ship.name)
		return SUCCESS
	else:
		return FAILURE
