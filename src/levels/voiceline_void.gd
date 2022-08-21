extends Control


signal voice_finished

onready var _n_voice := $AudioStreamPlayer
onready var _n_sub := $Label


func go(voice : AudioStream, subtitles : String) -> void:
	print(subtitles)
	_n_sub.text = subtitles
	_n_voice.stream = voice
	_n_voice.play()
	yield(_n_voice, "finished")
	emit_signal("voice_finished")
