class_name DifficultyProfile
extends Resource
## Tunables for a single-player difficulty level. Only affects enemy
## bots — never the player. A null profile anywhere means vanilla stats.

@export var display_name: String = ""
@export_multiline var description: String = ""

## Absolute number of enemy ships ShipsSystem keeps alive
@export var enemy_count: int = 4

## Multiplier on BotShip.shooting_rate (a cooldown: > 1.0 shoots SLOWER)
@export var shooting_rate_multiplier: float = 1.0

## Multiplier on the bot's Cannon.power (cannonball damage)
@export var cannon_power_multiplier: float = 1.0

## Multiplier on both the default and attacking detection radii
@export var detection_radius_multiplier: float = 1.0

## Multiplier on BotShip.shooting_distance (engage/hold range)
@export var engage_distance_multiplier: float = 1.0
