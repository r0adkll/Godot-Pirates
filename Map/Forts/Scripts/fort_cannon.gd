class_name FortCannon
extends Node2D

@onready var cannon: Cannon = $Cannon

## Set the target that this cannon will track and fire upon
var target: Node2D

## Automatically aim and fire at set targets
func _physics_process(_delta: float) -> void:
	if target and visible:
		# Aim towards the target
		_lead_target(target)

		# Fire. In multiplayer only the server decides when a fort fires;
		# clients aim locally for visuals and shoot when the server's
		# broadcast (keyed on the fort's deterministic id) arrives.
		if Lobby.active:
			if multiplayer.is_server():
				FactionSystem.request_fort_cannon_fire(self)
		else:
			fire()


func fire(force: bool = false) -> void:
	cannon.fire(force)

func _lead_target(node: Node2D) -> void:
	if is_instance_of(node, CharacterBody2D):
		var body = node as CharacterBody2D
		var lead_position = body.global_position + body.velocity
		look_at(lead_position)
	else:
		look_at(target.global_position)


## Clear the target if we become invisible
func _on_visibility_changed() -> void:
	if not visible:
		target = null
