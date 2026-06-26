class_name Hud
extends CanvasLayer

const kill_counter_scene := preload("res://UI/kill_counter.tscn")

@onready var ammo_container: UiAmmoContainer = $PlayerContainer/Magazine/MarginContainer/AmmoContainer
@onready var crew_counter: Label = $PlayerContainer/CrewCounter/HBoxContainer/MarginContainer/Label
@onready var coin_counter: Label = $PlayerContainer/Coins/HBoxContainer/MarginContainer/Label

@onready var player_counter: KillCounter = $KillCounters/PlayerCounter
@onready var enemy_counter: KillCounter = $KillCounters/EnemyCounter


func _ready() -> void:
	FactionSystem.kills_updated.connect(_on_faction_kills_updated)


func connect_magazine(magazine: Magazine) -> void:
	magazine.magazine_changed.connect(_on_magazine_changed)
	_on_magazine_changed(magazine.count, magazine.capacity)
	
	
func disconnect_magazine(magazine: Magazine) -> void:
	magazine.magazine_changed.disconnect(_on_magazine_changed)
	

func set_crew_count(count: int, max_crew: int) -> void:
	crew_counter.text = "{0}/{1}".format([count, max_crew])
	

func _on_magazine_changed(count: int, capacity: int) -> void:
	ammo_container.set_capacity(capacity)
	ammo_container.set_count(count)

func set_coin_count(amount: int) -> void:
	coin_counter.text = "%d" % amount


func _on_faction_kills_updated(faction: Faction, count: int) -> void:
	## TODO: This should probably be more dynamic or configured by 
	##       a faction system, but this works for now.
	if faction.equals(player_counter.faction):
		player_counter.set_count(faction, count)
	elif faction.equals(enemy_counter.faction):
		enemy_counter.set_count(faction, count)
	
