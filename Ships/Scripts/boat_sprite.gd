class_name BoatSprite
extends Sprite2D

enum State { 
	NEW, 
	LIGHT_DMG, 
	HEAVY_DMG, 
	DEAD 
}

# The state of the boat sprite
var state: State = State.NEW

@export var hulls: BoatHulls

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	apply_state(state)


# Set the state of this ship sprite applying the appropriate texture for the state of
# the ship
func apply_state(s: State) -> void:
	state = s
	match state:
		State.NEW:
			texture = hulls.new_sprite
		State.LIGHT_DMG:
			texture = hulls.damage_light
		State.HEAVY_DMG:
			texture = hulls.damage_heavy
		State.DEAD:
			texture = hulls.dead
