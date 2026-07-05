extends CanvasLayer

@export var new_game_scene: StringName = &""
@export var main_menu_scene: StringName = &""

@onready var banner: Label = $VBoxContainer/PanelContainer/Banner/Banner
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var description: Label = %GameOverDescription


const WIN_MESSAGES: Array[String] = [
	"Victory be yers! The seven seas bow to yer flag!",
	"Ye've plundered yer way to glory, Cap'n!",
	"The Karebeean be yers, ye salty sea dog!",
	"Huzzah! Davy Jones weeps at yer triumph!",
	"Yo ho ho! The booty and the glory be all yers!",
	"All hands salute ye — king o' the Karebeean!",
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
	# Set the state and pause the game
	is_game_over = true
	visible = true
	animation_player.play("transition")
	get_tree().paused = true
	
	# Update the victor label
	# TODO: This is not flexible to a multiplayer setup currently, but just an MVP
	#       for the single player experience
	if faction.type == Faction.Type.Player:
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
	SceneLoader.load_scene(main_menu_scene)
