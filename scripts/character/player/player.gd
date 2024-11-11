class_name Player
extends CharacterBody3D


const MINIMUM_PUSHABLE_MASS_RATIO := 0.25
const PUSH_FORCE_MULTIPLIER := 5.0
const CROUCH_TRANSLATE := 0.7
const MAX_STEP_HEIGHT := 0.5

@export var mass = 80
@export var walk_speed := 1.5
@export var sprint_speed := 2.5
@export var ground_accel := 8.0
@export var ground_decel := 3.0
@export var ground_friction := 2.5

@export var jump_velocity := 6.0
@export var climb_speed := 1.0

var is_crouching = false

var wish_dir := Vector3.ZERO

var _gravity: Vector3
var _last_frame_was_on_floor = -INF
var _snapped_to_stairs_last_frame: bool
var _current_ladder: Ladder

@onready var _head: Node3D = $Head


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
        velocity += jump_velocity * -_gravity.normalized()


func crouch(down: bool = true):
    is_crouching = down
    if down:
        _head.position = Vector3(0, 0.75, 0)
    else:
        _head.position = Vector3(0, 1.75, 0)


func _push_away_rigid_bodies():
    for i in get_slide_collision_count():
        var c := get_slide_collision(i)
        var collided = c.get_collider()
        if collided is RigidBody3D:
            var push_dir = -c.get_normal()
            # How much velocity the object needs to increase to match player velocity in the
            # push direction
            var velocity_diff_in_push_dir = (
                velocity.dot(push_dir) - collided.linear_velocity.dot(push_dir)
            )
            # No diff needed if moving away
            velocity_diff_in_push_dir = max(0.0, velocity_diff_in_push_dir)
            var mass_ratio = min(1.0, mass / collided.mass)
            if mass_ratio < MINIMUM_PUSHABLE_MASS_RATIO:
                continue
            push_dir.y = 0
            var push_force = mass_ratio * PUSH_FORCE_MULTIPLIER
            collided.apply_impulse(
                push_dir * velocity_diff_in_push_dir * push_force,
                c.get_position() - collided.global_position
            )


func _snap_down_to_staris_check():
    $StairsBelowRayCast3D.force_raycast_update()
    var floor_below = (
        $StairsBelowRayCast3D.is_colliding() &&
        !is_surface_too_steep($StairsBelowRayCast3D.get_collision_normal())
    )
    var was_on_floor_last_frame = Engine.get_physics_frames() == _last_frame_was_on_floor
    if (
        !is_on_floor() && velocity.y <= 0 && floor_below &&
        (was_on_floor_last_frame || _snapped_to_stairs_last_frame)
    ):
        var body_test_result = KinematicCollision3D.new()
        if test_move(transform, Vector3(0, -MAX_STEP_HEIGHT, 0), body_test_result):
            position.y += body_test_result.get_travel().y
            apply_floor_snap()
            _snapped_to_stairs_last_frame = true
            return
    _snapped_to_stairs_last_frame = false


func _snap_up_stairs_check(delta) -> bool:
    if !(is_on_floor() || _snapped_to_stairs_last_frame):
        return false
    var expected_move_motion = velocity * (basis.x + basis.z)
    if expected_move_motion.length() == 0:
        return false
    expected_move_motion *= delta
    var step_vector = basis.y * MAX_STEP_HEIGHT * 2
    var step_pos_with_clearance = global_transform.translated(
        expected_move_motion + step_vector
    )
    var down_check_result = KinematicCollision3D.new()
    if (
        test_move(step_pos_with_clearance, -step_vector, down_check_result) &&
        down_check_result.get_collider().is_class("StaticBody3D")
    ):
        var maybe_position = step_pos_with_clearance.origin + down_check_result.get_travel()
        var step_height = ((maybe_position - global_position) * basis.y).length()
        var check_pos = ((down_check_result.get_position() - global_position) * basis.y).length()
        if (
            step_height > MAX_STEP_HEIGHT ||
            step_height < 0.01 ||
            check_pos > MAX_STEP_HEIGHT
        ):
            print("%s %s %s\n%s %s" %
            [down_check_result.get_collider().get_parent(), step_height, check_pos,
            expected_move_motion, _head.rotation])
            return false
        $StairsAheadRayCast3D.position = (
            to_local(down_check_result.get_position()) +
            Vector3(0, MAX_STEP_HEIGHT, 0) +
            expected_move_motion.normalized() * 0.1
        )
        $StairsAheadRayCast3D.force_raycast_update()
        if (
            $StairsAheadRayCast3D.is_colliding() &&
            !is_surface_too_steep($StairsAheadRayCast3D.get_collision_normal())
        ):
            global_position = maybe_position
            apply_floor_snap()
            _snapped_to_stairs_last_frame = true
            return true
    return false


func _handle_ladder_physics() -> bool:
    # Kepp track of if we are on a ladder
    var was_climbing_ladder := _current_ladder && _current_ladder.overlaps_body(self)
    if !was_climbing_ladder:
        _current_ladder = null
        for ladder in get_tree().get_nodes_in_group("ladders"):
            if ladder.overlaps_body(self):
                _current_ladder = ladder
                break
    if !_current_ladder:
        return false

    var ladder_affine := _current_ladder.global_transform.affine_inverse()
    var pos_rel_to_ladder := ladder_affine * self.global_position

    var forward_move := wish_dir.z
    var side_move := -wish_dir.x
    var ladder_forward_move = (
        ladder_affine.basis *
        _head.global_transform.basis *
        Vector3(0, 0, -forward_move)
    )
    var ladder_side_move = (
        ladder_affine.basis *
        _head.global_transform.basis *
        Vector3(side_move, 0, 0)
    )

    var ladder_strafe_vel: float = climb_speed * (ladder_side_move.x + ladder_forward_move.x)
    var up_wish := -_gravity.rotated(Vector3(1,0,0), deg_to_rad(-45)).dot(ladder_forward_move)
    var ladder_climb_vel: float = climb_speed * (up_wish - ladder_side_move.z)

    var should_dismount := false
    if !was_climbing_ladder:
        var mounting_from_top := _current_ladder.is_over_top(pos_rel_to_ladder.y)
        if mounting_from_top:
            if ladder_climb_vel > 0:
                # Reached Top
                should_dismount = true
        else:
            # Facing away
            if (ladder_affine.basis * wish_dir).z > 0:
                should_dismount = true
        if abs(pos_rel_to_ladder.z) > 1:
            # Too far away
            should_dismount = true

    if is_on_floor() && ladder_climb_vel <= 0:
        should_dismount = true

    if should_dismount:
        _current_ladder = null
        return false

    var ladder_gtrans := _current_ladder.global_transform
    velocity = Vector3(ladder_strafe_vel, ladder_climb_vel, 0)
    pos_rel_to_ladder.z = 0
    global_position = ladder_gtrans * pos_rel_to_ladder

    if wish_dir.length() > 0:
        print("%s" % [velocity])

    move_and_slide()
    return true



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


func is_surface_too_steep(normal: Vector3) -> bool:
    return normal.angle_to(Vector3.UP) > floor_max_angle


func _apply_gravity(delta: float):
    _gravity = PhysicsServer3D.body_get_direct_state(get_rid()).total_gravity

    if _gravity == Vector3.ZERO:
        return

    up_direction = -_gravity.normalized()

    var target_rotation = transform.looking_at(position - basis.z, up_direction).basis
    transform.basis = transform.basis.slerp(target_rotation, delta).orthonormalized()

    if !is_on_floor():
        velocity += _gravity * delta


func _physics_process(delta):
    if is_on_floor():
        _last_frame_was_on_floor = Engine.get_physics_frames()

    if !_handle_ladder_physics():
        _apply_gravity(delta)
        # if is_on_floor() || _snapped_to_stairs_last_frame: # TODO: _handle_air_physics
        _handle_ground_physics(delta)
        # if !_snap_up_stairs_check(delta):
        _push_away_rigid_bodies()
        move_and_slide()
        # if get_slide_collision_count() > 0:
            # print(get_slide_collision(0).get_collider())
            # _snap_down_to_staris_check()


func on_portal_tracking_enter(portal: Portal) -> void:
    # collision_layer = 2
    # collision_mask = 2
    SceneManager.set_active_scene(portal.get_viewport().name)

# func on_portal_tracking_leave(_portal: Portal) -> void:
    # collision_layer = 1
    # collision_mask = 1
