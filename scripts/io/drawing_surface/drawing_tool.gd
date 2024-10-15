class_name DrawingTool
extends RigidBody3D


@export var draw_group: String


func on_use_by_character(character: PlayerController):
    var object = character._raycast.get_collider()
    if (
        !object ||
        !object.has_method("get_draw_group") ||
        object.get_draw_group() != draw_group
    ):
        return
    _on_draw(object, object.global_to_position(character._raycast.get_collision_point()))


func _on_draw(_surface: DrawingSurface, _touch_point: Vector2i):
    pass