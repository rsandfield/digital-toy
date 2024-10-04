class_name OsmobileExterior
extends Node3D

@export var portal_id: String
@export var world_index: int
var _door: ElevatorDoor

func _enter_tree():
    _door = find_child("ElevatorDoor") as ElevatorDoor
    _door.portal_id = portal_id
    _door.floor_index = world_index

func activate():
    _door.call_elevator()