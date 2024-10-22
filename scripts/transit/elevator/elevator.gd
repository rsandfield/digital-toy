class_name Elevator
extends GameScene

@export var id: String
@export var door_close_delay: int = 6

var current_floor: int = 0
var close_timer: float = 0
var opened: bool = false

@onready var _door: ElevatorDoor = $ElevatorDoor
@onready var _anim: AnimationPlayer = $AnimationPlayer


func _enter_tree():
    GameManager.register_elevator(self)


func _exit_tree():
    GameManager.deregister_elevator(self)


func _process(delta):
    if opened:
        close_timer += delta
        if close_timer >= door_close_delay:
            print("Closing")
            _close_doors()


func reset_elevator():
    _door.close()


func call_to_floor(value: int):
    if !_door.is_closed():
        print("Waiting for doors to close")
        _close_doors()
        await _door.closed

    if current_floor != value:
        print("Elevator %s currently on %d, moving to %d" % [id, current_floor, value])
        await animate_move(current_floor, value)
    else:
        print("%s already on %d" % [name, value])

    select_floor(value)
    print("%s opening doors" % id)
    _open_doors()


func _open_doors():
    opened = door_close_delay >= 0 # Negative disables close timer
    _door.open_both_sides()


func _close_doors():
    opened = false
    close_timer = 0
    _door.close_both_sides()


func animate_move(from: int, to: int):
    if !_anim || from == to:
        return

    var low = from
    var high = to
    var reverse = false
    if to < from:
        low = to
        high = from
        reverse = true

    if low < 0:
        low = 0
        if high == 0:
            high = 1

    var animations: Array[String]
    for i in range(abs(high - low)):
        var j = low + i
        animations.append("%d_%d" % [j, j+1])
    if reverse:
        animations.reverse()

    for animation in animations:
        assert(
            _anim.has_animation(animation),
            "Elevator %s is missing animation '%s'" % [name, animation]
        )
        if reverse:
            _anim.play_backwards(animation)
        else:
            _anim.play(animation)
        await _anim.animation_finished


func select_floor(value: int):
    current_floor = value
    var other_door = GameManager.get_portal(dynamic_connections[value]).get_parent()
    _door.set_other_door(other_door)
    _door._other_door.set_other_door(_door)
