class_name DrawingToolRectangle
extends DrawingTool


@export var size := Vector2i(40, 80)
@export var color := Color.BLACK


func _on_draw(surface: DrawingSurface, touch_point: Vector2i):
    surface.draw_rectangle(touch_point, size, color)