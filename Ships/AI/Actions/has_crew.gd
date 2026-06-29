@tool
extends ConditionLeaf


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var ship = actor as BotShip
	
	if ship.crew_cabin.crew > 0:
		return SUCCESS
	
	return FAILURE
