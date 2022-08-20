extends RigidBody


const _Explosion := preload("res://src/instance/Explosion.tscn")

const _EXPLOSION_SIZE := 5.0
const _SUPER_EXPLOSION_SIZE := 10.0


func _physics_process(_delta : float) -> void:
	# probably out of bounds
	if global_translation.y <= -20:
		queue_free()


func _on_Grenade_body_entered(_body : PhysicsBody) -> void:
	var explosion := _Explosion.instance()
	get_parent().add_child(explosion)
	
	explosion.global_translation = global_translation
	explosion.explode(_SUPER_EXPLOSION_SIZE if Settings.explosion_mode else _EXPLOSION_SIZE)
	
	queue_free()
