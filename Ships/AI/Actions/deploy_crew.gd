@tool
extends ActionLeaf

## The wait time in seconds
@export var wait_time := 0.5
@onready var cache_key = "time_limiter_%s" % self.get_instance_id()

func tick(actor: Node, blackboard: Blackboard) -> int:
	var ship = actor as BotShip
	if not ship.beach_head:
		blackboard.erase_value(ShipKeys.Key.ISLAND, ship.name)
		return FAILURE
	
	var actor_id := str(ship.get_instance_id())
	var total_time: float = blackboard.get_value(cache_key, 0.0, actor_id)
	
	var max_deploy_crew: int = 0
	var forts: Array[Fort] = ship.beach_head.island.get_fortifications()
	for fort in forts:
		if ship.faction.equals(fort.faction):
			max_deploy_crew += fort.max_crew - fort.crew
		else:
			max_deploy_crew += fort.max_crew + fort.crew
	
	var available_to_deploy = mini(max_deploy_crew, ship.crew_cabin.crew)
	if available_to_deploy > 0:
		if total_time < wait_time:
			total_time += get_physics_process_delta_time()
			blackboard.set_value(cache_key, total_time, actor_id)
		else:
			ship.crew_cabin.deploy(
				ship,
				ship.beach_head.island,
				ship.beach_head.get_landing_position(),
				ship.rotation + 90
			)
			blackboard.set_value(cache_key, 0.0, actor_id)
		return RUNNING
	else:
		blackboard.erase_value(ShipKeys.Key.ISLAND, ship.name)
		return FAILURE
	
