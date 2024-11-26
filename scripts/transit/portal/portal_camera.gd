class_name PortalCamera
extends Camera3D


signal portal_entered_view(portal: Portal)
signal portal_exited_view(portal: Portal)


var _portal: Portal
var _shape: ConvexPolygonShape3D
# var _mesh: ArrayMesh

func _init():
    var area = get_node_or_null("Area3D")
    if area:
        return
    area = Area3D.new()
    area.name = "Area3D"
    var shape = CollisionShape3D.new()
    shape.name = "CollisionShape3D"
    area.add_child(shape)
    add_child(area)

    # var mesh_instance := MeshInstance3D.new()
    # _mesh = ArrayMesh.new()
    # mesh_instance.mesh = _mesh
    # mesh_instance.material_override = preload(
    #     "res://materials/translucent/solid/cyan_translucent.tres"
    # )
    # add_child(mesh_instance)
    # print(get_children())


func _enter_tree():
    var shape = $Area3D/CollisionShape3D
    _shape = ConvexPolygonShape3D.new()
    shape.shape = _shape
    resize_frustum_area3d()
    _portal = get_parent().get_parent()

# Called when the node enters the scene tree for the first time.
func _ready():
    pass # Replace with function body.

func resize_frustum_area3d():
    var frustum = get_frustum()
    var points = PackedVector3Array([
        frustum[0].intersect_3(frustum[2], frustum[3]) as Vector3,
        frustum[0].intersect_3(frustum[3], frustum[4]) as Vector3,
        frustum[0].intersect_3(frustum[4], frustum[5]) as Vector3,
        frustum[0].intersect_3(frustum[5], frustum[2]) as Vector3,
        frustum[1].intersect_3(frustum[2], frustum[3]) as Vector3,
        frustum[1].intersect_3(frustum[3], frustum[4]) as Vector3,
        frustum[1].intersect_3(frustum[4], frustum[5]) as Vector3,
        frustum[1].intersect_3(frustum[5], frustum[2]) as Vector3,
    ])
    _shape.points = points
    # var arr = []
    # arr.resize(Mesh.ARRAY_MAX)
    # arr[Mesh.ARRAY_VERTEX] = points
    # arr[Mesh.ARRAY_INDEX] = PackedInt32Array([
    #     # 0, 1, 2, 0, 2, 3,
    #     # 4, 5, 6, 4, 6, 7,
    #     # 0, 1, 4, 1, 5, 4,  # Front right
    #     # 1, 2, 5, 2, 6, 5,  # Right side
    #     # 2, 3, 6, 3, 7, 6,  # Back right
    #     # 3, 0, 7, 0, 4, 7,  # Left side
    # ])
    # _mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLE_STRIP, arr)

func set_world_environment_no_tonemap(world_3d: World3D):
    if not world_3d or not world_3d.environment:
        return
    # The tonemap must be disabled/set to linear.
    # This is so the tonemap won't be applied twice in the main camera render.
    environment = world_3d.environment.duplicate()
    environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR


func cull_mask_string() -> String:
    var int_value = cull_mask
    var bin_str: String = ""
    while int_value > 0:
        bin_str = bin_str + str(int_value & 1)
        int_value = int_value >> 1
    return bin_str


func _on_frustum_entered(area: Area3D):
    if area is Portal && area != _portal:
        portal_entered_view.emit(area)


func _on_frustum_exited(area: Area3D):
    if area is Portal && area != _portal:
        portal_exited_view.emit(area)

# https://github.com/V-Sekai/avatar_vr_demo/blob/master/addons/V-Sekai.xr-mirror/mirror.gd
func set_projection_oblique_near_plane(matrix: Projection, clip_plane: Plane):
    # Based on the paper
    # Lengyel, Eric. “Oblique View Frustum Depth Projection and Clipping”.
    # Journal of Game Development, Vol. 1, No. 2 (2005), Charles River Media, pp. 5–16.

    # Calculate the clip-space corner point opposite the clipping plane
    # as (sgn(clipPlane.x), sgn(clipPlane.y), 1, 1) and
    # transform it into camera space by multiplying it
    # by the inverse of the projection matrix
    var q = Vector4(
        (sign(clip_plane.x) + matrix.z.x) / matrix.x.x,
        (sign(clip_plane.y) + matrix.z.y) / matrix.y.y,
        -1.0,
        (1.0 + matrix.z.z) / matrix.w.z)

    var clip_plane4 = Vector4(clip_plane.x, clip_plane.y, clip_plane.z, clip_plane.d)

    # Calculate the scaled plane vector
    var c: Vector4 = clip_plane4 * (2.0 / clip_plane4.dot(q))

    # Replace the third row of the projection matrix
    matrix.x.z = c.x - matrix.x.w
    matrix.y.z = c.y - matrix.y.w
    matrix.z.z = c.z - matrix.z.w
    matrix.w.z = c.w - matrix.w.w
    return matrix

# https://github.com/SebLague/Portals/blob/master/Assets/Scripts/Core/Portal.cs
func _update_near_clip_plane(exit_portal: Portal):
    var camera := self
    if not camera.has_method("set_override_projection"):
        return # Needs https://github.com/V-Sekai/godot/tree/override_projection_4.2 branch

    const NEAR_CLIP_OFFSET = 0.05
    const NEAR_CLIP_LIMIT = 0.1

    # Calculate the near clip plane in camera space
    var clip_plane = exit_portal.global_transform
    var clip_plane_forward: Vector3 = -clip_plane.basis.z
    var portal_side = MathHelper.nonzero_sign(clip_plane_forward.dot(
        exit_portal.global_transform.origin - camera.global_transform.origin
    ))

    var cam_space_pos = camera.get_camera_transform().affine_inverse() * clip_plane.origin
    var cam_space_normal = (
        camera.get_camera_transform().affine_inverse().basis * clip_plane_forward
    ) * portal_side
    var cam_space_dst = - cam_space_pos.dot(cam_space_normal) + NEAR_CLIP_OFFSET;

    # Oblique plane when very close to portal causes glitching/visual artifacts,
    # so only enable if a small distance away
    if abs(cam_space_dst) > NEAR_CLIP_LIMIT:
        var proj : Projection = camera.get_camera_projection()
        var near_clip_plane = Plane(cam_space_normal, cam_space_dst)
        proj = set_projection_oblique_near_plane(proj, near_clip_plane)
        camera.set_override_projection(proj)
    else:
        # Set back to unmodified frustum if camera is very close to portal
        camera.set_override_projection(
            Projection(Vector4.ZERO, Vector4.ZERO, Vector4.ZERO, Vector4.ZERO)
        )