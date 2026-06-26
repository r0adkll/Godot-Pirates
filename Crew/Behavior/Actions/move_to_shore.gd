@tool
extends ActionLeaf

@export var min_dist: float = 50


func tick(actor: Node, blackboard: Blackboard) -> int:
	var crew = actor as WalkingCrew
	
	## Check for actors deployment position
	crew.target = crew.deployment.landing_pos
	if crew.distance_squared_to_target() > min_dist * min_dist:
		return RUNNING
	else:
		return SUCCESS
