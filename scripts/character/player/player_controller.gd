class_name PlayerController
extends Node3D


signal dropped_held_object(character: PlayerController)


enum ControlState {
    FREE_MOVE,
    ON_RAILS,
    FOCUSED,
    PAUSED
}


@export var mouse_sensitivity: float = 0.1
@export var default_max_interaction_distance: float = 2.5

var pull_power := 8.0

var control_state_configs := {
    ControlState.FREE_MOVE: ControlStateConfig.new(),
    ControlState.ON_RAILS: ControlStateConfig.new(true, false),
    ControlState.FOCUSED: ControlStateConfig.new(false, false),
    ControlState.PAUSED: ControlStateConfig.new(false, false, false),
}

var _held_object: RigidBody3D
var _held_object_positioning_override: bool

var _previous_state := ControlState.FREE_MOVE
var _current_state := ControlState.FREE_MOVE

@onready var _player: Player = get_parent() as Player
@onready var _hud: HUD = $HUD as HUD
@onready var _hold_position: Node3D = $HoldPosition as Node3D
@onready var _raycast: RayCast3D = $RayCast as RayCast3D


class ControlStateConfig:
    var can_free_look: bool
    var can_move: bool
    var can_interact: bool

    func _init(free_look := true, move := true, interact := true):
        can_free_look = free_look
        can_move = move
        can_interact = interact



func _change_control_state(new_state: ControlState):
    # Prevent overwriting previous state with multiple pauses
    if _current_state != ControlState.PAUSED:
        _previous_state = _current_state
    _current_state = new_state
    match new_state:
        ControlState.FREE_MOVE:
            Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
            _hud.visible = true
        ControlState.PAUSED:
            Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
            _hud.visible = false


func _revert_state():
    _change_control_state(_previous_state)


func _is_PAUSED() -> bool:
    return _current_state == ControlState.PAUSED


func _unpause():
    if _is_PAUSED():
        _revert_state()

func _can_free_look() -> bool:
    return control_state_configs.get(_current_state).can_free_look


func _can_move() -> bool:
    return control_state_configs.get(_current_state).can_move


func _can_interact() -> bool:
    return control_state_configs.get(_current_state).can_interact


func _ready():
    _change_control_state(ControlState.FREE_MOVE)


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
    if _is_PAUSED() &&  event is InputEventMouseButton:
        _unpause()
    elif event.is_action_pressed("ui_cancel"):
        _change_control_state(ControlState.PAUSED)


func _handle_camera_input(event):
    if event is InputEventMouseMotion and _can_free_look():
        rotation_degrees.y -= event.relative.x * mouse_sensitivity
        rotation_degrees.x += event.relative.y * mouse_sensitivity
        rotation.y = fposmod(rotation.y, TAU)
        rotation.x = clamp(rotation.x, -PI / 2, PI / 2)


func focus(target: Node3D):
    _change_control_state(ControlState.FOCUSED)
    $Camera3D.global_position = target.global_position
    $Camera3D.global_rotation = target.global_rotation


func unfocus():
    _revert_state()
    $Camera3D.global_position = Vector3(0, 0, 0.1)
    $Camera3D.global_rotation = Vector3(0, PI, 0)


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


func on_grab_object(object: RigidBody3D):
    if !object || _held_object:
        return
    _held_object = object
    _player.add_collision_exception_with(object)
    _raycast.add_exception(object)
    object.reparent(_hold_position)


func _drop_held_object():
    if _held_object.has_method("on_drop_by_character"):
        _held_object.on_drop_by_character()
    _player.remove_collision_exception_with(_held_object)
    _raycast.remove_exception(_held_object)
    _held_object.reparent(get_viewport())
    _held_object = null
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

    if Input.is_action_pressed("use"):
        if _held_object && _held_object.has_method("on_use_by_character"):
            _held_object.on_use_by_character(self)


func _unhandled_input(event):
    _handle_pause(event)
    if _is_PAUSED():
        return

    _handle_camera_input(event)
    _handle_interaction()


func _move_held_object():
    if !_held_object || _held_object_positioning_override:
        return
    _held_object.linear_velocity = (
        _hold_position.global_position - _held_object.global_position
    ) * pull_power
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
