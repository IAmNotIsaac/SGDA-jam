extends Spatial


onready var _n_particles := $CPUParticles


func _ready() -> void:
	_n_particles.emitting = true


func _on_Timer_timeout() -> void:
	queue_free()
