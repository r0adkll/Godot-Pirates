class_name Cannon
extends Node2D

const cannon_ball_scene := preload("res://Cannons/cannon_ball.tscn")
const cannon_fire := preload("res://Cannons/cannon_fire.tscn")

@export var origin: Node2D
@export var faction: Faction
@export var magazine: Magazine
@export var power: float = 15.0
@export var muzzle_power: float = 1000.0

@export var fire_sfx: CannonSfx
@export var shoot_pos: Marker2D


# Fire the cannon from the 
func fire() -> bool:
	if magazine.try_chamber_round():
		var new_fire: CannonFire = cannon_fire.instantiate()
		new_fire.position = shoot_pos.position
		add_child(new_fire)
		
		var ball: CannonBall = cannon_ball_scene.instantiate()
		ball.velocity = Vector2.RIGHT.rotated(global_rotation) * muzzle_power
		ball.position = shoot_pos.global_position
		ball.rotation = global_rotation
		ball.damage = power
		ball.origin = origin
		ball.faction = faction
		SceneSpawnerSystem.add_entity(ball)
		
		fire_sfx.play()
		return true
	else:
		return false
