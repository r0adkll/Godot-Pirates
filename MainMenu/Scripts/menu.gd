@tool
class_name MainMenu
extends CanvasLayer

@export var game_scene: StringName = &""
@export var boat_hulls: Array[BoatHulls] = []

@onready var ship_texture: TextureRect = $PanelContainer/VBoxContainer/ShipSelector/ShipTexture

var current_hull: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ship_texture.texture = boat_hulls[0].new_sprite


## UI ACTIONS

func _on_new_game_button_pressed() -> void:
	SceneLoader.load_scene(game_scene, _apply_hull_to_new_game)


func _on_settings_button_pressed() -> void:
	pass # Replace with function body.


func _on_left_ship_selector_pressed() -> void:
	_change_hull(-1)


func _on_right_ship_selector_pressed() -> void:
	_change_hull(1)


func _change_hull(direction: int) -> void:
	current_hull = (current_hull + direction) % boat_hulls.size()
	ship_texture.texture = boat_hulls[current_hull].new_sprite
	

func _apply_hull_to_new_game(new_scene: Node) -> void:
	var player_faction = Faction.new()
	player_faction.id = "player1"
	player_faction.type = Faction.Type.Player
	player_faction.boat = boat_hulls[current_hull]
	
	var game = new_scene as MainGame
	game.player_faction = player_faction
