class_name PlayerController
extends Node3D

@export var mouse_sensitivity: float = 0.1
@export var default_max_interaction_distance: float = 2.5

@onready var _player: Player = get_parent() as Player
@onready var _hud: HUD = $HUD as HUD
@onready var _hold_position: Node3D = $HoldPosition as Node3D
@onready var _raycast: RayCast3D = $RayCast as RayCast3D

var _held_object: RigidBody3D


enum ControlState {
    FreeMove,
    Paused
}

var previus_state := ControlState.FreeMove
var current_state := ControlState.FreeMove


func _change_control_state(new_state: ControlState):
    # Prevent overwriting previous state with multiple pauses
    if current_state != ControlState.Paused:
        previus_state = current_state
    current_state = new_state
    match new_state:
        ControlState.FreeMove:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
            _hud.visible = true
        ControlState.Paused:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
            _hud.visible = false


func _is_paused() -> bool:
    return current_state == ControlState.Paused


func _unpause():
    if _is_paused():
        _change_control_state(previus_state)


func _can_free_look() -> bool:
    return current_state == ControlState.FreeMove


func _can_interact() -> bool:
    return current_state == ControlState.FreeMove


func _ready():
    _change_control_state(ControlState.FreeMove)


func _process(delta):
    if _held_object:
        _move_held_object(delta)
    else:
        _set_reticle()


func _physics_process(_delta):
    if Input.is_action_just_pressed("ui_accept"):
        _player.jump()

    if Input.is_action_just_pressed("crouch"):
        _player.crouch()

    if Input.is_action_just_released("crouch"):
        _player.crouch(false)

    # Get the input direction and handle the movement/deceleration.
    # As good practice, you should replace UI actions with custom gameplay actions.
    var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
    _player.move(-input_dir)


func _handle_pause(event: InputEvent):
    if _is_paused() &&  event is InputEventMouseButton:
        _unpause()
    elif event.is_action_pressed("ui_cancel"):
        _change_control_state(ControlState.Paused)


func _handle_camera_input(event):    
    if event is InputEventMouseMotion and _can_free_look():
        rotation_degrees.y -= event.relative.x * mouse_sensitivity
        rotation_degrees.x += event.relative.y * mouse_sensitivity
        rotation.y = fposmod(rotation.y, TAU)
        rotation.x = clamp(rotation.x, -PI / 2, PI / 2)


func get_interactiable_at_raycast() -> InteractableComponent:
    var object = _raycast.get_collider()
    return object.get_node_or_null("InteractableComponent")


func _on_grab_object(object: RigidBody3D):
    if !object:
        return
    assert(_held_object == null, "Player cannot pick up %s because they are already holding %s" % [object, _held_object])
    _held_object = object
    _player.add_collision_exception_with(object)
    _hud.visible = false


func _drop_held_object():
    if _held_object.has_method("_on_drop_by_character"):
        _held_object._on_drop_by_character()
    _player.remove_collision_exception_with(_held_object)
    _held_object = null
    _hud.visible = true


func _handle_interaction():
    if !_can_interact():
        return
    
    if Input.is_action_just_pressed("left_click"):
        if _held_object:
            _drop_held_object()
        else:
            var interactable = get_interactiable_at_raycast()
            if interactable:
                interactable.interact_with(self)
    
    if Input.is_action_just_pressed("right_click"):
        if _held_object && _held_object.has_method("_on_use_by_character"):
            _held_object._on_use_by_character(self)


func _unhandled_input(event):
    _handle_pause(event)
    if _is_paused():
        return
    
    _handle_camera_input(event)
    _handle_interaction()


func _move_held_object(delta):
    _held_object.global_position = _held_object.global_position.move_toward(_hold_position.global_position, delta * 10)
    _held_object.global_rotation = _held_object.global_rotation.move_toward(_hold_position.global_rotation, delta * 10)


func _is_in_interaction_range(object: Node3D) -> bool:
    if !("interactable_distance" in object):
        return false
    var max_distance = object.interactable_distance
    if max_distance == 0:
        return false
    if object.interactable_distance < 0:
        max_distance = default_max_interaction_distance
    return global_position.distance_to(object.global_position) < max_distance


func _set_reticle():    
    var object = _raycast.get_collider()
    if object && object.has_method("_reticle_shape_on_hover"):
        _hud.set_state(object._reticle_shape_on_hover())
    else:
        _hud.set_state(HUD.ReticleState.PINPOINT)
