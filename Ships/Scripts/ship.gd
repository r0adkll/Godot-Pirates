class_name Ship
extends BaseShip
## The main controller for the Player controlled ship

const GROUP = &"Player"

const cursor_target := preload("res://UI/Cursor/target_round_a.png")
const floating_crew := preload("res://Crew/floating_crew.tscn")

@export var game_camera: PlayerCamera

## Nodes / Components
@onready var sprite: BoatSprite = $BoatSprite
@onready var player_input: PlayerInput = $PlayerInput
@onready var aim_cursor: Sprite2D = $AimCursor

@onready var camera_harness: CameraHarness = $CameraHarness
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionPolygon2D = $CollisionPolygon2D
@onready var theme_song: AudioStreamPlayer = $Music/ThemeSong

@onready var emote: Emote = $Emote
@onready var hud: Hud = $"../HUD" #FIXME: This is broke af


func _ready() -> void:
	super._ready()
	add_to_group(GROUP)
	if game_camera:
		game_camera.set_following(camera_harness)
	# Setup mouse pointer
	# TODO: Adjust for controller inputs
	Input.set_custom_mouse_cursor(cursor_target, Input.CursorShape.CURSOR_ARROW, Vector2(16, 16))
	
	# Connect the HUD
	# TODO: There is probably a better way to connect ship-based state 
	#       to our HUD UI. This works for now, but is messy AF.
	if hud:
		hud.connect_magazine(cannon.magazine)
		hud.set_crew_count(crew_cabin.crew, crew_cabin.max_crew)
		coin_changed.connect(hud.set_coin_count)
		hud.set_coin_count(coin)
		

func _exit_tree() -> void:
	if hud:
		hud.disconnect_magazine(cannon.magazine)
		coin_changed.disconnect(hud.set_coin_count)

# Check health and other states of the ship that are not
# movement / frame critical
func _process(delta: float) -> void:
	super._process(delta)
	
	# DEBUG: If beached, modulate
	var beached_emote = Emote.Emotes.EMPTY
	if beach_head:
		if !emote.is_showing_emote():
			emote.emote = beached_emote
			emote.set_custom_icon(5) # F
			emote.duration = Emote.Duration.INFINITE
			emote.show_emote()
	else:
		#modulate = Color.WHITE
		if emote.is_showing_emote() and emote.emote == beached_emote:
			emote.hide_emote()


# Update and move our ship
func _physics_process(delta: float) -> void:
	can_drift = beach_head == null
	super._physics_process(delta)
	# Apply inputs if ship is alive
	if state == State.ALIVE:
			
		# Deploy crew if we are beached and we have crew
		if Input.is_action_just_pressed("ui_deploy") and beach_head and crew_cabin.crew > 0:
			# Decrease our cabin crew count
			crew_cabin.deploy(self, beach_head.island, beach_head.get_landing_position(), rotation + 90)
		
		# On Esc/ or start show the pause menu
		if Input.is_action_just_pressed("ui_cancel"):
			PauseMenu.pause()
				
		
	# Clamp our velocity and compute speed percentage
	#var ship_speed = abs(ship_velocity) / MAX_FORWARD_SPEED
		
	# Compute rotation based on angular velocity
	#var max_turning_strength = ship_speed * MAX_TURN_SPEED
	#angular_velocity = clampf(angular_velocity, -max_turning_strength, max_turning_strength)
	#rotation += angular_velocity * delta
	emote.rotation = -rotation
	
	# Move the boat
	move_and_slide()
	
	# Update beached state
	# Due to how the last_collision property works it HAS to be
	# called after move_and_slide() 
	check_if_beached()


## Handle any Player Ship specific functions when it dies here
func _on_die(_source: Faction) -> void:
	collision_shape.disabled = true
	remove_from_group(GROUP)
	
	game_camera.add_trauma(0.8)
	$Sfx/WoodBreaking.play()
	
	if hud:
		hud.set_crew_count(0, crew_cabin.max_crew)
	
	# Start "Sink" Animation
	animation_player.play(&"sinking")


func _generate_explosions() -> void:
	for i in range(15):
		var offset_rotation = randf() * (2*PI)
		var offset_magnitude = randf() * 75
		var offset = Vector2(1, 0).rotated(offset_rotation) * offset_magnitude
		var delay = randf() * 0.5
		
		var new_exp: Explosion = explosion.instantiate()
		new_exp.global_position = global_position + offset
		new_exp.delay = delay
		SceneSpawnerSystem.add_entity(new_exp)


func _on_lost_beach_head(_beach: BaseShip.BeachHead) -> void:
	pass


func _on_damage_target_apply_damage(hit_faction: Faction, amount: float) -> void:
	if state == State.ALIVE:
		# Hit Flash
		animation_player.play(&"hit_flash", -1, 2.5)
		
		# Camera shake
		game_camera.add_trauma(0.35)
		
		# Emote
		emote.emote = Emote.Emotes.ANGRY
		emote.duration = Emote.Duration.SHORT
		emote.show_emote()
		
		# Decrement health / check for death
		health -= amount
		if health <= 0:
			die(hit_faction)


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == &"sinking":
		state = State.DEAD
		fade_away()


func _on_crew_cabin_crew_updated(count: int, max_crew: int) -> void:
	if hud:
		hud.set_crew_count(count, max_crew)


func _on_crew_returned(amount: int) -> void:
	crew_cabin.add_crew(amount)
