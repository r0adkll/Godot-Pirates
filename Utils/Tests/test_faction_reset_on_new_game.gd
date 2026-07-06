extends SceneTree
## Regression test: starting a singleplayer game from the main menu must
## reset the FactionSystem autoload.
##
## FactionSystem survives scene changes, and its victory countdown is
## gated on `not winner_faction`. Only the game-over "New Game" button
## called reset(), so any game started from the main menu after a
## finished round kept the previous winner and could never be won by
## either team. Run headless:
##   /Applications/Godot.app/Contents/MacOS/Godot --headless --path . -s Utils/Tests/test_faction_reset_on_new_game.gd
##
## NOTE: project classes are load()ed at runtime and vars stay untyped —
## in -s mode this script compiles before autoloads register, so
## compile-time references to classes that use them fail.


func _initialize() -> void:
	# Wait a frame so autoloads are up
	await process_frame

	var faction_system: Node = root.get_node("/root/FactionSystem")
	var enemy_faction = load("res://Systems/Faction/enemy_faction.tres")
	var failed := false

	# Pollute the autoload as if a previous round ended with an enemy win
	faction_system.winner_faction = enemy_faction
	faction_system.winning_faction_id = enemy_faction.id
	faction_system.victory_timer = 99.0
	faction_system.faction_kills.set(enemy_faction.id, 12)

	# Symptom check: with a stale winner the victory timer is frozen
	faction_system.victory_timer = 0.0
	await process_frame
	await process_frame
	if faction_system.victory_timer != 0.0:
		print("FAIL: victory timer should be blocked while a stale winner is set")
		failed = true

	# The menu's new-game transformer runs before the scene enters the
	# tree, so neither instance needs to be added here
	var menu_scene: PackedScene = load("res://main_menu.tscn")
	var menu_root = menu_scene.instantiate()
	var menu = _find_menu(menu_root)
	if not menu:
		print("FAIL: could not find MainMenu node in main_menu.tscn")
		print("RESULT: FAIL")
		quit(1)
		return

	var game_scene: PackedScene = load("uid://dbc8p40r5bsej")
	var game = game_scene.instantiate()
	menu._apply_hull_to_new_game(game)

	if faction_system.winner_faction != null:
		print("FAIL: winner_faction not cleared by menu new-game path")
		failed = true
	if faction_system.winning_faction_id != -1:
		print("FAIL: winning_faction_id not cleared by menu new-game path")
		failed = true
	if faction_system.victory_timer != 0.0:
		print("FAIL: victory_timer not cleared by menu new-game path")
		failed = true
	if not faction_system.faction_kills.is_empty():
		print("FAIL: faction_kills not cleared by menu new-game path")
		failed = true
	if game.player_faction == null:
		print("FAIL: transformer no longer assigns the player faction")
		failed = true

	# With the stale winner gone the countdown must be able to run again
	faction_system.winning_faction_id = enemy_faction.id
	await process_frame
	await process_frame
	if faction_system.victory_timer <= 0.0:
		print("FAIL: victory timer still blocked after reset")
		failed = true

	faction_system.reset()
	game.free()
	menu_root.free()

	print("RESULT: %s" % ("FAIL" if failed else "PASS"))
	quit(1 if failed else 0)


func _find_menu(node: Node) -> Node:
	if node.has_method("_apply_hull_to_new_game"):
		return node
	for child in node.get_children():
		var found = _find_menu(child)
		if found:
			return found
	return null
