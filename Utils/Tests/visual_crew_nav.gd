extends SceneTree
## Visual repro for crew land navigation. Runs windowed, follows a deployed
## crew with a camera, dumps screenshots + diagnostics.
## Run: Godot --path . -s Utils/Tests/visual_crew_nav.gd

const FIXED_SEED: int = 12345
## Screenshots land here; override with the SHOT_DIR env var
var shot_dir: String = OS.get_environment("SHOT_DIR")


func _initialize() -> void:
	_run()


func _run() -> void:
	await process_frame

	NavigationServer2D.set_debug_enabled(true)
	root.size = Vector2i(1280, 720)

	var main_scene: Node = (load("res://main.tscn") as PackedScene).instantiate()
	var tm = main_scene.get_node("TreasureMap")
	tm.generate_map_on_ready = false
	root.add_child(main_scene)

	var rng := RandomNumberGenerator.new()
	rng.seed = FIXED_SEED
	tm.setup_rng(rng.seed, rng.state, FIXED_SEED)
	tm.generate_map()
	await tm.map_generated

	var nav_map: RID = root.find_world_2d().navigation_map
	var land_layer: TileMapLayer = tm.get_node("Land")

	var island: Node = null
	for candidate in get_nodes_in_group(&"islands"):
		if not candidate.get_fortifications().is_empty():
			island = candidate
			break
	var fort = island.get_fortifications()[0]

	# Poll until the land mesh is queryable
	var frames: int = 0
	while frames < 600 and NavigationServer2D.map_get_path(
			nav_map, land_layer.map_to_local(island.land[0]), fort.center, true, 2).is_empty():
		await physics_frame
		frames += 1

	# Spawn crew exactly like CrewCabin.deploy does (shared blackboard etc.)
	var start_cell: Vector2i = island.land[0]
	var best_dist: float = 0.0
	for cell in island.land:
		var d: float = land_layer.map_to_local(cell).distance_squared_to(fort.center)
		if d > best_dist:
			best_dist = d
			start_cell = cell

	var faction: Faction = load("res://Systems/Faction/player_faction.tres")
	var blackboard = load("res://addons/beehave/blackboard.gd").new()
	main_scene.add_child(blackboard)

	var crew = (load("res://Crew/walking_crew.tscn") as PackedScene).instantiate()
	crew.global_position = land_layer.map_to_local(start_cell)
	crew.rotation = 0.0
	crew.walk_speed = 200.0
	crew.deployment = crew.Deployment.new(faction, island, crew.global_position)
	crew.blackboard = blackboard
	root.get_node("/root/SceneSpawnerSystem").add_entity(crew)

	var cam := Camera2D.new()
	cam.zoom = Vector2(0.35, 0.35)
	crew.add_child(cam)
	cam.make_current()

	if shot_dir.is_empty():
		shot_dir = OS.get_user_data_dir() + "/nav_shots"
	DirAccess.make_dir_recursive_absolute(shot_dir)
	print("saving screenshots to %s" % shot_dir)
	var shot: int = 0
	frames = 0
	while frames < 2400 and is_instance_valid(crew):
		await physics_frame
		frames += 1
		if frames % 30 == 0 and is_instance_valid(crew):
			var agent: NavigationAgent2D = crew.get_node("NavigationAgent2D")
			print("f=%d state=%s pos=%s vel=%s nav_done=%s path_pts=%d next=%s target=%s" % [
				frames, crew.state, crew.global_position.round(), crew.velocity.round(),
				agent.is_navigation_finished(), agent.get_current_navigation_path().size(),
				agent.get_next_path_position().round(), crew.target.round()])
		if frames % 120 == 0:
			await RenderingServer.frame_post_draw
			var img: Image = root.get_texture().get_image()
			img.save_png("%s/shot_%02d.png" % [shot_dir, shot])
			shot += 1

	print("done: crew valid=%s fort.crew=%d frames=%d" % [is_instance_valid(crew), fort.crew, frames])
	quit(0)
