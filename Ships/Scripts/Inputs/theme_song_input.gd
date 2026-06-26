extends PlayerInputNode

const MIN_VOLUME: float = -20 #dB
const MAX_VOLUME: float = 5 #dB
const VOLUME_INC_RATE: float = 10
const VOLUME_DEC_RATE: float = 25

@onready var theme_song: AudioStreamPlayer = %ThemeSong


@export var enabled: bool = true

var _theme_volume: float = MIN_VOLUME


func process_input(delta: float) -> void:
	if enabled:
		var is_movement_pressed = (Input.is_action_pressed("ui_up") or Input.is_action_pressed("ui_down") or Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_right"))
		if is_movement_pressed:
			_theme_volume = move_toward(_theme_volume, MAX_VOLUME, VOLUME_INC_RATE * delta)
		else:
			_theme_volume = move_toward(_theme_volume, MIN_VOLUME, VOLUME_INC_RATE * delta)
		
		theme_song.volume_db = _theme_volume
		if _theme_volume > MIN_VOLUME and !theme_song.playing:
			theme_song.playing = true
		elif _theme_volume <= MIN_VOLUME and theme_song.playing:
			theme_song.playing = false
