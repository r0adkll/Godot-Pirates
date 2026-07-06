class_name Broadsides
extends WeaponNode

@onready var r_cannon_1: Cannon = $RCannon1
@onready var r_cannon_2: Cannon = $RCannon2
@onready var r_cannon_3: Cannon = $RCannon3
@onready var l_cannon_1: Cannon = $LCannon1
@onready var l_cannon_2: Cannon = $LCannon2
@onready var l_cannon_3: Cannon = $LCannon3

@onready var cannons: Array[Cannon] = [
	l_cannon_1,
	l_cannon_2,
	l_cannon_3,
	r_cannon_1,
	r_cannon_2,
	r_cannon_3,
]

@export var faction: Faction
@export var origin: Node2D

func _ready() -> void:
	for cannon in cannons:
		cannon.faction = faction
		cannon.origin = origin


func action() -> StringName:
	return &"ui_accept"



## Fire the broadsides. All six cannons share one magazine, so a volley
## can be partial — the returned bitmask records exactly which cannons
## fired so remote peers can replay the same volley.
func fire(force_mask: int = 0) -> int:
	var fired_mask := 0
	for i in cannons.size():
		var forced := force_mask & (1 << i) != 0
		# Replaying a remote volley: only the cannons that actually
		# fired on the controlling peer, regardless of local magazine
		if force_mask != 0 and not forced:
			continue
		if cannons[i].fire(forced):
			fired_mask |= 1 << i
	return fired_mask
