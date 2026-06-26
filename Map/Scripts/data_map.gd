class_name DataMap
extends TileMapLayer

const TREASURE_SRC_ID = 1
const TREASURE_LOCATION = Vector2i(0, 0)

func find_treasure_coords(coords: Array[Vector2i]) -> Array[Vector2i]:
	return coords.filter(_has_treasure)
	

func create_treasure(coord: Vector2i) -> TreasureChest:
	var treasure_scene: PackedScene = load("res://Map/Items/Treasure/treasure.tscn")
	var treasure: TreasureChest = treasure_scene.instantiate()
	treasure.position = map_to_local(coord)
	return treasure
		

## Check if a map position has a treasure tile
func _has_treasure(coords: Vector2i) -> bool:
	var source_id: int = get_cell_source_id(coords)
	if source_id == TREASURE_SRC_ID:
		var atlas_coords: Vector2i = get_cell_atlas_coords(coords)
		return atlas_coords == TREASURE_LOCATION
		
	return false


## Find a Faction blueprint in the coordinates
## This is a hack so I can encode faction data into islands
## while we are still hand drawing them
func find_blueprint(coords: Array[Vector2i]) -> Blueprint:
	for coord in coords:
		var blueprint: Blueprint = _find_blueprint(coord)
		if blueprint:
			print("Blueprint Found! Blueprint[{0}, {1}]".format([blueprint.type, blueprint.faction]))
			blueprint.coordinates = coord
			return blueprint
			
	return null
	

func _find_blueprint(coord: Vector2i) -> Blueprint:
	var tile_data: TileData = get_cell_tile_data(coord)
	if tile_data:
		var blueprint = tile_data.get_custom_data("blueprint")
		if blueprint:
			return blueprint as Blueprint
	return null
