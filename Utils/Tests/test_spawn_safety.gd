extends SceneTree
## Regression test for SpawnSafety: freshly spawned ships must not be
## placed inside hostile detection ranges (forts at 1500px, bots at
## 800px+) and the picker must degrade gracefully on a crowded map.
## Run headless:
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s Utils/Tests/test_spawn_safety.gd
##
## NOTE: project classes are load()ed at runtime and vars stay untyped — in
## -s mode this script compiles before autoloads register, so compile-time
## references to classes that use them (Fort → FactionSystem) fail.

const TILE := 128
const MAP_TILES := 40


func _initialize() -> void:
	# _initialize runs before the tree iterates — wait a frame so autoloads
	# are up and nodes added below actually enter the tree
	await process_frame

	var spawn_safety: GDScript = load("res://Systems/Ships/spawn_safety.gd")
	var fort_scene: PackedScene = load("res://Map/Forts/fort.tscn")
	var enemy_faction = load("res://Systems/Faction/enemy_faction.tres")
	var player_faction = load("res://Systems/Faction/player_faction.tres")
	var faction_system: Node = root.get_node("/root/FactionSystem")

	var failed := false

	# Build a minimal 40x40 navigation layer (5120x5120px, 128px tiles)
	var layer := _build_navigation_layer()
	root.add_child(layer)

	# 1. No threats: picks a used cell
	var pos: Vector2 = spawn_safety.pick_spawn_position(layer, player_faction)
	var map_extent := float(TILE * MAP_TILES)
	if pos.x < 0 or pos.y < 0 or pos.x > map_extent or pos.y > map_extent:
		print("FAIL: threat-free pick landed off the map: %s" % pos)
		failed = true

	# 2. A threat circle in the map center: every sampled spawn must
	#    clear radius + margin
	var threat_pos := Vector2(map_extent / 2, map_extent / 2)
	var threats: Array[Dictionary] = [{ "position": threat_pos, "radius": 1500.0 }]
	var required: float = 1500.0 + spawn_safety.CLEARANCE_MARGIN
	for i in 100:
		pos = spawn_safety.pick_position_clear_of(layer, threats)
		if pos.distance_to(threat_pos) < required:
			print("FAIL: spawn %s is %0.f px from threat (need %0.f)" % [
				pos, pos.distance_to(threat_pos), required,
			])
			failed = true
			break

	# 3. Threat covering the whole map: must terminate and return the
	#    farthest-from-danger candidate, not hang or error
	var everywhere: Array[Dictionary] = [{ "position": threat_pos, "radius": 100_000.0 }]
	pos = spawn_safety.pick_position_clear_of(layer, everywhere)
	if pos.distance_to(threat_pos) < map_extent / 4:
		print("FAIL: best-effort pick %s did not favor the map edge" % pos)
		failed = true

	# 4. gather_threats: only crewed hostile forts count
	var hostile_fort = fort_scene.instantiate()
	hostile_fort.fort_id = faction_system.register_fort(hostile_fort)
	root.add_child(hostile_fort)
	hostile_fort.global_position = threat_pos

	# Uncrewed fort can't fire — no threat
	var found: Array[Dictionary] = spawn_safety.gather_threats(layer, player_faction)
	if found.size() != 0:
		print("FAIL: uncrewed fort reported as a threat (%d threats)" % found.size())
		failed = true

	# Crewed enemy fort threatens the player at its detection radius
	hostile_fort.crew = 2
	hostile_fort.faction = enemy_faction
	found = spawn_safety.gather_threats(layer, player_faction)
	if found.size() != 1:
		print("FAIL: crewed hostile fort not gathered (%d threats)" % found.size())
		failed = true
	elif found[0]["radius"] < 1499.0:
		print("FAIL: fort threat radius %0.f, expected the 1500px detection shape" % found[0]["radius"])
		failed = true

	# ...but not its own faction
	found = spawn_safety.gather_threats(layer, enemy_faction)
	if found.size() != 0:
		print("FAIL: fort threatens its own faction (%d threats)" % found.size())
		failed = true

	print("RESULT: %s" % ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)


func _build_navigation_layer() -> TileMapLayer:
	var tex := PlaceholderTexture2D.new()
	tex.size = Vector2(TILE, TILE)

	var source := TileSetAtlasSource.new()
	source.texture = tex
	source.texture_region_size = Vector2i(TILE, TILE)
	source.create_tile(Vector2i.ZERO)

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE, TILE)
	var source_id := tile_set.add_source(source)

	var layer := TileMapLayer.new()
	layer.tile_set = tile_set
	for x in MAP_TILES:
		for y in MAP_TILES:
			layer.set_cell(Vector2i(x, y), source_id, Vector2i.ZERO)
	return layer
