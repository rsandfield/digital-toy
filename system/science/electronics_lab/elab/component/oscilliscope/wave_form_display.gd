class_name WaveFormDisplay
extends Node2D

@onready var size: Vector2 = (get_parent() as SubViewport).size
@export var count = 100
@export var width = 5
@export var box_size:int = 50

var input: GameSignal
var points: PackedVector2Array
var time = 0.0

@export var zoom: float = 100
@export var gain: float = 0.5
@export var offset: float = 0.0


func _process(delta):
	time += delta

	points = []
	if input:
		_push_buffer()
		queue_redraw()
	

func _push_buffer():
	points = PackedVector2Array()
	for i in count:
		var x = ((i / float(count)) - 0.5)
		points.append(Vector2(x, input.get_value_at_time((x + offset) / zoom) * gain) * size)

func _draw():
	for i in 2 * size.y / box_size + 1:
		var step = i * box_size
		draw_line(Vector2(-size.x, -size.y + step), Vector2(size.x, -size.y + step), Color.GRAY, 7)
	for i in 2 * size.x / box_size + 1:
		var step = i * box_size
		draw_line(Vector2(-size.x + step, -size.y), Vector2(-size.x + step, size.y), Color.GRAY, 7)
	
	for i in len(points) - 1:
		draw_line(points[i], points[i + 1], Color.GREEN, width)
