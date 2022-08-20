extends Spatial


const _Explosion := preload("res://src/instance/Explosion.tscn")
const _DamageIndicator := preload("res://src/instance/DamageIndicator.tscn")

const _MAX_HEALTH := 100.0
const _EXPLOSION_SIZE := 1.0

var _health := _MAX_HEALTH

onready var _n_skeleton := $Skeleton


func _ready() -> void:
	yield(get_tree(), "idle_frame") # ???
	_n_skeleton.physical_bones_start_simulation()


func damage(damage_data : Damage) -> void:
	var dmgind := _DamageIndicator.instance()
	get_parent().add_child(dmgind)
	
	dmgind.text = str(int(damage_data.amount))
	dmgind.global_translation = global_translation + Vector3(rand_range(-1, 1), 0.0, rand_range(-1, 1))
	
	_health -= damage_data.amount
	
	if _health < 0.0:
		var explosion := _Explosion.instance()
		get_parent().add_child(explosion)
		explosion.global_translation = _n_skeleton.get_bone_global_pose(_n_skeleton.find_bone("Torso")).origin + _n_skeleton.global_translation
		explosion.explode(_EXPLOSION_SIZE)
		queue_free()
