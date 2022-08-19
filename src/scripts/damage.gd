class_name Damage


class Type:
	class BulletDamage:
		const SHOTGUN  := 0
		const REVOLVER := 1
		const PISTOL   := 2
		const MINIGUN  := 3
	
	class ExplosionDamage:
		const GRENADE := 4


var damage_type : int
var amount : float


func _init(damage_type_ : int, amount_ : float) -> void:
	damage_type = damage_type_
	amount = amount_
