@tool
class_name PlayerInput
extends Node

@export var ship: BaseShip
@export var enabled: bool = true


## Process input on the physics process, checking the ship state
## and the input state
func _physics_process(delta: float) -> void:
	if !Engine.is_editor_hint():
		if ship.state == BaseShip.State.ALIVE and enabled:
			_process_input(delta)


## Process the input handling of all children nodes
func _process_input(delta: float) -> void:
	for child in get_children():
		if is_instance_of(child, PlayerInputNode):
			(child as PlayerInputNode).process_input(delta)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if !ship:
		warnings.append("You must set a 'Ship' export")
	
	if get_child_count() == 0:
		warnings.append("You must attach at least one 'PlayerInputNode'")
		
	for child in get_children():
		if !is_instance_of(child, PlayerInputNode):
			warnings.append("'%s' is not a PlayerInputNode" % child.name)

	return warnings
