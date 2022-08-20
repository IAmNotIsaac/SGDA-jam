extends Control


signal back_pressed


onready var _n_senslider := $"%SensitivitySlider"
onready var _n_conslider := $"%ControllerSensitivitySlider"
onready var _n_devmode := $"%DeveloperModeCheckButton"
onready var _n_sfmode := $"%SuperFastMode"
onready var _n_vdemode := $"%VeryDifficultEnemies"
onready var _n_godmode := $"%GodMode"
onready var _n_emode := $"%ExplosionMode"


func _ready() -> void:
	_n_senslider.value = Settings.camera_sensitivity
	_n_conslider.value = Settings.controller_sensitivity
	_n_devmode.pressed = Settings.developer_mode
	_n_sfmode.pressed = Settings.super_fast_mode
	_n_vdemode.pressed = Settings.super_difficult_enemies_mode
	_n_godmode.pressed = Settings.god_mode
	_n_emode.pressed = Settings.explosion_mode


func _on_ReturnButton_pressed() -> void:
	emit_signal("back_pressed")


func _on_SensitivitySlider_value_changed(value : float) -> void:
	Settings.camera_sensitivity = value


func _on_ControllerSensitivitySlider_value_changed(value : float) -> void:
	Settings.controller_sensitivity = value


func _on_DeveloperModeCheckButton_toggled(button_pressed : bool) -> void:
	Settings.developer_mode = button_pressed


func _on_SuperFastMode_toggled(button_pressed : bool) -> void:
	Settings.super_fast_mode = button_pressed


func _on_VeryDifficultEnemies_toggled(button_pressed : bool) -> void:
	Settings.super_difficult_enemies_mode = button_pressed


func _on_GodMode_toggled(button_pressed : bool) -> void:
	Settings.god_mode = button_pressed


func _on_ExplosionMode_toggled(button_pressed : bool) -> void:
	Settings.explosion_mode = button_pressed
