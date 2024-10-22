class_name WorldSelectPanel
extends Node3D


signal world_selected(index: int)
signal doinking_started
signal doinking_ended

enum State {
    PASSIVE,
    DOINKING,
    SELECTED,
}

@export var doink_delay := 0.25

var _state: State
var _timer: float
var _doinkers: Array[Doinker]
var _doinking: int

@onready var _animation: AnimationPlayer = $AnimationPlayer


func _ready():
    for child in get_node("StaticBody3D").get_children():
        if child.has_method("doink"):
            NodeHelper.connect_signal(child.pressed, self, "on_doinker_pressed", len(_doinkers))
            _doinkers.append(child)


func _process(delta):
    if _state != State.DOINKING:
        return
    _timer += delta
    if _timer >= doink_delay:
        _timer = 0
        _doink(_doinking + 1)


func _doink(index: int):
    _doinkers[_doinking].undoink()
    _doinking = index % len(_doinkers)
    _doinkers[_doinking].doink()


func begin_doinking():
    doinking_started.emit()
    _animation.play("flip_select")
    await _animation.animation_finished
    _state = State.DOINKING
    _timer = 0
    _doink(0)


func end_doinking():
    _state = State.PASSIVE
    _doinkers[_doinking].undoink()
    doinking_ended.emit()
    await get_tree().create_timer(doink_delay).timeout
    _animation.play("flip_back")


func on_doinker_pressed(index: int):
    world_selected.emit(index)
    _state = State.SELECTED
    _doinkers[_doinking].undoink()
    await get_tree().create_timer(doink_delay).timeout
    _doink(index)
    _doinkers[index].select()
    await get_tree().create_timer(2).timeout
    end_doinking()