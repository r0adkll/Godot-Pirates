@tool
extends ConditionLeaf


func tick(actor: Node, blackboard: Blackboard) -> int:
	if blackboard.has_value(ShipKeys.Key.ISLAND, actor.name):
		return SUCCESS
	else:
		return FAILURE
