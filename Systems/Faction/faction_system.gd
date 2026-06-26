extends Node

signal kills_updated(faction: Faction, count: int)

@export var faction_kills: Dictionary[String, int] = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func add_kill(faction: Faction, amount: int = 1) -> void:
	var current = faction_kills.get_or_add(faction.id, 0)
	var new_count = current + amount
	faction_kills.set(faction.id, new_count)
	kills_updated.emit(faction, new_count)
