@tool
class_name GravityArea3D
extends Area3D

func _notification(what):
    match what:
        NOTIFICATION_TRANSLATION_CHANGED,NOTIFICATION_TRANSFORM_CHANGED:
            reorient()
        _:
            pass

func reorient():
    gravity_direction = -global_basis.y
