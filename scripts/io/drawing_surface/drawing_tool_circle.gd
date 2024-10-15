class_name DrawingToolCircle
extends DrawingTool


@export var size := 10
@export var color := Color.WHITE


func _on_draw(surface: DrawingSurface, touch_point: Vector2i):
    surface.draw_circle(touch_point, size, color)