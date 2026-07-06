@tool
extends ActionLeaf

## Half-extent of the fort footprint (384px medium fort) — the crew garrisons
## as soon as it touches the footprint square, whichever side it arrives from
@export var contact_dist: float = 192.0


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
	
	# Aim for the fort's center; garrison on any contact with its footprint
	crew.set_target(fort.center)

	var offset: Vector2 = (fort.center - crew.global_position).abs()
	if offset.x <= contact_dist and offset.y <= contact_dist:
		return SUCCESS

	# The navmesh can't get us close enough (e.g. fort ringed by rocks) —
	# release the fort so the tree can retry another or escape
	if crew.is_target_unreachable():
		blackboard.erase_value(CrewKeys.Key.FORT, crew.name)
		CrewKeys.add_targetted_count(blackboard, fort, -1)
		return FAILURE
	return RUNNING
