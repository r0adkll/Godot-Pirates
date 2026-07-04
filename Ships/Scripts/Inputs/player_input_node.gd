@abstract
class_name PlayerInputNode
extends Node

## Process input 
@abstract func process_input(ship: Ship, delta: float) -> void

## Disable the processing of input node scripts
## since they are handled by the parent coordinator nodes
func _init() -> void:
	set_process(false)
	set_physics_process(false)

## Get the configured base ship from the PlayerInput node that
## this HAS to be a child of
func get_ship() -> BaseShip:
	var parent = get_parent()
	if parent is PlayerInputNode:
		return parent.get_ship()
	else:
		return (parent as PlayerInput).ship
