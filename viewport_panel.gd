@tool
class_name ViewportPanel
extends MeshInstance3D

func _ready():
	material_override.resource_local_to_scene = true
	material_override.albedo_texture = $SubViewport.get_texture()
