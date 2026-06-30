@tool
class_name KillCounter
extends MarginContainer

@export var faction: Faction:
	set(new_value):
		faction = new_value
		if faction and flag_texture:
			flag_texture.texture = faction.boat.flag

@onready var flag_texture: TextureRect = $HBoxContainer/TextureRect
@onready var counter_label: Label = $HBoxContainer/Label

func _ready() -> void:
	set_count(faction, 0)

## Set the flag/counter for this
func set_count(_faction: Faction, count: int) -> void:
	flag_texture.texture = _faction.boat.flag
	counter_label.text = str(count)
