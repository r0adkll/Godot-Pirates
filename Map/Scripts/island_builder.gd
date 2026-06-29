class_name IslandBuilder
extends RefCounted
## A utility class for building islands in the game from blobs of generated
## land data

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

## Initialize the builder's RNG and noise
func _init() -> void:
	_rng.randomize()
	

## Parse a blob of land cells for all individual islands
func parse(cells: Array[Vector2i], map_size: Vector2i) -> Array[IslandSpec]:
	var start = TimeUtil.mark()
	var grid: Grid = Grid.new(cells, map_size)
	
	print("Starting island parsing for grid of %d size" % grid.cells.size())
	
	var islands: Array[IslandSpec] = []
	
	while !grid.is_empty():
		var island_start = TimeUtil.mark()
		
		## Create new spec, and pop the first grid element as our starting point
		var spec: IslandSpec = IslandSpec.new()
		var first: Vector2i = grid.pop_first()
		spec.add(first)
		
		## Recursively scan all adjacent tiles for connected island pieces
		var coords = _scan_adjacent(grid, first)
		spec.add_all(coords)
		
		## Add our now completed island to our list of specs
		islands.append(spec)
		
		TimeUtil.print_time(island_start, "New Island[m:{0}, a:{1}] @ {2}".format([spec.mass(), spec.bounds().get_area(), first]))
	
	# Print the time calc
	TimeUtil.print_time(start, "Calculated %d islands" % islands.size())
	
	return islands


## Enrich an island spec with its beach, decor, and forts
func enrich(
	spec: IslandSpec, 
	map_size: Vector2i,
	decor_probability: float = 0.05,
) -> void:
	var start = TimeUtil.mark()
	spec.beach.clear()
	spec.shrubs.clear()
	spec.rocks.clear()
	spec.forts.clear()
	
	# Create a new grid of JUST this island
	var vestigial_land: Array[Vector2i] = []
	var grid: Grid = Grid.new(spec.land, map_size)
	var beach_grid: Grid = Grid.new([], map_size)
	var fort_locations: Array[Vector2i] = []
	
	
	# For each cell, compute if 
	var _k: float = 0
	for cell in spec.land:
		# Add to the beach by default 
		beach_grid.add(cell)
		
		# For each surrounding cell, check if land, if not add as beach
		var surrounding: Array[Vector2i] = _get_surrounding_cells(cell, true)
		var sborder_count: int = 0
		for scell in surrounding:
			if grid.has(scell): 
				sborder_count += 1
		
		# Check if this grid is vestigial
		#if sborder_count == 3 or sborder_count == 2:
			#vestigial_land.append(cell)
			#grid.remove(cell)
			#continue
		
		# Check surrounding
		for scell in surrounding:	
			if not grid.has(scell) and not beach_grid.has(scell):
				beach_grid.add(scell)
				
		# Check to add decor randomly
		if _rng.randf() < decor_probability:
			if _rng.randf() > 0.5:
				spec.shrubs.append(cell)
			else:
				spec.rocks.append(cell)
				
		# Scan from this cell if possible fort location
		if _scan_fort_location(grid, cell):
			fort_locations.append(cell)
	
	# Remove vestigial land
	for vestigial in vestigial_land:
		spec.land.erase(vestigial)
	
	# Now add all in the grid to our spec
	spec.beach.append_array(beach_grid.all())
	spec.forts.append_array(_generate_fort_specs(spec, fort_locations))
	
	# Print diagnostics
	var fort_to_mass_ratio = float(spec.mass()) / float(fort_locations.size())
	TimeUtil.print_time(start, "Island Enriched [shrubs: {0}, rocks: {1},\
 mass/forts/ratio: {2}/{3}/{4}]".format([spec.shrubs.size(), spec.rocks.size(), spec.mass(), fort_locations.size(), fort_to_mass_ratio]))


# Scan the land grid at the given coordinate to see if a fort would fit there
func _scan_fort_location(
	grid: Grid, 
	coord: Vector2i, 
	fort_size: Vector2i = Vector2i(3, 3),
) -> bool:
	for x in range(fort_size.x):
		for y in range(fort_size.y):
			var fcoord = coord + Vector2i(x, y)
			if not grid.has(fcoord):
				return false
				
			# Confirm that surrounding are all valid too
			var surrounding = _get_surrounding_cells(fcoord, true)
			for scoord in surrounding:
				if not grid.has(scoord):
					return false
				
	return true


## Generate a list of possible tile coordinates that we could
## put a fort on the island. 
## TODO: This is hardcoded to our medium forts
func _generate_fort_specs(
	spec: IslandSpec,
	available_fort_locations: Array[Vector2i],
	min_fort_dist: int = 5,
) -> Array[FortSpec]:
	var fort_locations: Array[Vector2i] = []
	if not available_fort_locations.is_empty() and spec.mass() > 40:
		var fmr: float = float(spec.mass()) / float(available_fort_locations.size())
		var fort_count: int = 1
		if fmr > 4 and fmr < 7:
			fort_count = 2
		
		for i in range(fort_count):
			var fort_location: Vector2i = available_fort_locations.pick_random()
			var fort_rect: Rect2i = Rect2i(fort_location, Vector2i(3, 3))
			
			# Check if far enough away from any already set locations
			var too_close = false
			for prev_locs in fort_locations:
				var prev_rect = Rect2i(prev_locs, Vector2i(3, 3))
				if prev_rect.intersects(fort_rect):
					too_close = true
					break
				
				var dist = prev_locs.distance_to(fort_location)
				if dist < min_fort_dist:
					too_close = true
					break
			
			if not too_close and fort_location:
				fort_locations.append(fort_location)
				
	return fort_locations.map(func (loc): return medium_fort(loc))


## Perform a recursive BFS search of the grid for adjacent cells
## and return an array of valid cells from the original coord
func _scan_adjacent(grid: Grid, coord: Vector2i) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	
	# Check and capture surrounding cells for BFS
	var surrounding: Array[Vector2i] = _get_surrounding_cells(coord)
	for cell in surrounding:
		if grid.contains(cell) and grid.remove(cell):
			coords.append(cell)
			
	# Recurse into valid surrounding nodes
	var _scanned: Array[Vector2i] = []
	for c in coords:
		_scanned.append_array(_scan_adjacent(grid, c))
	
	# Surface upwards the captured adjacent nodes, removed from the grid
	return coords + _scanned


## Get an array of surrounding cell locations, regardless of whether those
## locations actually have any data in a grid. 
## If include_diaglonals is true, it will also return the top-left, top-right,
## bottom-left, and bottom-right nodes as well
func _get_surrounding_cells(
	coord: Vector2i, 
	include_diagonals: bool = false,
) -> Array[Vector2i]:
	if !include_diagonals:
		return [
			coord + Vector2i.LEFT,
			coord + Vector2i.UP,
			coord + Vector2i.RIGHT,
			coord + Vector2i.DOWN,
		]
	else:
		return [
			coord + Vector2i.LEFT,
			coord + Vector2i.LEFT + Vector2i.UP,
			coord + Vector2i.UP,
			coord + Vector2i.RIGHT + Vector2i.UP,
			coord + Vector2i.RIGHT,
			coord + Vector2i.RIGHT + Vector2i.DOWN,
			coord + Vector2i.DOWN,
			coord + Vector2i.LEFT + Vector2i.DOWN
		]


## A data structure for managing a grid of map tile locations 
class Grid:
	var cells: PackedInt32Array
	var size: Vector2i
	
	func _init(coords: Array[Vector2i], size: Vector2i) -> void:
		cells = PackedInt32Array(coords.map(func (c): return _packed_coord(c, size)))
		cells.sort()
		self.size = size
	
	## Return whether or not a coordinate fits in a grid, regardless of the
	## grid containing that actual location
	func contains(coord: Vector2i) -> bool:
		if coord.x < 0 or coord.y < 0: 
			return false
		
		if coord.x > size.x or coord.y > size.y:
			return false
			
		return true
	
	## Return all cells as Vector2i coordinates from this grid
	func all() -> Array[Vector2i]:
		var coords: Array[Vector2i] = []
		for c in cells:
			coords.append(_unpack_coord(c))
		return coords
	
	## Returns the first coordinate in this grid, OR Vector2i.MAX
	func first() -> Vector2i:
		if cells.is_empty(): return Vector2i.MAX
		return _unpack_coord(cells.get(0))
	
	
	## Pop and return the first element from this grid
	func pop_first() -> Vector2i:
		var _first = cells.get(0)
		cells.erase(_first)
		return _unpack_coord(_first)
	
	
	## Check if this grid has coordinates in its cells
	func has(coord: Vector2i) -> bool:
		return cells.has(_packed_coord(coord))
	
	
	## Add a position to this grid
	func add(coord: Vector2i) -> void:
		cells.append(_packed_coord(coord))
	
	
	## Remove a coord from this grid
	func remove(coord: Vector2i) -> bool:
		return cells.erase(_packed_coord(coord))
	
	
	## Return whether or not this grid is empty
	func is_empty() -> bool:
		return cells.is_empty()
	
	
	## Pack a map coordinate into an integer based on the known map size. This makes it 
	## easier to reason about collecting and removing coordinates
	func _packed_coord(coord: Vector2i, map_size: Vector2i = self.size) -> int:
		return coord.x + coord.y * map_size.x
	
	
	## Unpack an integer into a map coordinate based on a known map size. 
	func _unpack_coord(packed_coord: int, map_size: Vector2i = self.size) -> Vector2i:
		var columns = map_size.x
		var x = packed_coord % columns
		@warning_ignore("integer_division")
		var y = packed_coord / columns
		return Vector2i(x, y)


## A class container for a parsed island from a land blob
class IslandSpec:
	## The land tile coordinate that compose this island
	var land: Array[Vector2i] = []
	var beach: Array[Vector2i] = []
	var shrubs: Array[Vector2i] = []
	var rocks: Array[Vector2i] = []
	var forts: Array[FortSpec] = []
	
	## The rect bounds of this island
	var _left: int = INT32_MAX
	var _top: int = INT32_MAX
	var _right: int = INT32_MIN
	var _bottom: int = INT32_MIN
	
	func mass() -> int:
		return land.size()
		
	func bounds() -> Rect2i:
		return Rect2i(_left, _top, (_right - _left) + 1, (_bottom -_top) + 1)
	
	func add(coord: Vector2i) -> void:
		land.append(coord)
		_adjust_bounds(coord)
		
	func add_all(coords: Array[Vector2i]) -> void:
		land.append_array(coords)
		for coord in coords:
			_adjust_bounds(coord)
		
	## Adjust the rect bounds of the island
	func _adjust_bounds(coord: Vector2i) -> void:
		if coord.x < _left: _left = coord.x
		if coord.x > _right: _right = coord.x
		if coord.y < _top: _top = coord.y
		if coord.y > _bottom: _bottom = coord.y


## The spec for creating and adding forts to an island
class FortSpec:
	var bounds: Rect2i
	var max_crew: int
	
	func _init(rect: Rect2i, crew: int) -> void:
		self.bounds = rect
		self.max_crew = crew

## Create a medium fort spec
func medium_fort(
	coord: Vector2i,
) -> FortSpec:
	return FortSpec.new(Rect2i(coord, Vector2i(3, 3)), 4)
