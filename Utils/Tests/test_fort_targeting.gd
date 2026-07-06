extends SceneTree
## Repro/regression test for cross-island TARGETTED_FORTS pollution.
##
## A ship's CrewCabin blackboard lives for the ship's lifetime, so the
## targetted-fort bookkeeping must not collide between forts on different
## islands. Run headless:
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s Utils/Tests/test_fort_targeting.gd
##
## NOTE: project classes are load()ed at runtime and vars stay untyped — in
## -s mode this script compiles before autoloads register, so compile-time
## references to classes that use them (Fort → FactionSystem) fail.


func _initialize() -> void:
	# _initialize runs before the tree iterates — wait a frame so autoloads
	# are up and nodes added below actually enter the tree
	await process_frame

	var fort_scene: PackedScene = load("res://Map/Forts/fort.tscn")
	var island_script: GDScript = load("res://Map/Scripts/island.gd")
	var blackboard_script: GDScript = load("res://addons/beehave/blackboard.gd")
	var crew_keys: GDScript = load("res://Crew/Behavior/crew_keys.gd")
	var faction = load("res://Systems/Faction/enemy_faction.tres")
	var faction_system: Node = root.get_node("/root/FactionSystem")

	# Two islands, one fort each — mirrors treasure_map.gd, which instantiates
	# fort.tscn and add_child()s it under each island without renaming.
	# Islands stay out of the tree (Island._ready needs a camera harness);
	# get_fortifications() only inspects children so this is representative.
	var island_a = island_script.new()
	var island_b = island_script.new()

	var fort_a = fort_scene.instantiate()
	var fort_b = fort_scene.instantiate()
	fort_a.fort_id = faction_system.register_fort(fort_a)
	fort_b.fort_id = faction_system.register_fort(fort_b)
	island_a.add_child(fort_a)
	island_b.add_child(fort_b)

	print("fort_a: name='%s' id=%d | fort_b: name='%s' id=%d" % [
		fort_a.name, fort_a.fort_id, fort_b.name, fort_b.fort_id,
	])

	var blackboard = blackboard_script.new()
	root.add_child(blackboard)

	# Ship deploys at island A: crew claim every slot of fort_a
	for i in fort_a.max_crew:
		crew_keys.add_targetted_count(blackboard, fort_a)

	# Ship then sails to island B: its untouched fort must still be available
	var a_available: bool = crew_keys.is_fort_available(blackboard, faction, fort_a)
	var b_available: bool = crew_keys.is_fort_available(blackboard, faction, fort_b)

	var failed := false
	if a_available:
		print("FAIL: fort_a should be fully targetted and unavailable")
		failed = true
	if not b_available:
		print("FAIL: fort_b (other island, zero claims) reads unavailable — island A's claims leaked into it")
		failed = true

	# Releasing island A's claims must not go through island B's count
	crew_keys.add_targetted_count(blackboard, fort_a, -fort_a.max_crew)
	if crew_keys.get_targetted_count(blackboard, fort_a) != 0:
		print("FAIL: fort_a count did not return to 0")
		failed = true
	if crew_keys.get_targetted_count(blackboard, fort_b) != 0:
		print("FAIL: fort_b count is nonzero without any claims on it")
		failed = true

	print("RESULT: %s" % ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
