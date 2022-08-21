class_name LevelEnd
extends Spatial


const LEVELS := {
	"LEVEL_1": 0,
	"LEVEL_2": 1,
	"LEVEL_3": 2,
	"LEVEL_FINAL": 3,
	"LEVEL_TUTORIAL": 4
}

const VOICE_LINE_DATA := {
	LEVELS.LEVEL_1: {
		"voice": preload("res://assets/voice/ability.ogg"),
		"subtitle": "Akimbot, you'll notice when you die, you can use an ability called \"Shrapnel\". Death is not the end."
	},
	LEVELS.LEVEL_2: {
		"voice": preload("res://assets/voice/minigun.ogg"),
		"subtitle": "Creator here. What's good? I think I dropped my minigun somewhere on this track. If you find it, you can keep it."
	},
	LEVELS.LEVEL_3: {
		"voice": preload("res://assets/voice/grenade.ogg"),
		"subtitle": "Akimbot! I left you a grenade launcher! Go crazy."
	},
	LEVELS.LEVEL_FINAL: {
		"voice": preload("res://assets/voice/challenge.ogg"),
		"subtitle": "Akimbot, there's just one more task for you. The final challenge."
	},
	LEVELS.LEVEL_TUTORIAL: {
		"voice": preload("res://assets/voice/intro.ogg"),
		"subtitle": "You are Akimbot. I am your creator. I made you so you could shoot guns. Now go shoot some guns."
	}
}

export(LEVELS) var _next_level
export(bool) var _short_level := false
export(bool) var _decorational := false


func _ready() -> void:
	if _short_level:
		$MeshInstance2.translation.y = 2.9


func _on_Area_body_entered(body : PhysicsBody) -> void:
	if not _decorational and body is Player:
		Settings.level = _next_level
		LevelSwitcher.load_level(VOICE_LINE_DATA[_next_level]["voice"], VOICE_LINE_DATA[_next_level]["subtitle"], LevelSwitcher.LEVELS[_next_level])
