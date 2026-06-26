@tool
extends ActionLeaf


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var ship = actor as BotShip
	
	# If the ship is no longer alive, return failure
	if ship.state != BaseShip.State.ALIVE:
		return FAILURE
	
	# If the ship is no longer targetting an enemy
	# return failure as we can't target anything
	if not ship.target:
		return FAILURE
	
	# Aim the cannons and fire
	# TODO: Lead the target a bit? Maybe lead with a difficulty mod?
	ship.cannon.look_at(ship.target.global_position) # Aim
	ship.fire_main_cannons() # Fire
	
	# Return the action as successful!
	return SUCCESS
