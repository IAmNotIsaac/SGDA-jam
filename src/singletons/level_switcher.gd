extends CanvasLayer


const LEVELS := [
	preload("res://src/levels/Level1.tscn"),
	preload("res://src/levels/Level2.tscn"),
	preload("res://src/levels/Level3.tscn")
]

onready var _n_control := $Control
onready var _n_fade := $Control/ColorRect


func load_level(level : PackedScene) -> void:
	_n_control.show()
	_n_fade.color.a = 0.0
	
	yield(get_tree().create_tween().tween_property(_n_fade, "color:a", 1.0, 0.25), "finished")
	var _e := get_tree().change_scene_to(level)
	yield(get_tree().create_tween().tween_property(_n_fade, "color:a", 0.0, 0.25), "finished")
	
	_n_control.hide()
