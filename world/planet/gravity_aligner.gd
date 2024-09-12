@tool
class_name GravityAligner
extends RigidBody3D

var last_pos: Vector3

func _ready():
    collision_layer = 0
    var cs = CollisionShape3D.new()
    cs.shape = SphereShape3D.new()
    add_child(cs)

func _notification(what):
    match what:
        NOTIFICATION_PROCESS,NOTIFICATION_PHYSICS_PROCESS:
            return
        NOTIFICATION_TRANSLATION_CHANGED,NOTIFICATION_TRANSFORM_CHANGED:
            var parent_pos = get_parent().global_position
            if parent_pos == last_pos:
                return
            last_pos = parent_pos
            align_parent()
        _:
            pass

func _physics_process(_delta):
    return

func align_parent() -> void:
    var up = -PhysicsServer3D.body_get_direct_state(get_rid()).total_gravity
    var orientation_direction = Quaternion(global_basis.y, up) * global_basis.get_rotation_quaternion()
    get_parent().global_rotation = orientation_direction.normalized().get_euler()