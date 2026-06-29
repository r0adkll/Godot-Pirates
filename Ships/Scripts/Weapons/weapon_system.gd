class_name WeaponSystem
extends Node2D

@export var ship: BaseShip

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if ship.state == BaseShip.State.ALIVE:
		for child in get_children():
			var weapon = child as WeaponNode
			if Input.is_action_just_pressed(weapon.action()):
				weapon.fire()
