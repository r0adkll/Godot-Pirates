@tool
extends ActionLeaf


func tick(actor: Node, blackboard: Blackboard) -> int:
	var crew = actor as WalkingCrew
	
	# Get cached fort
	var fort: Fort = blackboard.get_value(CrewKeys.Key.FORT)
	if not fort:
		return FAILURE
		
	# If fort is not same faction and has crew, decrement crew
	if fort.faction and !fort.faction.equals(crew.deployment.faction) and fort.crew > 0:
		print("Reducing fort faction[%s] crew by 1" % fort.faction.id)
		fort.crew -= 1
		crew.queue_free()
		return SUCCESS
	elif not fort.faction or fort.faction.equals(crew.deployment.faction) or fort.crew <= 0:
		fort.crew += 1
		fort.faction = crew.deployment.faction
		crew.queue_free()
		print("Gaining fort!")
		return SUCCESS
	
	
	return FAILURE
