class_name DeathAction


signal action_complete

enum Type {
	NONE, EXPLODE, BULLET_EXPLOSION, RANDOM_KO, SPEED_BUFF
}

const _ACTION_NAMES := {
	Type.NONE: "None",
	Type.EXPLODE: "Explode",
	Type.BULLET_EXPLOSION: "Bullet Explosion",
	Type.RANDOM_KO: "Head-shot",
	Type.SPEED_BUFF: "Increased speed"
}

const _Explosion := preload("res://src/instance/Explosion.tscn")
const _EXPLOSION_POWER := 7.0
const _SPEED_BUFF := 1.5

var _action : int


func _init(action : int) -> void:
	_action = action


func act(tree : SceneTree, player) -> void:
	match _action:
		Type.NONE: pass
		Type.EXPLODE:
			var _explosion := _Explosion.instance()
			
			_explosion.translation = player.global_translation
			tree.get_current_scene().add_child(_explosion)
			
			_explosion.explode(_EXPLOSION_POWER, player)
			
			yield(_explosion, "explosion_complete")
		
		Type.RANDOM_KO:
			var target = null
			
			for e in tree.get_nodes_in_group("enemy"):
				if e.can_see_player():
					target = e
					break
			
			if target != null:
				var dir : Vector3 = player.global_translation.direction_to(target.global_translation)
				var rot := Vector3(asin(dir.y), acos(-dir.z), 0.0)
				
				# whatever im lazy
				player._gun.shoot(tree, 5, player.global_translation, rot)
			
			yield(tree.create_timer(1.0), "timeout")
		
		Type.BULLET_EXPLOSION:
			var pitch_incs := 8.0
			var yaw_incs := 8.0
			
			for pitchi in range(-pitch_incs / 2 + 1, pitch_incs / 2):
				for yawi in range(yaw_incs):
					var rot := Vector3(PI / pitch_incs * pitchi, PI * 2.0 * (1.0 / yaw_incs) * (yawi), 0.0)
					
					player._gun.shoot(tree, 5, player.global_translation, rot, true)
			
			yield(tree.create_timer(1.0), "timeout")
		
		Type.SPEED_BUFF:
			player.speed_factor = _SPEED_BUFF
			
			yield(tree.create_timer(1.0), "timeout")
	
	emit_signal("action_complete")

static func get_action_name(type : int) -> String:
	return _ACTION_NAMES[type]
