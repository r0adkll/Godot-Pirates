@abstract
class_name WeaponNode
extends Node2D

## Tell a weapon system how to trigger 
@abstract func action() -> StringName

## Fire this weapon node
@abstract func fire() -> void
