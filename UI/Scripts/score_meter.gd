extends VBoxContainer

@onready var player_counter: KillCounter = $ScoreMeter/PlayerCounter
@onready var enemy_counter: KillCounter = $ScoreMeter/EnemyCounter

@onready var victory_timer: Label = $VictoryTimer

@onready var player_progress: Panel = $ScoreMeter/ControlBar/Meter/HBoxContainer/PlayerProgress
@onready var player_divider: Panel = $ScoreMeter/ControlBar/Meter/HBoxContainer/PlayerDivider
@onready var empty_progress: Panel = $ScoreMeter/ControlBar/Meter/HBoxContainer/EmptyProgress
@onready var enemy_divider: Panel = $ScoreMeter/ControlBar/Meter/HBoxContainer/EnemyDivider
@onready var enemy_progress: PanelContainer = $ScoreMeter/ControlBar/Meter/HBoxContainer/EnemyProgress


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	FactionSystem.conquest_updated.connect(_on_faction_system_conquest_updated)
	FactionSystem.victory_timer_updated.connect(_on_faction_system_victory_timer_updated)
	FactionSystem.victory.connect(_on_faction_system_victory)


func _on_faction_system_conquest_updated(conquest: Dictionary[int, float]) -> void:
	if not player_counter.faction:
		return

	var player_conquest = conquest.get_or_add(player_counter.faction.id, 0)
	var enemy_conquest: float = 0.0
	if enemy_counter.faction:
		enemy_conquest = conquest.get_or_add(enemy_counter.faction.id, 0)
	else:
		# Multiplayer: no single enemy faction, show the strongest rival
		for faction_id in conquest:
			if faction_id != player_counter.faction.id:
				enemy_conquest = maxf(enemy_conquest, conquest[faction_id])
	var empty_conquest = 1 - (player_conquest + enemy_conquest)

	player_progress.size_flags_stretch_ratio = player_conquest
	enemy_progress.size_flags_stretch_ratio = enemy_conquest
	empty_progress.size_flags_stretch_ratio = empty_conquest


func _on_faction_system_victory_timer_updated(faction: Faction, remaining: float) -> void:
	if not faction:
		victory_timer.visible = false
		return
	else:
		victory_timer.visible = true
	
	if faction.equals(player_counter.faction):
		victory_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	else:
		victory_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	
	## Update the victory timer
	victory_timer.text = "%s until Victory" % convert_time(int(remaining))


func _on_faction_system_victory(_faction: Faction) -> void:
	victory_timer.text = "Victory!"
	victory_timer.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func convert_time(seconds: int) -> String:
	@warning_ignore("integer_division")
	var minutes: int = int((seconds % 3600) / 60)
	var remaining_seconds: int = int(seconds % 60)
	return "%2d:%02d" % [minutes, remaining_seconds]
