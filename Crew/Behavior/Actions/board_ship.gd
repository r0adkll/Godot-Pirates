@tool
extends ActionLeaf


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var crew = actor as WalkingCrew
	
	var beached_ship = crew.deployment.island.find_closest_beached_ship(crew.global_position, crew.deployment.faction)
	if not beached_ship or not beached_ship.beach_head:
		return FAILURE
	
	beached_ship.return_crew(1)
	crew.queue_free()
		
	return SUCCESS
