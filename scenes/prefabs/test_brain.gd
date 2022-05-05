extends Node

const Player = preload("res://scenes/prefabs/player.gd")
const ViewModel = preload("res://scenes/prefabs/view_model.gd")

export(NodePath) var player_path
export(bool) var enabled = false

var _y_rotation := 0.0
var _navigation_node: Navigation
var _target: Player
var _path := []
var _path_node := 0

onready var _player: Player = get_node(player_path)

func _ready() -> void:
	# Get navigation node
	var navigation_nodes = get_tree().get_nodes_in_group("navigation")
	assert(navigation_nodes.size() == 1)
	_navigation_node = navigation_nodes.front()


func find_target() -> Player:
	print("find_target")
	var result: Player = null
	var players = get_tree().get_nodes_in_group("players")
	players.erase(_player)
	if players.size() > 0:
		result = players.front()
	
	return result


func _physics_process(delta: float) -> void:
	if enabled:
		if _target:
			_y_rotation += delta * PI
			var player_cmd = {
				"view_angles": Vector3(0, _y_rotation, 0),
				"forward": 0.0,
				"right": 0.0,
				"jump": false,
				"primary_attack": false,
				"selected_weapon": ViewModel.Weapon.UZI,
			}

			var direction = (_path[_path_node] - _player.global_transform.origin)
			#var direction = (_target.global_transform.origin - _player.global_transform.origin)

			var min_dist = 1.0
			if direction.length() < min_dist:
				if _path_node < _path.size() - 1:
					_path_node += 1
			else:
				# TODO: Support strafing?
				player_cmd["forward"] = 1.0
				var dir = direction
				dir.y = 0.0
				dir = dir.normalized()
				player_cmd["view_angles"].y = Vector3.FORWARD.signed_angle_to(dir, Vector3.UP)


			_player.apply_player_cmd(player_cmd, delta)


func move_to(target_pos: Vector3) -> void:
	print("move_to")
	_path = _navigation_node.get_simple_path(_player.global_transform.origin, target_pos)
	_path_node = 0


func _on_TestBrainTimer_timeout():
	print("_on_TestBrainTimer_timeout")
	if enabled:
		if not _target:
			_target = find_target()
		if _target:
			move_to(_target.global_transform.origin)
