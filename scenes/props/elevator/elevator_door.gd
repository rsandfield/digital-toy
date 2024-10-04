class_name ElevatorDoor
extends Door3D


@export var portal_id : String
@export var elevator: String
@export var floor_index: int

var _portal: Portal
var _other_door: ElevatorDoor


func _enter_tree():
    _portal = $Portal
    _portal.portal_id = portal_id


func call_elevator():
    assert(elevator, "%s does not have elevator name set" % name)
    GameManager.call_elevator(elevator, floor_index)


func set_other_door(other: ElevatorDoor):
    if !_portal:
        _portal = $Portal
    _other_door = other
    var other_portal = null
    if has_other_door():
        other_portal = _other_door._portal
    _portal.set_other_portal(other_portal)


func has_other_door() -> bool:
    return _other_door != null


func open():
    _open()
    if _other_door:
        _other_door._open()


func close():
    _close()
    if _other_door:
        _other_door._close()
