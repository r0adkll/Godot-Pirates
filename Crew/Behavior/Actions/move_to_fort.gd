@tool
extends ActionLeaf

@export var min_dist: float = 36864 #192^2 - radius of medium fort


func tick(actor: Node, blackboard: Blackboard) -> int:
	var crew = actor as WalkingCrew
	
	# Get cached fort
	var fort: Fort = blackboard.get_value(CrewKeys.Key.FORT, null, crew.name)
	if not fort:
		print("Fort missing for %s" % crew.name)
		return FAILURE
	
	# Validate that the fort is still occupiable,
	# If not, remove our target on the fort and decrement the targetted count
	var targetted_count = CrewKeys.get_targetted_count(blackboard, fort)
	var is_full: bool
	if not fort.faction or crew.deployment.faction.equals(fort.faction):
		is_full = fort.crew + targetted_count > fort.max_crew
	else:
		is_full = targetted_count >= fort.crew + fort.max_crew
	if is_full:
		print("Targetted fort[{0}] is full! {1}".format([fort.name, crew.name]))
		blackboard.erase_value(CrewKeys.Key.FORT, crew.name)
		CrewKeys.add_targetted_count(blackboard, fort, -1)
		return FAILURE
	
	# Set target and check dist
	crew.set_target(fort.center)
	
	## Check dist
	var dist = crew.position.distance_squared_to(fort.center)
	if dist > min_dist:
		return RUNNING
	else:
		return SUCCESS
