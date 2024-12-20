extends Node

@export var player_path: NodePath

var _snaplocks = {}
var _portals = {}
var _elevators = {}
var _player: Player
var _l := Logger.new("cyan")

func _ready():
    var controller = _player.get_child(1) as PlayerController
    for portal_id in _portals:
        var portal = _portals[portal_id] as Portal
        controller._raycast.add_exception(portal)


func register_player(player: Player):
    assert(not _player, "Player already registered")
    _l.print("Registered player %s" % player)
    _player = player


func get_player_camera() -> Camera3D:
    return _player.find_child("Camera3D")


func register_portal(portal: Portal):
    if Engine.is_editor_hint():
        return
    var id = portal.portal_id
    assert(id != "", "Portal ID cannot be empty")
    _l.print("Registering portal %s" % [id])
    assert(not _portals.has(id), "Portal [%s] already registered" % [id])
    _portals[id] = portal
    if !_player: return
    var controller = _player.get_child(1) as PlayerController
    if controller:
        controller.get_child(0).add_exception(portal)
        controller.get_child(0).add_exception(portal.get_node("PortalViewport/Camera3D/Area3D"))


func deregister_portal(portal: Portal):
    deregister_portal_id(portal.portal_id)


func deregister_portal_id(portal_id: String):
    if Engine.is_editor_hint():
        return
    _l.print("Deregistering %s" % portal_id)
    var portal = _portals.get(portal_id)
    assert(portal, "%s already deregistered" % [portal_id])
    var other = portal.exit_portal
    if is_instance_valid(other):
        other.set_exit_portal(null)
    (_player._head as PlayerController)._raycast.remove_exception(portal)
    _portals.erase(portal_id)


func get_portal(id: String) -> Portal:
    assert(id != "", "Portal ID cannot be empty")
    var exit_portal = _portals.get(id)
    assert(exit_portal, "Portal [%s] not registered" % [id])
    return exit_portal


func link_portals(portal: Portal, link_id: String):
    assert(portal, "Cannot link portals, first portal is undefined")
    var exit_portal = _portals.get(link_id)
    assert(
        exit_portal,
        "Cannot link portals %s and %s, [%s] not registered" %
        [portal.portal_id,  link_id,  link_id]
    )
    var portal_parent = portal.get_parent() as PairedDoor
    var other_parent = exit_portal.get_parent() as PairedDoor
    if portal_parent && other_parent:
        # Setting other door also links portals
        _l.print("Connecting paired doors %s and %s" % [portal_parent, other_parent])
        portal_parent.set_other_door(other_parent)
        other_parent.set_other_door(portal_parent)
    else:
        portal.set_exit_portal(exit_portal)
        exit_portal.set_exit_portal(portal)
    _l.print("Linked %s to %s" % [portal.portal_id, portal.exit_portal_id])


func register_signal_listener(node: Node, signal_bus: String):
    # TODO: Cross-signal signaling by refrerence
    _l.print("Connecting %s to %s" % [node, signal_bus])


func register_elevator(elevator: Elevator):
    assert(!_elevators.has(elevator.id), "Elevator [%s] already registered" % [elevator.id])
    _l.print("Registering elevator %s" % [elevator.id])
    _elevators[elevator.id] = elevator


func deregister_elevator(elevator: Elevator):
    assert(_elevators.has(elevator.id), "Elevator [%s] not registered" % [elevator.id])
    _l.print("Deregistering elevator %s" % [elevator.id])
    _elevators.erase(elevator.id)


func call_elevator(elevator_id: String, index: int):
    assert(_elevators.has(elevator_id), "Cannot call elevator [%s], not registered" % [elevator_id])
    _l.print("Calling %s to %d" % [elevator_id, index])
    var elevator = _elevators.get(elevator_id) as Elevator
    elevator.call_to_floor(index)


func register_snappable_lock(snaplock: SnappableLock):
    assert(len(snaplock.snap_group) > 0, "SnappableLock %s has no snap group" % snaplock)
    var group =_snaplocks.get_or_add(snaplock.snap_group, {})
    assert(!group.get(snaplock.get_instance_id()), "SnappableLock %s already registered" % snaplock)
    group[snaplock.get_instance_id()] = snaplock


func deregister_snappable_lock(snaplock: SnappableLock):
    assert(len(snaplock.snap_group) > 0, "SnappableLock %s has no snap group" % snaplock)
    var group =_snaplocks.get_or_add(snaplock.snap_group)
    assert(group.get(snaplock.get_instance_id()), "SnappableLock %s not registered" % snaplock)
    group.erase(snaplock.get_instance_id())
    if group.is_empty():
        _snaplocks.erase(snaplock.snap_group)


func activate_snappable_lock_indicators(snap_group: String):
    var group =_snaplocks.get(snap_group)
    if !group:
        push_error("Snap group %s not found" % snap_group)
        return
    for snap_id in group:
        group[snap_id].activate_indicator()


func deactivate_snappable_lock_indicators(snap_group: String):
    var group =_snaplocks.get(snap_group)
    if !group:
        push_error("Snap group %s not found" % snap_group)
        return
    for snap_id in group:
        group[snap_id].deactivate_indicator()
