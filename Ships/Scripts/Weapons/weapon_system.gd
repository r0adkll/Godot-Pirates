class_name WeaponSystem
extends Node2D

@export var ship: BaseShip

## Whether this system reads local input. Disabled on remote-controlled
## ships — their weapons stay in the tree so they can still fire via
## RPC from the controlling peer.
var enabled: bool = true


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# control is assigned before the ship enters the tree, so this also
	# covers the frames before the deferred setup_*_control calls run
	if not enabled or ship.control != BaseShip.LOCAL:
		return

	if ship.state == BaseShip.State.ALIVE:
		for child in get_children():
			var weapon = child as WeaponNode
			if Input.is_action_just_pressed(weapon.action()):
				# Only replicate volleys that actually fired, and replay
				# exactly the cannons that fired on this peer
				var mask = weapon.fire()
				if mask != 0 and Lobby.active:
					weapon.fire_remote.rpc(mask)
