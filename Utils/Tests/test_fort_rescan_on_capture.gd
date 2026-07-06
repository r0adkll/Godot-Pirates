extends SceneTree
## Regression test: capturing a fort must (re)target ships that are
## already inside its detection area.
##
## Area2D only signals body_entered on the transition into the area, so
## a ship that entered as an ally of the fort's owner is filtered out by
## _can_target() and never tracked. When ownership flips, the faction
## setter must rescan the overlapping bodies or that ship is never
## targeted until it exits and re-enters. Run headless:
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s Utils/Tests/test_fort_rescan_on_capture.gd
##
## NOTE: project classes are load()ed at runtime and vars stay untyped —
## in -s mode this script compiles before autoloads register, so
## compile-time references to classes that use them fail.


func _initialize() -> void:
	# Wait a frame so autoloads are up and nodes added below enter the tree
	await process_frame

	var fort_scene: PackedScene = load("res://Map/Forts/fort.tscn")
	var stub_script: GDScript = load("res://Utils/Tests/test_ship_stub.gd")
	var player_faction = load("res://Systems/Faction/player_faction.tres")
	var enemy_faction = load("res://Systems/Faction/enemy_faction.tres")
	var faction_system: Node = root.get_node("/root/FactionSystem")

	var fort = fort_scene.instantiate()
	fort.fort_id = faction_system.register_fort(fort)
	root.add_child(fort)

	# A player ship parked dead-center on the fort's detection area
	var ship = stub_script.new()
	ship.faction = player_faction
	ship.collision_layer = 1
	ship.position = fort.position + fort.get_node("DetectionArea").position

	var shape = CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	shape.shape.radius = 20.0
	ship.add_child(shape)

	var damage_target = Node2D.new()
	damage_target.name = "DamageTarget"
	ship.add_child(damage_target)

	root.add_child(ship)

	# The fort starts under the ship's own faction, then let physics flush
	# so DetectionArea processes the (filtered, allied) body_entered
	fort.faction = player_faction
	await physics_frame
	await physics_frame

	var failed := false
	if not fort.targets.is_empty():
		print("FAIL: allied ship should not be tracked as a target")
		failed = true

	# Enemy crew capture the fort — mirrors enter_fort.gd (crew before faction)
	fort.crew = 1
	fort.faction = enemy_faction

	if not fort.targets.has(ship):
		print("FAIL: ship inside detection area was not targeted after capture")
		failed = true
	if fort.tl_cannon.target != ship:
		print("FAIL: manned cannon was not assigned the in-area ship")
		failed = true

	# Recapture by the ship's faction must drop it from the target list
	fort.faction = player_faction
	if fort.targets.has(ship):
		print("FAIL: allied ship still targeted after friendly recapture")
		failed = true

	print("RESULT: %s" % ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)
