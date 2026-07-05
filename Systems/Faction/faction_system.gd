extends Node

const UNOWNED_FACTION = -1

signal kills_updated(faction: Faction, count: int)
signal conquest_updated(owned: Dictionary[int, float])
signal victory_timer_updated(faction: Faction, remaining: float)
signal victory(faction: Faction)

@export var time_to_win: float = 30 # 2min to hold majority to win
@export var faction_kills: Dictionary[int, int] = {}
@export var fort_factions: Dictionary[int, int] = {}
@export var factions: Dictionary[int, Faction] = {}

var winning_faction_id: int = -1
var victory_timer: float = 0
var winner_faction: Faction

var available_boats: Dictionary[String, BoatHulls]
var total_forts: int = 0


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	available_boats = BoatHulls.load_available_boats()


# Reset the faction system for a new game
func reset() -> void:
	total_forts = 0
	winner_faction = null
	victory_timer = 0
	winning_faction_id = -1
	faction_kills.clear()
	fort_factions.clear()


func _process(delta: float) -> void:
	if winning_faction_id != -1 and not winner_faction:
		victory_timer += delta
		victory_timer_updated.emit(get_faction(winning_faction_id), time_to_win - victory_timer)
		
		if victory_timer > time_to_win:
			winner_faction = get_faction(winning_faction_id)
			victory.emit(winner_faction)


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
	
	var majority_faction: int = -1
	
	for fort_id in fort_factions.keys():
		var fort_faction = fort_factions.get(fort_id)
		if fort_faction != -1:
			var current = counts.get_or_add(fort_faction, 0)
			var new_value = current + 1
			var coverage = float(new_value) / float(total_forts)
			counts.set(fort_faction, new_value)
			conquest.set(fort_faction, coverage)
			
			if coverage >= 0.5:
				majority_faction = fort_faction
	
	if winning_faction_id != majority_faction and majority_faction != -1:
		winning_faction_id = majority_faction
		victory_timer = 0
	elif majority_faction == -1:
		winning_faction_id = -1
		victory_timer = 0
		victory_timer_updated.emit(null, 0)
	
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
