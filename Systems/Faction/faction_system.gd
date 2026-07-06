extends Node

const UNOWNED_FACTION = -1

signal kills_updated(faction: Faction, count: int)
signal conquest_updated(owned: Dictionary[int, float])
signal victory_timer_updated(faction: Faction, remaining: float)
signal victory(faction: Faction)

## How often (seconds) the server rebroadcasts authoritative fort state
## so client-side crew simulation drift gets reconciled
const FORT_SYNC_INTERVAL: float = 2.0

@export var time_to_win: float = 30 # 2min to hold majority to win
@export var faction_kills: Dictionary[int, int] = {}
@export var fort_factions: Dictionary[int, int] = {}
@export var factions: Dictionary[int, Faction] = {}

## All forts on the current map keyed by their deterministic fort_id
var forts: Dictionary[int, Fort] = {}
var _fort_sync_timer: float = 0.0

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
	factions.clear()
	forts.clear()
	_fort_sync_timer = 0.0


func _process(delta: float) -> void:
	if winning_faction_id != -1 and not winner_faction:
		victory_timer += delta
		victory_timer_updated.emit(get_faction(winning_faction_id), time_to_win - victory_timer)

		if victory_timer > time_to_win:
			winner_faction = get_faction(winning_faction_id)
			victory.emit(winner_faction)

	# Periodically push authoritative fort state to clients so their
	# locally-simulated crew captures converge back to the server's view
	if Lobby.active and multiplayer.is_server() and not forts.is_empty():
		_fort_sync_timer += delta
		if _fort_sync_timer >= FORT_SYNC_INTERVAL:
			_fort_sync_timer = 0.0
			for fort: Fort in forts.values():
				if is_instance_valid(fort):
					_broadcast_fort(fort)


## Register a fort at map-generation time, returning its deterministic id.
## Generation is seeded so every peer assigns the same ids.
func register_fort(fort: Fort) -> int:
	var id = total_forts
	forts[id] = fort
	total_forts += 1
	return id


## Called by forts whenever their crew/faction changes. On the server this
## broadcasts the authoritative state to all clients.
func notify_fort_changed(fort: Fort) -> void:
	if Lobby.active and multiplayer.is_server() and fort.fort_id != -1:
		_broadcast_fort(fort)


func _broadcast_fort(fort: Fort) -> void:
	var faction_id = fort.faction.id if fort.faction else -1
	_sync_fort.rpc(fort.fort_id, fort.crew, faction_id)


@rpc("authority", "call_remote", "reliable")
func _sync_fort(fort_id: int, crew: int, faction_id: int) -> void:
	var fort: Fort = forts.get(fort_id)
	if fort and is_instance_valid(fort):
		fort.apply_synced_state(crew, faction_id)


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
	if not factions.has(player_id):
		factions[player_id] = _create_faction(player_id)
	return factions[player_id]


## Generate a new faction
func _create_faction(player_id: int) -> Faction:
	var player_info: Dictionary = Lobby.players.get(player_id, {})
	var faction = Faction.new()
	faction.id = player_id
	faction.type = Faction.Type.Player
	# A peer that already disconnected may still be referenced by late
	# sync messages; fall back to the plain hull instead of crashing
	faction.boat = available_boats[player_info.get("boat", "plain")]
	return faction
