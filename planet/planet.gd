@tool
class_name Planet
extends Node3D

@onready var sphere_mesh: SphereMesh = $MeshInstance3D.mesh
@onready var sphere_shape: SphereShape3D = $StaticBody3D/CollisionShape3D.shape
@onready var gravity_area: Area3D = $Gravity
@onready var gravity_shape: SphereShape3D = $Gravity/CollisionShape3D.shape

@export var radius: float = 100 : 
	get:
		return radius
	set(value):
		radius = value
		sphere_shape.radius = value
		sphere_mesh.radius = value
		sphere_mesh.height = 2 * value
		gravity_area.gravity_point_unit_distance = value
@export var surface_gravity: float = 9.81: 
	get:
		return gravity_area.gravity
	set(value):
		if(gravity_area):
			gravity_area.gravity = value
@export var influence_radius: float = 200 : 
	get:
		return gravity_shape.radius
	set(value):
		if gravity_shape:
			gravity_shape.radius = value
