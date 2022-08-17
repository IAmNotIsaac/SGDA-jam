extends KinematicBody


const _Bullet := preload("res://src/instance/Bullet.tscn")

enum States {
	DEFAULT,
	JUMP,
	AIR,
	LAND,
	WALLRUN
}

const _GRAVITY := 20.0
const _JUMP_FORCE := 7.0
const _RUN_SPEED := 8.0
const _AIR_FRICTION := 0.2
const _CONTROLLER_SENSITIVITY := 5.0
const _MAX_JUMPS := 2

var _state := StateMachine.new(self, States)
var _velocity := Vector3.ZERO
var _jump_count := 0
var _wallrun_cast : RayCast

onready var _n_gimbal := $Gimbal
onready var _n_cam := $Gimbal/Camera
onready var _n_bspawn := $Gimbal/Camera/BulletSpawn
onready var _n_hacky_floor_check := $HackyFloorCheck
onready var _n_wallrunl_check := $Gimbal/WallrunLeftCheck
onready var _n_wallrunr_check := $Gimbal/WallrunRightCheck
onready var _n_wallrun_tracker := $WallrunTracker


## Private methods ##


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		_n_gimbal.rotation_degrees.y -= event.relative.x
		_n_cam.rotation_degrees.x -= event.relative.y
		_n_cam.rotation_degrees.x = clamp(_n_cam.rotation_degrees.x, -90, 90)
	
	elif event is InputEventMouseButton:
		if event.is_pressed() and event.button_index == 1:
			# TEMPORARY!
			# TODO: make proper gun handling system
			
			var bullet := _Bullet.instance()
			
			bullet.translation = _n_bspawn.global_translation
			bullet.rotation = _n_cam.global_transform.basis.get_euler()
			
			get_parent().add_child(bullet)
			yield(get_tree(), "idle_frame")
			
			bullet.shoot(Bullet.ShotTypes.REVOLVER)
	
	elif event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _physics_process(delta : float) -> void:
	_state.process(delta)
	_controller_look()


func _controller_look() -> void:
	var input := Vector2(
		Input.get_action_strength("look_right") - Input.get_action_strength("look_left"),
		Input.get_action_strength("look_down") - Input.get_action_strength("look_up")
	)
	
	_n_gimbal.rotation_degrees.y -= input.x * _CONTROLLER_SENSITIVITY
	_n_cam.rotation_degrees.x -= input.y * _CONTROLLER_SENSITIVITY
	_n_cam.rotation_degrees.x = clamp(_n_cam.rotation_degrees.x, -90, 90)


## State processes ##


func _sp_DEFAULT(_delta : float) -> void:
	var input := Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")
	)
	
	_n_cam.v_offset = lerp(_n_cam.v_offset, sin(OS.get_ticks_msec() * 0.01) * 0.1 * abs(input.x + input.y), 0.2)
	
	var theta = _n_gimbal.global_transform.basis.get_euler().y
	
	var move_forward = Vector3(sin(theta) * input.y, 0.0, cos(theta) * input.y)
	var move_strafe = Vector3(cos(-theta) * input.x, 0.0, sin(-theta) * input.x)
	_velocity = (move_forward + move_strafe).normalized() * _RUN_SPEED
	
	_velocity = move_and_slide(_velocity)
	
	if Input.is_action_pressed("jump"):
		_state.switch(States.JUMP)
	
	if not _n_hacky_floor_check.is_colliding():
		_state.switch(States.AIR)


func _sp_LAND(delta : float) -> void:
	_n_cam.v_offset -= 2.0 * delta
	
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
		clamp(_velocity.x + (move_forward.x + move_strafe.x) * _AIR_FRICTION, -_RUN_SPEED, _RUN_SPEED),
		_velocity.y - accel,
		clamp(_velocity.z + (move_forward.z + move_strafe.z) * _AIR_FRICTION, -_RUN_SPEED, _RUN_SPEED)
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
	normal.z = max(normal.z, 0.001)
	var angle := -atan(normal.x / normal.z)
	
	_velocity = Vector3(cos(angle), 0.0, sin(angle)) * 10.0 * (-1 if _wallrun_cast == _n_wallrunr_check else 1)
	
	_velocity = move_and_slide(_velocity)
	
	if not _n_wallrun_tracker.get_collider():
		_jump_count -= 1
		_state.switch(States.JUMP)
	
	if Input.is_action_just_released("jump"):
		_jump_count -= 1
		_velocity = normal * _JUMP_FORCE
		_state.switch(States.JUMP)


## State (un)loading ##


func _sl_WALLRUN() -> void:
	var normal := _wallrun_cast.get_collision_normal()
	_n_wallrun_tracker.cast_to = -Vector3(normal.x, 0.0, normal.z)


func _sl_LAND() -> void:
	_jump_count = 0


func _su_DEFAULT() -> void:
	_n_cam.v_offset = 0.0


func _sl_JUMP() -> void:
	_jump_count += 1
	_velocity.y = _JUMP_FORCE
	_state.switch(States.AIR)
