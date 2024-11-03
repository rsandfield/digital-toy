class_name SnappableLock
extends Area3D


signal snapped(snapped_object: RigidBody3D)
signal unsnapped

enum SnapState {
    EMPTY,
    HOVERING,
    SNAPPED,
}

@export var snap_group: String

var _hovering_character: PlayerController
var _snap_state: SnapState
var _held_object: RigidBody3D
var _held_collision_layer: int
var _held_collision_mask: int
var _indicator: Node3D


func _enter_tree():
    GameManager.register_snappable_lock(self)


func _exit_tree():
    GameManager.deregister_snappable_lock(self)


func _ready():
    _indicator = get_node_or_null("Indicator")
    deactivate_indicator()
    var maybe = NodeHelper.find_duck_child(self, "get_snap_group")
    if maybe && maybe.get_snap_group() == snap_group:
        force_assign(maybe)


func reticle_shape_on_hover() -> HUD.ReticleState:
    if _held_object:
        return HUD.ReticleState.RING
    return HUD.ReticleState.PINPOINT


func _snap_held_object():
    print("Snapping %s" % _held_object)
    _snap_state = SnapState.SNAPPED
    _held_object.reparent(self)
    _held_object.freeze = true
    _held_object.position = Vector3.ZERO
    _held_object.rotation = Vector3.ZERO
    _held_collision_layer = _held_object.collision_layer
    _held_collision_mask = _held_object.collision_mask
    _held_object.collision_layer = 0
    _held_object.collision_mask = 0


func _release_held_object():
    print("Releaseing %s" % _held_object)
    _snap_state = SnapState.EMPTY
    _held_object.reparent(get_viewport())
    _held_object.freeze = false
    _held_object.collision_layer = _held_collision_layer
    _held_object.collision_mask = _held_collision_mask
    _held_object = null


func activate_indicator():
    if _indicator:
        _indicator.visible = true


func deactivate_indicator():
    if _indicator:
        _indicator.visible = false


func _on_hover_start_by_character(character: PlayerController):
    if _snap_state != SnapState.EMPTY:
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
        _snap_state = SnapState.HOVERING
        _snap_held_object()
        NodeHelper.connect_signal(
            character.dropped_held_object,
            self,
            "_on_character_dropped_held_object"
        )


func _on_hover_end_by_character(character: PlayerController):
    if character != _hovering_character:
        return

    _hovering_character = null
    NodeHelper.disconnect_signal(
        character.dropped_held_object,
        self,
        "_on_character_dropped_held_object"
    )

    if _snap_state == SnapState.HOVERING:
        _release_held_object()


func _on_interact_by_character(character: PlayerController):
    if _snap_state != SnapState.SNAPPED:
        return
    _hovering_character = character
    _snap_state = SnapState.HOVERING
    _held_object.on_grab_by_character(character)
    unsnapped.emit()
    _held_object.on_release()


func _on_character_dropped_held_object(_character: PlayerController):
    _snap_held_object()
    snapped.emit(_held_object)
    _held_object.on_snap(self)


func force_assign(object: Snappable):
    if _held_object || !object || object.get_snap_group() != snap_group:
        return
    _held_object = object
    _snap_held_object()
    snapped.emit(_held_object)
    _held_object.on_snap(self)

