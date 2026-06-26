extends Node

var entity_owner: Node2D


func add_entity(node: Node2D) -> void:
	entity_owner.add_child(node)
	

func remove_entity(node: Node2D) -> void:
	entity_owner.remove_child(node)
