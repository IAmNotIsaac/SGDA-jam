extends Spatial


const LEVELS := {
	"LEVEL_1": 0, #LevelSwitcher.LEVELS.,
	"LEVEL_2": 1, #LevelSwitcher.LEVELS.LEVEL2,
	"LEVEL_3": 2, #LevelSwitcher.LEVELS.LEVEL3
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
		LevelSwitcher.load_level(LevelSwitcher.LEVELS[_next_level])
