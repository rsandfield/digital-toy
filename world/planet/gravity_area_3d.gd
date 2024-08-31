@tool
class_name GravityArea3D
extends Area3D

func _notification(what):
    match what:
        NOTIFICATION_TRANSLATION_CHANGED,NOTIFICATION_TRANSFORM_CHANGED:
            gravity_direction = -global_basis.y
        _:
            pass
