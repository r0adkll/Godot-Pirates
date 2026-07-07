class_name MusicSystem
extends Node
## Plays the game's music, cross-fading between tracks by game state:
## game won/lost > victory countdown > any enemy engaging the local
## player > main theme.

enum Track { MAIN, FIGHTING, VICTORY, WINNER, LOSER }

## How often the game state is sampled
const POLL_INTERVAL: float = 0.25

## How long fighting music lingers after the last enemy disengages, so a
## bot briefly losing its target doesn't thrash the music back and forth
const FIGHT_LINGER: float = 4.0

const FADE_DURATION: float = 1.5
const SILENCE_DB: float = -60.0

@onready var _players: Dictionary = {
	Track.MAIN: $MainTheme,
	Track.FIGHTING: $Fighting,
	Track.VICTORY: $Victory,
	Track.WINNER: $Winner,
	Track.LOSER: $Loser,
}

## Scene-authored volumes each track fades back in to
var _base_db: Dictionary = {}
var _tweens: Dictionary = {}

var current: Track = Track.MAIN
var _poll_timer: float = 0.0
var _fight_linger: float = 0.0


func _ready() -> void:
	for track in _players:
		_base_db[track] = _players[track].volume_db
	_players[Track.MAIN].play()


func _process(delta: float) -> void:
	_fight_linger = maxf(_fight_linger - delta, 0.0)
	_poll_timer += delta
	if _poll_timer < POLL_INTERVAL:
		return
	_poll_timer = 0.0

	if _is_player_engaged():
		_fight_linger = FIGHT_LINGER
	_transition_to(_desired_track())


func _desired_track() -> Track:
	# Game decided: play the local player's win/lose sting until the
	# next game resets the faction system
	var winner: Faction = FactionSystem.winner_faction
	if winner:
		return Track.WINNER if _is_local_winner(winner) else Track.LOSER
	# A faction holding the fort majority (the win countdown) trumps combat
	if FactionSystem.winning_faction_id != -1:
		return Track.VICTORY
	if _fight_linger > 0.0:
		return Track.FIGHTING
	return Track.MAIN


## Mirrors the game over menu's local-win check
func _is_local_winner(winner: Faction) -> bool:
	if Lobby.active:
		return winner.id == multiplayer.get_unique_id()
	return winner.type == Faction.Type.Player


## True when any hostile bot ship currently targets the local player's
## ship. Forts intentionally don't count — sailing past one shouldn't
## kick off fighting music.
func _is_player_engaged() -> bool:
	var local_ship: Node2D = null
	for ship in get_tree().get_nodes_in_group(Ship.GROUP):
		if ship.control == BaseShip.LOCAL:
			local_ship = ship
			break
	if not local_ship:
		return false

	for bot in get_tree().get_nodes_in_group(BotShip.GROUP):
		if bot.target == local_ship:
			return true

	return false


func _transition_to(track: Track) -> void:
	if track == current:
		return
	var from: AudioStreamPlayer = _players[current]
	var to: AudioStreamPlayer = _players[track]
	current = track

	# The main theme keeps playing muted so it resumes where it left off;
	# fighting/victory stop and restart from the top on their next entrance
	_fade(from, SILENCE_DB, from != _players[Track.MAIN])
	if not to.playing:
		to.volume_db = SILENCE_DB
		to.play()
	_fade(to, _base_db[track], false)


func _fade(player: AudioStreamPlayer, to_db: float, stop_after: bool) -> void:
	var old: Tween = _tweens.get(player)
	if old:
		old.kill()
	var tween := create_tween()
	tween.tween_property(player, "volume_db", to_db, FADE_DURATION)
	if stop_after:
		tween.tween_callback(player.stop)
	_tweens[player] = tween
