class_name PlayerController
extends Node3D

@export var mouse_sensitivity : float = 0.1

@onready var _player: Player = get_parent() as Player
@onready var _hud: HUD = $HUD as HUD
@onready var _hold_position: Node3D = $HoldPosition as Node3D
@onready var _raycast: RayCast3D = $RayCast as RayCast3D

var _held_object: RigidBody3D

signal picked_up
signal dropped

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _process(delta):
	_capture_input()
	_handle_input()
	if _held_object:
		_move_held_object(delta)
	else:
		_set_reticle()

func _physics_process(delta):
	# Handle jump.
	if Input.is_action_just_pressed("ui_accept"):
		_player.jump()

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	_player.move(delta, input_dir)

	

func _capture_input():
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			_hud.visible = false
		elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			_hud.visible = true

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation_degrees.y -= event.relative.x * mouse_sensitivity
		rotation_degrees.x += event.relative.y * mouse_sensitivity
		rotation.y = fposmod(rotation.y, TAU)
		rotation.x = clamp(rotation.x, -PI / 2, PI / 2)

func _handle_input():
	if Input.is_action_just_pressed("left_click") and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		if _handle_clicking():
			return
		if _handle_grabbing():
			return

func _handle_clicking() -> bool:
	var object = _raycast_clickable()
	if !object:
		return false
	object.on_click()

	return true

func _handle_grabbing() -> bool:
	var handled = false
	if _held_object:
		_drop_held_object()
		handled = true
	else:
		_pick_up_object(_raycast_grabbable())
		handled = !!_held_object
	_hud.visible = !_held_object
	return handled

func _pick_up_object(object: RigidBody3D):
	if !object:
		return
	_held_object = object
	_held_object.freeze = true
	_held_object.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	_player.add_collision_exception_with(object)
	_connect_signal(dropped, _held_object, "_on_picked_up")
	_connect_signal(dropped, _held_object, "_on_dropped")
	picked_up.emit()

func _drop_held_object():
	dropped.emit()
	_disconnect_signal(dropped, _held_object, "_on_picked_up")
	_disconnect_signal(dropped, _held_object, "_on_dropped")
	_player.remove_collision_exception_with(_held_object)
	_held_object.freeze = false
	_held_object = null

func _connect_signal(sig: Signal, object: Node, method_name: String):
	if object.has_method(method_name):
		sig.connect(object.get_method(method_name))

func _disconnect_signal(sig: Signal, object: Node, method_name: String):
	if object.has_method(method_name):
		sig.disconnect(object.get_method(method_name))

func _move_held_object(delta):
	_held_object.global_position = _held_object.global_position.move_toward(_hold_position.global_position, delta * 10)
	_held_object.global_rotation = _held_object.global_rotation.move_toward(_hold_position.global_rotation, delta * 10)

func _is_grabbable(object: Object) -> bool:
	if object and object is RigidBody3D:
		var shape = object.shape_owner_get_owner(object.shape_find_owner(_raycast.get_collider_shape()))
		return shape and shape is Grabbable
	return false

func _raycast_grabbable():
	var object = _raycast.get_collider()
	if _is_grabbable(object):
		return object

func _is_clickable(object: Object) -> bool:
	if object:
		var shape = object.shape_owner_get_owner(object.shape_find_owner(_raycast.get_collider_shape()))
		return shape.get_parent().has_method("on_click")
	return false

func _raycast_clickable():
	var object = _raycast.get_collider()
	if _is_clickable(object):
		return object as Button3D

func _set_reticle():	
	var object = _raycast.get_collider()
	if _is_clickable(object):
		_hud.set_state(HUD.ReticleState.CIRCLE)
	elif _is_grabbable(object):
		_hud.set_state(HUD.ReticleState.RING)
	else:
		_hud.set_state(HUD.ReticleState.PINPOINT)
