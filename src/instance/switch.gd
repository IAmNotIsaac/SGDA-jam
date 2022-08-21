class_name Switch
extends Area


export(NodePath) var _door_path : NodePath

var _activated := false

onready var _n_door : Door = get_node_or_null(_door_path)
onready var _n_anim := $SwitchMesh/AnimationPlayer
onready var _n_sfx := $SoundEffect


## Private methods ##


func _ready() -> void:
	if _n_door:
		_n_door.link_switch()


## Public methods ##


func activate() -> void:
	if _n_door and _activated == false:
		_n_anim.play("default")
		_n_door.switch_activate()
		_activated = true
		_n_sfx.play_sound(SoundEffect.SOUNDS.SWITCH, 1.0)
