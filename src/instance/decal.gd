tool
class_name Decal
extends Spatial


export(Texture) var _texture setget set_texture
export(bool) var _transparent setget set_transparent


func _ready() -> void:
	$MeshInstance.cast_shadow = GeometryInstance.SHADOW_CASTING_SETTING_OFF
	_update_texture()
	
	if Engine.editor_hint:
		set_process(true)
	else:
		set_process(false)


func set_texture(new_texture : Texture) -> void:
	_texture = new_texture
	_update_texture()


func set_transparent(new_transparent : bool) -> void:
	_transparent = new_transparent
	_update_texture()


func _update_texture() -> void:
	var mat := SpatialMaterial.new()
	
	mat.albedo_texture = _texture
	mat.set_feature(SpatialMaterial.FEATURE_TRANSPARENT, _transparent)
	
	$MeshInstance.set_surface_material(0, mat)
