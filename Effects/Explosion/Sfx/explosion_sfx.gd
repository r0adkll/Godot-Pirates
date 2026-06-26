class_name ExplosionSfx
extends Node

## Proxy signal for the audio players
signal finished

@onready var sfx: Dictionary = {
	0: $Explosion1,
	1: $Explosion2,
	2: $Explosion3,
	3: $Explosion4,
}

@export var volume: float = -20.0 #dB

var is_playing: bool: get = _get_is_playing

func play_random() -> void:
	var sfx_player: AudioStreamPlayer = sfx[randi_range(0, 3)]
	sfx_player.volume_db = volume
	sfx_player.finished.connect(_signal_finished, Object.CONNECT_ONE_SHOT)
	sfx_player.play()

func _get_is_playing() -> bool:
	return sfx.values().any(func (p: AudioStreamPlayer): return p.playing)

func _signal_finished() -> void:
	finished.emit()
