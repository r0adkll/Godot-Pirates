class_name Emote
extends Control
## Class for displaying / controlling emotes for ships / entities

enum Emotes {
	EMPTY = 0,
	BROKEN_HEART = 4,
	HEART = 5,
	SMALL_HEARTS = 6,
	DBL_BANG = 7,
	EXCLAIM = 8, 
	QUESTION = 9,
	ZED = 10,
	SLEEP = 11,
	BARS = 12,
	HAPPY = 13,
	SAD = 14,
	ANGRY = 15,
	TADA = 16,
	STAR = 17,
	SPARKLE = 18, 
	MUSIC = 19,
	WATER = 20,
	WET = 21,
	POUND = 22,
	DOLLAR = 23,
	CONFUSION = 24,
	X = 25,
	O = 26,
	IDEA = 27,
	LAUGHING = 28,
	CLOUD = 29,
}

enum Duration {
	SHORT,
	LONG,
	INFINITE,
}

var SECONDS: Dictionary = {
	Duration.SHORT: 3,
	Duration.LONG: 8,
}

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var custom_icon: AnimatedSprite2D = $CustomIcon
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var timer: Timer = $Timer

@export var emote: Emotes = Emotes.EMPTY: set = _set_emote
@export var duration: Duration = Duration.SHORT
@export var remove_on_hide: bool = false

var is_showing: bool = false
func is_showing_emote() -> bool:
	return is_showing or animation_player.current_animation == &"appear"

func _set_emote(new_emote: Emotes) -> void:
	emote = new_emote
	sprite.set_frame_and_progress(emote, 0)
	custom_icon.visible = emote == Emotes.EMPTY
	

## Set the icon frame for the custom icon image for the emote
func set_custom_icon(frame: int, animation: String = "keyboard_filled"):
	custom_icon.animation = animation
	custom_icon.frame = frame

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	sprite.set_frame_and_progress(emote, 0)
	
	if duration != Duration.INFINITE:
		animation_player.play(&"appear")
		timer.start(SECONDS[duration])

func show_emote() -> void:
	animation_player.play(&"appear")
	if duration != Duration.INFINITE:
		timer.stop()
		timer.start(SECONDS[duration])


func hide_emote() -> void:
	animation_player.play(&"disappear")
	

func _on_timer_timeout() -> void:
	animation_player.play(&"disappear")
	

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	match anim_name:
		"appear": is_showing = true
		"disappear": is_showing = false
	
	if anim_name == &"disappear" and remove_on_hide:
		queue_free()
