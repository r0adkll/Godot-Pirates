extends SceneTree
## Headless check that the SFX/Music bus layout loads, players are routed
## to the right buses, and Settings volume properties drive the AudioServer.
## Run: Godot --headless -s Utils/Tests/test_audio_buses.gd

var failures := 0


func _initialize() -> void:
	await process_frame
	_run()


func _run() -> void:
	# --- Bus layout ---
	var sfx_idx := AudioServer.get_bus_index(&"SFX")
	var music_idx := AudioServer.get_bus_index(&"Music")
	_check(sfx_idx >= 0, "SFX bus exists")
	_check(music_idx >= 0, "Music bus exists")
	if failures > 0:
		print("%d CHECKS FAILED" % failures)
		quit(1)
		return
	_check(AudioServer.get_bus_send(sfx_idx) == &"Master", "SFX sends to Master")
	_check(AudioServer.get_bus_send(music_idx) == &"Master", "Music sends to Master")

	# --- Player routing ---
	var cannon_sfx = load("res://Cannons/Sounds/cannon_sfx.tscn").instantiate()
	root.add_child(cannon_sfx)
	await process_frame
	_check(cannon_sfx.get_node("Fire1").bus == &"SFX", "cannon fire routed to SFX")

	var explosion = load("res://Effects/Explosion/explosion.tscn").instantiate()
	root.add_child(explosion)
	await process_frame
	_check(explosion.get_node("Sfx/Explosion1").bus == &"SFX", "explosion routed to SFX")

	# --- Settings drive the AudioServer ---
	var settings = root.get_node("/root/Settings")
	var original_sfx: float = settings.sfx_volume
	var original_music: float = settings.music_volume

	settings.sfx_volume = 0.5
	_check(absf(AudioServer.get_bus_volume_db(sfx_idx) - linear_to_db(0.5)) < 0.01,
		"sfx_volume=0.5 sets SFX bus to %f dB" % linear_to_db(0.5))
	_check(!AudioServer.is_bus_mute(sfx_idx), "SFX bus not muted at 0.5")

	settings.sfx_volume = 0.0
	_check(AudioServer.is_bus_mute(sfx_idx), "SFX bus muted at 0")

	settings.music_volume = 0.75
	_check(absf(AudioServer.get_bus_volume_db(music_idx) - linear_to_db(0.75)) < 0.01,
		"music_volume=0.75 sets Music bus volume")

	settings.sfx_volume = 2.0
	_check(settings.sfx_volume == 1.0, "volume clamped to 1.0")
	_check(!AudioServer.is_bus_mute(sfx_idx), "SFX bus unmuted again")

	# Restore user's real settings (setters persist to user://settings.cfg)
	settings.sfx_volume = original_sfx
	settings.music_volume = original_music

	# --- Menus still instantiate with the new controls ---
	var settings_menu = load("res://MainMenu/settings_menu.tscn").instantiate()
	root.add_child(settings_menu)
	await process_frame
	var slider = settings_menu.get_node("PanelContainer/VBoxContainer/SfxVolumeRow/SfxVolumeSlider")
	_check(slider is HSlider, "settings menu has SFX slider")
	_check(absf(slider.value - settings.sfx_volume) < 0.001, "slider initialized from Settings")

	var pause_menu = load("res://MainMenu/pause_menu.tscn").instantiate()
	root.add_child(pause_menu)
	await process_frame
	_check(pause_menu.get_node_or_null("SettingsMenu") != null, "pause menu embeds settings menu")

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
