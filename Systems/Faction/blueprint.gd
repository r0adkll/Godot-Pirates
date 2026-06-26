class_name Blueprint
extends Resource

enum Type {
	BASE,
	OUTPOST,
}

@export var type: Type
@export var faction: Faction
var coordinates: Vector2i
