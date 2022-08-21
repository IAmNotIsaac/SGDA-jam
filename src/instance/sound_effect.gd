class_name SoundEffect
extends AudioStreamPlayer3D


const SOUNDS := {
	"STEP": [
		preload("res://assets/sfx/Step1.ogg"),
		preload("res://assets/sfx/Step2.ogg"),
		preload("res://assets/sfx/Step3.ogg"),
		preload("res://assets/sfx/Step4.ogg")
	],
	
	"SHOTGUN": preload("res://assets/sfx/Shotgun.ogg"),
	"SHOTGUN_PUMP": preload("res://assets/sfx/ShotgunPump.ogg"),
	"REVOLVER": preload("res://assets/sfx/Revolver.mp3"),
	"PISTOL": preload("res://assets/sfx/Pistol.mp3"),
	"MINIGUN": preload("res://assets/sfx/MachineGun.ogg"),
	"GRENADE_LAUNCHER": preload("res://assets/sfx/GrenadeLauncher.ogg"),
	
	"BULLET_IMPACT": preload("res://assets/sfx/ConcreteImpact.mp3"),
	"EXPLOSION": preload("res://assets/sfx/Explosion.mp3"),
	
	"SWITCH": preload("res://assets/sfx/Switch.ogg"),
	"DOOR": preload("res://assets/sfx/Door.ogg"),
}


func play_sound(sound, distance := 1.0) -> void:
	if sound is Array:
		sound = sound[randi() % len(sound)]
	
	stream = sound
	unit_size = distance
	max_db = linear2db(Settings.sfx)
	unit_db = linear2db(Settings.sfx)
	play()
	
	yield(self, "finished")
	
	queue_free()
