extends CanvasLayer

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var is_paused: bool = false

func _ready() -> void:
	PauseMenu.state_changed.connect(_on_paused_changed)
	
func _on_paused_changed(paused: bool) -> void:
	is_paused = paused
	if paused:
		visible = true
		animation_player.play("transition")
	else:
		animation_player.play_backwards("transition")


func _on_resume_button_pressed() -> void:
	PauseMenu.resume()


func _on_quit_button_pressed() -> void:
	PauseMenu.resume()
	SceneLoader.load_scene(&"uid://dmt04rkfnmmkq")


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if !is_paused:
		visible = false
