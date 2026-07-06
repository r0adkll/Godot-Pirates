extends SceneTree
## Headless verification for the land navmesh crew navigation.
## Run: /Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s Utils/Tests/test_land_nav.gd
##
## Generates a fixed-seed map, then asserts that for every fort a path on the
## land nav layer (2) exists from the island's shore to the fort, stays on
## land/beach tiles, respects fort obstructions, and ends within the behavior
## tree's 192px capture threshold. Prints an aggregate path hash so two runs
## can be diffed for determinism.

const FIXED_SEED: int = 12345
const FORT_CAPTURE_DIST: float = 192.0
const SAMPLE_STEP: float = 32.0

var _failures: int = 0


func _initialize() -> void:
	_run()


func _run() -> void:
	# _initialize runs before the tree iterates — wait a frame so nodes added
	# below actually enter the tree and get _ready
	await process_frame

	var main_scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	var tm = main_scene.get_node("TreasureMap")
	tm.generate_map_on_ready = false
	root.add_child(main_scene)

	# Fixed seed for reproducible generation across runs/peers
	var rng := RandomNumberGenerator.new()
	rng.seed = FIXED_SEED
	tm.setup_rng(rng.seed, rng.state, FIXED_SEED)
	tm.generate_map()
	await tm.map_generated

	var nav_map: RID = root.find_world_2d().navigation_map
	var land_layer: TileMapLayer = tm.get_node("Land")
	var beach_layer: TileMapLayer = tm.get_node("Beach")

	var islands: Array[Node] = get_nodes_in_group(&"islands")

	# The NavigationServer applies the baked land polygon in a later map
	# iteration — poll until a probe query on the land layer succeeds
	var probe_origin := Vector2.INF
	var probe_target := Vector2.INF
	for island in islands:
		if not island.get_fortifications().is_empty():
			probe_origin = land_layer.map_to_local(island.land[0])
			probe_target = island.get_fortifications()[0].center
			break
	_check(probe_origin != Vector2.INF, "found an island with a fort to probe")
	var sync_frames: int = 0
	while sync_frames < 600 and NavigationServer2D.map_get_path(
			nav_map, probe_origin, probe_target, true, 2).is_empty():
		await physics_frame
		sync_frames += 1
	print("land navmesh queryable after %d physics frames" % sync_frames)
	_check(islands.size() > 0, "map has islands (found %d)" % islands.size())

	var forts_tested: int = 0
	var path_hash: int = 0

	for island in islands:
		var forts: Array = island.get_fortifications()
		if forts.is_empty():
			continue

		var origin: Vector2 = land_layer.map_to_local(island.land[0])
		for fort in forts:
			forts_tested += 1
			var path: PackedVector2Array = NavigationServer2D.map_get_path(
				nav_map, origin, fort.center, true, 2)
			var label: String = "%s -> %s" % [island.name, fort.name]

			_check(path.size() >= 2, "%s: path exists (%d points)" % [label, path.size()])
			if path.size() < 2:
				continue

			var arrival: float = path[path.size() - 1].distance_to(fort.center)
			_check(arrival <= FORT_CAPTURE_DIST,
				"%s: path ends %.1fpx from fort center (<= %.0f)" % [label, arrival, FORT_CAPTURE_DIST])

			_check_path_on_land(path, label, land_layer)

			# Same query twice must yield an identical path (peer determinism)
			var again: PackedVector2Array = NavigationServer2D.map_get_path(
				nav_map, origin, fort.center, true, 2)
			_check(again == path, "%s: repeated query is identical" % label)

			path_hash = hash([path_hash, path])

	_check(forts_tested > 0, "at least one fort tested (tested %d)" % forts_tested)

	# A target across open water must clamp to this island's shore, far from
	# the requested point — the premise of the is_target_unreachable() guard
	var first_island: Node = null
	for island in islands:
		if not island.get_fortifications().is_empty():
			first_island = island
			break
	if first_island:
		var origin: Vector2 = land_layer.map_to_local(first_island.land[0])
		var unreachable_target: Vector2 = Vector2(-5000, -5000)
		var clamped: PackedVector2Array = NavigationServer2D.map_get_path(
			nav_map, origin, unreachable_target, true, 2)
		if clamped.size() > 0:
			var end_dist: float = clamped[clamped.size() - 1].distance_to(unreachable_target)
			_check(end_dist > FORT_CAPTURE_DIST,
				"unreachable target clamps far away (%.0fpx)" % end_dist)

	print("PATH_HASH: %d" % path_hash)

	await _check_crew_walks_and_captures(land_layer, beach_layer)

	if _failures == 0:
		print("ALL CHECKS PASSED (%d forts)" % forts_tested)
		quit(0)
	else:
		print("FAILED: %d check(s)" % _failures)
		quit(1)


## Sample along the path and assert every point is over a land tile (the mesh
## must never cross beach or water). Fort footprints are legitimate territory
## — crew garrison on contact with them.
func _check_path_on_land(
	path: PackedVector2Array,
	label: String,
	land_layer: TileMapLayer,
) -> void:
	var off_land: int = 0
	for i in path.size() - 1:
		var seg_len: float = path[i].distance_to(path[i + 1])
		var steps: int = maxi(1, int(seg_len / SAMPLE_STEP))
		for s in steps + 1:
			var point: Vector2 = path[i].lerp(path[i + 1], float(s) / steps)
			var coord: Vector2i = land_layer.local_to_map(point)
			if land_layer.get_cell_source_id(coord) == -1:
				off_land += 1
				print("    off-land sample %s (cell %s) on segment %s -> %s" % [
					point, coord, path[i], path[i + 1]])
	_check(off_land == 0, "%s: all samples on land tiles (%d off)" % [label, off_land])


## End-to-end: spawn a real WalkingCrew on an island and let its behavior
## tree navigate the land mesh and capture a fort
func _check_crew_walks_and_captures(
	land_layer: TileMapLayer,
	beach_layer: TileMapLayer,
) -> void:
	var island: Node = null
	for candidate in get_nodes_in_group(&"islands"):
		if not candidate.get_fortifications().is_empty():
			island = candidate
			break
	if not island:
		return
	var fort = island.get_fortifications()[0]

	# Start from the land cell farthest from the fort to force a real walk
	var start_cell: Vector2i = island.land[0]
	var best_dist: float = 0.0
	for cell in island.land:
		var d: float = land_layer.map_to_local(cell).distance_squared_to(fort.center)
		if d > best_dist:
			best_dist = d
			start_cell = cell

	var faction: Faction = load("res://Systems/Faction/player_faction.tres")

	# Share a blackboard the way CrewCabin.deploy does, parented under a
	# disposable holder that stands in for the deploying ship — freeing it
	# mid-walk simulates the ship dying after deploy
	var ship_stub := Node.new()
	var shared_blackboard = load("res://addons/beehave/blackboard.gd").new()
	ship_stub.add_child(shared_blackboard)
	root.add_child(ship_stub)

	var crew = (load("res://Crew/walking_crew.tscn") as PackedScene).instantiate()
	crew.global_position = land_layer.map_to_local(start_cell)
	crew.deployment = crew.Deployment.new(faction, island, crew.global_position)
	crew.blackboard = shared_blackboard
	root.get_node("/root/SceneSpawnerSystem").add_entity(crew)

	var start_dist: float = crew.global_position.distance_to(fort.center)
	print("crew spawned %.0fpx from fort, walking..." % start_dist)

	var frames: int = 0
	var off_land: int = 0
	while frames < 3600 and is_instance_valid(crew):
		await physics_frame
		frames += 1
		if frames == 120:
			# The "ship" sinks — its shared blackboard is freed with it
			ship_stub.free()
			print("freed shared blackboard at frame 120 (simulated ship death)")
		if is_instance_valid(crew) and frames % 10 == 0:
			var coord: Vector2i = land_layer.local_to_map(crew.global_position)
			if land_layer.get_cell_source_id(coord) == -1 \
					and beach_layer.get_cell_source_id(coord) == -1:
				off_land += 1

	_check(not is_instance_valid(crew),
		"crew reached and entered the fort within %d frames" % frames)
	_check(fort.crew == 1 and fort.faction and fort.faction.equals(faction),
		"fort captured by crew faction (crew: %d)" % fort.crew)
	_check(off_land == 0, "crew stayed on land/beach while walking (%d samples off)" % off_land)


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  PASS: %s" % description)
	else:
		_failures += 1
		printerr("  FAIL: %s" % description)
