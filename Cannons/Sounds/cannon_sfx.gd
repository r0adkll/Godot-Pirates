class_name CannonSfx
extends Node

enum Effects {
	FIRE_1,
	FIRE_2,
	FIRE_3,
	RANDOM,
}

@onready
var _PLAYERS: Dictionary = {
	Effects.FIRE_1: $Fire1,
	Effects.FIRE_2: $Fire2,
	Effects.FIRE_3: $Fire3,
}

var _START_TIMES: Dictionary = {
	Effects.FIRE_1: 0.0,
	Effects.FIRE_2: 0.25,
	Effects.FIRE_3: 0.25,
}

@export var effect: Effects = Effects.FIRE_1


func _ready() -> void:
	if effect == Effects.RANDOM:
		effect = _random_effect()

func play() -> void:
	if effect == Effects.RANDOM:
		var r_effect = _random_effect()
		play_effect(r_effect)
	else:
		play_effect(effect)
	
	
func play_effect(e: Effects) -> void:
	if e == Effects.RANDOM: return
	_PLAYERS[e].play(_START_TIMES[e])


func _random_effect() -> Effects:
	match randi_range(0, 2):
		0: return Effects.FIRE_1
		1: return Effects.FIRE_2
		2: return Effects.FIRE_3
		_: return Effects.FIRE_1
