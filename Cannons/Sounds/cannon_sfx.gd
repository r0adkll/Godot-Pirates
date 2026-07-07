class_name CannonSfx
extends Node2D

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

## Pitch variance so simultaneous broadside shots don't stack into
## one phasey wall of sound
@export var pitch_variance: float = 0.1

@export var effect: Effects = Effects.FIRE_1

var _base_pitches: Dictionary = {}


func _ready() -> void:
	for e in _PLAYERS:
		_base_pitches[e] = _PLAYERS[e].pitch_scale
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
	var player: AudioStreamPlayer2D = _PLAYERS[e]
	player.pitch_scale = _base_pitches[e] * randf_range(1.0 - pitch_variance, 1.0 + pitch_variance)
	player.play(_START_TIMES[e])


func _random_effect() -> Effects:
	match randi_range(0, 2):
		0: return Effects.FIRE_1
		1: return Effects.FIRE_2
		2: return Effects.FIRE_3
		_: return Effects.FIRE_1
