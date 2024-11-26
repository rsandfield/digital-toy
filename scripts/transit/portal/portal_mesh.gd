@tool
class_name PortalMesh
extends MeshInstance3D


# Maybe could calculate the necessary thickness based on camera near cull plane
# 0.3 isn't always enough had to up it to 0.5 to prevent occasional glitching
const THICKNESS = 0.05

var visible_layer: int = 5

var _portal: Portal
var _viewport: PortalViewport


func _ready():
    _portal = get_parent()


func _exit_tree():
    if is_instance_valid(_viewport):
        _viewport.queue_free()


func assign_viewport(viewport: PortalViewport):
    _viewport = viewport
    var portal_material = ShaderMaterial.new()
    portal_material.shader = preload("res://scripts/transit/portal/portal_sps.gdshader")
    portal_material.resource_local_to_scene = true
    portal_material.set_shader_parameter("albedo", viewport.get_texture())
    material_override = portal_material


func resize(new_size: Vector2):
    if (
        !(mesh is BoxMesh) ||
        (mesh.size.x == new_size.x &&
        mesh.size.y == new_size.y)
    ):
        return
    mesh.size.x = new_size.x
    mesh.size.y = new_size.y
    position = Vector3(0, mesh.size.y * 0.5, 0)


func replace_layer_mask(layer: int):
    visible_layer = layer
    set_layer_mask_value(layers, false)
    set_layer_mask_value(visible_layer, true)


func reassign_camera_portal(portal: Portal):
    if portal == null:
        portal = _portal

    if get_parent() == portal:
        return

    _viewport.reparent(portal)


func thicken_if_necessary(parent_basis: Basis, camera: Camera3D):
    if !(mesh is BoxMesh):
        return

    resize(get_parent().size)

    var forward : Vector3 = parent_basis.z
    var right : Vector3 = parent_basis.x
    var up : Vector3 = parent_basis.y
    var camera_offset_from_portal = camera.global_position - self.global_position
    var dist_from_portal_plane_forward = camera_offset_from_portal.dot(forward)
    var dist_from_portal_plane_to_right = camera_offset_from_portal.dot(right)
    var dist_from_portal_plane_up = camera_offset_from_portal.dot(up)
    var portal_side = sign(dist_from_portal_plane_forward)
    if portal_side == 0:
        portal_side = 1

    var half_portal_width = mesh.size.x * 0.5
    var half_portal_height = mesh.size.y * 0.5
    position = Vector3(0, half_portal_height, 0)
    # Only thicken portal if we are very close to it
    if (abs(dist_from_portal_plane_forward) > 1.0
        or abs(dist_from_portal_plane_to_right) > half_portal_width + 0.3
        or dist_from_portal_plane_up > half_portal_height + 0.3):
        mesh.size.z = 0.0
        position.z = 0.0
        return

    mesh.size.z = THICKNESS

    # Check if the camera is facing the portal and is within a certain distance
    if portal_side == 1:
        position.z = -THICKNESS/2.0
    else:
        position.z = THICKNESS/2.0


func is_on_screen(camera: Camera3D) -> bool:
    if camera.get_viewport() != get_viewport():
        return false
    if !camera.is_position_behind(global_transform.origin):
        return false
    if !camera.unproject_position(global_transform.origin):
        return false
    return true


func _to_string():
    return "%s[%s]" % [name, visible_layer]