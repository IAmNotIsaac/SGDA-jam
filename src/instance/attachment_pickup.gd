extends Spatial


export(Gun.GunTypes) var _pickup_attachment

onready var _n_mesh := $MeshInstance
onready var _n_outline := $MeshInstance/Outline


func _ready() -> void:
	var mesh := CapsuleMesh.new()
	var outline := SpatialMaterial.new()
	
	mesh.radius = 0.5
	
	outline.albedo_color = Color.black
	outline.metallic_specular = 0.0
	outline.params_cull_mode = SpatialMaterial.CULL_FRONT
	outline.params_grow = true
	outline.params_grow_amount = 0.1
	
	_n_mesh.mesh = mesh
	_n_outline.mesh = mesh.duplicate()
	
	_n_outline.mesh.material = outline


func _on_Area_body_entered(body : PhysicsBody) -> void:
	if body is Player:
		body._gun.secondaries.append(_pickup_attachment)
		body._gun.secondary_idx = len(body._gun.secondaries) - 1
		queue_free()
