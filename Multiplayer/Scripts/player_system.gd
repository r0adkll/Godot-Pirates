class_name PlayerSystem
extends Node2D


const ship_scene := preload("res://Ships/ship.tscn")

@onready var treasure_map: TreasureMap = $"../TreasureMap"
@onready var player_camera: PlayerCamera = %PlayerCamera

@export var available_boats: Dictionary[String, BoatHulls] = {}

var factions: Dictionary[int, Faction] = {}

## Perform the initial setup for players by generating their factions
## and preparing all clients to handle/spawn ships
func setup_players() -> void:
	if multiplayer.is_server():
		var ids: Array = Lobby.players.keys()
		for player_id: int in ids:
			var pos = get_random_position()
			spawn_player.rpc(player_id, pos)


func get_faction(player_id: int) -> Faction:
	return factions.get(player_id) if factions.has(player_id) else _create_faction(player_id)


## Generate a new faction
func _create_faction(player_id: int) -> Faction:
	var player_info: Dictionary = Lobby.players.get(player_id)
	var faction = Faction.new()
	faction.id = player_id
	faction.type = Faction.Type.Player
	faction.boat = available_boats[player_info["boat"]]
	return faction


@rpc("any_peer", "call_local", "reliable")
func spawn_player(player_id: int, pos: Vector2) -> void:
	var faction = get_faction(player_id)
	var is_client = player_id == multiplayer.get_unique_id()
	
	print(str(multiplayer.get_unique_id()) + ": Spawning player [is_client=" + str(is_client) + "]")
	
	var new_player: Ship = ship_scene.instantiate()
	new_player.global_position = pos
	new_player.faction = faction
	new_player.name = "player_" + str(player_id) + "_ship"
	new_player.player_system = self
	
	if is_client:
		new_player.game_camera = player_camera
		new_player.setup_local_control.call_deferred()
	else:
		new_player.setup_remote_control.call_deferred()
	
	# Only the server cares about re-spawning ships
	if multiplayer.is_server():
		new_player.state_changed.connect(_on_player_state_changed)
		
	# Add the entity to the scene
	SceneSpawnerSystem.add_entity(new_player)


## Get a random navigable position on the map that an enemy 
## can navigate to.
func get_random_position() -> Vector2:
	var coord = treasure_map.navigation.get_used_cells().pick_random()
	return treasure_map.navigation.map_to_local(coord)


## Called when spawned player dies
func _on_player_state_changed(
	ship: BaseShip, 
	_prev_state: BaseShip.State, 
	new_state: BaseShip.State
) -> void:
	if new_state == BaseShip.State.DEAD:
		var new_position = get_random_position()
		spawn_player.rpc(ship.faction.id, new_position)
