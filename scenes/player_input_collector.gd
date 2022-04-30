extends Node

const Player = preload("res://scenes/prefabs/player.gd")

# For the enums, they should probably be an autoload
const ViewModel = preload("res://scenes/prefabs/view_model.gd")

var _player: Player
var _selected_weapon: int = ViewModel.Weapon.UZI


func set_player_entity(player: Player) -> void:
	print("set_player_entity: %s" % player)
	_player = player


func build_player_command() -> Dictionary:
	var player_cmd = {}

	if is_instance_valid(_player):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

		var forward: float = 0.0
		var right: float = 0.0
		var jump: bool = false
		var primary_attack: bool = false

		if Input.is_action_pressed("move_forwards"):
			forward += 1.0
		if Input.is_action_pressed("move_backwards"):
			forward -= 1.0
		if Input.is_action_pressed("move_left"):
			right -= 1.0
		if Input.is_action_pressed("move_right"):
			right += 1.0

		if Input.is_action_pressed("jump"):
			jump = true

		if Input.is_action_pressed("fire"):
			primary_attack = true

		if Input.is_action_pressed("select_uzi"):
			_selected_weapon = ViewModel.Weapon.UZI
		if Input.is_action_pressed("select_shotgun"):
			_selected_weapon = ViewModel.Weapon.SHOTGUN

		player_cmd = {
			"view_angles": _player.get_view_angles(),
			"forward": forward,
			"right": right,
			"jump": jump,
			"primary_attack": primary_attack,
			"selected_weapon": _selected_weapon,
		}

	return player_cmd


func _unhandled_input(event) -> void:
	if event is InputEventMouseMotion:
		if is_instance_valid(_player):
			_player.handle_camera_rotation(event)
