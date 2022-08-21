extends Spatial


const _SFX := preload("res://src/instance/SoundEffect.tscn")

export(Gun.GunTypes) var _pickup_attachment

onready var _n_model := $Spatial/GunModel


func _ready() -> void:
	_n_model.switch_to(_pickup_attachment)


func _on_Area_body_entered(body : PhysicsBody) -> void:
	if body is Player:
		var sound := _SFX.instance()
		get_parent().add_child(sound)
		sound.global_translation = global_translation
		sound.play_sound(SoundEffect.SOUNDS.PICK_UP, 2.0)
		
		body._gun.secondaries.append(_pickup_attachment)
		body._gun.secondary_idx = len(body._gun.secondaries) - 1
		queue_free()
