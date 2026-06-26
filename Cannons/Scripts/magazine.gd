class_name Magazine
extends Node2D

signal magazine_changed(count: int, capacity: int)

@export var capacity: int = 3
@export var reload_speed_sec: float = 2

@onready var reload_timer: Timer = $ReloadTimer

var count: int = capacity

func _ready() -> void:
	count = capacity
	magazine_changed.emit(count, capacity)

# "Chamber" a round
# Returns true if a round was consumed, false otherwise
func try_chamber_round() -> bool:
	if count > 0:
		count -= 1
		
		magazine_changed.emit(count, capacity)
		
		if reload_timer.is_stopped():
			reload_timer.start(reload_speed_sec)
			
		return true
	else:
		return false

func _on_reload_timer_timeout() -> void:
	if count < capacity:
		count += 1
		magazine_changed.emit(count, capacity)
	
	# If we are still low, auto-reload
	if count < capacity:
		reload_timer.start(reload_speed_sec)
