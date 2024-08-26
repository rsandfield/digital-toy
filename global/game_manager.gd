extends Node

var _portals = {}
var _player: Player

func _ready():
	for id in _portals:
		var portal = _portals[id]
		print("Checking portal %s for link (%s)" % [portal.portal_id, portal.other_portal_id])
		if portal.other_portal_id != "":
			link_portals(portal, portal.other_portal_id)
	set_active_viewport(_player.get_viewport())


func register_player(player: Player):
	assert(not _player, "Player already registered")
	_player = player
	print("Registed player")


func register_portal(id: String, portal: Portal):
	assert(id != "", "Portal ID cannot be empty")
	assert(not _portals.has(id), "Portal ID [%s] already registered" % [id])
	_portals[id] = portal
	print("Registered portal %s" % [id])


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


func set_active_viewport(viewport: SubViewport):
	var curr_viewport = _player.get_viewport()
	if curr_viewport != viewport:
		curr_viewport.remove_child(_player)
		viewport.add_child(_player)
	viewport.get_parent().move_child(viewport, -1)
	print("Switched view to %s" % [viewport.name])
