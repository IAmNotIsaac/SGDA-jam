class_name Player
extends KinematicBody

enum States {
	DEFAULT,
	JUMP,
	AIR,
	LAND,
	WALLRUN,
	DEAD,
	DEAD_PAUSE
}

const _Ragdoll := preload("res://src/instance/RobotRagdoll.tscn")

const _GRAVITY := 20.0
const _JUMP_FORCE := 7.0
const _RUN_SPEED := 8.0
const _AIR_FRICTION := 0.2
const _MAX_JUMPS := 2
const _MAX_HEALTH := 100.0
const _HEAL_RATE := 20.0 # health per second
const _HOLD_HEALTH_TIME := 2000 # measured in milliseconds
const _WALLRUN_CAM_TILT := 5.0
const _FAST_SPEED := 1.5

export(Resource) var _gun = Gun.new()

var _state := StateMachine.new(self, States)
var _velocity := Vector3.ZERO
var _jump_count := 0
var _wallrun_cast : RayCast
var _health := _MAX_HEALTH
var _last_damage_time := 0
var _target_camera_tilt := 0.0
var _action := DeathAction.new(DeathAction.Type.NONE)
var _spawn_pos := translation
var _spawn_rot := rotation.y

var speed_factor := 1.0

onready var _n_gimbal := $Gimbal
onready var _n_cam := $Gimbal/Camera
onready var _n_bspawn := $Gimbal/Camera/BulletSpawn
onready var _n_hacky_floor_check := $HackyFloorCheck
onready var _n_wallrunl_check := $Gimbal/WallrunLeftCheck
onready var _n_wallrunr_check := $Gimbal/WallrunRightCheck
onready var _n_wallrun_tracker := $WallrunTracker
onready var _n_pause_menu := $Control/PauseMenu
onready var _n_damage_vignette := $Control/DamageVignette
onready var _n_interact_cast := $Gimbal/Camera/InteractCast
onready var _n_death_action := $Control/DeathAction
onready var _n_death_action_buttons := $Control/DeathAction/HBoxContainer


## Private methods ##


func _spawn() -> void:
	if _action._action != DeathAction.Type.NONE:
		_action.act(get_tree(), self)
		yield(_action, "action_complete")
	
	_state.switch(States.DEFAULT)
	translation = _spawn_pos
	_n_gimbal.rotation.y = _spawn_rot
	_health = _MAX_HEALTH
	_gun.clear_cooldowns()


func _ready() -> void:
	_spawn_pos = translation
	_spawn_rot = rotation.y
	rotation.y = 0.0
	_spawn()
#	SoundTrack.play(SoundTrack.Songs.KILLER, [0, 2])
#	yield(get_tree().create_timer(2.0), "timeout")
#	SoundTrack.activate_layers(SoundTrack.Songs.KILLER, [1])
#	SoundTrack.deactivate_layers(SoundTrack.Songs.KILLER, [0])


func _input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		if is_alive():
			_n_gimbal.rotation_degrees.y -= event.relative.x * Settings.camera_sensitivity
			_n_cam.rotation_degrees.x -= event.relative.y * Settings.camera_sensitivity
			_n_cam.rotation_degrees.x = clamp(_n_cam.rotation_degrees.x, -90, 90)
	
	elif event.is_action_pressed("next_gun"):
		_gun.next_alt()
	
	elif event.is_action_pressed("prev_gun"):
		_gun.prev_alt()
	
	elif event.is_action_pressed("interact"):
		var col : Area = _n_interact_cast.get_collider()
		if col is Switch:
			col.activate()


func _physics_process(delta : float) -> void:
	_state.process(delta)
	_controller_look()
	_shoot()
	_health_stuff(delta)
	_camera_tilt()
	
	$Control/Label.visible = Settings.developer_mode
	if _gun.get_secondaries():
		$Control/Label.text = Gun.GunTypes.keys()[_gun.secondaries[_gun.secondary_idx]]


func _controller_look() -> void:
	if is_alive():
		var input := Vector2(
			Input.get_action_strength("look_right") - Input.get_action_strength("look_left"),
			Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
		)
		
		_n_gimbal.rotation_degrees.y -= input.x * Settings.controller_sensitivity
		_n_cam.rotation_degrees.x -= input.y * Settings.controller_sensitivity
		_n_cam.rotation_degrees.x = clamp(_n_cam.rotation_degrees.x, -90, 90)


func _shoot() -> void:
	if is_alive():
		if (Input.is_action_pressed("shoot_base") and _gun.is_base_auto()) or (Input.is_action_just_pressed("shoot_base") and not _gun.is_base_auto()):
			_gun.shoot_base(
				get_tree(),
				_n_bspawn.global_translation,
				_n_cam.global_transform.basis.get_euler()
			)
		
		elif (Input.is_action_pressed("shoot_alt") and _gun.is_alt_auto()) or (Input.is_action_just_pressed("shoot_alt") and not _gun.is_alt_auto()):
			_gun.shoot_alt(
				get_tree(),
				_n_bspawn.global_translation,
				_n_cam.global_transform.basis.get_euler()
			)


func _health_stuff(delta : float) -> void:
	_n_damage_vignette.modulate.a = 1.0 - _health / _MAX_HEALTH
	
	if OS.get_ticks_msec() - _last_damage_time > _HOLD_HEALTH_TIME:
		_health = min(_health + _HEAL_RATE * delta, _MAX_HEALTH)


func _camera_tilt() -> void:
	_n_cam.rotation_degrees.z = lerp(_n_cam.rotation_degrees.z, _target_camera_tilt, 0.2)


func _on_deathbutton_pressed(id : int) -> void:
	_action = DeathAction.new(id)
	_spawn()
	
	for c in _n_death_action_buttons.get_children():
		c.queue_free()
	
	_n_death_action.hide()


## State processes ##


func _sp_DEFAULT(_delta : float) -> void:
	var input := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)
	
	_n_cam.v_offset = lerp(_n_cam.v_offset, sin(OS.get_ticks_msec() * 0.01) * 0.1 * int(input.x or input.y), 0.2)
	
	var theta = _n_gimbal.global_transform.basis.get_euler().y
	
	var move_forward = Vector3(sin(theta) * input.y, 0.0, cos(theta) * input.y)
	var move_strafe = Vector3(cos(-theta) * input.x, 0.0, sin(-theta) * input.x)
	_velocity = (move_forward + move_strafe).normalized() * _RUN_SPEED * speed_factor * max(_FAST_SPEED * int(Settings.super_fast_mode), 1.0)
	
	_velocity = move_and_slide(_velocity)
	
	if Input.is_action_pressed("jump"):
		_state.switch(States.JUMP)
	
	if not _n_hacky_floor_check.is_colliding():
		_state.switch(States.AIR)


func _sp_LAND(delta : float) -> void:
	_n_cam.v_offset = max(_n_cam.v_offset - 2.0 * delta, -0.2)
	
	if _state.get_state_time() > 0.1:
		_state.switch(States.DEFAULT)
	
	_velocity = move_and_slide(_velocity)
	
	if Input.is_action_pressed("jump"):
		_state.switch(States.JUMP)


func _sp_AIR(delta : float) -> void:
	var input := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)
	
	var theta = _n_gimbal.global_transform.basis.get_euler().y
	
	var move_forward = Vector3(sin(theta) * input.y, 0.0, cos(theta) * input.y)
	var move_strafe = Vector3(cos(-theta) * input.x, 0.0, sin(-theta) * input.x)
	var accel := _GRAVITY * delta
	
	_velocity = Vector3(
		clamp(_velocity.x + (move_forward.x + move_strafe.x) * _AIR_FRICTION, -_RUN_SPEED * speed_factor * max(_FAST_SPEED * int(Settings.super_fast_mode), 1.0), _RUN_SPEED * speed_factor * max(_FAST_SPEED * int(Settings.super_fast_mode), 1.0)),
		_velocity.y - accel,
		clamp(_velocity.z + (move_forward.z + move_strafe.z) * _AIR_FRICTION, -_RUN_SPEED * speed_factor * max(_FAST_SPEED * int(Settings.super_fast_mode), 1.0), _RUN_SPEED * speed_factor * max(_FAST_SPEED * int(Settings.super_fast_mode), 1.0))
	)
	var impact_vel := _velocity.y
	
	_velocity = move_and_slide(_velocity, Vector3.UP)
	
	if is_on_floor():
		_state.switch(States.LAND if impact_vel < -accel - 0.1 else States.DEFAULT)
	
	if Input.is_action_just_pressed("jump"):
		for c in [ {
				"raycast": _n_wallrunl_check,
				"input": "move_left"
			}, {
				"raycast": _n_wallrunr_check,
				"input": "move_right"
		} ]:
			if c["raycast"].get_collider() and Input.is_action_pressed(c["input"]):
				_wallrun_cast = c["raycast"]
				_state.switch(States.WALLRUN)
				return
		
		if _jump_count < _MAX_JUMPS:
			_velocity = (move_forward + move_strafe).normalized() * _RUN_SPEED
			_state.switch(States.JUMP)


func _sp_WALLRUN(_delta : float) -> void:
	var normal : Vector3 = _n_wallrun_tracker.get_collision_normal()
	_n_wallrun_tracker.cast_to = -Vector3(normal.x, 0.0, normal.z)
	var angle := atan2(normal.z, normal.x) + PI * 0.5 * (-1 if _wallrun_cast == _n_wallrunr_check else 1)
	
	_velocity = -Vector3(cos(angle), 0.0, sin(angle)) * 10.0
	
	_velocity = move_and_slide(_velocity)
	
	_target_camera_tilt = _WALLRUN_CAM_TILT * (-1.0 if _wallrun_cast == _n_wallrunl_check else 1.0)
	
	if not _n_wallrun_tracker.get_collider():
		_jump_count -= 1
		_state.switch(States.JUMP)
	
	if Input.is_action_just_released("jump"):
		_jump_count -= 1
		_velocity = normal * _JUMP_FORCE
		_state.switch(States.JUMP)


func _sp_DEAD(_delta : float) -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


## State (un)loading ##


func _sl_WALLRUN() -> void:
	var normal := _wallrun_cast.get_collision_normal()
	_n_wallrun_tracker.cast_to = -Vector3(normal.x, 0.0, normal.z)


func _su_WALLRUN() -> void:
	_target_camera_tilt = 0.0


func _sl_LAND() -> void:
	_jump_count = 0


func _su_DEFAULT() -> void:
	_n_cam.v_offset = 0.0


func _sl_JUMP() -> void:
	_jump_count += 1
	_velocity.y = _JUMP_FORCE
	_state.switch(States.AIR)


func _sl_DEAD() -> void:
	for g in _gun.get_secondaries() + [_gun.get_base()]:
		var id : int = _gun.get_gun_action_type(g)
		var button := DeathButton.new()
		var font := DynamicFont.new()
		
		font.font_data = load("res://assets/fonts/propaganda/PROPAGAN.ttf")
		font.size = 32
		
		button.id = id
		button.text = DeathAction.get_action_name(id)
		button.hint_tooltip = DeathAction.get_action_hint(id)
		button.add_font_override("font", font)
		
		_n_death_action_buttons.add_child(button)
		button.set_h_size_flags(Button.SIZE_EXPAND_FILL)
		var _e := button.connect("db_pressed", self, "_on_deathbutton_pressed")
	
	_n_death_action_buttons.get_children()[0].grab_focus()
	_n_death_action_buttons.show()


func _su_DEAD() -> void:
	_n_death_action_buttons.hide()
	_n_death_action.hide()
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _sl_DEAD_PAUSE() -> void:
	var ragdoll = _Ragdoll.instance()
	
	get_parent().add_child(ragdoll)
	ragdoll.global_translation = global_translation
	
	speed_factor = 1.0
	_n_death_action.show()
	yield(get_tree().create_timer(1.0), "timeout")
	_state.switch(States.DEAD)


## Public methods ##


func damage(damage_data : Damage) -> void:
	if Settings.god_mode:
		return
	
	_last_damage_time = OS.get_ticks_msec()
	_health -= damage_data.amount
	if _health <= 0.0 and is_alive():
		die()


func die() -> void:
#	global_translation = _spawn_pos
	_state.switch(States.DEAD_PAUSE)


func is_alive() -> bool:
	return not _state.matches_any([States.DEAD, States.DEAD_PAUSE])
