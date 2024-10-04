class_name Door3D
extends Node3D

signal opened
signal closed

@onready var _animation: AnimationPlayer = $AnimationPlayer
@onready var _audio: AudioStreamPlayer3D = $AudioStreamPlayer3D
var _door_state: DoorState = DoorState.CLOSED


enum DoorState {
    OPEN,
    CLOSED,
    OPENING,
    CLOSING,
}


func is_open():
    return _door_state == DoorState.OPEN || _door_state == DoorState.OPENING


func is_closed():
    return _door_state == DoorState.CLOSED || _door_state == DoorState.CLOSING


func open():
    _open()


func _open():
    match  _door_state:
        DoorState.CLOSED:
            _door_state = DoorState.OPENING
            _animation.play("open")
            _audio.play()
            await _animation.animation_finished
            _door_state = DoorState.OPEN
        DoorState.CLOSING:
            _door_state = DoorState.OPENING
            var pos = _animation.current_animation_position
            _animation.stop()
            _animation.play_backwards("close")
            _animation.seek(pos)
            await _animation.animation_finished
            _door_state = DoorState.OPEN
        DoorState.OPENING:
            return
        DoorState.OPEN:
            opened.emit()
        _:
            print('%s given unknown state: %s' % [name, _door_state])


func close():
    _close()


func _close():
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
