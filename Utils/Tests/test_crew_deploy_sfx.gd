extends SceneTree
## Headless check that deployed walking crew play a deploy voice line,
## round-robining through the four pirate sounds across instances.
## Run: Godot --headless -s Utils/Tests/test_crew_deploy_sfx.gd

var failures := 0


func _initialize() -> void:
	await process_frame
	_run()


func _run() -> void:
	var crew_scene = load("res://Crew/walking_crew.tscn")
	var faction = load("res://Systems/Faction/player_faction.tres")

	# Deployed crew should voice, cycling 1 -> 2 -> 3 -> 4 -> 1 -> 2.
	# Crew are freed before any physics frame runs so the behavior tree
	# never ticks against the null island.
	var expected := [
		"pirate_1", "pirate_2", "pirate_3", "pirate_4", "pirate_1", "pirate_2",
	]
	for i in range(expected.size()):
		var crew = crew_scene.instantiate()
		crew.deployment = crew.Deployment.new(faction, null, Vector2.ZERO)
		root.add_child(crew)
		var sfx = crew.get_node("DeploySfx")
		_check(sfx.playing, "deploy %d plays a sound" % i)
		_check(sfx.stream != null and sfx.stream.resource_path.contains(expected[i]),
			"deploy %d uses %s (got %s)" % [i, expected[i],
				sfx.stream.resource_path if sfx.stream else "<null>"])
		if i == 0:
			_check(sfx.bus == &"SFX", "deploy sfx routed to SFX bus")
		crew.free()

	# Crew instantiated without a deployment (tests, future spawns) stay silent
	var silent_crew = crew_scene.instantiate()
	root.add_child(silent_crew)
	_check(!silent_crew.get_node("DeploySfx").playing, "undeployed crew is silent")
	silent_crew.free()

	if failures == 0:
		print("ALL CHECKS PASSED")
	else:
		print("%d CHECKS FAILED" % failures)
	quit(1 if failures > 0 else 0)


func _check(cond: bool, label: String) -> void:
	if cond:
		print("  PASS: " + label)
	else:
		failures += 1
		print("  FAIL: " + label)
