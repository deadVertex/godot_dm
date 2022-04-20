extends KinematicBody

signal bullet_impact(position, normal)

enum ViewModelAnimation { IDLE, FIRE }
enum Weapon { UZI, SHOTGUN } # TODO: Move away from fix enum for weapons

const BeanBoi = preload("res://scenes/prefabs/bean_boi.gd")

const BULLET_DISTANCE: float = 100.0
export var camera_sensitivity: float = 0.05
export var speed: float = 120.0
export var jump_impulse: float = 12.0
export var gravity: float = -20.0
export var friction: float = 8.0
export var time_between_shots: float = 0.18

export var view_model_animation: int = ViewModelAnimation.IDLE

var velocity: Vector3 = Vector3.ZERO

var _time_until_next_shot: float = 0.0
var _weapon: int = Weapon.UZI
var _rng = RandomNumberGenerator.new()

onready var head: Spatial = $Head
onready var _animation_player: AnimationPlayer = $Head/ViewModel/AnimationPlayer
onready var _uzi: Spatial = $Head/ViewModel/UziBase
onready var _shotgun: Spatial = $Head/ViewModel/ShotgunBase

func _ready():
	_rng.randomize()

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

	set_view_model(cmd["selected_weapon"])
	set_view_angles(cmd["view_angles"])

	if cmd["jump"] and is_on_floor():
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
			_time_until_next_shot = time_between_shots
			# Set animation state which we replicate to client
			view_model_animation = ViewModelAnimation.FIRE
	else:
		view_model_animation = ViewModelAnimation.IDLE


# NOTE: This should only be run on the server
func _handle_shooting():
	var start = head.global_transform.origin

	if _weapon == Weapon.UZI:
		var end = start - head.global_transform.basis.z * BULLET_DISTANCE
		_process_bullet(start, end, 25.0)
	elif _weapon == Weapon.SHOTGUN:
		for _index in range(8):
			var scale = 0.02
			var offset = Vector3(_rng.randf_range(-scale, scale),
				_rng.randf_range(-scale, scale),
				_rng.randf_range(-scale, scale))
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

		if collider is BeanBoi:
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


func get_view_angles():
	return Vector3(head.rotation.x, rotation.y, 0.0)


func set_view_angles(view_angles: Vector3):
	rotation.y = view_angles.y
	head.rotation.x = clamp(view_angles.x, -PI * 0.5, PI * 0.5)


func handle_camera_rotation(event):
	rotate_y(deg2rad(-event.relative.x * camera_sensitivity))
	head.rotate_x(deg2rad(-event.relative.y * camera_sensitivity))
	head.rotation.x = clamp(head.rotation.x, -PI * 0.5, PI * 0.5)


func set_view_model_animation(animation: int) -> void:
	assert(animation in ViewModelAnimation.values())
	view_model_animation = animation
	if animation == ViewModelAnimation.IDLE:
		if _weapon == Weapon.UZI:
			_animation_player.play("Uzi_Idle")
		elif _weapon == Weapon.SHOTGUN:
			_animation_player.play("Shotgun_Idle")
	elif animation == ViewModelAnimation.FIRE:
		if _weapon == Weapon.UZI:
			_animation_player.play("Uzi_Fire")
		elif _weapon == Weapon.SHOTGUN:
			_animation_player.play("Shotgun_Fire")


func set_view_model(weapon: int) -> void:
	_weapon = weapon
	if weapon == Weapon.UZI:
		_uzi.show()
		_shotgun.hide()
	elif weapon == Weapon.SHOTGUN:
		_uzi.hide()
		_shotgun.show()


func get_view_model() -> int:
	return _weapon
