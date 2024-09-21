class_name LightBulb3D
extends Node3D

@export var unlit: StandardMaterial3D
@export var lit: StandardMaterial3D
@export var _on: bool = true

var _lights: Array[Light3D]
var _lit_meshes: Array[MeshInstance3D]

func _ready():
    for child in get_children():
        if child.is_class("Light3D"):
            _lights.append(child)
        if child.is_class("MeshInstance3D") && child.is_in_group("bulbs"):
            _lit_meshes.append(child)
    set_on(_on)


func toggle():
    set_on(!_on)


func set_on(on: bool):
    if on:
        turn_on()
    else:
        turn_off()


func turn_on():
    _on = true
    for light in _lights:
        light.show()
    _set_mesh_material(lit)


func turn_off():
    _on = false
    for light in _lights:
        light.hide()
    _set_mesh_material(unlit)

func _set_mesh_material(mat: StandardMaterial3D):
    if !mat:
        return
    for mesh in _lit_meshes:
        mesh.material_override = mat
