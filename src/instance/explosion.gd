extends Spatial


signal _physics_process
signal explosion_complete

const _SFX := preload("res://src/instance/SoundEffect.tscn")

onready var _n_explosion := $Explosion
onready var _n_smoke := $Smoke
onready var _n_tween := $Tween
onready var _n_damage_zone := $Area
onready var _n_collision := $Area/CollisionShape


func _physics_process(_delta : float) -> void:
	emit_signal("_physics_process")


func explode(size : float, ignore : PhysicsBody = null) -> void:
	_n_collision.shape = _n_collision.shape.duplicate()
	_n_collision.shape.radius = size
	
	# hack
	for i in 3:
		yield(get_tree(), "physics_frame")
	
	for body in _n_damage_zone.get_overlapping_bodies():
		if body != ignore:
			if body.is_in_group("entity"):
				var distance_factor : float = max(0.0, 1.0 - (body.global_translation.distance_to(global_translation) / size))
				var amount : float = 125.0 * distance_factor
				body.damage(Damage.new(
					Damage.Type.ExplosionDamage.GRENADE, amount
				))
			
			elif body.is_in_group("ragdoll_bone"):
				body = body.get_parent().get_parent()
				
				var distance_factor : float = max(0.0, 1.0 - (body.global_translation.distance_to(global_translation) / size))
				var amount : float = 125.0 * distance_factor
				body.damage(Damage.new(
					Damage.Type.ExplosionDamage.GRENADE, amount
				))
	
	var sound := _SFX.instance()
	get_parent().add_child(sound)
	sound.global_translation = global_translation
	sound.play_sound(SoundEffect.SOUNDS.EXPLOSION, 12.0)
	
	_n_explosion.mesh = _n_explosion.mesh.duplicate()
	_n_explosion.mesh.material = _n_explosion.mesh.material.duplicate()
	
	_n_smoke.mesh = _n_smoke.mesh.duplicate()
	_n_smoke.mesh.material = _n_smoke.mesh.material.duplicate()
	
	_n_tween.interpolate_property(_n_explosion, "scale", Vector3.ZERO, Vector3(size, size, size), 0.3)
	_n_tween.interpolate_property(_n_smoke, "scale", Vector3.ZERO, Vector3(size, size, size), 0.3)
	_n_tween.interpolate_property(_n_explosion, "scale", Vector3(size, size, size), Vector3.ZERO, 0.2, 0, 2, 0.3)
	_n_tween.interpolate_property(_n_smoke, "scale", Vector3(size, size, size), Vector3.ZERO, 0.8, 0, 2, 0.3)
	
	_n_tween.interpolate_property(_n_explosion, "rotation_degrees:y", 0.0, 360.0, 0.8)
	_n_tween.interpolate_property(_n_smoke, "rotation_degrees:y", 0.0, -360.0, 0.8)
	
	_n_tween.interpolate_property(_n_explosion.mesh.material, "albedo_color:a", 1.0, 0.0, 0.2, 0, 2, 0.2)
	_n_tween.interpolate_property(_n_explosion.mesh.material, "emission_energy", 0.06, 4.0, 0.2, 0, 2, 0.1)
	_n_tween.interpolate_property(_n_smoke.mesh.material, "albedo_color:a", 0.0, 0.5, 0.5, 0, 2, 0.3)
	_n_tween.interpolate_property(_n_smoke.mesh.material, "albedo_color:a", 0.5, 0.0, 0.19, 0, 2, 0.7)
	_n_tween.start()
	
	yield(_n_tween, "tween_all_completed")
	
	emit_signal("explosion_complete")
	queue_free()
