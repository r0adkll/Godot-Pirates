class_name Land
extends TileMapLayer

## Find the island that contains the global position in the game
func find_island_for_position(g_position: Vector2) -> Island:
	var map_pos: Vector2i = local_to_map(g_position)
	for child in get_tree().get_nodes_in_group(Island.GROUP):
		if is_instance_of(child, Island):
			if (child as Island).contains_coord(map_pos):
				return child as Island
			
	return null
