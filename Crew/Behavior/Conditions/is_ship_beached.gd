@tool
extends ConditionLeaf


func tick(actor: Node, _blackboard: Blackboard) -> int:
	var crew = actor as WalkingCrew
	
	## If the originating ship is actively beached ON the same beach
	## TODO: Its not sustainable to keep a reference from the deployment ship
	##       because ships can re-spawn and become new instances. Instead, the
	##       island should track which ships are beached, and direct crew to 
	##       same-faction ships that are beached. Fail for now.
	#if crew.deployment.ship.beach_head:
		#if crew.deployment.ship.beach_head.island == crew.deployment.island:
			#return SUCCESS
	
	return FAILURE
