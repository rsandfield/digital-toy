extends Node

@export var player_path: NodePath

var _portals = {}
var _elevators = {}
var _player: Player

func _ready():
    var controller = _player.get_child(1) as PlayerController
    for portal_id in _portals:
        var portal = _portals[portal_id] as Portal
        controller._raycast.add_exception(portal)


func register_player(player: Player):
    assert(not _player, "Player already registered")
    print("Registered player %s" % player)
    _player = player


func register_portal(portal: Portal):
    var id = portal.portal_id
    assert(id != "", "Portal ID cannot be empty")
    print("Registering portal %s" % [id])
    assert(not _portals.has(id), "Portal [%s] already registered" % [id])
    _portals[id] = portal
    if !_player: return
    var controller = _player.get_child(1) as PlayerController
    if controller:
        controller.get_child(0).add_exception(portal)


func deregister_portal(portal: Portal):
    deregister_portal_id(portal.portal_id)


func deregister_portal_id(portal_id: String):
    print("Deregistering %s" % portal_id)
    var portal = _portals[portal_id]
    assert(portal, "%s already deregistered" % [portal_id])
    var other = portal.other_portal
    if other && is_instance_valid(other):
        other.set_other_portal(null)
    portal.set_other_portal(null)
    (_player._head as PlayerController)._raycast.remove_exception(portal)
    _portals.erase(portal_id)

func get_portal(id: String):
    assert(id != "", "Portal ID cannot be empty")
    var other_portal = _portals.get(id)
    assert(other_portal, "Portal [%s] not registered" % [id])
    return other_portal


func link_portals(portal: Portal, link_id: String):
    assert(portal, "Cannot link portals, first portal is undefined")
    var other_portal = _portals.get(link_id)
    assert(other_portal, "Cannot link portals %s and %s, [%s] not registered" % [portal.portal_id,  link_id,  link_id])
    portal.set_other_portal(other_portal)
    other_portal.set_other_portal(portal)
    print("Linked %s to %s" % [portal.portal_id, portal.other_portal_id])


func register_signal_listener(node: Node, signal_bus: String):
    print("Connecting %s to %s" % [node, signal_bus])


func register_elevator(elevator: Elevator):
    assert(!_elevators.has(elevator.id), "Elevator [%s] already registered" % [elevator.id])
    print("Registering elevator %s" % [elevator.id])
    _elevators[elevator.id] = elevator


func deregister_elevator(elevator: Elevator):
    assert(_elevators.has(elevator.id), "Elevator [%s] not registered" % [elevator.id])
    print("Deregistering elevator %s" % [elevator.id])
    _elevators.erase(elevator.id)


func call_elevator(elevator_id: String, index: int):
    assert(_elevators.has(elevator_id), "Cannot call elevator [%s], not registered" % [elevator_id])
    print("Calling %s to %d" % [elevator_id, index])
    var elevator = _elevators.get(elevator_id) as Elevator
    elevator.call_to_floor(index)
