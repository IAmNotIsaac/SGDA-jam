extends RigidBody


const _Explosion := preload("res://src/instance/Explosion.tscn")


func _on_Grenade_body_entered(_body : PhysicsBody) -> void:
	var explosion := _Explosion.instance()
	get_parent().add_child(explosion)
	
	explosion.global_translation = global_translation
	explosion.explode(5.0)
	
	queue_free()
