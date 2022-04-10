extends KinematicBody

export var camera_sensitivity: float = 0.05

onready var head: Spatial = $Head

var velocity: Vector3 = Vector3.ZERO

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	var movement = _get_movement_direction()

	velocity = movement
	velocity = move_and_slide(velocity)

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

	return direction
