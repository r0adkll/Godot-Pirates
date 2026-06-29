class_name Island
extends Node2D
## This class/node is responsible for representing an "island" on the map
## it exists as a child of the "Land" TileMapLayer and represents a destinct 
## group of land tiles in the layer. 
##
## This is used for computing if a ship is "beached" or docked on an island
## and deploying crew members.

const GROUP = &"islands"

## Configuration
## The land map layer that these islands exist in
@export var map: TreasureMap

## The land coordinates on the tilemap that compose this island
var land: Array[Vector2i]

## The rect of all land tiles in the map
var bounds: Rect2i

## Island Camera
var camera_harness: CameraHarness

## Tracking array for ships beached on the island
var beached_ships: Array[BaseShip] = []

## Cache for when we generate the poly shape of this island
## for debugging
var _shape: ConvexPolygonShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group(GROUP)
	
	# Add island camera
	add_child(camera_harness)
	
#func _draw() -> void:
	#var color = Color.RED
	#color.a = 0.5
	#var rect = get_local_area()
	#rect.position = Vector2()
	#draw_rect(rect, color)
	
## Get the local (non-map) vector positions of ALL land tiles packed into
## a PackedVector2Array
func get_packed_positions() -> PackedVector2Array:
	var vector_pos: PackedVector2Array = PackedVector2Array()
	for coord in land:
		vector_pos.append(map.land.map_to_local(coord))

	return vector_pos
	
## Get the Convex Hull shape of this island to be used for debug rendering
## or rudementary collisions. This is not super reliable since islands 
## could be concave. Use for debugging only for now.
func get_polygon_shape() -> ConvexPolygonShape2D:
	if _shape == null:
		_shape = ConvexPolygonShape2D.new()
		_shape.set_point_cloud(get_packed_positions())
	
	return _shape
	
## Get the "Inland" position for a local vector coordinate (often the beached location of a ship)
## so as to take action (i.e. deploy crew) further inland to avoid interactions with the ship.
func get_inland_position(local_pos: Vector2, tile_offset: int = 1) -> Vector2:
	var map_pos = map.land.local_to_map(local_pos)
	var surrounding = map.land.get_surrounding_cells(map_pos)
	var left: int
	var right: int
	var top: int
	var bottom: int
	for neighbor in surrounding:
		if neighbor.x < map_pos.x: left = map.land.get_cell_source_id(neighbor)
		if neighbor.x > map_pos.x: right = map.land.get_cell_source_id(neighbor)
		if neighbor.y < map_pos.y: top = map.land.get_cell_source_id(neighbor)
		if neighbor.y > map_pos.y: bottom = map.land.get_cell_source_id(neighbor)
	
	var offset: Vector2i = Vector2i(0, 0)
	if left == -1: 
		offset += Vector2i(tile_offset, 0)
	elif right == -1:
		offset += Vector2i(-tile_offset, 0)
	elif top == -1:
		offset += Vector2i(0, tile_offset)
	elif bottom == -1:
		offset += Vector2i(0, -tile_offset)

	return map.land.map_to_local(map_pos + offset)


## All forts exist as children of an island, 
## find and return all of them
func get_fortifications() -> Array[Fort]:
	var forts: Array[Fort] = []
	
	for child in get_children():
		if is_instance_of(child, Fort):
			forts.append(child as Fort)

	return forts


func add_beached_ship(ship: BaseShip) -> void:
	if !beached_ships.has(ship):
		beached_ships.append(ship)


func remove_beached_ship(ship: BaseShip) -> void:
	beached_ships.erase(ship)


## Get the closest beached ship that is of the same faction
## May return null if no beached ships of that faction exist
func find_closest_beached_ship(position: Vector2, faction: Faction) -> BaseShip:
	var closest_ship: BaseShip
	var closest_dist: float
	
	for ship in beached_ships:
		if ship.faction.equals(faction):
			var dist = ship.global_position.distance_squared_to(position)
			if not closest_dist or dist < closest_dist:
				closest_ship = ship
				closest_dist = dist
	
	return closest_ship

## Check if this island contains the passed map coordinates
func contains_coord(coord: Vector2i) -> bool:
	return land.has(coord)


## Check if this island contains the passed local position
func contains_position(pos: Vector2) -> bool:
	return contains_coord(map.local_to_map(pos))
	

## Get the area of this island translated to local coordinates
func get_local_area() -> Rect2:
	return Rect2(
		map.land.map_to_local(bounds.position),
		map.land.map_to_local(bounds.size),
	)
