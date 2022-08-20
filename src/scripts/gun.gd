class_name Gun
extends Resource


enum GunTypes {
	SHOTGUN,
	REVOLVER,
	PISTOL,
	MINIGUN,
	GRENADE_LAUNCHER,
	INSTAKILL
}

const _Bullet := preload("res://src/instance/Bullet.tscn")
const _Grenade := preload("res://src/instance/Grenade.tscn")
# measured in milliseconds
const _COOLDOWNS := {
	GunTypes.SHOTGUN: 1000,
	GunTypes.REVOLVER: 1500,
	GunTypes.PISTOL: 250,
	GunTypes.MINIGUN: 100,
	GunTypes.GRENADE_LAUNCHER: 2000,
	GunTypes.INSTAKILL: 0
}
const _FULL_AUTOS := [
	GunTypes.MINIGUN,
	GunTypes.INSTAKILL
]
const _ACTIONS := {
	GunTypes.SHOTGUN: DeathAction.Type.BULLET_EXPLOSION,
	GunTypes.REVOLVER: DeathAction.Type.RANDOM_KO,
	GunTypes.PISTOL: DeathAction.Type.NONE,
	GunTypes.MINIGUN: DeathAction.Type.SPEED_BUFF,
	GunTypes.GRENADE_LAUNCHER: DeathAction.Type.EXPLODE
}

export(GunTypes) var base : int = GunTypes.PISTOL
export(Array, GunTypes) var secondaries := []
export(int) var secondary_idx := 0

var _last_shot_times := {
	"base": -100000,
	"alt": {}
}


## Private methods ##


func _can_shoot(alt : bool) -> bool:
	if alt:
		return can_shoot_alt()
	return can_shoot_base()


func _get_alt_shot_time(idx : int) -> int:
	if _last_shot_times["alt"].has(idx):
		return _last_shot_times["alt"][idx]
	return -1000000


func _cooldown(alt : bool) -> void:
	match alt:
		true:
			_last_shot_times["alt"][secondary_idx] = OS.get_ticks_msec()
		
		false:
			_last_shot_times["base"] = OS.get_ticks_msec()


func _spawn_bullet(bullet_type : int, tree : SceneTree, spawn_pos : Vector3, spawn_rot : Vector3) -> void:
	var bullet := _Bullet.instance()
	
	bullet.translation = spawn_pos
	bullet.rotation = spawn_rot
	
	tree.get_current_scene().add_child(bullet)
	yield(tree, "idle_frame")
	
	bullet.shoot(bullet_type)


func _shoot(gun_type : int, alt : bool, tree : SceneTree, spawn_pos : Vector3, spawn_rot : Vector3, ignore_cooldown := false) -> void:
	if (not ignore_cooldown and not _can_shoot(alt)):
		return
	
	match gun_type:
		GunTypes.SHOTGUN:
			for i in 5:
				_spawn_bullet(Bullet.ShotTypes.SHOTGUN, tree, spawn_pos, spawn_rot)
			_cooldown(alt)
		
		GunTypes.REVOLVER:
			_spawn_bullet(Bullet.ShotTypes.REVOLVER, tree, spawn_pos, spawn_rot)
			_cooldown(alt)
		
		GunTypes.PISTOL:
			_spawn_bullet(Bullet.ShotTypes.PISTOL, tree, spawn_pos, spawn_rot)
			_cooldown(alt)
		
		GunTypes.MINIGUN:
			_spawn_bullet(Bullet.ShotTypes.MINIGUN, tree, spawn_pos, spawn_rot)
			_cooldown(alt)
		
		GunTypes.GRENADE_LAUNCHER:
			spawn_rot = Vector3(-sin(spawn_rot.y), sin(spawn_rot.x), -cos(spawn_rot.y))
			
			var grenade := _Grenade.instance()
			tree.get_current_scene().add_child(grenade)
			
			grenade.global_translation = spawn_pos + spawn_rot * 0.5
			grenade.add_central_force(spawn_rot * 1000.0)
			grenade.apply_torque_impulse(Vector3.ONE)
			_cooldown(alt)
		
		GunTypes.INSTAKILL:
			_spawn_bullet(Bullet.ShotTypes.INSTAKILL, tree, spawn_pos, spawn_rot)
			_cooldown(alt)


## Public methods ##


func shoot(tree : SceneTree, gun_ : int, spawn_pos : Vector3, spawn_rot : Vector3, ignore_cooldown := false) -> void:
	_shoot(gun_, true, tree, spawn_pos, spawn_rot, ignore_cooldown)


func shoot_base(tree : SceneTree, spawn_pos : Vector3, spawn_rot : Vector3) -> void:
	_shoot(base, false, tree, spawn_pos, spawn_rot)


func shoot_alt(tree : SceneTree, spawn_pos : Vector3, spawn_rot : Vector3) -> void:
	if has_alt():
		_shoot(secondaries[secondary_idx], true, tree, spawn_pos, spawn_rot)


func can_shoot_base() -> bool:
	return (OS.get_ticks_msec() - _last_shot_times["base"]) >= _COOLDOWNS[base]


func can_shoot_alt() -> bool:
	return (OS.get_ticks_msec() - _get_alt_shot_time(secondary_idx)) >= _COOLDOWNS[secondaries[secondary_idx]]


func is_base_auto() -> bool:
	return base in _FULL_AUTOS


func is_alt_auto() -> bool:
	if not has_alt():
		return false
	return secondaries[secondary_idx] in _FULL_AUTOS


func next_alt() -> void:
	secondary_idx = wrapi(secondary_idx + 1, 0, len(secondaries))


func prev_alt() -> void:
	secondary_idx = wrapi(secondary_idx - 1, 0, len(secondaries))


func has_alt() -> bool:
	return len(secondaries) > 0


func get_base_bullet_distance() -> float:
	return Bullet.SHOT_DATA[base]["distance"]


func get_alt_bullet_distance() -> float:
	if not len(secondaries) > 0:
		return 0.0
	return Bullet.SHOT_DATA[secondaries[secondary_idx]]["distance"]


func get_base() -> int:
	return base


func get_secondaries() -> Array:
	return secondaries


func get_gun_action_type(gun : int) -> int:
	return _ACTIONS[gun]


func clear_cooldowns() -> void:
	_last_shot_times = {
		"base": -100000,
		"alt": {}
	}
