extends CanvasLayer


const _VoicelineVoid := preload("res://src/levels/VoicelineVoid.tscn")

const LEVELS := [
	preload("res://src/levels/Level1.tscn"),
	preload("res://src/levels/Level2.tscn"),
	preload("res://src/levels/Level3.tscn"),
	preload("res://src/levels/Final.tscn"),
	preload("res://src/levels/Tutorial.tscn"),
]

onready var _n_control := $Control
onready var _n_fade := $Control/ColorRect


func load_level(voice : AudioStream, subtitles : String, level : PackedScene) -> void:
	SoundTrack.stop()
	
	_n_control.show()
	_n_fade.color.a = 0.0
	
	yield(get_tree().create_tween().tween_property(_n_fade, "color:a", 1.0, 0.25), "finished")
	_n_fade.hide()
	
	var _e := get_tree().change_scene_to(_VoicelineVoid)
	yield(get_tree(), "idle_frame")
	get_tree().get_current_scene().go(voice, subtitles)
	yield(get_tree().get_current_scene(), "voice_finished")
	
	_n_fade.show()
	
	_e = get_tree().change_scene_to(level)
	
	if Settings.level != 3:
		SoundTrack.play(SoundTrack.Songs.KILLER, [0, 2])
	
	yield(get_tree().create_tween().tween_property(_n_fade, "color:a", 0.0, 0.25), "finished")
	
	_n_control.hide()
