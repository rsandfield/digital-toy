class_name Elevator
extends Node3D

@export var floors: Array[String]
var current_floor: int = 0
@onready var _door: ElevatorDoor = $ElevatorDoor

func _ready():
	select_floor(0)
	_door.open()
	if _door.other_door:
		_door.other_door.open()

func call_to_floor(value: int):
	if current_floor == value:
		return
	
	_door.close()
	if _door.other_door:
		_door.other_door.close()
	await _door.closed
	print('closed')
	
	select_floor(value)

	_door.open()
	if _door.other_door:
		_door.other_door.open()

func select_floor(value: int):
	current_floor = value
	var other_portal = GameManager.get_portal(floors[value])
	_door.set_other_door(other_portal.get_parent())
	_door.other_door.set_other_door(_door)
