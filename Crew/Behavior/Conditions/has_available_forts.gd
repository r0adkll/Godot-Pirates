@tool
extends ConditionLeaf


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var crew = actor as WalkingCrew
	
	var forts: Array[Fort] = crew.deployment.island.get_fortifications()
	var available_forts: Array[Fort] = forts.filter(
		func (f: Fort):
			return !f.is_full() or !crew.deployment.faction.equals(f.faction)
	)
	
	## If there are available forts, return success
	if not available_forts.is_empty():
		return SUCCESS
	
	## Otherwise return failure
	return FAILURE
