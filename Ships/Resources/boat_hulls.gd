class_name BoatHulls
extends Resource
## Resource container class for all the stages of a single boats hull
## from brand new to dead. 

const PLAIN = "plain"
const RED = "red"
const BLUE = "blue"
const GREEN = "green"
const YELLOW = "yellow"
const PIRATE = "pirate"

@export var flag: Texture2D
@export var new_sprite: Texture2D
@export var damage_light: Texture2D
@export var damage_heavy: Texture2D
@export var dead: Texture2D


## Load a dictionary of all available boat hulls mapped to 
## the above constants
static func load_available_boats() -> Dictionary[String, BoatHulls]:
	return {
		PLAIN: ResourceLoader.load("res://Ships/Resources/plain_boat_hull.tres"),
		RED: ResourceLoader.load("res://Ships/Resources/red_boat_hull.tres"),
		BLUE: ResourceLoader.load("res://Ships/Resources/blue_boat_hull.tres"),
		GREEN: ResourceLoader.load("res://Ships/Resources/green_boat_hull.tres"),
		YELLOW: ResourceLoader.load("res://Ships/Resources/yellow_boat_hull.tres"),
		PIRATE: ResourceLoader.load("res://Ships/Resources/pirate_boat_hull.tres"),
	}
