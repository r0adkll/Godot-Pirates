class_name ShipsSystem
extends Node2D

const player_ship_scene := preload("res://Ships/ship.tscn")
const bot_ship_scene := preload("res://Ships/bot_ship.tscn")

## The faction to spawn enemy ships with
@export var enemy_faction: Faction
@export var player_faction: Faction

## The tilemap layer used as navigation that we can use to spawn
## and control enemy ships
@export var navigation_layer: TileMapLayer

## The minimum proximity distance to select a destination near a player
@export var min_proximity_tiles: int = 5

## The max proximity distance to select a destination near a player
@export var max_proximity_tiles: int = 20

## The amount of enemies that should be alive on the map
@export var enemy_count: int = 4

@onready var player_camera: PlayerCamera = %PlayerCamera
@onready var enemy_blackboard: Blackboard = $EnemyBlackboard


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass


## Get a random navigable position on the map that an enemy 
## can navigate to.
func get_random_position() -> Vector2:
	var coord = navigation_layer.get_used_cells().pick_random()
	return navigation_layer.map_to_local(coord)


func get_position_near_player() -> Vector2:
	var player: Ship = get_tree().get_first_node_in_group(Ship.GROUP)
	if player:
		var player_coord: Vector2i = navigation_layer.local_to_map(player.global_position)
		var coord: Vector2i
		while not coord:
			var x_offset = randi_range(min_proximity_tiles, max_proximity_tiles) * _rand_sign()
			var y_offset = randi_range(min_proximity_tiles, max_proximity_tiles) * _rand_sign()
			var offset_coord = player_coord + Vector2i(x_offset, y_offset)
			if navigation_layer.get_cell_source_id(offset_coord) != -1:
				coord = offset_coord
		
		return navigation_layer.map_to_local(coord)
	else:
		return get_random_position()


func _rand_sign() -> int:
	if randf() > 0.5:
		return 1
	else:
		return -1


## Spawn the player ship 
func spawn_player() -> void:
	var player: Ship = player_ship_scene.instantiate()
	player.game_camera = player_camera
	player.global_position = get_random_position()
	player.faction = player_faction
	player.state_changed.connect(_on_player_state_changed)
	SceneSpawnerSystem.add_entity(player)


## Spawn a new enemy into a random position
func spawn_enemy() -> void:	
	var count = enemy_count - _active_enemy_count()
	for i in count:
		var new_boat: BotShip = bot_ship_scene.instantiate()
		new_boat.global_position = get_random_position()
		new_boat.faction = enemy_faction
		new_boat.ships_system = self
		new_boat.ship_blackboard = enemy_blackboard
		new_boat.state_changed.connect(_on_enemy_state_changed)
		SceneSpawnerSystem.add_entity(new_boat)


## Called when a spawned enemy ship 
func _on_enemy_state_changed(
	_ship: BaseShip, 
	_prev_state: BaseShip.State, 
	new_state: BaseShip.State
) -> void:
	if new_state == BaseShip.State.DEAD:
		spawn_enemy()


## Called when spawned player dies
func _on_player_state_changed(
	_ship: BaseShip, 
	_prev_state: BaseShip.State, 
	new_state: BaseShip.State
) -> void:
	if new_state == BaseShip.State.DEAD:
		spawn_player()


func _active_enemy_count() -> int:
	return get_tree().get_nodes_in_group(BotShip.GROUP)\
		.filter(func (e: BotShip): return e.state != BaseShip.State.DEAD)\
		.size()
