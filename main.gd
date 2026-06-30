class_name MainGame
extends Node2D

@onready var ships_system: ShipsSystem = %ShipsSystem
@onready var hud: Hud = $HUD

@export var player_faction: Faction

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	SceneSpawnerSystem.entity_owner = self
	ships_system.player_faction = player_faction
	hud.player_counter.faction = player_faction


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass
