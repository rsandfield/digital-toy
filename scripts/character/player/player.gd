class_name Player
extends CharacterBody3D

@onready var _head: Node3D = $Head

var gravity: Vector3
@export var mass = 80
const MINIMUM_PUSHABLE_MASS_RATIO := 0.25
const PUSH_FORCE_MULTIPLIER := 5.0

@export var walk_speed := 1.5
@export var sprint_speed := 2.5
@export var ground_accel := 8.0
@export var ground_decel := 3.0
@export var ground_friction := 2.5

@export var jump_velocity := 6.0
@export var climb_speed := 7.0

const CROUCH_TRANSLATE := 0.7
var is_crouching = false

var wish_dir := Vector3.ZERO

var _last_frame_was_on_floor = -INF


func _init():
    GameManager.register_player(self)

func get_move_speed() -> float:
    if is_crouching:
        return walk_speed * CROUCH_TRANSLATE
    if Input.is_action_pressed("sprint"):
        return sprint_speed
    return walk_speed


func move(dir: Vector2):
    wish_dir = global_basis * Vector3(dir.x, 0, dir.y).rotated(Vector3.UP, _head.rotation.y)


func jump():
    if is_on_floor():
        velocity += jump_velocity * -gravity.normalized()


func crouch(down: bool = true):
    is_crouching = down
    if down:
        _head.position = Vector3(0, 0.75, 0)
    else:
        _head.position = Vector3(0, 1.75, 0)


func _slide_camera_smooth_back_to_origin(_delta: float):
    pass


func _push_away_rigid_bodies():
    for i in get_slide_collision_count():
        var c := get_slide_collision(i)
        var collided = c.get_collider()
        if collided is RigidBody3D:
            var push_dir = -c.get_normal()
            # How much velocity the object needs to increase to match player velocity in the push direction
            var velocity_diff_in_push_dir = velocity.dot(push_dir) - collided.linear_velocity.dot(push_dir)
            # No diff needed if moving away
            velocity_diff_in_push_dir = max(0.0, velocity_diff_in_push_dir)
            var mass_ratio = min(1.0, mass / collided.mass)
            if mass_ratio < MINIMUM_PUSHABLE_MASS_RATIO:
                continue
            push_dir.y = 0
            var push_force = mass_ratio * PUSH_FORCE_MULTIPLIER
            collided.apply_impulse(push_dir * velocity_diff_in_push_dir * push_force, c.get_position() - collided.global_position)


func _handle_ground_physics(delta: float):
    var curr_speed_in_wish_dir = velocity.dot(wish_dir)
    var move_speed = get_move_speed()
    var speed_cap_delta = move_speed - curr_speed_in_wish_dir
    if speed_cap_delta > 0:
        var accel_speed = ground_accel * delta * move_speed
        accel_speed = min(accel_speed, speed_cap_delta)
        velocity += accel_speed * wish_dir
    
    var control = max(velocity.length(), ground_decel)
    var drop = control * ground_friction * delta
    var new_speed = max(0.0, velocity.length() - drop)
    if velocity.length() > 0:
        new_speed /= velocity.length()
    velocity *= new_speed


func _get_gravity_orientation() -> Vector3:    
    var orientation_direction = Quaternion(global_basis.y, -gravity) * global_basis.get_rotation_quaternion()
    # orientation_direction *= Quaternion(global_basis.y, $Head.rotation.y)
    # $Head.rotation.y = 0
    var eulered = orientation_direction.normalized().get_euler()
    return eulered


func _apply_gravity(delta: float):
    gravity = PhysicsServer3D.body_get_direct_state(get_rid()).total_gravity
    var orientation = _get_gravity_orientation()
    rotation = rotation.move_toward(orientation, delta)
    
    if gravity != Vector3.ZERO:
        up_direction = -gravity.normalized()

    if !is_on_floor():
        velocity += gravity * delta


func _physics_process(delta):
    if is_on_floor():
        _last_frame_was_on_floor = Engine.get_physics_frames()
    
    _apply_gravity(delta)
    _handle_ground_physics(delta)
    _push_away_rigid_bodies()
    move_and_slide()
    _slide_camera_smooth_back_to_origin(delta)


func _on_portal_tracking_enter(portal: Portal) -> void:
    # collision_layer = 2
    # collision_mask = 2
    SceneManager.set_active_scene(portal.get_viewport().name, self)

# func _on_portal_tracking_leave(_portal: Portal) -> void:
    # collision_layer = 1
    # collision_mask = 1
