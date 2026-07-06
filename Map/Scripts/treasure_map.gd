class_name TreasureMap
extends Node2D
## This is the main coordinator for rendering pirate maps for our game
## For the first iteration, it will be very hand built as we transition 
## into a more generative design

## Signal observers that the map is generated and ready
signal map_generated

const fort_scene := preload("res://Map/Forts/fort.tscn")

@onready var player_camera: PlayerCamera = %PlayerCamera

@onready var sea_floor: TileMapLayer = $SeaFloor
@onready var ocean: TileMapLayer = $Ocean
@onready var beach: TileMapLayer = $Beach
@onready var land: Land = $Land
@onready var navigation: TileMapLayer = $Navigation
@onready var decor: TileMapLayer = $Decor
@onready var forts: TileMapLayer = $Forts

@onready var camera_harness: CameraHarness = $CameraHarness
@onready var navigation_region_2d: NavigationRegion2D = $"../NavigationRegion2D"

## Navigation layer bitmask for land traversal (water navmesh is layer 1)
const LAND_NAV_LAYER: int = 2

## Navmesh that crew use to walk islands. Built at generation time from the
## exact island cell data (land/beach traversable; rocks and forts obstruct).
var land_nav_region: NavigationRegion2D
var _land_nav_source: NavigationMeshSourceGeometryData2D

@export var map_size: Vector2i
@export var generate_map_on_ready: bool = true

var map_ready: bool = false

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _noise: FastNoiseLite = FastNoiseLite.new()
var _island_builder: IslandBuilder = IslandBuilder.new(_rng)

## TileSet Cell Data for easily applying specific tiles to a map 
var water_tile: CellData = CellData.new(0, Vector2i(8, 4), 0)
var translucent_water_tile: CellData = CellData.new(0, Vector2i(8, 4), 1)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	land_nav_region = NavigationRegion2D.new()
	land_nav_region.navigation_layers = LAND_NAV_LAYER
	add_child(land_nav_region)

	# If this component is setup to generate a map, go ahead
	# and do so
	if generate_map_on_ready:
		generate_server_map()


func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_focus_next"):
		var player: Ship = get_tree().get_first_node_in_group(Ship.GROUP)
		if player_camera.follow == camera_harness and player:
			player_camera.set_following(player.camera_harness)
		elif player_camera.follow != camera_harness:
			player_camera.set_following(camera_harness)


func setup_rng(rng_seed: int, rng_state: int, noise_seed: int) -> void:
	_rng.seed = rng_seed
	_rng.state = rng_state
	_noise.seed = noise_seed
	_noise.fractal_octaves = 3
	_noise.fractal_lacunarity = 1.575
	_noise.frequency = 0.08
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN


## Setup the map RNG and generate a new map for a server to communicate to clients
## This should only be used in Multiplayer games
func generate_server_map() -> void:
	_rng.randomize()
	setup_rng(_rng.seed, _rng.state, _rng.randi())
	generate_map()


## Generate the automatic layers of the map (sea floor and ocean layers)
## Based on the map size
func generate_map() -> void:
	# A previous game's forts/islands may still be registered (and freed
	# with that scene) — clear them before registering this map's
	FactionSystem.clear_map_registries()

	_setup_camera_limits()

	_land_nav_source = NavigationMeshSourceGeometryData2D.new()

	var land_cells: Array[Vector2i] = []
	
	var k: float = 0
	for x in map_size.x+1:
		for y in map_size.y+1:
			var coord: Vector2i = Vector2i(x, y)
			
			# Setup the ocean tile
			_setup_ocean_tile(coord)
			
			k = _noise.get_noise_2d(x, y)
			
			if k > 0.15:
				land_cells.append(coord)
	
	## Parse and add islands to the map
	var islands: Array[IslandBuilder.IslandSpec] = _island_builder.parse(land_cells, map_size)
	for island in islands:
		# Mass filter, we just want to exclude islands that are too small
		if island.mass() > 10:
			# Generate the nodes and add to the scene tree
			_process_island(island)
			
	await get_tree().physics_frame

	var nav_bake_start = TimeUtil.mark()
	navigation_region_2d.bake_navigation_polygon(false)
	TimeUtil.print_time(nav_bake_start, "Baked NavRegtion")

	_bake_land_navigation()

	# Notify observers
	map_ready = true
	map_generated.emit()


## Bake the land navmesh from the source geometry accumulated per-island
## during generation. Baked synchronously so the mesh is registered before
## map_ready is flagged. Inputs derive solely from the seeded RNG/noise, so
## every peer bakes an identical mesh — crew paths stay deterministic.
func _bake_land_navigation() -> void:
	var bake_start = TimeUtil.mark()
	var land_poly := NavigationPolygon.new()
	land_poly.agent_radius = 24.0
	land_poly.baking_rect = Rect2(Vector2.ZERO, Vector2(map_size * land.tile_set.tile_size.x))
	NavigationServer2D.bake_from_source_geometry_data(land_poly, _land_nav_source)
	land_nav_region.navigation_polygon = land_poly
	TimeUtil.print_time(bake_start, "Baked land NavRegion")


## Append an island's navmesh source geometry: painted land cells are
## traversable, rock cells obstruct. Forts deliberately do NOT obstruct —
## crew aim for the fort center and garrison on contact with its footprint
## (see MoveToFort), so paths must be able to reach it from any side.
func _add_island_nav_geometry(spec: IslandBuilder.IslandSpec) -> void:
	var tile_size := Vector2(land.tile_set.tile_size)
	var half := tile_size / 2.0

	# Land cells only: beach rings from opposite shores of a narrow strait
	# touch each other, which would bridge separate landmasses — and beach
	# tiles read as water, so crew walking them look like they're swimming.
	# Slightly off-mesh targets (beach landings, fort centers) are covered by
	# the crew's straight-line finish (WalkingCrew.OFF_MESH_WALK_DIST).
	for cell in spec.land:
		# Terrain-connect can leave spit cells unpainted when no tile matches
		# their peering config — those render as water, keep them off the mesh
		if land.get_cell_source_id(cell) == -1:
			continue
		_land_nav_source.add_traversable_outline(_cell_outline(cell, half))

	for cell in spec.rocks:
		_land_nav_source.add_obstruction_outline(_cell_outline(cell, half))


func _cell_outline(cell: Vector2i, half: Vector2) -> PackedVector2Array:
	var center := land.map_to_local(cell)
	return PackedVector2Array([
		center + Vector2(-half.x, -half.y),
		center + Vector2(half.x, -half.y),
		center + Vector2(half.x, half.y),
		center + Vector2(-half.x, half.y),
	])


## Process an island spec into its tilemap tiles and generate it's Island
## Node object to add to the scene tree
func _process_island(spec: IslandBuilder.IslandSpec) -> void:
	# Enrich our island spec with decor, beach, and fort tile data
	_island_builder.enrich(spec, map_size)
			
	# Setup tilemap
	land.set_cells_terrain_connect(spec.land, 0, 0)
	beach.set_cells_terrain_connect(spec.beach, 0, 1)
	decor.set_cells_terrain_connect(spec.shrubs, 0, 2)
	decor.set_cells_terrain_connect(spec.rocks, 0, 3)
	
	# Remove the island from the navigation
	for cell in spec.land:
		navigation.erase_cell(cell)

	# Accumulate this island's walkable geometry for the land navmesh
	_add_island_nav_geometry(spec)
	
	# Generate Nodes
	var island: Island = Island.new()
	island.map = self
	island.island_id = FactionSystem.register_island(island)
	island.bounds = spec.bounds()
	island.position = land.map_to_local(island.bounds.position) - Vector2(land.tile_set.tile_size) / 2
	island.land = spec.land
	island.camera_harness = CameraHarness.new()
	island.camera_harness.viewport_rect = land.map_to_local(island.bounds.size)
	
	for fort in spec.forts:
		## TODO: Generate a Fort by its spec
		var new_fort: Fort = fort_scene.instantiate()
		
		# Compute fort position relative to island since it will be a 
		# nested node2d.
		var local_fort_position = fort.bounds.position - island.bounds.position
		new_fort.position = land.map_to_local(local_fort_position) - Vector2(64, 64)

		# Register the fort with the FactionSystem for conquest tracking.
		# Map generation is seeded, so every peer assigns the same id to
		# the same fort — this is what fort state RPCs key on.
		new_fort.fort_id = FactionSystem.register_fort(new_fort)
		island.add_child(new_fort)
	
	## TODO: Add to "land" layer?
	add_child(island)

## Generate an individual island at a given location
func _generate_island(center: Vector2i, size: int) -> void:
	var land_cells: Array[Vector2i] = []
	
	var k: float = 0
	for i in range(size*2):
		for j in range(size*2):
			var x = i - size
			var y = j - size
			var coord: Vector2i = center + Vector2i(x, y)
			
			var _dist = coord.distance_to(center) / size
			k = _noise.get_noise_2d(coord.x, coord.y) - _dist 
			
			if k > -0.3:
				land_cells.append(coord)

	land.set_cells_terrain_connect(land_cells, 0, 0)


## Setup the sea_floor and ocen tiles for a given coordinate so we can create a layered
## water effect
func _setup_ocean_tile(coord: Vector2i) -> void:
	water_tile.apply(sea_floor, coord)
	translucent_water_tile.apply(ocean, coord)


## Bound the player camera to this map
func _setup_camera_limits() -> void:
	player_camera.limit_enabled = true
	player_camera.limit_left = 0
	player_camera.limit_top = 0
	player_camera.limit_right = map_size.x * ocean.tile_set.tile_size.x
	player_camera.limit_bottom = map_size.y * ocean.tile_set.tile_size.y


## A class representation of tile information for a cell
class CellData:
	var source_id: int
	var atlas_coord: Vector2i
	var alternate_tile: int = 0
	
	func _init(src: int, atlas: Vector2i, alt: int = 0):
		self.source_id = src
		self.atlas_coord = atlas
		self.alternate_tile = alt
	
	func apply(map: TileMapLayer, coord: Vector2i) -> void:
		map.set_cell(coord, source_id, atlas_coord, alternate_tile)
