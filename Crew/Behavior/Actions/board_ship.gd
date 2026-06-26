@tool
extends ActionLeaf


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var crew = actor as WalkingCrew
	
	crew.deployment.ship.return_crew(1)
	crew.queue_free()
		
	return SUCCESS
