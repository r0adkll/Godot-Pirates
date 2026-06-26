class_name UiAmmoIndicator
extends Control

@onready var foreground: TextureRect = $Foreground

@export var enabled: bool = true

func _ready() -> void:
	foreground.visible = enabled

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	foreground.visible = enabled
