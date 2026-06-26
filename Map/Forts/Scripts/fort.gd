class_name Fort
extends StaticBody2D

@onready var sprite: Sprite2D = $Sprite
@onready var faction_flag: Sprite2D = $FactionFlag
@onready var count: Label = $FactionFlag/Count
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var detection_area: Area2D = $DetectionArea
@onready var tl_cannon: FortCannon = $TL_Cannon
@onready var bl_cannon: FortCannon = $BL_Cannon
@onready var tr_cannon: FortCannon = $TR_Cannon
@onready var br_cannon: FortCannon = $BR_Cannon

@export var faction: Faction:
	set(new_value):
		faction = new_value
		_set_flag(new_value)
		
		# Remove targets that match this faction
		if new_value:
			_clean_targets()


## The amount of crew currently occupying this fort
@export var max_crew: int = 4
@export var crew: int = 0:
	set(new_value):
		crew = clampi(new_value, 0, max_crew)
		_set_crew_count()
		_update_cannons()
		_distribute_targets()
		if new_value <= 0:
			faction = null
			

## A fort can target up to [crew] number of targets
var targets: Array[Node2D] = []

## Get the center position of this entity
var center: Vector2: 
	get(): 
		return sprite.global_position

func _ready() -> void:
	_set_cannon_origin()
	_update_cannons()
	_distribute_targets()
	_set_crew_count()
	_clean_targets()
	_set_flag(faction)

func is_full() -> bool:
	return crew == max_crew

func _set_cannon_origin() -> void:
	tl_cannon.cannon.origin = self
	tr_cannon.cannon.origin = self
	bl_cannon.cannon.origin = self
	br_cannon.cannon.origin = self

func _update_cannons() -> void:
	if not is_visible_in_tree(): return
	if crew > 0: tl_cannon.visible = true
	else: tl_cannon.visible = false
	if crew > 1: tr_cannon.visible = true
	else: tr_cannon.visible = false
	if crew > 2: bl_cannon.visible = true
	else: bl_cannon.visible = false
	if crew > 3: br_cannon.visible = true
	else: br_cannon.visible = false


## Check whether or not a body is target-able
func _can_target(body: Node2D) -> bool:
	var dmg_target = body.get_node_or_null("DamageTarget")
	if dmg_target:
		# Check if it is a base ship and has health (i.e. not ded)
		var is_alive = true
		var is_ally = false
		if is_instance_of(body, BaseShip):
			var ship = (body as BaseShip)
			is_alive = ship.state == BaseShip.State.ALIVE
			is_ally = ship.faction.equals(faction)
			
		# If, in fact, is alive then return it otherwise skip
		if is_alive and !is_ally:
			return true
	
	# If none of the prior conditions match, return false
	return false


## Distribute the targets amongst all the crew'd cannons on the fort
func _distribute_targets() -> void:
	if not is_visible_in_tree(): return
	
	# Reset all cannons
	tl_cannon.target = null
	tr_cannon.target = null
	bl_cannon.target = null
	br_cannon.target = null

	# Can't target anything if we have no sight on any ships 
	# or any crew to man the cannons
	if targets.is_empty() or crew == 0:
		return
	
	# For each crew in the fort, man the cannons against known targets
	for c in crew:
		var cannon = _cannon_at(c)
		var target = targets.get(c) if targets.size() > c else targets.get(0)
		if target and cannon:
			cannon.cannon.faction = faction
			cannon.target = target

func _clean_targets() -> void:
	var non_targets: Array[Node2D] = []
	
	for target in targets:
		if is_instance_of(target, BaseShip):
			var ship = target as BaseShip
			if ship.faction.equals(faction):
				non_targets.append(target)
				if ship.state_changed.is_connected(_on_target_state_changed):
					ship.state_changed.disconnect(_on_target_state_changed)
	
	if not non_targets.is_empty():
		for dead in non_targets:
			targets.erase(dead)
		_distribute_targets()

func _cannon_at(idx: int) -> FortCannon:
	match idx:
		0: return tl_cannon
		1: return tr_cannon
		2: return bl_cannon
		3: return br_cannon
		_: return null


func _set_flag(f: Faction) -> void:
	if not is_inside_tree(): return
	
	if not f or not f.boat:
		faction_flag.visible = false
		faction_flag.texture = null
	elif f and f.boat:
		faction_flag.visible = true
		faction_flag.texture = f.boat.flag

func _set_crew_count() -> void:
	if not is_inside_tree(): return
	count.text = str(crew)

## Detection Zone Signals

func _on_detection_area_body_entered(body: Node2D) -> void:
	if body != self && body not in targets and _can_target(body):
		targets.append(body)
		_distribute_targets()
		
		# If the new target is of BaseShip, bind to its state signal
		if body is BaseShip:
			(body as BaseShip).state_changed.connect(_on_target_state_changed)

func _on_target_state_changed(
	ship: BaseShip, 
	_prev_state: BaseShip.State, 
	new_state: BaseShip.State,
) -> void:
	if new_state != BaseShip.State.ALIVE:
		_clear_target(ship)

func _clear_target(target: Node2D) -> void:
	# If exiting body is a base ship, disconnect its state signal
	# then set the target to null
	if target and target is BaseShip:
		var ship = target as BaseShip
		if ship.state_changed.is_connected(_on_target_state_changed):
			ship.state_changed.disconnect(_on_target_state_changed)
		targets.erase(target)
		_distribute_targets()

func _on_detection_area_body_exited(body: Node2D) -> void:
	_clear_target(body)
