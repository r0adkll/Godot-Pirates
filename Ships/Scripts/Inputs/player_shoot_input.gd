extends PlayerInputNode


func process_input(_delta: float) -> void:
	# Fire Cannon on input
	if Input.is_action_just_pressed("ui_shoot"):
		get_ship().fire_main_cannon()
