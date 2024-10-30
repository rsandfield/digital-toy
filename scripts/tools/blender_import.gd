@tool
extends EditorScenePostImport

const MAT_DIR = "res://materials"
const SUFFIX_AREA_3D = "-area"
const SUFFIX_GRAVITY = "-grav"
const SUFFIX_LADDER = "-ladder"

func _post_import(scene):
    _iterate(scene)
    return scene


func _iterate(node):
    if node == null:
        return

    _handle_node(node)

    for child in node.get_children():
        _iterate(child)


func _handle_node(node):
    if node is MeshInstance3D:
        _handle_mesh_instance_3d(node)


func _handle_mesh_instance_3d(node: MeshInstance3D):
    var static_body = node.get_node_or_null("StaticBody3D")
    if static_body:
        static_body.name = node.name + static_body.name
    if node.name.ends_with(SUFFIX_AREA_3D):
        _handle_replace_with_area_3d(node)
        return
    if node.name.ends_with(SUFFIX_GRAVITY):
        _handle_replace_with_gravity(node)
        return
    if node.name.ends_with(SUFFIX_LADDER):
        _handle_replace_with_ladder(node)
        return

    _handle_mesh_replacement(node)


func _handle_replace_with_area_3d(node: MeshInstance3D):
    var area3d := Area3D.new()
    area3d.name = node.name.trim_suffix(SUFFIX_AREA_3D)

    var col_shape := _mesh_to_collision_shape(node.mesh, area3d.name)

    _replace_node(node, area3d)
    area3d.add_child(col_shape)
    col_shape.set_owner(area3d.get_parent())


func _handle_replace_with_gravity(node: MeshInstance3D):
    var grav := GravityArea3D.new()
    grav.name = node.name.trim_suffix(SUFFIX_GRAVITY)
    grav.gravity_space_override = Area3D.SPACE_OVERRIDE_COMBINE
    grav.reorient()

    var col_shape := _mesh_to_collision_shape(node.mesh, grav.name)

    _replace_node(node, grav)
    grav.add_child(col_shape)
    col_shape.set_owner(grav.get_parent())


func _handle_replace_with_ladder(node: MeshInstance3D):
    var parent = node.get_parent()
    var ladder := Ladder.new()
    parent.add_child(ladder)
    ladder.set_owner(parent)
    ladder.name = node.name.trim_suffix(SUFFIX_LADDER)
    node.name = "MeshInstance3D"

    ladder.transform = node.transform
    ladder.basis = node.basis
    node.set_owner(null)
    node.reparent(ladder)
    node.set_owner(parent)

    # Mounting collision
    var col_shape := CollisionShape3D.new()
    col_shape.name = ladder.name + "CollisionShape3D"
    var aabb := node.mesh.get_aabb()
    var box_mesh := BoxShape3D.new()
    box_mesh.size = aabb.size
    box_mesh.size.z = 0.4 # Depth ladder is mounted from
    col_shape.shape = box_mesh
    col_shape.position = aabb.position + Vector3(0, box_mesh.size.y * 0.5, 0.2)
    ladder.add_child(col_shape)
    col_shape.set_owner(parent)

    # # Dismount helper
    var top := Node3D.new()
    top.name = "TopOfLadder"
    top.position.y = box_mesh.size.y * 0.5 + col_shape.position.y
    ladder.add_child(top)
    top.set_owner(parent)

    # # Actual collisions
    var static_body := StaticBody3D.new()
    var mesh_shape = _mesh_to_collision_shape(node.mesh)
    ladder.add_child(static_body)
    static_body.add_child(mesh_shape)
    mesh_shape.set_owner(parent)



func _replace_node(node: MeshInstance3D, new_node: Node3D):
    new_node.transform = node.transform
    new_node.basis = node.basis

    var parent = node.get_parent()
    parent.add_child(new_node)
    new_node.set_owner(parent)
    parent.remove_child(node)


func _mesh_to_collision_shape(mesh: Mesh, prefix: String = "") -> CollisionShape3D:
    var col_shape := CollisionShape3D.new()
    col_shape.name = prefix + "CollisionShape3D"
    col_shape.shape = mesh.create_convex_shape()
    return col_shape


func _handle_mesh_replacement(node: MeshInstance3D):
    var mesh = node.mesh
    for index in mesh.get_surface_count():
        var editor_mat = mesh.surface_get_material(index)
        var mat_path = _find_material_file(MAT_DIR, editor_mat.resource_name)
        if len(mat_path) == 0:
            continue
        var mat = ResourceLoader.load(mat_path)
        node.set_surface_override_material(index, mat)


func _find_material_file(directory: String, material_name: String) -> String:
    var root_dir = DirAccess.open(directory)
    for filename in root_dir.get_files():
        if filename == material_name + ".tres":
            return"%s/%s" % [directory, filename]
    for child_dir in root_dir.get_directories():
        var maybe = _find_material_file("%s/%s" % [directory, child_dir], material_name)
        if len(maybe) > 0:
            return maybe
    return ""
