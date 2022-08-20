class_name DeathButton
extends Button


signal db_pressed(id)

var id : int


func _pressed() -> void:
	emit_signal("db_pressed", id)
