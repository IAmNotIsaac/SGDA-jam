class_name Enemey
extends KinematicBody


enum MovementMode {
	STATIC,    # Does not move
	SCARED,    # Static unless player gets too close
	PATH,      # Follows a predetermined path
	CHASE      # Chases player
}

enum States {
	DEFAULT,   # Walking
	AIR,       # In air
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

const _SPEED := 7.0
const _GRAVITY := 20.0

export(MovementMode) var _move_mode : int = MovementMode.STATIC
export(Resource) var _gun : Resource
export(AccuracyModes) var _accuracy_mode : int = AccuracyModes.LOW
export(ReactionModes) var _reaction_mode : int = ReactionModes.LOW

var _state := StateMachine.new(
	self, States
)
var _player : KinematicBody
var _velocity : Vector3
var _uncomfortable := false

onready var _n_player_cast := $PlayerViewCast
onready var _n_agent := $NavigationAgent


func _ready() -> void:
	_player = get_tree().get_nodes_in_group("player")[0]


func _physics_process(delta : float) -> void:
	_state.process(delta)


func _shoot_at_player(alt : bool) -> void:
	var w : float = _n_player_cast.cast_to.z
#	var h : float = _n_player_cast.cast_to.y
	var d : float = _n_player_cast.cast_to.x
	var r : float = atan2(d, w) + rand_range(0.0, _ACCURACY_FACTORS[_accuracy_mode]) * [1, -1][randi() % 2]
	
	var f1 : bool = _gun.has_alt() and alt and not _gun.is_alt_auto()
	var f2 : bool = not alt and not _gun.is_base_auto()
	
	if f1 or f2:
		var t : float = rand_range(_REACTION_FACTORS[_reaction_mode][0], _REACTION_FACTORS[_reaction_mode][1])
		yield(get_tree().create_timer(t), "timeout")
	
	match alt:
		true:
			_gun.shoot_alt(
				get_tree(),
				_n_player_cast.global_translation,
				Vector3(0.0, PI + r, 0.0) #atan(h/w)
			)
		false:
			_gun.shoot_base(
				get_tree(),
				_n_player_cast.global_translation,
				Vector3(0.0, PI + r, 0.0) #atan(h/w)
			)


func _shoot_if_can() -> void:
	_n_player_cast.cast_to = _player.global_translation - _n_player_cast.global_translation
	if _n_player_cast.get_collider() == _player:
		if _gun.can_shoot_base():
			_shoot_at_player(false)
		else:
			_shoot_at_player(true)


## State processing ##


func _sp_DEFAULT(_delta : float) -> void:
	match _move_mode:
		MovementMode.STATIC:
			_shoot_if_can()
		
		MovementMode.SCARED:
			if translation.distance_to(_player.translation) < 5.0:
				var away_dir := -translation.direction_to(_player.translation)
				away_dir.y = 0.0
				_velocity = away_dir * _SPEED
			
			else:
				_velocity = Vector3.ZERO
				_shoot_if_can()
			
			_velocity = move_and_slide(_velocity, Vector3.UP)
			
			if not is_on_floor():
				_state.switch(States.AIR)


func _sp_AIR(delta : float) -> void:
	match _move_mode:
		MovementMode.STATIC: pass
		MovementMode.SCARED:
			_velocity.y -= _GRAVITY * delta
			_velocity = move_and_slide(_velocity, Vector3.UP)
			
			if is_on_floor():
				_state.switch(States.DEFAULT)