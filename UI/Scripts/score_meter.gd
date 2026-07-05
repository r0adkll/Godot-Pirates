extends HBoxContainer

@onready var player_counter: KillCounter = $PlayerCounter
@onready var enemy_counter: KillCounter = $EnemyCounter

@onready var player_progress: Panel = $ControlBar/Meter/HBoxContainer/PlayerProgress
@onready var player_divider: Panel = $ControlBar/Meter/HBoxContainer/PlayerDivider
@onready var empty_progress: Panel = $ControlBar/Meter/HBoxContainer/EmptyProgress
@onready var enemy_divider: Panel = $ControlBar/Meter/HBoxContainer/EnemyDivider
@onready var enemy_progress: PanelContainer = $ControlBar/Meter/HBoxContainer/EnemyProgress


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	FactionSystem.conquest_updated.connect(_on_faction_system_conquest_updated)


func _on_faction_system_conquest_updated(conquest: Dictionary[int, float]) -> void:
	var player_conquest = conquest.get_or_add(player_counter.faction.id, 0)
	var enemy_conquest = conquest.get_or_add(enemy_counter.faction.id, 0)
	var empty_conquest = 1 - (player_conquest + enemy_conquest)
	
	player_progress.size_flags_stretch_ratio = player_conquest
	enemy_progress.size_flags_stretch_ratio = enemy_conquest
	empty_progress.size_flags_stretch_ratio = empty_conquest
