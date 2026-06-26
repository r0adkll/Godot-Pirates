@tool
extends ActionLeaf

@export var min_dist: float = 36864 #192^2 - radius of medium fort


func tick(actor: Node, blackboard: Blackboard) -> int:
	var crew = actor as WalkingCrew
	
	# Get cached fort
	var fort: Fort = blackboard.get_value(CrewKeys.Key.FORT)
	if not fort:
		return FAILURE
		
	# Set target and check dist
	crew.set_target(fort.center)
	
	## Check dist
	var dist = crew.position.distance_squared_to(fort.center)
	if dist > min_dist:
		return RUNNING
	else:
		return SUCCESS
