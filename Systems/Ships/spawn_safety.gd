class_name SpawnSafety
extends Object
## Picks spawn positions on the water navigation layer that keep newly
## spawned ships out of hostile detection ranges, so a fresh spawn is
## never immediately blasted by a fort or an enemy ship before the
## player (or bot) has a chance to react.


## How many random candidate cells to sample before settling for the
## safest one found
const MAX_ATTEMPTS := 100

## Extra padding (px) beyond a threat's detection radius — one tile so a
## spawn isn't sitting exactly on the detection edge
const CLEARANCE_MARGIN := 128.0

## Threat radius used when a detection shape can't be read (e.g. player
## ships, which have no DetectionArea but shouldn't be spawned into)
const DEFAULT_THREAT_RADIUS := 800.0

## Keep at least this far from ANY living ship, allies included, so
## spawns never overlap another hull
const SHIP_SPACING := 256.0


## Pick a navigable spawn position for a ship of [param faction] that is
## clear of every hostile fort/ship detection range. If the map is so
## crowded that no sampled cell is fully clear, returns the safest
## (farthest-from-danger) candidate instead of failing.
static func pick_spawn_position(navigation_layer: TileMapLayer, faction: Faction) -> Vector2:
	var threats := gather_threats(navigation_layer, faction)
	return pick_position_clear_of(navigation_layer, threats)


## Pick a random used cell that is outside every threat circle, sampling
## up to MAX_ATTEMPTS cells and falling back to the best candidate seen
static func pick_position_clear_of(navigation_layer: TileMapLayer, threats: Array[Dictionary]) -> Vector2:
	var cells := navigation_layer.get_used_cells()
	if cells.is_empty():
		return Vector2.ZERO

	var best_pos := _cell_position(navigation_layer, cells.pick_random())
	if threats.is_empty():
		return best_pos

	var best_clearance := _clearance(best_pos, threats)
	for i in MAX_ATTEMPTS:
		if best_clearance >= 0.0:
			break
		var pos := _cell_position(navigation_layer, cells.pick_random())
		var clearance := _clearance(pos, threats)
		if clearance > best_clearance:
			best_clearance = clearance
			best_pos = pos

	return best_pos


## Collect everything on the map that could immediately engage a ship of
## [param faction], as { "position": Vector2, "radius": float } entries.
## Hostile ships and crewed hostile forts count at their live detection
## radius; allied ships still get a small spacing radius so hulls don't
## spawn stacked.
static func gather_threats(navigation_layer: TileMapLayer, faction: Faction) -> Array[Dictionary]:
	var threats: Array[Dictionary] = []
	var tree := navigation_layer.get_tree()
	if not tree:
		return threats

	var ships := tree.get_nodes_in_group(Ship.GROUP)
	ships.append_array(tree.get_nodes_in_group(BotShip.GROUP))
	for node in ships:
		var ship := node as BaseShip
		if not ship or ship.state != BaseShip.State.ALIVE:
			continue
		var is_ally: bool = ship.faction and ship.faction.equals(faction)
		var radius := SHIP_SPACING if is_ally \
			else maxf(_detection_radius(ship), SHIP_SPACING)
		threats.append({ "position": ship.global_position, "radius": radius })

	# Forts only fire while crewed, and never at their own faction
	for fort_id in FactionSystem.forts.keys():
		var fort = FactionSystem.forts[fort_id]
		if not is_instance_valid(fort) or fort.crew <= 0:
			continue
		if fort.faction and fort.faction.equals(faction):
			continue
		threats.append({ "position": fort.center, "radius": _detection_radius(fort) })

	return threats


## The smallest gap (px) between [param pos] and any threat's clearance
## circle; negative when inside one
static func _clearance(pos: Vector2, threats: Array[Dictionary]) -> float:
	var worst := INF
	for threat in threats:
		var required: float = threat["radius"] + CLEARANCE_MARGIN
		worst = minf(worst, pos.distance_to(threat["position"]) - required)
	return worst


## Read a threat's live detection radius from its DetectionArea shape —
## bots expand theirs while attacking and difficulty scales it, so the
## scene value can't be hardcoded here
static func _detection_radius(threat: Node) -> float:
	var shape_node := threat.get_node_or_null("DetectionArea/CollisionShape2D") as CollisionShape2D
	if shape_node and shape_node.shape is CircleShape2D:
		return (shape_node.shape as CircleShape2D).radius
	return DEFAULT_THREAT_RADIUS


static func _cell_position(navigation_layer: TileMapLayer, cell: Vector2i) -> Vector2:
	return navigation_layer.to_global(navigation_layer.map_to_local(cell))
