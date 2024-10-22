class_name ElevatorDoor
extends Door3D


@export var portal_id : String
@export var elevator: String
@export var floor_index: int

var _other_door: ElevatorDoor
@onready var _portal: Portal = $Portal


func _enter_tree():
    _portal = $Portal
    _portal.portal_id = portal_id


func call_elevator():
    assert(elevator, "%s does not have elevator name set" % name)
    GameManager.call_elevator(elevator, floor_index)


func clear_other_door():
    _other_door = null
    _portal.set_other_portal(null)


func set_other_door(other: ElevatorDoor):
    if other == _other_door:
        return
    if has_other_door():
        _other_door.clear_other_door()
    _other_door = other
    var other_portal = null
    if has_other_door():
        other_portal = _other_door._portal
    _portal.set_other_portal(other_portal)


func has_other_door() -> bool:
    return _other_door != null


func open_both_sides():
    open()
    if _other_door:
        _other_door.open()


func close_both_sides():
    close()
    if _other_door:
        _other_door.close()
