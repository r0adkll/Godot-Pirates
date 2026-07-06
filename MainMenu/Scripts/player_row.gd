class_name PlayerRow
extends PanelContainer

const checkbox_empty := preload("res://UI/Resources/BIG/checkbox_beige_empty 1.png")
const checkbox_checked := preload("res://UI/Resources/BIG/checkbox_beige_checked 1.png")

@onready var player_flag_texture: TextureRect = $HBoxContainer/PlayerFlag
@onready var player_name_label: Label = $HBoxContainer/PlayerName
@onready var ready_check_texture: TextureRect = $HBoxContainer/ReadyCheck

var peer_id: int

var boat: BoatHulls:
	set(new_value):
		boat = new_value
		if player_flag_texture:
			player_flag_texture.texture = boat.flag


var player_name: String:
	set(new_value):
		player_name = new_value
		if player_name_label:
			player_name_label.text = new_value


## Whether this player has readied up in the lobby
var ready_state: bool = false:
	set(new_value):
		ready_state = new_value
		if ready_check_texture:
			ready_check_texture.texture = checkbox_checked if ready_state else checkbox_empty

func _ready() -> void:
	player_flag_texture.texture = boat.flag
	player_name_label.text = player_name
	ready_check_texture.texture = checkbox_checked if ready_state else checkbox_empty
