extends KinematicBody

const BeanBoi = preload("res://scenes/prefabs/bean_boi.gd")

const BULLET_DISTANCE: float = 100.0
const BULLET_HOLE_OFFSET: float = 0.001
export var camera_sensitivity: float = 0.05
export var speed: float = 120.0
export var jump_impulse: float = 12.0
export var gravity: float = -20.0
export var friction: float = 8.0
export var time_between_shots: float = 0.18

export var blood_splatter_fx_prefab: PackedScene

var velocity: Vector3 = Vector3.ZERO

# TODO: Make this editor configurable
var _bullet_hole_prefab = preload("res://scenes/prefabs/bullet_hole.tscn")

var _time_until_next_shot: float = 0.0

onready var head: Spatial = $Head
onready var uzi_animations: AnimationPlayer = $Head/ViewModel/AnimationPlayer


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta):
	var movement = _get_movement_direction()

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_impulse

	velocity.x = (
		velocity.x
		+ movement.x * speed * delta
		- velocity.x * friction * delta
	)
	velocity.z = (
		velocity.z
		+ movement.z * speed * delta
		- velocity.z * friction * delta
	)
	velocity.y += gravity * delta
	velocity = move_and_slide(velocity, Vector3.UP)

	_time_until_next_shot = max(_time_until_next_shot - delta, 0.0)

	if Input.is_action_pressed("fire"):
		if _time_until_next_shot <= 0.0:
			_handle_shooting()
			_time_until_next_shot = time_between_shots
			uzi_animations.play("Uzi_Fire")
	else:
		uzi_animations.play("Uzi_Idle")


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		_handle_camera_rotation(event)


func _handle_camera_rotation(event):
	rotate_y(deg2rad(-event.relative.x * camera_sensitivity))
	head.rotate_x(deg2rad(-event.relative.y * camera_sensitivity))
	head.rotation.x = clamp(head.rotation.x, -PI * 0.5, PI * 0.5)


func _handle_shooting():
	var space_state = get_world().direct_space_state
	var start = head.global_transform.origin
	var end = start - head.global_transform.basis.z * BULLET_DISTANCE
	var result = space_state.intersect_ray(start, end)
	if !result.empty():
		var collider = result["collider"]
		if collider is BeanBoi:
			collider.apply_damage(25)
			_spawn_blood_splatter_fx(
				collider, result["position"], result["normal"]
			)
		else:
			_spawn_bullet_hole(result["position"], result["normal"])


func _spawn_blood_splatter_fx(boi: Spatial, position: Vector3, normal: Vector3):
	var blood_splatter = blood_splatter_fx_prefab.instance()
	boi.add_child(blood_splatter)
	var up = Vector3.UP
	if normal.dot(up) >= 0.99999:
		up = Vector3.RIGHT
	blood_splatter.look_at_from_position(position, position + normal, up)
	blood_splatter.restart()


func _spawn_bullet_hole(position: Vector3, normal: Vector3):
	var bullet_hole = _bullet_hole_prefab.instance()
	var up = Vector3.UP
	if normal.dot(up) >= 0.99999:
		up = Vector3.RIGHT

	bullet_hole.look_at_from_position(
		position + normal * BULLET_HOLE_OFFSET, position + normal, up
	)
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
