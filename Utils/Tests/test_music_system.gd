extends SceneTree
## Headless check of the MusicSystem state machine: main theme by default,
## fighting music while an enemy targets the local player (with linger),
## victory music during the win countdown trumping everything.
## Run: Godot --headless -s Utils/Tests/test_music_system.gd

var failures := 0


func _initialize() -> void:
	await process_frame
	_run()


func _run() -> void:
	var faction_system = root.get_node("/root/FactionSystem")
	var music = (load("res://Music/music_system.tscn") as PackedScene).instantiate()
	root.add_child(music)

	# --- Default state ---
	_check(music.get_node("MainTheme").playing, "main theme plays on start")
	_check(!music.get_node("Fighting").playing, "fighting silent on start")
	_check(!music.get_node("Victory").playing, "victory silent on start")
	for player_name in ["MainTheme", "Fighting", "Victory"]:
		var stream = music.get_node(player_name).stream
		_check(stream.loop, "%s stream loops" % player_name)

	# --- Stub a local player ship and a bot engaging it ---
	var stub := GDScript.new()
	stub.source_code = "extends Node2D\nvar control: int = 0\nvar target: Node2D = null"
	stub.reload()

	var player_ship: Node2D = stub.new()
	player_ship.add_to_group(&"Player")
	root.add_child(player_ship)

	var bot: Node2D = stub.new()
	bot.add_to_group(&"BotShips")
	root.add_child(bot)

	await create_timer(0.6).timeout
	_check(music.current == music.Track.MAIN, "untargeted player keeps main theme")

	bot.target = player_ship
	await create_timer(0.6).timeout
	_check(music.current == music.Track.FIGHTING, "bot engaging player starts fighting music")
	_check(music.get_node("Fighting").playing, "fighting player is playing")
	_check(music.get_node("MainTheme").playing, "main theme stays playing (muted) for resume")

	# --- Disengage: linger holds, then falls back to main ---
	bot.target = null
	await create_timer(0.6).timeout
	_check(music.current == music.Track.FIGHTING, "fighting lingers briefly after disengage")
	music._fight_linger = 0.0
	await create_timer(0.6).timeout
	_check(music.current == music.Track.MAIN, "falls back to main theme after linger expires")

	# --- Victory countdown trumps combat ---
	bot.target = player_ship
	faction_system.winning_faction_id = 1
	await create_timer(0.6).timeout
	_check(music.current == music.Track.VICTORY, "win countdown plays victory music even mid-fight")
	_check(music.get_node("Victory").playing, "victory player is playing")

	# --- Countdown cancelled -> back to fighting ---
	faction_system.winning_faction_id = -1
	faction_system.victory_timer = 0
	await create_timer(0.6).timeout
	_check(music.current == music.Track.FIGHTING, "cancelled countdown returns to fighting music")

	# --- Game decided: winner/loser sting by local result ---
	faction_system.winning_faction_id = 0
	faction_system.winner_faction = load("res://Systems/Faction/player_faction.tres")
	await create_timer(0.6).timeout
	_check(music.current == music.Track.WINNER, "local player winning plays winner music")
	_check(music.get_node("Winner").playing, "winner player is playing")
	_check(music.get_node("Winner").stream.loop, "winner stream loops")

	faction_system.winner_faction = load("res://Systems/Faction/enemy_faction.tres")
	faction_system.winning_faction_id = 1
	await create_timer(0.6).timeout
	_check(music.current == music.Track.LOSER, "enemy winning plays loser music")
	_check(music.get_node("Loser").stream.loop, "loser stream loops")

	# Restore the faction system for any tests that follow
	faction_system.winner_faction = null
	faction_system.winning_faction_id = -1
	faction_system.victory_timer = 0

	if failures == 0:
		print("ALL CHECKS PASSED")
	else:
		print("%d CHECKS FAILED" % failures)
	quit(1 if failures > 0 else 0)


func _check(cond: bool, label: String) -> void:
	if cond:
		print("  PASS: " + label)
	else:
		failures += 1
		print("  FAIL: " + label)
