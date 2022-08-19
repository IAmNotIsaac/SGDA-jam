class_name Door
extends StaticBody


var _met := 0
var _quota := 0

onready var _n_door_collision := $DoorCollision
onready var _n_anim := $DoorMesh/AnimationPlayer


## Public methods ##


func link_switch() -> void:
	_quota += 1


func switch_activate() -> void:
	_met += 1
	if _met >= _quota:
		_n_door_collision.set_disabled(true)
		_n_anim.play("Open")
