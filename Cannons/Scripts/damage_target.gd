class_name DamageTarget
extends Node2D

signal apply_damage(faction: Faction, amount: float)

func damage(faction: Faction, amount: float) -> void:
	apply_damage.emit(faction, amount)
