class_name StateMachine


var _owner : Object
var _states : Dictionary
var _state := 0


## Private methods ##

func _init(owner : Object, states : Dictionary, default_state := 0) -> void:
	_owner = owner
	_states = states
	_state = default_state


func _unload_state() -> void:
	var func_name : String = "_su_" + _states.keys()[_state]
	if _owner.has_method(func_name):
		_owner.call(func_name)


func _load_state() -> void:
	var func_name : String = "_sl_" + _states.keys()[_state]
	if _owner.has_method(func_name):
		_owner.call(func_name)


## Public methods ##

func process(delta : float) -> void:
	var func_name : String = "_sp_" + _states.keys()[_state]
	if _owner.has_method(func_name):
		_owner.call(func_name, delta)


func switch(new_state : int) -> void:
	_unload_state()
	_state = new_state
	_load_state()


func matches(state : int) -> bool:
	return _state == state


func matches_any(states : PoolIntArray) -> bool:
	return _state in states


## Setgets ##

func get_state() -> int:
	return _state
