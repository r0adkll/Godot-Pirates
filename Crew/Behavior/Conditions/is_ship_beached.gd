@tool
extends ConditionLeaf


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var crew = actor as WalkingCrew
	
	## Check our deployed island for any beached ships
	var beached_ship = crew.deployment.island.find_closest_beached_ship(crew.global_position, crew.deployment.faction)
	if beached_ship:
		return SUCCESS
	
	return FAILURE
