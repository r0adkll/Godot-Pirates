class_name UiAmmoContainer
extends VBoxContainer

const ammo_indicator_scene := preload("res://UI/ammo_indicator.tscn")

func set_count(count: int) -> void:
	var current_capacity = get_child_count()
	if count > current_capacity or count < 0:
		return
	
	for i in range(current_capacity):
		var idx = (current_capacity - 1) - i
		(get_child(idx) as UiAmmoIndicator).enabled = i < count

func set_capacity(capacity: int) -> void:
	var current_capacity = get_child_count()
	if current_capacity < capacity:
		var diff = capacity - current_capacity
		for i in range(diff):
			var indicator: UiAmmoIndicator = ammo_indicator_scene.instantiate()
			add_child(indicator)
	elif current_capacity > capacity:
		var diff = current_capacity - capacity
		for i in range(diff):
			var child = get_child(0)
			remove_child(child)
