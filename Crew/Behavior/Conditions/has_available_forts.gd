@tool
extends ConditionLeaf


func tick(actor: Node, blackboard: Blackboard) -> int:
	var crew = actor as WalkingCrew
	
	# Pull from the blackboard all targeted forts by crew in the blackboard
	var available_forts: Array[Fort] = CrewKeys.get_available_forts(blackboard, crew)
	
	## If there are available forts, return success
	if not available_forts.is_empty():
		return SUCCESS
	
	## Otherwise return failure
	return FAILURE
