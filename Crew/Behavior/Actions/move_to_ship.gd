@tool
extends ActionLeaf

@export var min_dist: float = 50


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var crew = actor as WalkingCrew
	
	## EITHER, set crew target to ship active beached location, or last seen
	if crew.deployment.ship.beach_head:
		if crew.deployment.ship.beach_head.island == crew.deployment.island:
			var _target = crew.deployment.ship.beach_head.landing_pos
			
			## Set target
			crew.set_target(_target)
			
			## Check dist
			var dist = crew.position.distance_squared_to(_target)
			if dist > min_dist * min_dist:
				return RUNNING
			else:
				return SUCCESS

	return FAILURE
