extends Node

const UNOWNED_FACTION = -1

signal kills_updated(faction: Faction, count: int)
signal conquest_updated(owned: Dictionary[int, float])

@export var faction_kills: Dictionary[int, int] = {}
@export var fort_factions: Dictionary[int, int] = {}
@export var factions: Dictionary[int, Faction] = {}
var available_boats: Dictionary[String, BoatHulls]

var total_forts: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	available_boats = BoatHulls.load_available_boats()


func add_kill(faction: Faction, amount: int = 1) -> void:
	var current = faction_kills.get_or_add(faction.id, 0)
	var new_count = current + amount
	faction_kills.set(faction.id, new_count)
	kills_updated.emit(faction, new_count)


func set_fort_faction(fort_id: int, faction: Faction) -> void:
	if not faction:
		fort_factions.set(fort_id, -1)
	else:
		fort_factions.set(fort_id, faction.id)

	## Compute owned percentages of forts by faction
	_compute_conquest()


func _compute_conquest() -> void:
	var counts: Dictionary[int, int] = {}
	var conquest: Dictionary[int, float] = {}
	
	for fort_id in fort_factions.keys():
		var fort_faction = fort_factions.get(fort_id)
		if fort_faction != -1:
			var current = counts.get_or_add(fort_faction, 0)
			var new_value = current + 1
			counts.set(fort_faction, new_value)
			conquest.set(fort_faction, float(new_value) / float(total_forts))
	
	
	conquest_updated.emit(conquest)


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
