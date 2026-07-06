extends CanvasLayer

@export var new_game_scene: StringName = &""
@export var main_menu_scene: StringName = &""

@onready var banner: Label = $VBoxContainer/PanelContainer/Banner/Banner
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var description: Label = %GameOverDescription
@onready var new_game_button: Button = $VBoxContainer/PanelContainer/MarginContainer/PanelContainer/MarginContainer/VBoxContainer/NewGame


const WIN_MESSAGES: Array[String] = [
	"Victory be yers! The seven seas bow to yer flag!",
	"Ye've plundered yer way to glory, Cap'n!",
	"The high seas be yers, ye salty sea dog!",
	"Huzzah! Davy Jones weeps at yer triumph!",
	"Yo ho ho! The booty and the glory be all yers!",
	"All hands salute ye — prince o' the privateers!",
	"Ye sank 'em all! Crack open the grog!",
	"A legend be born this day, Cap'n!",
]

const LOSE_MESSAGES: Array[String] = [
	"Ye've been sent to Davy Jones' locker!",
	"Yer ship be sleepin' with the fishes...",
	"Blimey! The sea has claimed another soul.",
	"Dead men tell no tales, matey.",
	"Yer treasure now belongs to the briny deep.",
	"Abandon ship! ...Too late for that, eh?",
	"The kraken sends its regards, landlubber.",
	"Walk the plank o' shame, ye scurvy dog.",
]

var is_game_over: bool = false

func _ready() -> void:
	FactionSystem.victory.connect(_on_victory)
	

func _on_victory(faction: Faction) -> void:
	# Set the state and pause the game. In multiplayer the world keeps
	# simulating for the other peers, so only pause locally offline.
	is_game_over = true
	visible = true
	animation_player.play("transition")
	if not Lobby.active:
		get_tree().paused = true

	# Restarting into a fresh round isn't supported in multiplayer yet;
	# players exit back to the main menu instead
	new_game_button.visible = not Lobby.active

	# Did the local player win?
	var player_won: bool
	if Lobby.active:
		player_won = faction.id == multiplayer.get_unique_id()
	else:
		player_won = faction.type == Faction.Type.Player

	if player_won:
		banner.text = "Winner!"
		description.text = WIN_MESSAGES.pick_random()
	else:
		banner.text = "Loser!"
		description.text = LOSE_MESSAGES.pick_random()


func _on_new_game_button_pressed() -> void:
	get_tree().paused = false
	SceneLoader.load_scene(new_game_scene, _setup_new_game)


func _setup_new_game(new_scene: Node) -> void:
	## FIXME: This is hardcoding the player faction, Ideally this would
	##        be more dynamic, but just getting this working for now.
	var player_faction = FactionSystem.get_faction(0)
	var game = new_scene as MainGame
	game.player_faction = player_faction
	
	# Reset the faction system
	FactionSystem.reset()


func _on_exit_button_pressed() -> void:
	get_tree().paused = false
	if Lobby.active:
		Lobby.remove_multiplayer_peer()
	SceneLoader.load_scene(main_menu_scene)


func _on_animation_player_animation_finished(_anim_name: StringName) -> void:
	pass
