class_name Player
extends CharacterBody3D

@onready var _head: Node3D = $Head

var gravity: Vector3
const SPEED = 1.5
const JUMP_VELOCITY = 4.5

func _init():
    GameManager.register_player(self)

func _physics_process(delta):
    # Add the gravity.
    gravity = PhysicsServer3D.body_get_direct_state(get_rid()).total_gravity
    var orientation = _get_gravity_orientation()
    rotation = rotation.move_toward(orientation, delta)
    # rotation = orientation
    if gravity != Vector3.ZERO:
        up_direction = -gravity.normalized()

    if not is_on_floor():
        velocity += gravity * delta

func jump():
    if is_on_floor():
        velocity.y = JUMP_VELOCITY

func crouch(down: bool = true):
    if down:
        _head.position = Vector3(0, 0.75, 0)
    else:
        _head.position = Vector3(0, 1.75, 0)


func move(delta, input_dir):
    var movement_basis = global_basis.rotated(transform.basis.y, _head.rotation.y)
    var direction = movement_basis.x * input_dir.x + movement_basis.z * input_dir.y

    if is_on_floor():
        velocity = velocity.move_toward(-direction * SPEED, 1)
    else:
        velocity = lerp(velocity, -direction * SPEED, delta)
    move_and_slide()

func _get_gravity_orientation() -> Vector3:    
    var orientation_direction = Quaternion(global_basis.y, -gravity) * global_basis.get_rotation_quaternion()
    # orientation_direction *= Quaternion(global_basis.y, $Head.rotation.y)
    # $Head.rotation.y = 0
    var eulered = orientation_direction.normalized().get_euler()
    return eulered

func _on_portal_tracking_enter(portal: Portal) -> void:
    # collision_layer = 2
    collision_mask = 2
    SceneManager.set_active_scene(portal.get_viewport().name, self)

func _on_portal_tracking_leave(_portal: Portal) -> void:
    # collision_layer = 1
    collision_mask = 1
