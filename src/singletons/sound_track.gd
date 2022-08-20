extends Spatial


enum Songs {
	NONE,
	KILLER
}

var now_playing : int = Songs.NONE

onready var _n_killer_drum := $Killer/Drum
onready var _n_killer_drumnsnare := $Killer/DrumNSnare
onready var _n_killer_guitar := $Killer/Guitar
onready var _n_killer_scream := $Killer/Scream
onready var _n_killer_shakey := $Killer/Shakey
onready var _tracks := {
	Songs.NONE: [],
	Songs.KILLER: [[_n_killer_shakey], [_n_killer_guitar, _n_killer_scream], [_n_killer_drumnsnare, _n_killer_drum]]
}


func play(song : int, layers : PoolIntArray) -> void:
	for l in _tracks[now_playing]:
		for t in l:
			t.stop()
	
	var i := 0
	for l in _tracks[song]:
		for t in l:
			t.play()
			if i in layers:
				t.volume_db = linear2db(Settings.music)
			else:
				t.volume_db = linear2db(0.0)
		i += 1
	
	now_playing = song


func stop() -> void:
	for l in _tracks[now_playing]:
		for t in l:
			t.stop()


func activate_layers(song : int, layers : PoolIntArray) -> void:
	if song == now_playing:
		var i := 0
		for l in _tracks[song]:
			if i in layers:
				for t in l:
					t.volume_db = linear2db(0.01)
					var _e := get_tree().create_tween().tween_property(t, "volume_db", linear2db(Settings.music), 1.0)
			i += 1


func deactivate_layers(song : int, layers : PoolIntArray) -> void:
	if song == now_playing:
		var i := 0
		for l in _tracks[song]:
			if i in layers:
				for t in l:
					t.volume_db = linear2db(Settings.music)
					var _e := get_tree().create_tween().tween_property(t, "volume_db", linear2db(0.0), 1.0)
			i += 1
