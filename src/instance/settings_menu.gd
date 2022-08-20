extends Control


signal back_pressed


func _on_ReturnButton_pressed() -> void:
	emit_signal("back_pressed")


func _on_SensitivitySlider_value_changed(value : float) -> void:
	Settings.camera_sensitivity = value


func _on_ControllerSensitivitySlider_value_changed(value : float) -> void:
	Settings.controller_sensitivity = value


func _on_DeveloperModeCheckButton_toggled(button_pressed : bool) -> void:
	Settings.developer_mode = button_pressed
