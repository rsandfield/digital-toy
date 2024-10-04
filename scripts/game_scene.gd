class_name GameScene
extends Node3D

@export var dynamic_connections: PackedStringArray = []

var _osmobile: OsmobileExterior

func _enter_tree():
    _osmobile = find_child("Osmobile") as OsmobileExterior


func on_enter():
    pass
    # if _osmobile:
    #     _osmobile.activate()