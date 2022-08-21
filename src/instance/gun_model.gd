class_name GunModel
extends Spatial


var _gun_model
var _gun := -1

onready var _models := {
	Gun.GunTypes.GRENADE_LAUNCHER: $GrenadeLauncher,
	Gun.GunTypes.PISTOL: $Pistol,
	Gun.GunTypes.REVOLVER: $Revolver,
	Gun.GunTypes.MINIGUN: $Minigun,
	Gun.GunTypes.SHOTGUN: $Shotgun
}


func switch_to(gun : int) -> void:
	if gun == _gun:
		return
	
	_gun = gun
	
	if _gun_model:
		_gun_model.hide()
	
	if gun != -1:
		_gun_model = _models[gun]
		_gun_model.show()
