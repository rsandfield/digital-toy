class_name ElevatorDoor
extends PairedDoor


@export var elevator: String
@export var floor_index: int


func call_elevator():
    assert(elevator, "%s does not have elevator name set" % name)
    GameManager.call_elevator(elevator, floor_index)
