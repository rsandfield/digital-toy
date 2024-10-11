class_name PlayerController
extends Node3D

@export var mouse_sensitivity: float = 0.1
@export var default_max_interaction_distance: float = 2.5

@onready var _player: Player = get_parent() as Player
@onready var _hud: HUD = $HUD as HUD
@onready var _hold_position: Node3D = $HoldPosition as Node3D
@onready var _raycast: RayCast3D = $RayCast as RayCast3D

var pull_power := 8.0
var _held_object: RigidBody3D
var _held_object_positioning_override: bool

signal dropped_held_object(character: PlayerController)

enum ControlState {
    FreeMove,
    OnRails,
    Focused,
    Paused
}

class ControlStateConfig:
    var can_free_look: bool
    var can_move: bool
    var can_interact: bool

    func _init(free_look := true, move := true, interact := true):
        can_free_look = free_look
        can_move = move
        can_interact = interact


var control_state_configs := {
    ControlState.FreeMove: ControlStateConfig.new(),
    ControlState.OnRails: ControlStateConfig.new(true, false),
    ControlState.Focused: ControlStateConfig.new(false, false),
    ControlState.Paused: ControlStateConfig.new(false, false, false),
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
    return control_state_configs.get(current_state).can_free_look


func _can_move() -> bool:
    return control_state_configs.get(current_state).can_move


func _can_interact() -> bool:
    return control_state_configs.get(current_state).can_interact


func _ready():
    _change_control_state(ControlState.FreeMove)


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


func _is_in_interaction_range(interactable: InteractableComponent) -> bool:
    if !interactable:
        return false
    
    var max_distance = interactable.interactable_distance
    if max_distance == 0:
        return false
    if max_distance < 0:
        max_distance = default_max_interaction_distance
    return global_position.distance_to(interactable.get_parent().global_position) < max_distance


func get_interactiable_at_raycast() -> InteractableComponent:
    var object = _raycast.get_collider()
    if !object:
        return null
    var shape = object.shape_owner_get_owner(object.shape_find_owner(_raycast.get_collider_shape()))
    var interactable = shape.get_node_or_null("InteractableComponent")
    if !interactable:
        interactable = object.get_node_or_null("InteractableComponent")
    if !_is_in_interaction_range(interactable):
        return null
    return interactable


func _on_grab_object(object: RigidBody3D):
    if !object || _held_object:
        return
    # assert(_held_object == null, "Player cannot pick up %s because they are already holding %s" % [object, _held_object])
    _held_object = object
    _player.add_collision_exception_with(object)
    _raycast.add_exception(object)
    _hud.visible = false


func _drop_held_object():
    if _held_object.has_method("_on_drop_by_character"):
        _held_object._on_drop_by_character()
    _player.remove_collision_exception_with(_held_object)
    _raycast.remove_exception(_held_object)
    _held_object = null
    _hud.visible = true
    _held_object_positioning_override = false
    dropped_held_object.emit(self)


func _handle_interaction():
    if !_can_interact():
        return
        
    if Input.is_action_just_pressed("interact"):
        if _held_object:
            _drop_held_object()
        else:
            var interactable = get_interactiable_at_raycast()
            if interactable:
                interactable.interact_with(self)
    
    if Input.is_action_just_pressed("use"):
        if _held_object && _held_object.has_method("_on_use_by_character"):
            _held_object._on_use_by_character(self)


func _unhandled_input(event):
    _handle_pause(event)
    if _is_paused():
        return
    
    _handle_camera_input(event)
    _handle_interaction()


func _move_held_object():
    if !_held_object || _held_object_positioning_override:
        return
    _held_object.linear_velocity = (_hold_position.global_position - _held_object.global_position) * pull_power
    _held_object.angular_velocity = -_held_object.rotation.normalized()


func _set_reticle(interactable: InteractableComponent):
    if interactable:
        _hud.set_state(interactable.get_reticle_state())
    else:
        _hud.set_state(HUD.ReticleState.PINPOINT)


func _process(_delta):
    var interactable = get_interactiable_at_raycast()
    _set_reticle(interactable)

    if interactable:
        interactable.hover_cursor(self)
    _move_held_object()
