@abstract
class_name PlayerInputNode
extends Node

## Process input 
@abstract func process_input(delta: float) -> void

## Get the configured base ship from the PlayerInput node that
## this HAS to be a child of
func get_ship() -> BaseShip:
	var parent = get_parent()
	if parent is PlayerInputNode:
		return parent.get_ship()
	else:
		return (get_parent() as PlayerInput).ship
