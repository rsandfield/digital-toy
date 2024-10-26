@tool
extends EditorScenePostImport

const MAT_DIR = "res://materials"
const SUFFIX_AREA_3D = "-area"
const SUFFIX_GRAVITY = "-grav"

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
    if node.name.ends_with(SUFFIX_AREA_3D):
        _handle_replace_with_area_3d(node)
        return
    if node.name.ends_with(SUFFIX_GRAVITY):
        _handle_replace_with_gravity(node)
        return

    _handle_mesh_replacement(node)


func _handle_replace_with_area_3d(node: MeshInstance3D):
    var area3d := Area3D.new()
    area3d.name = node.name.trim_suffix(SUFFIX_AREA_3D)

    var col_shape := _mesh_to_collision_shape(node.mesh)

    _replace_node(node, area3d)
    area3d.add_child(col_shape)
    col_shape.set_owner(area3d.get_parent())


func _handle_replace_with_gravity(node: MeshInstance3D):
    var grav := GravityArea3D.new()
    grav.name = node.name.trim_suffix(SUFFIX_GRAVITY)
    grav.gravity_space_override = Area3D.SPACE_OVERRIDE_COMBINE
    grav.reorient()

    var col_shape := _mesh_to_collision_shape(node.mesh)

    _replace_node(node, grav)
    grav.add_child(col_shape)
    col_shape.set_owner(grav.get_parent())


func _replace_node(node: MeshInstance3D, new_node: Node3D):
    new_node.transform = node.transform
    new_node.basis = node.basis

    var parent = node.get_parent()
    parent.add_child(new_node)
    new_node.set_owner(parent)
    parent.remove_child(node)


func _mesh_to_collision_shape(mesh: Mesh) -> CollisionShape3D:
    var col_shape := CollisionShape3D.new()
    col_shape.name = "CollisionShape3D"
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
