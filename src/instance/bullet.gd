class_name Bullet
extends Spatial


enum ShotTypes {
	SHOTGUN,
	REVOLVER,
	PISTOL,
	MINIGUN,
	INSTAKILL
}

const _Explosion := preload("res://src/instance/Explosion.tscn")
const _SFX := preload("res://src/instance/SoundEffect.tscn")
const _BulletHole := preload("res://src/instance/BulletHole.tscn")

const _EXPLOSION_SIZE := 4.0

const SHOT_DATA := {
	ShotTypes.SHOTGUN: {
		"distance": 10.0,
		"accuracy": 0.9,
		"damage": 15.0,
		"dmgtype": Damage.Type.BulletDamage.SHOTGUN
	},
	
	ShotTypes.REVOLVER: {
		"distance": 50.0,
		"accuracy": 0.99,
		"damage": 40.0,
		"dmgtype": Damage.Type.BulletDamage.REVOLVER
	},
	
	ShotTypes.PISTOL: {
		"distance": 25.0,
		"accuracy": 0.95,
		"damage": 20.0,
		"dmgtype": Damage.Type.BulletDamage.PISTOL
	},
	
	ShotTypes.MINIGUN: {
		"distance": 25.0,
		"accuracy": 0.9,
		"damage": 10.0,
		"dmgtype": Damage.Type.BulletDamage.MINIGUN
	},
	
	ShotTypes.INSTAKILL: {
		"distance": 200.0,
		"accuracy": 1.0,
		"damage": 999.0,
		"dmgtype": Damage.Type.BulletDamage.INSTAKILL
	}
}

onready var _n_ray := $RayCast
onready var _n_mesh := $MeshInstance


func shoot(type : int) -> void:
	var distance : float = SHOT_DATA[type]["distance"]
	var offset := Vector3(
		rand_range(0.0, 90.0 * (1.0 - SHOT_DATA[type]["accuracy"])) * [1.0, -1.0][randi() % 2],
		rand_range(0.0, 90.0 * (1.0 - SHOT_DATA[type]["accuracy"])) * [1.0, -1.0][randi() % 2],
		rand_range(0.0, 90.0 * (1.0 - SHOT_DATA[type]["accuracy"])) * [1.0, -1.0][randi() % 2]
	)
	
	rotation_degrees += offset
	
	_n_ray.cast_to = Vector3(0, 0, -distance)
	yield(get_tree(), "idle_frame")
	
	var col = _n_ray.get_collider()
	
	if col != null:
		_n_mesh.global_translation = _n_ray.get_collision_point()
		_n_mesh.translation /= 2.0
		
		_n_mesh.scale.z = translation.distance_to(_n_ray.get_collision_point())
		
		if col.is_in_group("entity"):
			col.damage(Damage.new(
				SHOT_DATA[type]["dmgtype"],
				SHOT_DATA[type]["damage"]
			))
		
		elif col.is_in_group("ragdoll_bone"):
			col.apply_impulse(_n_ray.get_collision_point(), Vector3.UP * 0.1)
			
			col = col.get_parent().get_parent()
			col.damage(Damage.new(
				SHOT_DATA[type]["dmgtype"],
				SHOT_DATA[type]["damage"]
			))
		
		else:
			var sound := _SFX.instance()
			
			get_parent().add_child(sound)
			sound.global_translation = _n_ray.get_collision_point()
			sound.play_sound(SoundEffect.SOUNDS.BULLET_IMPACT, 2.0)
			
			
			var bullet_hole := _BulletHole.instance()
			
			get_parent().add_child(bullet_hole)
			
			bullet_hole.global_translation = _n_ray.get_collision_point()
			
			# required because look at fails if aligned with axis
			match _n_ray.get_collision_normal():
				Vector3.UP:
					bullet_hole.rotation = Vector3(90.0, 0.0, 0.0)
				
				Vector3.DOWN:
					bullet_hole.rotation = Vector3(-90.0, 0.0, 0.0)
				
				_:
					bullet_hole.look_at(_n_ray.get_collision_point() + _n_ray.get_collision_normal(), Vector3.UP)
		
		
		if Settings.explosion_mode:
			
			var explosion := _Explosion.instance()
			
			get_parent().add_child(explosion)
			
			explosion.global_translation = _n_ray.get_collision_point()
			explosion.explode(_EXPLOSION_SIZE)
	
	else:
		_n_mesh.translation = _n_ray.cast_to / 2.0
		_n_mesh.scale.z = distance
	
	
	var mat := SpatialMaterial.new()
	mat.set_feature(SpatialMaterial.FEATURE_TRANSPARENT, true)
	mat.set_flag(SpatialMaterial.FLAG_UNSHADED, true)
	mat.albedo_color = Color(1.0, 1.0, 0.0, 0.7)
	_n_mesh.mesh = _n_mesh.mesh.duplicate()
	_n_mesh.mesh.surface_set_material(0, mat)
	
	var tween = get_tree().create_tween()
	tween.tween_property(mat, "albedo_color", Color(1.0, 1.0, 6.0, 0.0), 0.5)
	yield(tween, "finished")
	queue_free()
