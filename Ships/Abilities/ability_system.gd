@tool
class_name AbilitySystem
extends Node

signal state_changed(state: State, progress: float)

enum State {
	INACTIVE,
	ACTIVE, 
	RECHARGING,
}

@export var ship: Ship
@export var enabled: bool = true

var state: State = State.INACTIVE
var _active_time: float = 0
var _recharging_time: float = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	if get_child_count() == 0:
		return
	
	# Get the curret set ability
	var current_ability: ShipAbility = get_child(0)
	
	# Recharge the ability
	if state == State.RECHARGING:
		_recharging_time += delta
		state_changed.emit(state, clampf(_recharging_time / current_ability.recharge_time, 0, 1))
		if _recharging_time >= current_ability.recharge_time:
			_recharging_time = 0
			state = State.INACTIVE
			state_changed.emit(state, 1)
	elif state == State.ACTIVE:
		_active_time += delta
		state_changed.emit(state, clampf(_active_time / current_ability.duration, 0, 1))
		
	# Activate the ability
	if Input.is_action_just_pressed("ui_ability") and state == State.INACTIVE:
		state = State.ACTIVE
		state_changed.emit(state, 1)
		current_ability.activate(ship)
		
		await get_tree().create_timer(current_ability.duration).timeout
		current_ability.deactivate(ship)
		state = State.RECHARGING
		_active_time = 0
		state_changed.emit(state, 1)


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []
	
	if !ship:
		warnings.append("You must set a 'Ship' export")
	
	if get_child_count() == 0:
		warnings.append("You must attach at MOST one 'ShipAbility' node")
		
	if get_child_count() > 1:
		warnings.append("You can only attach one ability at a time, only the first is called")
		
	return warnings
