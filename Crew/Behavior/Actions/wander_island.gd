@tool
extends ActionLeaf


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var crew = actor as WalkingCrew
	
	# Check ship is beached, if so exit this script
	if crew.deployment.ship.beach_head and \
	crew.deployment.ship.beach_head.island == crew.deployment.island:
		return FAILURE
		
	# otherwise check if crew is in "Wander" state
	crew.set_wander()
	
	return RUNNING
