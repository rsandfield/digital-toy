class_name PortalViewport
extends SubViewport

const MAX_RECURSION_DEPTH := 0

var depth := 0
var viewed_portal_meshes: Dictionary = {}
var _camera: Camera3D
var _portal: Portal


func _ready():
    _camera = get_node_or_null("Camera3D")
    if !_camera:
        _camera = PortalCamera.new()
        _camera.name = "Camera3D"
        add_child(_camera)
    _camera.set_world_environment_no_tonemap(_portal.get_viewport().world_3d)
    NodeHelper.connect_signal(_camera.portal_entered_view, self, "_on_portal_entered_view")
    NodeHelper.connect_signal(_camera.portal_exited_view, self, "_on_portal_exited_view")
    get_tree().get_root().size_changed.connect(resize)
    resize()


func _enter_tree():
    _portal = get_parent()


func _exit_tree():
    for portal_id in viewed_portal_meshes:
        var mesh = viewed_portal_meshes[portal_id]
        if is_instance_valid(mesh):
            mesh.queue_free()


func update_camera(ref_camera: Camera3D):
    if !ref_camera:
        return

    if _portal.exit_portal:
        _camera.global_transform = _portal.exit_portal.global_transform_relative_to_exit(ref_camera)
    else:
        _camera.global_transform = ref_camera.global_transform
    # if _portal.exit_portal:
    #     print("%s %s" % [
    #         _portal.global_transform.affine_inverse() * ref_camera.global_transform,
    #         _portal.exit_portal.global_transform.affine_inverse() * _camera.global_transform
    #     ])
    _camera.fov = ref_camera.fov

    _camera.cull_mask = GameManager.get_player_camera().cull_mask
    _camera.set_cull_mask_value(4, false) # Player can see base portals

    for portal_id in viewed_portal_meshes:
        var mesh = viewed_portal_meshes[portal_id]
        _camera.set_cull_mask_value(mesh.visible_layer, true)
        mesh._viewport.update_camera(_camera)


func resize():
    var viewport = get_tree().get_root()
    size = viewport.get_visible_rect().size
    msaa_3d = viewport.msaa_3d
    screen_space_aa = viewport.screen_space_aa
    use_taa = viewport.use_taa
    use_debanding = viewport.use_debanding
    use_occlusion_culling = viewport.use_occlusion_culling
    mesh_lod_threshold = viewport.mesh_lod_threshold

    for portal_id in viewed_portal_meshes:
        viewed_portal_meshes[portal_id].resize(viewport)


func _on_portal_entered_view(portal: Portal):
    print("%s can see %s" % [_portal, portal])
    if depth >= MAX_RECURSION_DEPTH:
        return

    var viewport = PortalViewport.new()
    viewport.depth = depth + 1
    viewport.name = "%s[%s]" % [name, portal.portal_id]
    portal.add_child(viewport)

    var mesh = PortalMesh.new()
    mesh.mesh = portal.mesh.mesh
    mesh.assign_viewport(viewport)
    mesh.reassign_camera_portal(portal.exit_portal)
    mesh.resize(portal.size)
    var used = portal.get_used_visual_layers()
    used.append_array(_portal.get_used_visual_layers())
    print(used)
    for portal_id in viewed_portal_meshes:
        used.append(viewed_portal_meshes[portal_id].visible_layer)
    for i in range(5, 10):
        if !used.has(i):
            mesh.replace_layer_mask(i)
            break
    portal.add_nested_portal_mesh(mesh)
    portal.add_child(mesh)
    mesh.global_transform = portal.mesh.global_transform

    viewed_portal_meshes[portal.portal_id] = mesh


func _on_portal_exited_view(portal: Portal):
    # print("%s can no longer see %s" % [_portal, portal])
    if !viewed_portal_meshes.has(portal.portal_id):
        return
    viewed_portal_meshes[portal.portal_id].queue_free()
    viewed_portal_meshes.erase(portal.portal_id)
