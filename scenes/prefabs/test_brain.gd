extends Node

const Player = preload("res://scenes/prefabs/player.gd")
const ViewModel = preload("res://scenes/prefabs/view_model.gd")

export(NodePath) var player_path
export(bool) var enabled = false

var _y_rotation := 0.0

onready var _player: Player = get_node(player_path)

func _physics_process(delta: float) -> void:
	if enabled:
		_y_rotation += delta * PI
		var player_cmd = {
			"view_angles": Vector3(0, _y_rotation, 0),
			"forward": 1.0,
			"right": 0.0,
			"jump": false,
			"primary_attack": true,
			"selected_weapon": ViewModel.Weapon.UZI,
		}

		_player.apply_player_cmd(player_cmd, delta)

