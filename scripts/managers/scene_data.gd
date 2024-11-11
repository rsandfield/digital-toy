class_name SceneData
extends Object

signal loaded

enum State {
    UNLOADED,
    LOADING,
    LOADED,
    UNLOADING,
}

var filepath: String
var nodes: Array[Dictionary]
var connections: PackedStringArray
var portal_ids: PackedStringArray
var viewport_node: SubViewport
var name: String
var _mutex: Mutex = Mutex.new()
var _state := State.UNLOADED
var _l := Logger.new("cyan")

func _init(fp: String, n: Array[Dictionary]):
    filepath = fp
    nodes = n
    name = SceneManager.file_path_to_name(filepath)


func load(container: SubViewportContainer):
    if _state == State.LOADED || _state == State.LOADING:
        return
    if !_mutex.try_lock():
        return
    _state = State.LOADING
    _l.print("Loading %s" % name)
    viewport_node = SubViewport.new()
    viewport_node.name = name
    viewport_node.own_world_3d = true
    viewport_node.audio_listener_enable_3d = true
    var scene = load(filepath)
    var instance = scene.instantiate()
    viewport_node.add_child(instance)
    container.add_child.call_deferred(viewport_node)
    container.move_child.call_deferred(viewport_node, 0)
    reset_elevators.call_deferred(instance)

    await viewport_node.ready

    for portal_id in portal_ids:
        var portal = GameManager.get_portal(portal_id)
        var other_portal_id = portal.other_portal_id
        if other_portal_id == null || len(other_portal_id) < 1:
            continue
        if SceneManager.is_portal_loaded(other_portal_id):
            GameManager.link_portals(portal, other_portal_id)

    _state = State.LOADED
    loaded.emit()
    _mutex.unlock()

func unload():
    if _state == State.LOADING:
        await loaded
    if _state != State.LOADED:
        return
    if !_mutex.try_lock():
        return
    _l.print("Unloading %s" % self)
    _state = State.UNLOADING
    # Return portal assets to owners before freeing nodes
    for portal_id in portal_ids:
        GameManager.deregister_portal_id(portal_id)
    viewport_node.queue_free()
    await viewport_node.tree_exited
    _state = State.UNLOADED
    _mutex.unlock()


func set_active(container: SubViewportContainer, player: Player):
    if is_loaded():
        if player.get_viewport() != viewport_node:
            player.reparent.call_deferred(viewport_node)
            await player.tree_entered
            print("Player moved")
        container.move_child.call_deferred(viewport_node, -1)
        await container.child_order_changed
        var scene = viewport_node.get_child(0) as GameScene
        if scene:
            scene.on_enter()


func is_loaded() -> bool:
    return _state == State.LOADED


func reset_elevators(node: Node3D):
    if node.has_method("reset_elevator"):
        node.reset_elevator()
        return
    for child in node.get_children():
        if child is Node3D:
            reset_elevators(child)


func _to_string():
    return name
