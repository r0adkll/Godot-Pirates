@abstract
class_name ShipAbility
extends Node

@export var duration: float = 10
@export var recharge_time: float = 5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(false)
	set_physics_process(false)


## Activate the ability
@abstract func activate(ship: Ship) -> void

## Called to disable ability by decorator modifier or 
## other game logic
@abstract func deactivate(ship: Ship) -> void
