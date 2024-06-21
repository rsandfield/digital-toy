class_name SclLander
extends Node2D

var running: bool = false
var engine_power = Vector2(18, 0.6)
var speed: Vector2
var gravity: float = 9.81

func _ready():
	pass # Replace with function body.

func _process(delta: float):
	if running:
		speed += Vector2(0, gravity * delta)
		position += speed * delta

func thrust(direction: Vector2, delta: float):
	speed += engine_power * direction * delta

func reset(pos: Vector2):
	running = false
	speed = Vector2.ZERO
	position = pos
