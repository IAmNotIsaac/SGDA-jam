class_name Enemy
extends KinematicBody


const _DamageIndicator := preload("res://src/instance/DamageIndicator.tscn")

enum MovementMode {
	STATIC,    # Does not move
	SCARED,    # Static unless player gets too close
	PATH,      # Follows a predetermined path
	CHASE      # Chases player
}

enum States {
	DEFAULT,   # Walking
	AIR,       # In air
	DEAD
}

enum AccuracyModes {
	LOW, MID, HIGH
}

enum ReactionModes {
	LOW, MID, HIGH
}

const _ACCURACY_FACTORS := {
	AccuracyModes.LOW:  deg2rad(15.0),
	AccuracyModes.MID:  deg2rad(8.0),
	AccuracyModes.HIGH: deg2rad(3.0)
}

const _REACTION_FACTORS := {
	ReactionModes.LOW:  [0.2, 0.4],
	ReactionModes.MID:  [0.07, 0.15],
	ReactionModes.HIGH: [0.02, 0.05]
}

const _Ragdoll := preload("res://src/instance/RobotRagdoll.tscn")

const _SPEED := 5.0
const _GRAVITY := 20.0
const _IDLE_TIME_AT_POINTS := 2000
const _MAX_HEALTH := 100.0

export(MovementMode) var _move_mode : int = MovementMode.STATIC
export(Resource) var _gun : Resource
export(AccuracyModes) var _accuracy_mode : int = AccuracyModes.MID
export(ReactionModes) var _reaction_mode : int = ReactionModes.MID
export(NodePath) var _path_points_path : NodePath
export(bool) var _no_damage := false

var _state := StateMachine.new(
	self, States
)
var _player : KinematicBody
var _velocity : Vector3
var _uncomfortable := false
var _time_at_point := 0
var _point_idx := -1
var _nav_finished := true
var _last_seen_player_pos = null
var _health := _MAX_HEALTH
var _permitted_shoot_time := 0.0

onready var _n_player_cast := $PlayerViewCast
onready var _n_agent := $NavigationAgent
onready var _n_model := $robot
onready var _n_anim := $robot/AnimationPlayer
onready var _n_skele := $robot/Armature/Skeleton
onready var _n_gun_model := $robot/GunModel
onready var _n_path_points := get_node_or_null(_path_points_path)


## Private methods ##


func _ready() -> void:
	if _gun != null:
		_n_gun_model.switch_to(_gun.get_base())
	var _e := _n_agent.connect("navigation_finished", self, "_on_agent_navfinished")
	_player = get_tree().get_nodes_in_group("player")[0]


func _physics_process(delta : float) -> void:
	_state.process(delta)
	
	if not _player.has_enemy(self) and can_see_player():
		_player.add_enemies([self])
	
	var b : Vector3 = _n_skele.get_bone_global_pose(_n_skele.find_bone("GunHold")).origin - _n_model.translation
	_n_gun_model.translation = (
		#_n_skele.get_bone_global_pose(_n_skele.find_bone("GunHold")).origin #+
		b
		#Vector3(sin(t), 0.0, cos(t))
	)


func _look_at_player() -> void:
	var dir := global_translation.direction_to(_player.global_translation)
	var rot := atan2(dir.x, dir.z)
	_n_model.rotation.y = rot


func _shoot_at_player(alt : bool) -> void:
	if OS.get_ticks_msec() / 1000.0 >= _permitted_shoot_time:
		var w : float = _n_player_cast.cast_to.z
		#	var h : float = _n_player_cast.cast_to.y
		var d : float = _n_player_cast.cast_to.x
		var r : float = atan2(d, w) + rand_range(0.0, _ACCURACY_FACTORS[_accuracy_mode]) * [1, -1][randi() % 2] * int(not Settings.super_difficult_enemies_mode)
		
		var f1 : bool = _gun and _gun.has_alt() and alt and not _gun.is_alt_auto()
		var f2 : bool = not alt and _gun and not _gun.is_base_auto()
		
		if not Settings.super_difficult_enemies_mode and (f1 or f2):
			_permitted_shoot_time = OS.get_ticks_msec() / 1000.0 + rand_range(_REACTION_FACTORS[_reaction_mode][0], _REACTION_FACTORS[_reaction_mode][1])
		
		var dist := global_translation.distance_to(_player.global_translation)
		
		match alt:
			true:
				if _gun and dist <= _gun.get_alt_bullet_distance():
					_n_gun_model.switch_to(_gun.get_secondary())
					_gun.shoot_alt(
						get_tree(),
						_n_player_cast.global_translation,
						Vector3(0.0, PI + r, 0.0) #atan(h/w)
					)
			false:
				if _gun and dist <= _gun.get_base_bullet_distance():
					_n_gun_model.switch_to(_gun.get_base())
					_gun.shoot_base(
						get_tree(),
						_n_player_cast.global_translation,
						Vector3(0.0, PI + r, 0.0) #atan(h/w)
					)


func _shoot_if_can() -> void:
	if _player.is_alive():
		_n_player_cast.cast_to = _player.global_translation - _n_player_cast.global_translation
		if _n_player_cast.get_collider() == _player:
			if _gun and _gun.can_shoot_base():
				_shoot_at_player(false)
			else:
				_shoot_at_player(true)


func _on_agent_navfinished() -> void:
	_nav_finished = true
	_time_at_point = OS.get_ticks_msec()


## State processing ##


func _sp_DEFAULT(_delta : float) -> void:
	match _move_mode:
		MovementMode.STATIC:
			_shoot_if_can()
			_look_at_player()
			
			if can_see_player():
				_n_anim.play("IdleAim")
			else:
				_n_anim.play("Idle")
		
		
		MovementMode.SCARED:
			_n_player_cast.cast_to = _player.global_translation - _n_player_cast.global_translation
			if translation.distance_to(_player.translation) < 5.0 and _n_player_cast.get_collider() == _player:
				var away_dir := -translation.direction_to(_player.translation)
				away_dir.y = 0.0
				_velocity = away_dir * _SPEED
				_n_anim.play("RunBackward")
			
			else:
				_velocity = Vector3.ZERO
				_shoot_if_can()
				
				if can_see_player():
					_n_anim.play("IdleAim")
				else:
					_n_anim.play("Idle")
			
			_velocity = move_and_slide(_velocity, Vector3.UP)
			
			if not is_on_floor():
				_state.switch(States.AIR)
			
			_look_at_player()
		
		
		MovementMode.PATH:
			_velocity = global_translation.direction_to(_n_agent.get_next_location()) * _SPEED
			
			if _nav_finished:
				_velocity = Vector3.ZERO
				_shoot_if_can()
				
				if (OS.get_ticks_msec() - _time_at_point > _IDLE_TIME_AT_POINTS) or (global_translation.distance_to(_player.global_translation) < 5.0):
					_point_idx = wrapi(_point_idx + 1, 0, len(_n_path_points.get_children()))
					_n_agent.set_target_location(_n_path_points.get_children()[_point_idx].global_translation)
					_nav_finished = false
			
			_velocity = move_and_slide(_velocity)
		
		
		MovementMode.CHASE:
			if _n_player_cast.get_collider() == _player:
				_last_seen_player_pos = _player.global_translation
			
			var dist := translation.distance_to(_player.translation)
			_n_player_cast.cast_to = _player.global_translation - _n_player_cast.global_translation
			if dist < 2.0 and _n_player_cast.get_collider() == _player:
				var away_dir := -translation.direction_to(_player.translation)
				away_dir.y = 0.0
				_velocity = away_dir * _SPEED
				
				_n_anim.play("RunBackward")
			
			elif _last_seen_player_pos != null and dist > 3.0 and dist < 25.0:
				_n_agent.set_target_location(_last_seen_player_pos)
				var towards_dir := translation.direction_to(_n_agent.get_next_location())
				towards_dir.y = 0.0
				_velocity = towards_dir * _SPEED
				_shoot_if_can()
				
				if can_see_player():
					_n_anim.play("RunBackwardAim")
				else:
					_n_anim.play("RunBackward")
			
			else:
				_velocity = Vector3.ZERO
				_shoot_if_can()
				
				if can_see_player():
					_n_anim.play("IdleAim")
				else:
					_n_anim.play("Idle")
			
			_velocity = move_and_slide(_velocity, Vector3.UP)
			
			if not is_on_floor():
				_state.switch(States.AIR)
			
			_look_at_player()


func _sp_AIR(delta : float) -> void:
	match _move_mode:
		MovementMode.STATIC: pass
		MovementMode.SCARED:
			_velocity.y -= _GRAVITY * delta
			_velocity = move_and_slide(_velocity, Vector3.UP)
			
			if is_on_floor():
				_state.switch(States.DEFAULT)
		
		
		MovementMode.CHASE:
			_velocity.y -= _GRAVITY * delta
			_velocity = move_and_slide(_velocity, Vector3.UP)
			
			if is_on_floor():
				_state.switch(States.DEFAULT)


## Public methods ##


func damage(damage_data : Damage) -> void:
	if _no_damage:
		return
	
	var dmgind := _DamageIndicator.instance()
	get_parent().add_child(dmgind)
	
	dmgind.text = str(int(damage_data.amount))
	dmgind.global_translation = global_translation + Vector3(rand_range(-1, 1), 0.0, rand_range(-1, 1))
	
	_health -= damage_data.amount
	
	var percentage := _health / _MAX_HEALTH
	dmgind.modulate = Color(1.0 - percentage, percentage, percentage)
	if _health <= 0.0 and is_alive():
		dmgind.modulate = Color.yellow
		die()


func die() -> void:
	_state.switch(States.DEAD)
	
	var ragdoll := _Ragdoll.instance()
	
	get_parent().add_child(ragdoll)
	ragdoll.global_translation = global_translation
	
	_player.remove_enemy(self)
	
	queue_free()


func can_see_player() -> bool:
	return _n_player_cast.get_collider() == _player


func is_alive() -> bool:
	return not _state.matches(States.DEAD)
