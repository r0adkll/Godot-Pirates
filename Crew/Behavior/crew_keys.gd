class_name CrewKeys
extends RefCounted

enum Key {
	TREASURE_POS,
	FORT,
	TARGETTED_FORTS,
}


## Return the total number of crew current targetting a fort
static func get_targetted_count(blackboard: Blackboard, fort: Fort) -> int:
	var targetted_forts: Dictionary = blackboard.get_value(Key.TARGETTED_FORTS, {})
	return targetted_forts.get_or_add(fort.name, 0)


## Add an amount to the number of crew targetting the [fort]
static func add_targetted_count(blackboard: Blackboard, fort: Fort, amount: int = 1) -> int:
	var targetted_forts: Dictionary = blackboard.get_value(Key.TARGETTED_FORTS, {})
	var current_count: int = targetted_forts.get_or_add(fort.name, 0)
	var new_count = current_count + amount
	targetted_forts.set(fort.name, new_count)
	blackboard.set_value(Key.TARGETTED_FORTS, targetted_forts)
	return new_count


## The an array of available forts to target for a crew's deployed island
static func get_available_forts(
	blackboard: Blackboard, 
	crew: WalkingCrew,
) -> Array[Fort]:
	var forts: Array[Fort] = crew.deployment.island.get_fortifications()
	return forts.filter(
		func (f: Fort):
			return is_fort_available(blackboard, crew.deployment.faction, f)
	)


## Return whether or not a fort is available by comparing its faction, current
## crew count, max crew count, and how many of crew are targetting it (by passing
## in the Blackboard for the ship/crew
static func is_fort_available(
	blackboard: Blackboard,
	faction: Faction,
	fort: Fort,
) -> bool:
	var targetted_count = get_targetted_count(blackboard, fort)
	var is_fully_targetted = fort.crew + targetted_count >= fort.max_crew
	var is_empty_or_friendly = not fort.faction or faction.equals(fort.faction)
	
	return (!is_fully_targetted and is_empty_or_friendly) or \
	(targetted_count < fort.crew + fort.max_crew and !is_empty_or_friendly)
