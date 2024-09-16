class_name SceneManager

const SCENE_ROOT_DIR: String = "res://scenes/game_scenes"

var _container: SubViewportContainer
var _game_scenes: Dictionary = {}
var _portals: Dictionary = {}

static func file_path_to_name(filepath: String) -> String:
	return filepath.split("/")[-1].split(".")[0]


static func reset_elevators(node: Node3D):
	if node.has_method("reset_elevator"):
		node.reset_elevator()
		return
	for child in node.get_children():
		if child is Node3D:
			reset_elevators(child)


func _init(container: SubViewportContainer):
	_container = container
	var files = get_scene_files(SCENE_ROOT_DIR)
	_game_scenes = parse_scene_files(files)
	find_portals(_game_scenes)
	for scene in _game_scenes.keys():
		_game_scenes[scene].nodes.clear()


func _get_scene_data(scene_name: String) -> SceneData:
	return _game_scenes.get(scene_name)


func _get_portal_scene_name(portal_id: String) -> String:
	assert(portal_id, "Cannot get scene for empty portal ID")
	var scene_name = _portals.get(portal_id)
	assert(scene_name, "Invalid portal ID [%s]" % portal_id)
	return scene_name


func set_active_scene(scene_name: String, player: Player):
	var viewport = _get_scene_data(scene_name).viewport_node
	if player.get_viewport() != viewport:
		player.reparent(viewport)
	_container.move_child(viewport, -1)
	load_scene(scene_name)


func load_scene(scene_name: String, depth: int = 2):
	var scene = _get_scene_data(scene_name)
	print(scene_name, " ", depth, " ", scene.connections)
	if depth < 0:
		scene.Unload()
		return
	
	scene.Load(_container)

	for portal_id in scene.portal_ids:
		var portal = GameManager.get_portal(portal_id)
		var other_portal_id = portal.other_portal_id
		print("%s | %s" % [portal_id, other_portal_id])
		if other_portal_id == null || len(other_portal_id) < 1:
			continue
		if _get_scene_data(_get_portal_scene_name(other_portal_id)).IsLoaded():
			GameManager.link_portals(portal, other_portal_id)
	
	reset_elevators.call_deferred(scene.viewport_node.get_child(0))

	for connection in scene.connections:
		load_scene(_get_portal_scene_name(connection), depth - 1)


func get_scene_files(directory: String) -> PackedStringArray:
	assert(DirAccess.dir_exists_absolute(directory), "Root scene directiory '%s' is missing" % directory)
	var root_dir = DirAccess.open(directory)
	var files: PackedStringArray = []
	for file in root_dir.get_files():
		if file.ends_with(".tscn"):
			files.append("%s/%s" % [directory, file])
	for child_dir in root_dir.get_directories():
		files.append_array(get_scene_files("%s/%s" % [directory, child_dir]))
	return files


func find_portals(scenes: Dictionary):
	var portal_connections: Dictionary = {}
	for scene_name in scenes:
		var scene = scenes[scene_name]
		var scene_nodes = scene.nodes
		var root_node = scene_nodes[0]
		var dynamic_connections_string: String = root_node.get("dynamic_connections", "")
		var dynamic_connections = dynamic_connections_string.substr(15, dynamic_connections_string.length() - 17).replace('"', '').split(', ')
		for connection in dynamic_connections:#.filter(func (val): return len(val) > 0):
			if len(connection) == 0:
				continue
			scene.connections.append(connection)
			portal_connections[connection] = scene_name

		for node: Dictionary in scene_nodes:
			var portal_id = node.get("portal_id")
			if !portal_id:
				continue
			assert(!_portals.has(portal_id), "Duplicate portal ID: %s [%s, %s]" % [portal_id, _portals.get(portal_id), scene_name])
			_portals[portal_id] = scene_name
			_game_scenes.get(scene_name).portal_ids.append(portal_id)
			var other_portal_id = node.get("other_portal_id")
			if other_portal_id:
				portal_connections[other_portal_id] = portal_id
	for connection in portal_connections:
		var portal_id = portal_connections.get(connection)
		var sence_name = _portals.get(portal_id, "scene")
		assert(_portals.has(connection), "'%s' [%s] has dead connection to '%s'" % [portal_id, sence_name, connection])


func parse_scene_files(filepaths: PackedStringArray) -> Dictionary:
	var scenes: Dictionary = {}
	for filepath in filepaths:
		var scene_name = file_path_to_name(filepath)
		var scene: SceneData = SceneData.new(filepath, parse_tscn_nodes_flat(filepath))
		scenes[scene_name] = scene
	return scenes


func get_text_file_contents(filepath) -> String: 
	if !FileAccess.file_exists(filepath):
		push_error("File '%s' does not exist" % filepath)
		return ""
	var f = FileAccess.open(filepath, FileAccess.READ)
	return f.get_as_text()


func parse_tscn_nodes_flat(filepath) -> Array[Dictionary]:
	var content = get_text_file_contents(filepath)
	return get_flat_nodes(content)


func parse_tscn_nodes_nested(filepath) -> Dictionary:
	var flat_nodes = parse_tscn_nodes_flat(filepath)
	return get_nested_nodes(flat_nodes)


func get_flat_nodes(content: String) -> Array[Dictionary]:
	var _prune_quotations = func (data: String) -> String:
		if data.begins_with('"') && data.ends_with('"'):
			return data.replace('"', '')
		return data

	var  _get_header_data = func (header_kvp: String) -> Dictionary:
		var kvp = header_kvp.split("=")
		return { kvp[0]: _prune_quotations.call(kvp[1]) }
	
	var  _get_override_data = func (override_kvp: String) -> Dictionary:
		var kvp = override_kvp.split(" = ")
		if len(kvp) != 2:
			return {}
		return { kvp[0]: _prune_quotations.call(kvp[1]) }

	var flat_nodes: Array[Dictionary] = []
	var current_node = null
	for line in content.split("\n"):
		line = line.strip_edges()

		if line.begins_with("[editable"):
			break
		elif line.begins_with("[node") && line.ends_with("]"):
			current_node = {}
			var header_data = line.substr(6, line.length()-7).split(" ")
			for kvp in header_data:
				current_node.merge(_get_header_data.call(kvp))
		elif current_node != null:
			if len(line) > 0:
				current_node.merge(_get_override_data.call(line))
			else:
				flat_nodes.append(current_node)
				current_node = null
	
	return flat_nodes


func get_nested_nodes(flat_nodes: Array[Dictionary]) -> Dictionary:
	var root = flat_nodes[0]
	flat_nodes.reverse()
	var current_parent = "." 
	var children = []
	for node in flat_nodes:
		var node_parent = node.get("parent")
		if node_parent == null:
			break
		elif node_parent == current_parent:
			children.append(node)
		elif len(children) > 0:
			node["children"] = children
			children = []
			current_parent = node_parent

	return root
