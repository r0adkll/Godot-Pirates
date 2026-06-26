@tool
extends ActionLeaf


func tick(actor: Node, blackboard: Blackboard) -> int:
	var crew = actor as WalkingCrew
	
	# Check if we've already selected a fort
	if blackboard.has_value(CrewKeys.Key.FORT):
		return SUCCESS
	
	# If not attempt to find the closest available fort
	var forts: Array[Fort] = crew.deployment.island.get_fortifications()
	var available_forts: Array[Fort] = forts.filter(
		func (f: Fort):
			return !f.is_full() or !crew.deployment.faction.equals(f.faction)
	)
	
	# Determine what available fort is closest
	var closest_fort: Fort
	var closest_dist_sq: float = float(INT64_MAX)
	for fort in available_forts:
		var dist = crew.global_position.distance_squared_to(fort.global_position)
		if dist < closest_dist_sq:
			closest_fort = fort
			closest_dist_sq = dist
	
	# If we found our closest fort, cache it!
	if closest_fort:
		blackboard.set_value(CrewKeys.Key.FORT, closest_fort)
		return SUCCESS
	
	return FAILURE
