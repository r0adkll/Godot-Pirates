class_name TreasureChest
extends Area2D

const GROUP = &"treasure"

@onready var chest: Sprite2D = $Chest
@onready var health_bar: HealthBar = $HealthBar

@export() var plunder_rate: int = 1

var max_coins: int = 100
var coins: int

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group(GROUP)
	coins = max_coins


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	# Resource Health
	health_bar.progress = float(coins) / float(max_coins)
	
	# Make the resource translucent when empty!
	if coins <= 0:
		modulate.a = 0.25
	else:
		modulate.a = 1

## Whether or not this chest has any more treasure
func has_treasure() -> bool:
	return coins > 0

## "Plunder" this booty and receive 
func acquire_treasure() -> Treasure:
	if coins <= 0: return null
	
	coins -= plunder_rate
	coins = clampi(coins, 0, max_coins)
	var treasure = Treasure.new()
	treasure.coin = plunder_rate
	return treasure
	
