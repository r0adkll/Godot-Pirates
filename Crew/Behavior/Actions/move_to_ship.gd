@tool
extends ActionLeaf

@export var min_dist: float = 50


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var crew = actor as WalkingCrew
	
	var beached_ship = crew.deployment.island.find_closest_beached_ship(crew.global_position, crew.deployment.faction)
	if not beached_ship or not beached_ship.beach_head:
		return FAILURE
	
	var _target = beached_ship.beach_head.get_landing_position()
			
	## Set target
	crew.set_target(_target)
	
	## Check dist
	var dist = crew.position.distance_squared_to(_target)
	if dist > min_dist * min_dist:
		return RUNNING
	else:
		return SUCCESS
