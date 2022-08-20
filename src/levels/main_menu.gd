extends Spatial


onready var _n_play_button := $"%PlayButton"
onready var _n_model_anim := $robot/AnimationPlayer
onready var _n_anim := $AnimationPlayer
onready var _n_settings := $"%SettingsMenu"


func _process(_delta : float) -> void:
	_n_model_anim.play("Idle")


func _ready() -> void:
	SoundTrack.stop()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_n_play_button.grab_focus()


func _on_PlayButton_pressed() -> void:
	SoundTrack.play(SoundTrack.Songs.KILLER, [0, 2])
	LevelSwitcher.load_level(LevelSwitcher.LEVELS[Settings.level])


func _on_SettingsButton_pressed() -> void:
	_n_anim.play("open_settings")
	_n_settings.focus_up()


func _on_SettingsMenu_back_pressed() -> void:
	_n_anim.play("close_settings")
	_n_play_button.grab_focus()


func _on_ExitButton_pressed() -> void:
	pass # Replace with function body.
