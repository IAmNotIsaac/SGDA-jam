extends KinematicBody


enum States {
	DEFAULT,
	JUMP,
	AIR
}

const _GRAVITY := 9.8
const _JUMP_FORCE := 4.0
const _RUN_SPEED := 5.0
const _AIR_FRICTION := 0.2
const _CONTROLLER_SENSITIVITY := 5.0

var _state := StateMachine.new(self, States)
var _velocity := Vector3.ZERO

onready var _n_gimbal := $Gimbal
onready var _n_cam := $Gimbal/Camera


## Private methods ##


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event : InputEvent) -> void:
	if event is InputEventMouseMotion:
		_n_gimbal.rotation_degrees.y -= event.relative.x
		_n_cam.rotation_degrees.x -= event.relative.y
		_n_cam.rotation_degrees.x = clamp(_n_cam.rotation_degrees.x, -90, 90)


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
	
	var theta = _n_gimbal.global_transform.basis.get_euler().y
	
	var move_forward = Vector3(sin(theta) * input.y, 0.0, cos(theta) * input.y)
	var move_strafe = Vector3(cos(-theta) * input.x, 0.0, sin(-theta) * input.x)
	_velocity = (move_forward + move_strafe).normalized() * _RUN_SPEED
	
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
	
	_velocity = Vector3(
		clamp(_velocity.x + (move_forward.x + move_strafe.x) * _AIR_FRICTION, -_RUN_SPEED, _RUN_SPEED),
		_velocity.y - _GRAVITY * delta,
		clamp(_velocity.z + (move_forward.z + move_strafe.z) * _AIR_FRICTION, -_RUN_SPEED, _RUN_SPEED)
	)
	
	_velocity = move_and_slide(_velocity, Vector3.UP)
	
	if is_on_floor():
		_state.switch(States.DEFAULT)


## State (un)loading ##


func _sl_JUMP() -> void:
	_velocity.y = _JUMP_FORCE
	_state.switch(States.AIR)
