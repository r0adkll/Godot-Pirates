class_name MultiplayerGame
extends Node2D

@onready var treasure_map: TreasureMap = $TreasureMap
@onready var player_system: PlayerSystem = $PlayerSystem
@onready var hud: Hud = $HUD


var player_maps_loaded: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SceneSpawnerSystem.entity_owner = self

	# Clear any state left over from a previous game
	FactionSystem.reset()

	Lobby.player_disconnected.connect(_on_player_disconnected)
	Lobby.server_disconnected.connect(_on_server_disconnected)

	# With up to 5 rival players there is no single "enemy" faction;
	# the score meter falls back to tracking the strongest rival
	hud.enemy_counter.faction = null
	hud.enemy_counter.visible = false

	## Notify server that we have loaded the scene
	Lobby.player_loaded.rpc()


## Remove a disconnected player's ship and faction on every peer
func _on_player_disconnected(peer_id: int) -> void:
	var ship := get_node_or_null("player_%d_ship" % peer_id)
	if ship:
		ship.queue_free()
	player_system.remove_faction(peer_id)


## The host went away; nothing left to play, return to the main menu
func _on_server_disconnected() -> void:
	SceneLoader.load_scene("uid://dmt04rkfnmmkq")


## If server, then generate the map 
func start_game() -> void:
	if multiplayer.is_server():
		treasure_map.generate_server_map()


## Called when our map is generated and ready.
## Import for hosts to know when to signal clients 
## to "mimic" the map
func _on_treasure_map_map_generated() -> void:
	if multiplayer.is_server():
		player_maps_loaded += 1
		# Signal clients to generate with an rng spec
		var rng_seed: int = treasure_map._rng.seed
		var rng_state: int = treasure_map._rng.state
		var noise_seed: int = treasure_map._noise.seed
		generate_client_map.rpc(rng_seed, rng_state, noise_seed)
	else:
		player_map_loaded.rpc()


@rpc("authority", "call_remote", "reliable")
func generate_client_map(rng_seed: int, rng_state: int, noise_seed: int) -> void:
	if not multiplayer.is_server() and not treasure_map.map_ready:
		treasure_map.setup_rng(rng_seed, rng_state, noise_seed)
		treasure_map.generate_map()


@rpc("any_peer", "call_local", "reliable")
func player_map_loaded():
	if multiplayer.is_server():
		player_maps_loaded += 1
		if player_maps_loaded == Lobby.players.size():
			player_system.setup_players()
			
