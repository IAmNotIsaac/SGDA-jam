extends Area


var _enemies := []


func _on_Room_body_entered(body : PhysicsBody) -> void:
	if body is Enemy:
		_enemies.append(body)
	
	elif body is Player:
		body.add_enemies(_enemies)
		queue_free()
