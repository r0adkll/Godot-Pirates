extends Node

signal kills_updated(faction: Faction, count: int)

@export var faction_kills: Dictionary[int, int] = {}
@export var factions: Dictionary[int, Faction] = {}
var available_boats: Dictionary[String, BoatHulls]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	available_boats = BoatHulls.load_available_boats()


func add_kill(faction: Faction, amount: int = 1) -> void:
	var current = faction_kills.get_or_add(faction.id, 0)
	var new_count = current + amount
	faction_kills.set(faction.id, new_count)
	kills_updated.emit(faction, new_count)


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
