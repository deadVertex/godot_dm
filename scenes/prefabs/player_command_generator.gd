extends Node

const Player = preload("res://scenes/prefabs/player.gd")

# For the enums, they should probably be an autoload
const ViewModel = preload("res://scenes/prefabs/view_model.gd")

export var register_with_collector: bool = false
export var player_path: NodePath

var _selected_weapon: int = ViewModel.Weapon.UZI

onready var _player: Player = get_node(player_path)


func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	if register_with_collector:
		var collector = get_tree().get_root().get_node(
			"Main/PlayerCommandCollector"
		)
		collector.register(self)


func build_player_command():
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

	var player_cmd = {
		"view_angles": _player.get_view_angles(),
		"forward": forward,
		"right": right,
		"jump": jump,
		"primary_attack": primary_attack,
		"selected_weapon": _selected_weapon,
	}

	return player_cmd


func _unhandled_input(event):
	if event is InputEventMouseMotion:
		_player.handle_camera_rotation(event)
