extends SceneTree
## Headless check that SFX players are positional (AudioStreamPlayer2D),
## inherit their owner's world transform, and vary pitch per shot.
## Run: Godot --headless -s Utils/Tests/test_positional_sfx.gd

var failures := 0


func _initialize() -> void:
	await process_frame
	_run()


func _run() -> void:
	# --- CannonSfx: positional players + transform inheritance + pitch variance ---
	var cannon_sfx_scene = load("res://Cannons/Sounds/cannon_sfx.tscn")
	var holder := Node2D.new()
	holder.position = Vector2(1234, 567)
	root.add_child(holder)
	var cannon_sfx = cannon_sfx_scene.instantiate()
	holder.add_child(cannon_sfx)
	await process_frame

	_check(cannon_sfx is Node2D, "CannonSfx root is Node2D")
	var fire1 = cannon_sfx.get_node("Fire1")
	_check(fire1 is AudioStreamPlayer2D, "Fire1 is AudioStreamPlayer2D")
	_check(fire1.global_position == Vector2(1234, 567),
		"Fire1 inherits parent transform (got %s)" % fire1.global_position)
	_check(fire1.max_distance == 2500.0, "Fire1 max_distance set")

	var base_pitch: float = fire1.pitch_scale
	var pitches := {}
	for i in range(12):
		cannon_sfx.play_effect(cannon_sfx.Effects.FIRE_1)
		pitches[fire1.pitch_scale] = true
		_check(absf(fire1.pitch_scale - base_pitch) <= base_pitch * 0.1 + 0.001,
			"pitch within variance (got %f, base %f)" % [fire1.pitch_scale, base_pitch])
	_check(pitches.size() > 1, "pitch varies across shots (%d unique)" % pitches.size())

	# --- Explosion: positional players + transform inheritance ---
	var explosion_scene = load("res://Effects/Explosion/explosion.tscn")
	var explosion = explosion_scene.instantiate()
	explosion.position = Vector2(-400, 250)
	root.add_child(explosion)
	await process_frame

	var exp_sfx = explosion.get_node("Sfx")
	_check(exp_sfx is Node2D, "Explosion Sfx container is Node2D")
	var exp1 = exp_sfx.get_node("Explosion1")
	_check(exp1 is AudioStreamPlayer2D, "Explosion1 is AudioStreamPlayer2D")
	_check(exp1.global_position == Vector2(-400, 250),
		"Explosion1 inherits explosion position (got %s)" % exp1.global_position)
	exp_sfx.play_random()
	_check(exp_sfx.is_playing, "explosion sfx plays")

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
