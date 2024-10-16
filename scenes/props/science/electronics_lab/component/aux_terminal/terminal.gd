class_name AuxTerminal
extends SnappableLock

var component: Component
var index: int

var _cable: AuxCable


func register_component(c: Component, i: int):
    component = c
    index = i


func _on_interact_by_character(character: PlayerController):
    if _snap_state != SnapState.SNAPPED:
        return
    super(character)
    _cable = null


func _on_character_dropped_held_object(character: PlayerController):
    super(character)
    _cable = _held_object.cable


func component_name():
    if component:
        return component.name
    return "null"
