extends SceneTree
## Difficulty must scale enemy bot stats at spawn, per-instance:
## shooting_rate, cannon power, engage distance, detection radius, and
## the ShipsSystem population target. Two bots on different profiles
## must not share detection-shape state (the CircleShape2D in
## bot_ship.tscn is resource_local_to_scene — regression guard for the
## shared-shape bug where one bot targeting expanded everyone's radius).
## Run headless:
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s Utils/Tests/test_difficulty_apply.gd
##
## NOTE: project classes are load()ed at runtime and vars stay untyped —
## in -s mode this script compiles before autoloads register, so
## compile-time references to classes that use them fail.


func _initialize() -> void:
	# Wait a frame so autoloads are up and nodes added below enter the tree
	await process_frame

	var bot_scene: PackedScene = load("res://Ships/bot_ship.tscn")
	var kraken = load("res://Systems/Difficulty/krakens_wrath.tres")
	var calm = load("res://Systems/Difficulty/calm_seas.tres")
	var failed := false

	# Baseline values from an unmodified instance (never enters the tree,
	# so _apply_difficulty never runs on it)
	var vanilla = bot_scene.instantiate()
	var base_rate: float = vanilla.shooting_rate
	var base_power: float = vanilla.cannon.power
	var base_engage: float = vanilla.shooting_distance
	var base_radius: float = vanilla.get_detection_radius()

	var hard = _spawn(bot_scene, kraken)
	var easy = _spawn(bot_scene, calm)
	await physics_frame

	if not is_equal_approx(hard.shooting_rate, base_rate * kraken.shooting_rate_multiplier):
		print("FAIL: shooting_rate not scaled")
		failed = true
	if not is_equal_approx(hard.cannon.power, base_power * kraken.cannon_power_multiplier):
		print("FAIL: cannon power not scaled")
		failed = true
	if not is_equal_approx(hard.shooting_distance, base_engage * kraken.engage_distance_multiplier):
		print("FAIL: shooting_distance not scaled")
		failed = true
	if not is_equal_approx(hard.get_detection_radius(), base_radius * kraken.detection_radius_multiplier):
		print("FAIL: detection radius not scaled")
		failed = true
	# Per-instance isolation — the two bots must hold different radii
	if not is_equal_approx(easy.get_detection_radius(), base_radius * calm.detection_radius_multiplier):
		print("FAIL: detection shape shared across instances")
		failed = true

	# Population target honors difficulty, falls back to the export
	# (script-only node, never added to tree so %-lookups don't run)
	var ss = load("res://Systems/Ships/ships_system.gd").new()
	ss.difficulty = kraken
	if ss._target_enemy_count() != kraken.enemy_count:
		print("FAIL: enemy count target ignores difficulty")
		failed = true
	ss.difficulty = null
	if ss._target_enemy_count() != ss.enemy_count:
		print("FAIL: null difficulty should fall back to enemy_count export")
		failed = true

	vanilla.free()
	ss.free()
	print("RESULT: %s" % ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)


func _spawn(bot_scene: PackedScene, profile) -> Node:
	var bot = bot_scene.instantiate()
	bot.difficulty = profile
	# No ShipsSystem/nav in this harness — stop the behavior tree ticking
	bot.get_node("BeehaveTree").enabled = false
	root.add_child(bot)  # triggers _ready → _apply_difficulty
	return bot
