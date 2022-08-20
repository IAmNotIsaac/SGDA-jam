extends Control


signal back_pressed


func _on_SensitivitySlider_value_changed(value : float) -> void:
	Settings.camera_sensitivity = value


func _on_ReturnButton_pressed() -> void:
	emit_signal("back_pressed")
