class_name JoinGame
extends CanvasLayer

signal join_game(address: String, player_name: String)

@onready var name_input: LineEdit = $PanelContainer/VBoxContainer/NameInput
@onready var address_input: LineEdit = $PanelContainer/VBoxContainer/AddressInput
@onready var cancel_button: Button = $PanelContainer/VBoxContainer/Buttons/CancelButton
@onready var join_button: Button = $PanelContainer/VBoxContainer/Buttons/JoinButton

func _on_address_input_text_changed(_new_text: String) -> void:
	_validate_input()


func _on_name_input_text_changed(_new_text: String) -> void:
	_validate_input()


func _on_cancel_button_pressed() -> void:
	visible = false


func _on_join_button_pressed() -> void:
	join_game.emit(address_input.text, name_input.text)
	visible = false


func _validate_input() -> void:
	## TODO there should be IP address format editing, but 
	##      this is a demo so dropping that for now
	join_button.disabled = address_input.text.is_empty() or name_input.text.is_empty()
