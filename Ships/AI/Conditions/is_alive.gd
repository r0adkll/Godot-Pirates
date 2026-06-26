@tool
extends ConditionLeaf


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var ship = actor as BaseShip
	if ship.state == BaseShip.State.ALIVE:
		return SUCCESS
	else:
		return FAILURE
