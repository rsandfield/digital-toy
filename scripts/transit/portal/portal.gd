
@tool
class_name Portal
extends Area3D


const CAM_NEAR_NEEDED_TO_PREVENT_GLITCH = 0.001
const MESH_DUPLICATE_RETAIN_TIME_MS = 5000

# If a body moved further than this while passing through the portal, consider it a teleport.
# Disables portal movement in cases where the player teleports via some ability, but moved
# over the portal border in the process. Should only activate portal when walking through.
const MOVE_WAS_TELEPORT_THRESHOLD = 5.0

@export var portal_id: String
@export var exit_portal_id: String

## The visual layer the portal is rendered on. Set this to something other than
## the layer your level and models are on. This is used to hide the destination
## portal from the camera's view so we can see past it.
@export var cull_layer: int = 4

@export var make_mesh_duplicates := true
@export var portal_area_z_margin := 1.0
@export var portal_area_x_margin := 0.1
@export var portal_area_y_margin := 0.1
@export var size: Vector2:
    get:
        return _size
    set(value):
        _size = value
        _update_portal_area_size()
@export var use_body_camera_as_teleport_origin = true

## Was getting weird behavior with the near cull plane,
## only solution I found was to lower near cull plane on camera
@export var enable_camera_near_plane_fix: bool = true

var exit_portal: Node3D
var is_in_world: bool = true
var mesh: PortalMesh

# Mesh duplicate cache
# Helps performance and seems to make the transition from portal to portal slightly smoother
var mesh_duplicate_cache = [] #[body, mesh_duplicate, store_time]
var _tracked_phys_bodies = []
var _hosted_portal_meshs = []

var _size := Vector2(1,2)

var _l := Logger.new("purple")

func set_exit_portal(other: Portal):
    if exit_portal:
        # Purge current tracked bodies
        var i = len(_tracked_phys_bodies) - 1
        while i >= 0:
            exit_portal.remove_tracked_phys_body(_tracked_phys_bodies[i].body)
            i -= 1

    exit_portal = other
    if exit_portal:
        # Populate tracked bodies
        $ShapeCast3D.force_shapecast_update()
        for i in $ShapeCast3D.get_collision_count():
            _on_body_entered($ShapeCast3D.get_collider(i))
        mesh.reassign_camera_portal(exit_portal)
    else:
        mesh.reassign_camera_portal(self)


func _enter_tree():
    if Engine.is_editor_hint():
        return

    GameManager.register_portal(self)


func _notification(what):
    if Engine.is_editor_hint():
        return
    match what:
        NOTIFICATION_EXIT_WORLD:
            is_in_world = false


func _ready():
    if Engine.is_editor_hint():
        return
    mesh = $PortalVisual
    mesh.assign_viewport($PortalViewport)
    $PortalViewport.name = portal_id
    mesh.replace_layer_mask(cull_layer)
    _update_portal_area_size()


func _update_portal_area_size():
    if !mesh:
        return

    mesh.resize(size)
    var portal_size = Vector3(
        self.size.x + self.portal_area_x_margin * 2,
        self.size.y + self.portal_area_y_margin * 2,
        self.portal_area_z_margin * 2)
    $CollisionShape3D.shape.size = portal_size
    $ShapeCast3D.shape.size = portal_size

    var portal_pos = Vector3(0, self.size.y * 0.5, 0)
    $CollisionShape3D.position = portal_pos
    $ShapeCast3D.position = portal_pos

func do_updates():
    if Engine.is_editor_hint():
        return

    $CollisionShape3D.disabled = not self.visible

    for body in _get_bodies_which_passed_through_this_frame():
        if body.is_multiplayer_authority():
            _move_to_exit_portal(body)
    for tracked_body in _tracked_phys_bodies:
        if (not tracked_body.body.is_multiplayer_authority()
            and _try_detect_portal_pass_through_on_multiplayer_peer(tracked_body)):
            # Added to prevent visual glitching for multiplayer peers.
            # Try to detect when peer has swapped places with their mesh duplicate and then
            # move it to the appropriate position.
            remove_tracked_phys_body(tracked_body.body)
            exit_portal.add_tracked_phys_body(tracked_body.body)

    # Note: placing these after above so portal thickening/camera update happen same frame as move
    _clear_mesh_duplicate_cache()
    if !mesh._viewport:
        mesh.assign_viewport(PortalViewport.new())
    mesh._viewport.update_camera(GameManager.get_player_camera())
    mesh.thicken_if_necessary(basis, GameManager.get_player_camera())
    _remove_hanging_body_check()


# For some reason need to call both of these to prevent flicker
func _process(_delta):
    do_updates()


func _physics_process(_delta):
    do_updates()


func _try_detect_portal_pass_through_on_multiplayer_peer(tracked_body):
    if not tracked_body.mesh_duplicator:
        return false
    const DISTANCE_THRESHOLD_FROM_DUPLICATE = 2.5
    var dist_from_dupe = (
        tracked_body.body.global_position -
        tracked_body.mesh_duplicator.dupe.global_position
    ).length()
    #if dist_from_dupe < DISTANCE_THRESHOLD_FROM_DUPLICATE:
    #    _l.print("DETECTED OTHER PEER TELEPORT, dist was "+str(dist_from_dupe))
    return dist_from_dupe < DISTANCE_THRESHOLD_FROM_DUPLICATE


func _remove_hanging_body_check():
    # Code to prevent edge case, mostly for multiplayer
    # It's possible you can skip the Area3D on the other side of portal if
    # moving too fast/teleporting. Since we need to hand object off to other
    # portal same frame we remove it from this on port, do this check to prevent
    # handing off an object that is outside of the area3d, leaving it lingering
    var i = len(_tracked_phys_bodies) - 1
    while i >= 0:
        var tracked_body = _tracked_phys_bodies[i].body
        var track_duration = Time.get_ticks_msec() - _tracked_phys_bodies[i].track_start_time
        if track_duration > 250.0 and not overlaps_body(tracked_body):
            remove_tracked_phys_body(tracked_body)
            _l.print("%s removed tracked body [%s] for edge case" % [portal_id, tracked_body])
        i -= 1


func _move_to_exit_portal(body: PhysicsBody3D):
    if not exit_portal:
        return

    _l.print("%s moving %s to %s" % [portal_id, body, exit_portal_id])

    # var transform_rel_to_this_portal = (
    #     self.global_transform.affine_inverse() * body.global_transform
    # )
    # var moved_to_exit_portal = exit_portal.global_transform * transform_rel_to_this_portal
    body.global_transform = global_transform_relative_to_exit(body)

    var r = exit_portal.global_transform.basis.get_euler() - global_transform.basis.get_euler()
    if body.get("velocity"):
        body.velocity = body.velocity \
            .rotated(Vector3(1, 0, 0), r.x) \
            .rotated(Vector3(0, 1, 0), r.y) \
            .rotated(Vector3(0, 0, 1), r.z)
    elif body.get("linear_velocity"):
        body.linear_velocity = body.linear_velocity \
            .rotated(Vector3(1, 0, 0), r.x) \
            .rotated(Vector3(0, 1, 0), r.y) \
            .rotated(Vector3(0, 0, 1), r.z)

    remove_tracked_phys_body(body)
    var newly_tracked_body = exit_portal.add_tracked_phys_body(body)
    # We just moved the body. If it was a player, the camera may have been moved.
    # So we must do updates on the other portal. The camera and thickening will need to be updated.
    # No guarantee other portal has done updates for this frame already or not.
    if newly_tracked_body.camera:
        exit_portal.do_updates()


func _get_bodies_which_passed_through_this_frame():
    var bodies_that_passed_through = []
    for tracked_body in _tracked_phys_bodies:
        var pos_node = tracked_body.camera if tracked_body.camera else tracked_body.body
        var dist_moved = pos_node.global_position - tracked_body.position_last_frame
        # Use dot product to check if side of portal we're on changed
        var forward: Vector3 = self.global_transform.basis.z
        var offset_from_portal = pos_node.global_position - self.global_position
        var prev_offset_from_portal = tracked_body.position_last_frame - self.global_position
        var portal_side = MathHelper.nonzero_sign(offset_from_portal.dot(forward))
        var prev_portal_side = MathHelper.nonzero_sign(prev_offset_from_portal.dot(forward))
        if portal_side != prev_portal_side and dist_moved.length() < MOVE_WAS_TELEPORT_THRESHOLD:
            bodies_that_passed_through.push_back(tracked_body.body)
        # Once we're done set position_last_frame again
        tracked_body.position_last_frame = pos_node.global_position
    return bodies_that_passed_through


func _clear_mesh_duplicate_cache():
    var mesh_duplicate_cache_to_remove = []
    for i in range(len(mesh_duplicate_cache)):
        var reverse_idx = mesh_duplicate_cache.size() - 1 - i
        var item = mesh_duplicate_cache[reverse_idx]
        if Time.get_ticks_msec() - item[2] > MESH_DUPLICATE_RETAIN_TIME_MS:
            mesh_duplicate_cache_to_remove.push_back(item)
            mesh_duplicate_cache.remove_at(reverse_idx)
    for item in mesh_duplicate_cache_to_remove:
        if is_instance_valid(item[1]):
            item[1].queue_free()


func _store_mesh_duplicate_in_cache(body, mesh_duplicate):
    mesh_duplicate_cache.push_back([body, mesh_duplicate, Time.get_ticks_msec()])


func get_mesh_duplicate_from_cache(body, ask_exit_portal = false):
    if ask_exit_portal and exit_portal:
        var other_result = exit_portal.get_mesh_duplicate_from_cache(body)
        if other_result != null:
            return other_result
    for i in range(len(mesh_duplicate_cache)):
        var item = mesh_duplicate_cache[i]
        if item[0] == body:
            mesh_duplicate_cache.remove_at(i)
            return item[1]
    return null


func _make_or_get_mesh_duplicate(body):
    var cache_result = get_mesh_duplicate_from_cache(body, true)
    if cache_result:
        cache_result.in_portal = self
        cache_result.out_portal = exit_portal
        return cache_result
    var new_mesh_duplicator = PortalMeshDuplicator.new()
    new_mesh_duplicator.body = body
    new_mesh_duplicator.in_portal = self
    new_mesh_duplicator.out_portal = exit_portal
    return new_mesh_duplicator


func _get_tracked_phys_body_entry(body):
    for entry in _tracked_phys_bodies:
        if entry.body == body:
            return entry
    return null


func add_tracked_phys_body(body):
    # First check if we already have the body or not in our list
    var tracked_body_entry = _get_tracked_phys_body_entry(body)
    if tracked_body_entry != null:
        return tracked_body_entry
    # If not, add it
    var newly_tracked_body = {
        "body": body,
        "position_last_frame": body.global_position,
        "camera": find_by_class(body, "Camera3D") if use_body_camera_as_teleport_origin else null,
        "mesh_duplicator": null,
        "track_start_time": Time.get_ticks_msec()
    }
    if make_mesh_duplicates:
        newly_tracked_body.mesh_duplicator = _make_or_get_mesh_duplicate(body)
        exit_portal.add_child(newly_tracked_body.mesh_duplicator)
        newly_tracked_body.mesh_duplicator.synchronize_all()
    if newly_tracked_body.camera:
        newly_tracked_body.position_last_frame = newly_tracked_body.camera.global_position
        newly_tracked_body.prev_camera_near = newly_tracked_body.camera.near
        if enable_camera_near_plane_fix:
            newly_tracked_body.camera.near = CAM_NEAR_NEEDED_TO_PREVENT_GLITCH
    _tracked_phys_bodies.push_back(newly_tracked_body)

    if body.has_method("on_portal_tracking_enter"):
        body.on_portal_tracking_enter(self)
    if body.get_viewport() != get_viewport():
        body.reparent(get_viewport())
    _l.print("%s entered by %s" % [portal_id, body])
    return newly_tracked_body


func remove_tracked_phys_body(body):
    for i in len(_tracked_phys_bodies):
        if _tracked_phys_bodies[i].body == body:
            _l.print("%s removed body %s" % [portal_id, body])

            if _tracked_phys_bodies[i].mesh_duplicator:
                if is_instance_valid(_tracked_phys_bodies[i].mesh_duplicator):
                    exit_portal.remove_child(_tracked_phys_bodies[i].mesh_duplicator)
                    _store_mesh_duplicate_in_cache(
                        _tracked_phys_bodies[i].body,
                        _tracked_phys_bodies[i].mesh_duplicator
                    )
            if _tracked_phys_bodies[i].camera:
                _tracked_phys_bodies[i].camera.near = _tracked_phys_bodies[i].prev_camera_near
            _tracked_phys_bodies.remove_at(i)

            if body.has_method("on_portal_tracking_leave"):
                body.on_portal_tracking_leave(self)
            return


func find_by_class(node: Node, name_of_class: String):
    if node.is_class(name_of_class) :
        return node
    for child in node.get_children():
        var found = find_by_class(child, name_of_class)
        if found:
            return found
    return null


# This shapecast is necessary because _on_body_entered and _on_body_exited may be fired late in some
# edge cases Which could cause the conundrum of _on_body_entered being called late, after body has
# left, or _on_body_exited being called late, like firing the same frame it was added. Causing
# incorrectly adding or removing a body. Something like that is going on. This fixes the bug of
# teleporting up to the roof when you rotate the exit velocity by PI on the y axis and it
# rubberbands very quickly between the 2 portals. May happen rarely even without the incorrect y
# rotation set
func _check_shapecast_collision(body):
    if !(is_in_world && is_inside_tree()):
        return false
    $ShapeCast3D.force_shapecast_update()
    for i in $ShapeCast3D.get_collision_count():
        if $ShapeCast3D.get_collider(i) == body:
            return true
    return false


func _on_body_entered(body):
    # Disable non-moving static bodes from teleporting (except AnimatableBody3Ds
    # which are considered static). CSGShape3Ds are also static if you enable
    # their use_collision property so disable them.
    if (
        (!body.is_class("StaticBody3D") || body.is_class("AnimatableBody3D")) &&
        !body.is_class("CSGShape3D")
    ):
        if exit_portal and _check_shapecast_collision(body):
            add_tracked_phys_body(body)


func _on_body_exited(body):
    if not _check_shapecast_collision(body) or $CollisionShape3D.disabled:
        remove_tracked_phys_body(body)


func global_transform_relative_to_exit(n: Node3D) -> Transform3D:
    if !exit_portal:
        return n.global_transform
    var transform_rel_to_this_portal = global_transform.affine_inverse() * n.global_transform
    return exit_portal.global_transform * transform_rel_to_this_portal


func add_nested_portal_mesh(nested_mesh: PortalMesh):
    _hosted_portal_meshs.append(nested_mesh)


func get_used_visual_layers() -> Array[int]:
    var used: Array[int] = [mesh.visible_layer]
    for nested in _hosted_portal_meshs:
        if is_instance_valid(nested):
            used.append(nested.visible_layer)
        else:
            _hosted_portal_meshs.erase(nested)
    return used


func _to_string():
    return "Portal[%s]" % [portal_id]
