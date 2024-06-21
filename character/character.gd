extends CharacterBody3D

var gravity: Vector3

const SPEED = 5.0
const JUMP_VELOCITY = 4.5
@export var mouse_sensitivity : float = 0.1

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _process(_delta):	
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		elif Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		$Head.rotation_degrees.y -= event.relative.x * mouse_sensitivity
		$Head.rotation_degrees.x += event.relative.y * mouse_sensitivity
		$Head.rotation.y = fposmod($Head.rotation.y, TAU)
		$Head.rotation.x = clamp($Head.rotation.x, -PI / 2, PI / 2)

func _physics_process(delta):
	# Add the gravity.
	gravity = PhysicsServer3D.body_get_direct_state(get_rid()).total_gravity
	_orient_character_to_direction($Head.rotation)
	if gravity != Vector3.ZERO:
		up_direction = -gravity.normalized()

	if not is_on_floor():
		velocity += gravity * delta

	# Handle jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	handle_movement(delta, input_dir)

func handle_movement(delta, input_dir):
	var movement_basis = transform.basis.rotated(transform.basis.y, $Head.rotation.y)
	var direction = movement_basis.x * input_dir.x + movement_basis.z * input_dir.y

	if is_on_floor():
		velocity = velocity.move_toward(-direction, SPEED * delta)
	else:
		velocity = lerp(velocity, -direction * SPEED, delta)
	move_and_slide()

func _orient_character_to_direction(direction: Vector3) -> void:
	direction.x = 0
	var left_axis = -gravity.cross(direction)
	var new_basis = Basis(left_axis, -gravity, direction)
	if new_basis.determinant() != 0:
		transform.basis = new_basis.orthonormalized()