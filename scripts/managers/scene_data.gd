class_name SceneData
extends Object

var filepath: String
var nodes: Array[Dictionary]
var connections: PackedStringArray
var portal_ids: PackedStringArray
var viewport_node: SubViewport

func _init(fp: String, n: Array[Dictionary]):
    filepath = fp
    nodes = n


func Load(container: SubViewportContainer):
    if IsLoaded():
        return
    var scene_name = SceneManager.file_path_to_name(filepath)
    viewport_node = SubViewport.new()
    viewport_node.name = scene_name
    viewport_node.own_world_3d = true
    var scene = load(filepath)
    viewport_node.add_child(scene.instantiate())
    container.add_child(viewport_node)


func Unload():
    if !IsLoaded():
        return
    viewport_node.queue_free()


func IsLoaded() -> bool:
    return viewport_node != null