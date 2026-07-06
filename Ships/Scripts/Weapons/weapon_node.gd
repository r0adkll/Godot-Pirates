@abstract
class_name WeaponNode
extends Node2D

## Tell a weapon system how to trigger
@abstract func action() -> StringName

## Fire this weapon node.
## Returns a bitmask of which sub-weapons fired (0 = nothing fired).
## When force_mask is non-zero the weapon is replaying a remote peer's
## shot: fire exactly those sub-weapons, ignoring local magazine state.
@abstract func fire(force_mask: int = 0) -> int


## Replay a fire event from the ship's controlling peer
@rpc("any_peer", "call_remote", "reliable")
func fire_remote(mask: int) -> void:
	fire(mask)
