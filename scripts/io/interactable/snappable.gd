class_name Snappable
extends RigidBody3D

@export var snap_group: String

func get_snap_group() -> String:
    return snap_group

func on_grab_by_character(character: PlayerController):
    character.on_grab_object(self)