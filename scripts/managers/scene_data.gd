class_name SceneData
extends Object

var filepath: String
var nodes: Array[Dictionary]
var connections: PackedStringArray
var portal_ids: PackedStringArray
var viewport_node: SubViewport
var name: String
var mutex: Mutex = Mutex.new()

func _init(fp: String, n: Array[Dictionary]):
    filepath = fp
    nodes = n
    name = SceneManager.file_path_to_name(filepath)


func load(container: SubViewportContainer):
    if is_loaded():
        return
    mutex.lock()
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
    mutex.unlock()

    for portal_id in portal_ids:
        var portal = GameManager.get_portal(portal_id)
        var other_portal_id = portal.other_portal_id
        if other_portal_id == null || len(other_portal_id) < 1:
            continue
        if SceneManager.is_portal_loaded(other_portal_id):
            GameManager.link_portals(portal, other_portal_id)


func unload():
    if !is_loaded():
        return
    print("Unloading %s" % self)
    mutex.lock()
    # Return portal assets to owners before freeing nodes
    for portal_id in portal_ids:
        GameManager.deregister_portal_id(portal_id)
    viewport_node.free()
    mutex.unlock()


func set_active(container: SubViewportContainer, player: Player):
    if is_loaded():
        if player.get_viewport() != viewport_node:
            player.reparent(viewport_node)
        container.move_child(viewport_node, -1)
        var scene = viewport_node.get_child(0) as GameScene
        if scene:
            scene.on_enter()


func is_loaded() -> bool:
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
