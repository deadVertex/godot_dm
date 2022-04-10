extends KinematicBody

export var camera_sensitivity: float = 0.05
export var speed: float = 13.0
export var acceleration: float = 6.0
export var jump_impulse: float = 12.0
export var gravity: float = -20.0

onready var head: Spatial = $Head

var velocity: Vector3 = Vector3.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	var movement = _get_movement_direction()

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_impulse

	velocity.x = lerp(velocity.x, movement.x * speed, acceleration * delta)
	velocity.z = lerp(velocity.z, movement.z * speed, acceleration * delta)
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector3.UP)

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		_handle_camera_rotation(event)

func _handle_camera_rotation(event):
	rotate_y(deg2rad(-event.relative.x * camera_sensitivity))
	head.rotate_x(deg2rad(-event.relative.y * camera_sensitivity))
	head.rotation.x = clamp(head.rotation.x, -PI * 0.5, PI * 0.5);

func _get_movement_direction():
	var direction = Vector3.DOWN

	if Input.is_action_pressed("move_forwards"):
		direction -= transform.basis.z
	if Input.is_action_pressed("move_backwards"):
		direction += transform.basis.z
	if Input.is_action_pressed("move_left"):
		direction -= transform.basis.x
	if Input.is_action_pressed("move_right"):
		direction += transform.basis.x

	return direction.normalized()
