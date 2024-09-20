@tool
class_name Box3D
extends Node3D

@export var size: Vector3 = Vector3.ONE :
    get:
        return size
    set(value):
        size = value
        ($CollisionShape3D.shape as BoxShape3D).size = value
        ($MeshInstance3D.mesh as BoxMesh).size = value

@export var material: BaseMaterial3D :
    get:
        return material
    set(value):
        material = value
        ($MeshInstance3D as MeshInstance3D).material_override = value
