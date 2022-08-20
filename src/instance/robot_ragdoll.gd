extends Spatial


onready var _n_skeleton := $robot/Armature/Skeleton


func _ready() -> void:
	_n_skeleton.physical_bones_start_simulation()
