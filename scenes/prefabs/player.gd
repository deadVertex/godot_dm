extends KinematicBody

signal bullet_impact(position, normal)

const BeanBoi = preload("res://scenes/prefabs/bean_boi.gd")

# Only used for enums!
const ViewModel = preload("res://scenes/prefabs/view_model.gd")

const BULLET_DISTANCE: float = 100.0
export var camera_sensitivity: float = 0.05
export var speed: float = 120.0
export var jump_impulse: float = 12.0
export var gravity: float = -20.0
export var friction: float = 8.0
export var uzi_time_between_shots: float = 0.18
export var shotgun_time_between_shots: float = 1.0
export var health: int = 120

var velocity: Vector3 = Vector3.ZERO

var _time_until_next_shot: float = 0.0
var _rng = RandomNumberGenerator.new()
var _active_weapon: int = ViewModel.Weapon.UZI
var _current_view_model_animation: int = ViewModel.ViewModelAnimation.IDLE
var _weapons := {ViewModel.Weapon.UZI: true}
var _previous_cmd: Dictionary = {}
var _is_locally_controlled := false

onready var head: Spatial = $Head
onready var camera: Camera = $Head/Camera
onready var _body: MeshInstance = $Body


func _ready():
	_rng.randomize()
	camera.current = false


func set_locally_controlled(is_locally_controlled: bool) -> void:
	_is_locally_controlled = is_locally_controlled
	camera.current = is_locally_controlled
	_body.visible = not is_locally_controlled


func is_locally_controlled() -> bool:
	return _is_locally_controlled


func apply_damage(amount: int) -> void:
	print("apply_damage: self: %s amount: %d" % [self, amount])
	health = health - amount
	if health <= 0:
		queue_free()


func _get_movement_direction(cmd):
	var direction = Vector3.DOWN

	if cmd.forward > 0.0:
		direction -= transform.basis.z
	if cmd.forward < 0.0:
		direction += transform.basis.z

	if cmd.right > 0.0:
		direction += transform.basis.x
	if cmd.right < 0.0:
		direction -= transform.basis.x

	return direction.normalized()


func apply_player_cmd(cmd, delta):
	#print("apply_player_cmd")
	var movement = _get_movement_direction(cmd)

	# print("apply_player_cmd: %s" % cmd)
	if _weapons.has(cmd["selected_weapon"]):
		_active_weapon = cmd["selected_weapon"]

	set_view_angles(cmd["view_angles"])

	if cmd["jump"] and is_on_floor():
		if not _previous_cmd["jump"]:
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

	if cmd["primary_attack"]:
		if _time_until_next_shot <= 0.0:
			_handle_shooting()

			# Calculate time to wait between shots for each weapon
			var time_between_shots = 0.0
			if _active_weapon == ViewModel.Weapon.SHOTGUN:
				time_between_shots = shotgun_time_between_shots
			else:
				time_between_shots = uzi_time_between_shots

			_time_until_next_shot = time_between_shots

			# Set animation state which we replicate to client
			_current_view_model_animation = ViewModel.ViewModelAnimation.FIRE
	else:
		_current_view_model_animation = ViewModel.ViewModelAnimation.IDLE
	
	_previous_cmd = cmd


# NOTE: This should only be run on the server
func _handle_shooting():
	var start = head.global_transform.origin

	if _active_weapon == ViewModel.Weapon.UZI:
		var end = start - head.global_transform.basis.z * BULLET_DISTANCE
		_process_bullet(start, end, 25.0)
	elif _active_weapon == ViewModel.Weapon.SHOTGUN:
		for _index in range(8):
			var scale = 0.02
			var offset = Vector3(
				_rng.randf_range(-scale, scale),
				_rng.randf_range(-scale, scale),
				_rng.randf_range(-scale, scale)
			)
			var forward = -head.global_transform.basis.z + offset
			forward = forward.normalized()
			var end = start + forward * BULLET_DISTANCE
			_process_bullet(start, end, 16)


func _process_bullet(start: Vector3, end: Vector3, damage: float):
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(start, end)
	if !result.empty():
		var collider = result["collider"]

		# Network event for bullet impact
		# print("emit_signal: bullet_impact")
		emit_signal("bullet_impact", result["position"], result["normal"])

		if collider.has_method("apply_damage"):
			collider.apply_damage(damage)

			#_spawn_blood_splatter_fx(
			#collider, result["position"], result["normal"]
			#)


#func _spawn_blood_splatter_fx(boi: Spatial, position: Vector3, normal: Vector3):
#var blood_splatter = blood_splatter_fx_prefab.instance()
#boi.add_child(blood_splatter)
#var up = Vector3.UP
#if normal.dot(up) >= 0.99999:
#up = Vector3.RIGHT
#blood_splatter.look_at_from_position(position, position + normal, up)
#blood_splatter.restart()


func get_view_angles() -> Vector3:
	return Vector3(head.rotation.x, rotation.y, 0.0)


func set_view_angles(view_angles: Vector3) -> void:
	#print("%s - set_view_angles: %s" % [self, view_angles])
	rotation.y = view_angles.y
	head.rotation.x = clamp(view_angles.x, -PI * 0.5, PI * 0.5)


func handle_camera_rotation(event: InputEventMouseMotion) -> void:
	#print("handle_camera_rotation: self: %s" % self)
	rotate_y(deg2rad(-event.relative.x * camera_sensitivity))
	head.rotate_x(deg2rad(-event.relative.y * camera_sensitivity))
	head.rotation.x = clamp(head.rotation.x, -PI * 0.5, PI * 0.5)


func get_active_weapon() -> int:
	return _active_weapon


func get_current_view_model_animation() -> int:
	return _current_view_model_animation


func give_weapon(weapon: int) -> void:
	print("give_weapon: %d" % weapon)
	_weapons[weapon] = true
