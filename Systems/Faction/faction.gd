class_name Faction
extends Resource
## A descriptive node for entities to tell the game and systems
## which team they belong to or currently belong to. Used to identify
## multiple ships to each other, what team has currently captured an island
## what team a Fort belongs too, etc


## The enum type that dictates the TYPE of faction
## This controls whether entities are spawned with player controls
## with the forsight that we might want to support multiplayer at some
## point.
enum Type {
	Player,
	Bot,
}


## The id of the faction that this node is identifying
@export var id: int
@export var type: Type
@export var boat: BoatHulls

## Check if this faction is equal to another
func equals(other: Faction) -> bool:
	if !other: return false
	return id == other.id and type == other.type
