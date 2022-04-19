extends Node

const Player = preload("res://scenes/prefabs/player.gd")

export var player_path: NodePath

var enabled: bool = true

onready var _player: Player = get_node(player_path)
onready var _last_received_player_cmd = _default_player_cmd()


func _physics_process(delta: float):
	print("_physics_process: enabled: %s" % enabled)
	if enabled == true:
		print("_player.apply_player_cmd: %s" % _last_received_player_cmd)
		# Apply last received player_cmd to our player entity
		_player.apply_player_cmd(_last_received_player_cmd, delta)


func receive_player_cmd(cmd: Dictionary):
	_last_received_player_cmd = cmd


func _default_player_cmd():
	var player_cmd = {
		"view_angles": Vector3(0, 0, 0),
		"forward": 0.0,
		"right": 0.0,
		"jump": false,
		"primary_attack": false,
	}

	return player_cmd
