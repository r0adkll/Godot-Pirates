@tool
extends ConditionLeaf


func tick(actor: Node, blackboard: Blackboard) -> int:
	var crew = actor as WalkingCrew

	# A crew already holding a fort claim has work to do — its own claim on
	# the last open slot makes the fort read fully-targetted, and without
	# this check the crew would abandon it mid-walk and board the ship
	# (MoveToFort re-validates the claim and releases it if truly full)
	if blackboard.has_value(CrewKeys.Key.FORT, crew.name):
		return SUCCESS

	# Pull from the blackboard all targeted forts by crew in the blackboard
	var available_forts: Array[Fort] = CrewKeys.get_available_forts(blackboard, crew)
	
	## If there are available forts, return success
	if not available_forts.is_empty():
		return SUCCESS
	
	## Otherwise return failure
	return FAILURE
