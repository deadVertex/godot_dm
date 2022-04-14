extends KinematicBody

const BULLET_DISTANCE: float = 100.0
const BULLET_HOLE_OFFSET: float = 0.001
export var camera_sensitivity: float = 0.05
export var speed: float = 13.0
export var acceleration: float = 6.0
export var jump_impulse: float = 12.0
export var gravity: float = -20.0

var velocity: Vector3 = Vector3.ZERO

# TODO: Make this editor configurable
var _bullet_hole_prefab = preload("res://scenes/prefabs/bullet_hole.tscn")

onready var head: Spatial = $Head
onready var uzi_animations: AnimationPlayer = $Head/ViewModel/AnimationPlayer

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

	if Input.is_action_pressed("fire"):
		_handle_shooting()
		uzi_animations.play("Uzi_Fire")
	else:
		uzi_animations.play("Uzi_Idle")

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		_handle_camera_rotation(event)

func _handle_camera_rotation(event):
	rotate_y(deg2rad(-event.relative.x * camera_sensitivity))
	head.rotate_x(deg2rad(-event.relative.y * camera_sensitivity))
	head.rotation.x = clamp(head.rotation.x, -PI * 0.5, PI * 0.5);

func _handle_shooting():
	var space_state = get_world().direct_space_state
	var start = head.global_transform.origin
	var end = start - head.global_transform.basis.z * BULLET_DISTANCE
	var result = space_state.intersect_ray(start, end)
	if !result.empty():
		_spawn_bullet_hole(result["position"], result["normal"])

func _spawn_bullet_hole(position: Vector3, normal: Vector3):
	var bullet_hole = _bullet_hole_prefab.instance()
	var up = Vector3.UP
	if normal.dot(up) >= 0.99999:
		up = Vector3.RIGHT

	bullet_hole.look_at_from_position(position + normal * BULLET_HOLE_OFFSET,
		position + normal, up)
	get_tree().get_root().add_child(bullet_hole)

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
