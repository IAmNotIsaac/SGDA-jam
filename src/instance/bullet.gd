class_name Bullet
extends Spatial


enum ShotTypes {
	SHOTGUN,
	REVOLVER,
	PISTOL,
	MINIGUN
}

const SHOT_DATA := {
	ShotTypes.SHOTGUN: {
		"distance": 5.0,
		"accuracy": 0.9
	},
	
	ShotTypes.REVOLVER: {
		"distance": 50.0,
		"accuracy": 0.98
	},
	
	ShotTypes.PISTOL: {
		"distance": 25.0,
		"accuracy": 0.95
	},
	
	ShotTypes.MINIGUN: {
		"distance": 25.0,
		"accuracy": 0.9
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
	
	if _n_ray.get_collider() != null:
		_n_mesh.global_translation = _n_ray.get_collision_point()
		_n_mesh.translation /= 2.0
		
		_n_mesh.scale.z = translation.distance_to(_n_ray.get_collision_point())
	
	else:
		_n_mesh.translation = _n_ray.cast_to / 2.0
		_n_mesh.scale.z = distance
	
	
	var mat := SpatialMaterial.new()
	mat.set_feature(SpatialMaterial.FEATURE_TRANSPARENT, true)
	mat.set_flag(SpatialMaterial.FLAG_UNSHADED, true)
	mat.albedo_color = Color(1.0, 1.0, 0.0, 0.7)
	_n_mesh.mesh.surface_set_material(0, mat)
	
	var tween = get_tree().create_tween()
	tween.tween_property(mat, "albedo_color", Color(1.0, 1.0, 6.0, 0.0), 0.5)
	yield(tween, "finished")
	queue_free()
