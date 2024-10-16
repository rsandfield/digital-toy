class_name Snappable
extends RigidBody3D


signal snapped_to(lock: SnappableLock)
signal released()

@export var snap_group: String


func get_snap_group() -> String:
    return snap_group


func on_grab_by_character(character: PlayerController):
    character.on_grab_object(self)


func on_snap(lock: SnappableLock):
    snapped_to.emit(lock)


func on_release():
    released.emit()