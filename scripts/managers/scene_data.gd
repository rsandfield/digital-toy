class_name SceneData
extends Object

var filepath: String
var nodes: Array[Dictionary]
var connections: PackedStringArray
var portal_ids: PackedStringArray
var viewport_node: SubViewport
var name: String

func _init(fp: String, n: Array[Dictionary]):
    filepath = fp
    nodes = n
    name = SceneManager.file_path_to_name(filepath)


func Load(container: SubViewportContainer):
    if IsLoaded():
        return
    print("Loading %s" % name)
    viewport_node = SubViewport.new()
    viewport_node.name = name
    viewport_node.own_world_3d = true
    viewport_node.audio_listener_enable_3d = true
    var scene = load(filepath)
    var instance = scene.instantiate()
    viewport_node.add_child(instance)
    container.add_child(viewport_node)
    reset_elevators.call_deferred(instance)

    for portal_id in portal_ids:
        var portal = GameManager.get_portal(portal_id)
        var other_portal_id = portal.other_portal_id
        if other_portal_id == null || len(other_portal_id) < 1:
            continue
        if SceneManager.is_portal_loaded(other_portal_id):
            GameManager.link_portals(portal, other_portal_id)


func Unload():
    if !IsLoaded():
        print("Failed unloading %s" % self)
        return
    print("Unloading %s" % self)
    GameManager.queue_kill(viewport_node)


func IsLoaded() -> bool:
    return viewport_node != null


func reset_elevators(node: Node3D):
    if node.has_method("reset_elevator"):
        node.reset_elevator()
        return
    for child in node.get_children():
        if child is Node3D:
            reset_elevators(child)


func _to_string():
    return name
