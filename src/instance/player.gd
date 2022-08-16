extends Spatial


enum States {
	DEFAULT,
	ALT
}

var state := StateMachine.new(self, States)

onready var _n_cam := $Gimbal/Camera


func _physics_process(delta : float) -> void:
	state.process(delta)


func _sp_DEFAULT(delta : float) -> void:
	state.switch(States.ALT)


func _sp_ALT(delta : float) -> void:
	state.switch(States.DEFAULT)
