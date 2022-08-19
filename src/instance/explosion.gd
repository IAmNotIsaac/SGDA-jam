extends Spatial


signal _physics_process

onready var _n_explosion := $Explosion
onready var _n_smoke := $Smoke
onready var _n_tween := $Tween
onready var _n_damage_zone := $Area
onready var _n_collision := $Area/CollisionShape


func _physics_process(_delta : float) -> void:
	emit_signal("_physics_process")


func explode(size : float) -> void:
	_n_collision.shape = _n_collision.shape.duplicate()
	_n_collision.shape.radius = size
	
	# hack
	for i in 3:
		yield(get_tree(), "physics_frame")
	
	for body in _n_damage_zone.get_overlapping_bodies():
		if body.is_in_group("entity"):
			body.damage(Damage.new(
				Damage.Type.ExplosionDamage.GRENADE, 100.0 * (body.global_translation.distance_to(global_translation) / size) + 15.0
			))
	
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
	
	var _e := _n_tween.connect("tween_all_completed", self, "queue_free")