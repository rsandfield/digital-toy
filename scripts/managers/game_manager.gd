extends Node

var _portals = {}
var _player: Player
var _scene_manager: SceneManager
var _game_root: GameRoot 

func _ready():
	_game_root = get_tree().root.get_child(-1) as GameRoot
	var container = _game_root.get_child(-1)
	_scene_manager = SceneManager.new(container)
	_scene_manager.load_scene(_game_root.starting_scene)
	set_active_viewport.call_deferred(_game_root.starting_scene)


func register_player(player: Player):
	assert(not _player, "Player already registered")
	_player = player


func register_portal(portal: Portal):
	var id = portal.portal_id
	assert(id != "", "Portal ID cannot be empty")
	assert(not _portals.has(id), "Portal ID [%s] already registered" % [id])
	_portals[id] = portal
	print("Registered portal %s" % [id])


func deregister_portal(portal: Portal):
	_portals[portal.portal_id] = null


func get_portal(id: String):
	assert(id != "", "Portal ID cannot be empty")
	var other_portal = _portals.get(id)
	assert(other_portal, "Portal ID [%s] not registered" % [id])
	return other_portal


func link_portals(portal: Portal, link_id: String):
	var other_portal = _portals.get(link_id)
	assert(other_portal, "Cannot link portals %s and %s, [%s] not registered" % [portal.portal_id,  link_id,  link_id])
	portal.set_other_portal(other_portal)
	other_portal.set_other_portal(portal)
	print("Linked %s to %s" % [portal.portal_id, portal.other_portal_id])


func set_active_viewport(viewport_name: String):
	_scene_manager.set_active_scene(viewport_name, _player)
	print("Switched view to %s" % [viewport_name])
