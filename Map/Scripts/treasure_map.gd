class_name TreasureMap
extends Node2D
## This is the main coordinator for rendering pirate maps for our game
## For the first iteration, it will be very hand built as we transition 
## into a more generative design

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

@export var map_size: Vector2i

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _noise: FastNoiseLite = FastNoiseLite.new()
var _island_builder: IslandBuilder = IslandBuilder.new()

## TileSet Cell Data for easily applying specific tiles to a map 
var water_tile: CellData = CellData.new(0, Vector2i(8, 4), 0)
var translucent_water_tile: CellData = CellData.new(0, Vector2i(8, 4), 1)

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_rng.randomize()
	_noise.seed = _rng.randi()
	_noise.fractal_octaves = 3
	_noise.fractal_lacunarity = 1.575
	_noise.frequency = 0.08
	_noise.noise_type = FastNoiseLite.TYPE_PERLIN
	
	_generate_map()
	
	
func _physics_process(_delta: float) -> void:
	if Input.is_action_just_pressed("ui_focus_next"):
		var player: Ship = get_tree().get_first_node_in_group(Ship.GROUP)
		if player_camera.follow == camera_harness and player:
			player_camera.set_following(player.camera_harness)
		elif player_camera.follow != camera_harness:
			player_camera.set_following(camera_harness)


## Generate the automatic layers of the map (sea floor and ocean layers)
## Based on the map size
func _generate_map() -> void:	
	_setup_camera_limits()
	
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
	
	# TEST: Add a player to the map
	%ShipsSystem.spawn_player()
	%ShipsSystem.spawn_enemy()
	


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
	
	# Generate Nodes
	var island: Island = Island.new()
	island.map = self
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
