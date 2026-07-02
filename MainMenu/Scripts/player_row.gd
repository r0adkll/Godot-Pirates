class_name PlayerRow
extends PanelContainer

@onready var player_flag_texture: TextureRect = $HBoxContainer/PlayerFlag
@onready var player_name_label: Label = $HBoxContainer/PlayerName

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

func _ready() -> void:
	player_flag_texture.texture = boat.flag
	player_name_label.text = player_name
	
