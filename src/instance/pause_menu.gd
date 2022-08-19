extends Control


onready var _resume_button := $VBoxContainer/ResumeButton


func _ready() -> void:
	unpause()


func _input(event : InputEvent) -> void:
	if event.is_action_pressed("ui_pause"):
		match get_tree().paused:
			true: unpause()
			false: pause()


func pause() -> void:
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_resume_button.grab_focus()
	show()


func unpause() -> void:
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	hide()


func _on_ResumeButton_pressed() -> void:
	unpause()


func _on_RestartButton_pressed() -> void:
	unpause()
	var _e := get_tree().reload_current_scene()


func _on_TitleButton_pressed() -> void:
	print("TODO")
