class_name ElevatorDoor
extends Node3D

signal closed

@export var portal_id : String
@export var elevator: String
@export var floor_index: int

var _portal: Portal
@onready var _animation: AnimationPlayer = $AnimationPlayer
@onready var _audio: AudioStreamPlayer3D = $AudioStreamPlayer3D
var _door_state: DoorState = DoorState.CLOSED
var other_door: ElevatorDoor

enum DoorState {
    OPEN,
    CLOSED,
    OPENING,
    CLOSING,
}

func _enter_tree():
    _portal = $Portal
    _portal.portal_id = portal_id


func call_elevator():
    assert(elevator, "%s does not have elevator name set" % name)
    GameManager.call_elevator(elevator, floor_index)


func set_other_door(other: ElevatorDoor):
    if not _portal:
        _portal = $Portal
    other_door = other
    if other_door:
        _portal.set_other_portal(other_door._portal)
    else:
        _portal.set_other_portal(null)


func open():
    if _door_state == DoorState.CLOSED:
        _door_state = DoorState.OPENING
        _animation.play("open")
        _audio.play()
        await _animation.animation_finished
        _door_state = DoorState.OPEN
    if _door_state == DoorState.CLOSING:
        _door_state = DoorState.OPENING
        var pos = _animation.current_animation_position
        _animation.stop()
        _animation.play_backwards("close")
        _animation.seek(pos)
        await _animation.animation_finished
        _door_state = DoorState.OPEN


func close():
    match _door_state:
        DoorState.OPEN:
            _door_state = DoorState.CLOSING
            _animation.play("close")
            _audio.play()
            await _animation.animation_finished
            _door_state = DoorState.CLOSED
            closed.emit()
        DoorState.OPENING:
            _door_state = DoorState.CLOSING
            var pos = _animation.current_animation_position
            _animation.stop()
            _animation.play_backwards("open")
            _animation.seek(pos)
            await _animation.animation_finished
            _door_state = DoorState.CLOSED
        DoorState.CLOSING:
            return
        DoorState.CLOSED:
            closed.emit()
        _:
            print('%s given unknown state: %s' % [name, _door_state])
