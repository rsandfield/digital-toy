class_name SnappableLock
extends Area3D


signal snapped(snapped_object: RigidBody3D)
signal unsnapped


@export var snap_group: String

enum SnapState {
    Empty,
    Hovering,
    Snapped,
}

var _hovering_character: PlayerController
var _snap_state: SnapState
var _held_object: RigidBody3D

func _ready():
    # TODO: Register draggable groups with game manager to enable indicator glow
    pass


func reticle_shape_on_hover() -> HUD.ReticleState:
    if _held_object:
        return HUD.ReticleState.RING
    else:
        return HUD.ReticleState.PINPOINT


func _snap_held_object():
    _snap_state = SnapState.Snapped
    _held_object.reparent(self)
    _held_object.freeze = true
    _held_object.position = Vector3.ZERO
    _held_object.rotation = Vector3.ZERO


func _release_held_object():
    _snap_state = SnapState.Empty
    _held_object.reparent(get_viewport())
    _held_object.freeze = false
    _held_object = null


func _on_hover_start_by_character(character: PlayerController):
    if _snap_state != SnapState.Empty:
        print(_snap_state)
        return
    
    var object = character._held_object
    if (
        object &&
        object.has_method("get_snap_group") &&
        object.get_snap_group() == snap_group
    ):
        # character._held_object_positioning_override = true
        _hovering_character = character
        _held_object = character._held_object
        _snap_state = SnapState.Hovering
        _snap_held_object()
        NodeHelper.connect_signal(character.dropped_held_object, self, "_on_character_dropped_held_object")


func _on_hover_end_by_character(character: PlayerController):
    if character != _hovering_character:
        return
    
    _hovering_character = null
    NodeHelper.disconnect_signal(character.dropped_held_object, self, "_on_character_dropped_held_object")
    
    if _snap_state == SnapState.Hovering:
        _release_held_object()


func _on_interact_by_character(character: PlayerController):
    if _snap_state != SnapState.Snapped:
        return
    _hovering_character = character
    _snap_state = SnapState.Hovering
    character._on_grab_object(_held_object)
    unsnapped.emit()


func _on_character_dropped_held_object(_character: PlayerController):
    _snap_held_object()
    snapped.emit(_held_object)
