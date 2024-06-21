class_name SclTerrain
extends Node2D

var random = RandomNumberGenerator.new()
var segment_length = 64

# Called when the node enters the scene tree for the first time.
func _ready():
	random.randomize()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func height_at(pos: float):
	return 384


func _build_segment(count: int, start_x: float, start_height: float, end_height: float, roughness: float):
	var points: Array[Vector2] = []
	
	for i in range(count):
		var y = (start_height - end_height) * (i / (count as float))
		points.append(Vector2((i * segment_length) + start_x, y + fmod(random.randf(), roughness)))
	
	return points

func build_terrain(screen_size: Vector2, ground_level: int, height: int):
	var count = (screen_size.x / segment_length + 1) as int
	var points: Array[Vector2] = []
	
	var peak_x = random.randi() % (count / 2) + count / 4
	
	points += _build_segment(peak_x, 0, ground_level, ground_level - height, 8)
	points += _build_segment(count - peak_x, peak_x * segment_length, ground_level - height, ground_level, 8)
	
	for i in range(count):
		points.append(Vector2(i * segment_length, ground_level - random.randi() % height))
	
	($Line2D as Line2D).points = points
	
	points.append(screen_size)
	points.append(Vector2(0, screen_size.y))
