class_name LobbyMenu
extends Node2D

const player_row_scene := preload("res://MainMenu/player_row.tscn")

@onready var start_game_button: Button = $Menu/PanelContainer/VBoxContainer/StartGameButton
@onready var ready_check_button: HBoxContainer = $Menu/PanelContainer/VBoxContainer/ReadyCheckButton
@onready var ready_button: Button = $Menu/PanelContainer/VBoxContainer/ReadyCheckButton/ReadyButton
@onready var ready_check_box: TextureRect = $Menu/PanelContainer/VBoxContainer/ReadyCheckButton/ReadyCheckBox
@onready var name_input: LineEdit = $Menu/PanelContainer/VBoxContainer/NameInput
@onready var player_list: VBoxContainer = $Menu/Players/PlayerList

@onready var ship_texture: TextureRect = $Menu/PanelContainer/VBoxContainer/ShipSelector/ShipTexture

@export var available_boats: Dictionary[String, BoatHulls] = {}

var is_host: bool = true
var host_address: String
var current_hull: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	name_input.text = Lobby.player_info["name"]
	
	if is_host:
		start_game_button.visible = true
		ready_check_button.visible = false
	else:
		start_game_button.visible = false
		ready_check_button.visible = true
		
	Lobby.player_connected.connect(_on_player_connected)
	Lobby.player_disconnected.connect(_on_player_disconnected)
	Lobby.server_disconnected.connect(_on_server_disconnected)
	if is_host:
		Lobby.create_game()
	elif host_address:
		Lobby.join_game(host_address)


func _on_player_connected(peer_id: int, player_info: Dictionary) -> void:
	var existing = _find_player_row(peer_id)
	if existing:
		existing.player_name = player_info["name"]
		existing.boat = available_boats[player_info["boat"]]
	else:
		var new_player_row: PlayerRow = player_row_scene.instantiate()
		new_player_row.peer_id = peer_id
		new_player_row.player_name = player_info["name"]
		new_player_row.boat = available_boats[player_info["boat"]]
		player_list.add_child(new_player_row)


func _on_player_disconnected(peer_id: int) -> void:
	var player_row = _find_player_row(peer_id)
	if player_row:
		player_list.remove_child(player_row)


func _find_player_row(peer_id: int) -> PlayerRow:
	for child in player_list.get_children():
		var player_row = child as PlayerRow
		if player_row.peer_id == peer_id:
			return player_row
	return null


func _on_server_disconnected() -> void:
	SceneLoader.load_scene("uid://dmt04rkfnmmkq")


func _on_name_input_text_submitted(new_text: String) -> void:
	print("Updated: %s" % new_text)
	Lobby.player_info["name"] = new_text
	Lobby._on_player_updated()


func _on_left_ship_selector_pressed() -> void:
	_change_hull(-1)


func _on_right_ship_selector_pressed() -> void:
	_change_hull(1)


func _change_hull(direction: int) -> void:
	current_hull = (current_hull + direction) % available_boats.size()
	var boat_key = available_boats.keys()[current_hull]
	ship_texture.texture = available_boats.values()[current_hull].new_sprite
	Lobby.player_info["boat"] = boat_key
	Lobby._on_player_updated()


func _on_start_game_button_pressed() -> void:
	if multiplayer.is_server():
		Lobby.load_game.rpc("uid://ba4c0ajms5lda")
