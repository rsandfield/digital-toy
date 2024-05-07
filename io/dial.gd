class_name Dial3D
extends Node3D

signal value_changed(value: float)

@export var minAngle = 0.0
@export var maxAngle = 360.0
@export var angle = 0.0

@export var minValue = 0.0
@export var maxValue = 10.0
@export var increment = 1.0

@export var snap = true

var selected = false
var prev_mouse_position
var next_mouse_position

func _process(delta):
    if selected:
        next_mouse_position = get_viewport().get_mouse_position()


func on_value_changed():
    var relativeAngle = (angle - minAngle) / (maxAngle - minAngle)
    var looseValue = lerp(minValue, maxValue, relativeAngle)
    var value = roundf(looseValue / increment) * increment
    value_changed.emit(value)