@tool
class_name MainMenu
extends CanvasLayer

@export var game_scene: StringName = &""
@export var lobby_scene: StringName = &""
@export var boat_hulls: Array[BoatHulls] = []
@export var difficulties: Array[DifficultyProfile] = []

## Rough Waters — transient, resets every launch
const DEFAULT_DIFFICULTY_INDEX := 1

@onready var ship_texture: TextureRect = $PanelContainer/VBoxContainer/ShipSelector/ShipTexture
@onready var difficulty_name: Label = $PanelContainer/VBoxContainer/DifficultySelector/DifficultyInfo/DifficultyName
@onready var difficulty_description: Label = $PanelContainer/VBoxContainer/DifficultySelector/DifficultyInfo/DifficultyDescription
@onready var multiplayer_buttons: HBoxContainer = $PanelContainer/VBoxContainer/Buttons2
@onready var join_game_menu: JoinGame = $"../JoinGameMenu"
@onready var settings_menu: SettingsMenu = $"../SettingsMenu"

var current_hull: int = 0
var current_difficulty: int = DEFAULT_DIFFICULTY_INDEX

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ship_texture.texture = boat_hulls[0].new_sprite
	_update_difficulty_display()
	# Multiplayer is WIP and ENet doesn't work in browsers
	if OS.has_feature("web"):
		multiplayer_buttons.visible = false


## UI ACTIONS

func _on_new_game_button_pressed() -> void:
	SceneLoader.load_scene(game_scene, _apply_hull_to_new_game)


func _on_settings_button_pressed() -> void:
	settings_menu.visible = true


func _on_multiplayer_button_pressed() -> void:
	SceneLoader.load_scene(lobby_scene, _host_multiplayer_lobby)

func _host_multiplayer_lobby(new_scene: Node) -> void:
	var lobby = new_scene as LobbyMenu
	lobby.is_host = true

func _on_join_game_button_pressed() -> void:
	join_game_menu.visible = true

func _on_left_ship_selector_pressed() -> void:
	_change_hull(-1)


func _on_right_ship_selector_pressed() -> void:
	_change_hull(1)


func _change_hull(direction: int) -> void:
	current_hull = (current_hull + direction) % boat_hulls.size()
	ship_texture.texture = boat_hulls[current_hull].new_sprite


func _on_left_difficulty_selector_pressed() -> void:
	_change_difficulty(-1)


func _on_right_difficulty_selector_pressed() -> void:
	_change_difficulty(1)


func _change_difficulty(direction: int) -> void:
	current_difficulty = wrapi(current_difficulty + direction, 0, difficulties.size())
	_update_difficulty_display()


func _update_difficulty_display() -> void:
	# @tool safety: in-editor the array may not be populated yet
	if difficulties.is_empty():
		return
	var profile := difficulties[current_difficulty]
	difficulty_name.text = profile.display_name
	difficulty_description.text = profile.description


func _apply_hull_to_new_game(new_scene: Node) -> void:
	var player_faction = Faction.new()
	player_faction.id = 0
	player_faction.type = Faction.Type.Player
	player_faction.boat = boat_hulls[current_hull]

	var game = new_scene as MainGame
	game.player_faction = player_faction
	game.difficulty = difficulties[current_difficulty]


func _on_join_game_menu_join_game(_address: String, player_name: String) -> void:
	Lobby.player_info["name"] = player_name
	SceneLoader.load_scene(lobby_scene, _join_multiplayer_lobby)

func _join_multiplayer_lobby(new_scene: Node) -> void:
	var lobby = new_scene as LobbyMenu
	lobby.is_host = false
	lobby.host_address = join_game_menu.address_input.text
