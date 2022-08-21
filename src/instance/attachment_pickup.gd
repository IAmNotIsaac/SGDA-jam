extends Spatial


export(Gun.GunTypes) var _pickup_attachment

onready var _n_model := $Spatial/GunModel


func _ready() -> void:
	_n_model.switch_to(_pickup_attachment)


func _on_Area_body_entered(body : PhysicsBody) -> void:
	if body is Player:
		body._gun.secondaries.append(_pickup_attachment)
		body._gun.secondary_idx = len(body._gun.secondaries) - 1
		queue_free()
