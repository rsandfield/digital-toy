extends Node

var _portals = {}
var _elevators = {}
var _player: Player


func register_player(player: Player):
    assert(not _player, "Player already registered")
    _player = player


func register_portal(portal: Portal):
    var id = portal.portal_id
    assert(id != "", "Portal ID cannot be empty")
    print("Registering portal %s" % [id])
    assert(not _portals.has(id), "Portal ID [%s] already registered" % [id])
    _portals[id] = portal


func deregister_portal(portal: Portal):
    deregister_portal_id(portal.portal_id)


func deregister_portal_id(portal_id: String):
    print("Deregistering %s" % portal_id)
    var portal = _portals[portal_id]
    assert(portal, "%s already deregistered" % [portal_id])
    var other = portal.other_portal
    if other:
        other.set_other_portal(null)
    portal.set_other_portal(null)
    _portals.erase(portal_id)

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


func register_signal_listener(node: Node, signal_bus: String):
    print("Connecting %s to %s" % [node, signal_bus])
