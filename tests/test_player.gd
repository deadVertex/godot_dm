extends "res://addons/gut/test.gd"

const Player = preload("res://scenes/prefabs/player.gd")
const PlayerScene = preload("res://scenes/prefabs/player.tscn")
# Only used for enums!
const ViewModel = preload("res://scenes/prefabs/view_model.gd")

func test_player_shotgun_semi_auto():
	var player = PlayerScene.instance()
	add_child_autofree(player)
	player.give_weapon(ViewModel.Weapon.SHOTGUN)

	var cmd = {
		"selected_weapon": ViewModel.Weapon.SHOTGUN,
		"jump": false,
		"right": 0.0,
		"forward": 0.0,
		"view_angles": Vector3(0, 0, 0),
		"primary_attack": true,
	}

	player.shotgun_time_between_shots = 1.0
	player.apply_player_cmd(cmd, 1.0)
	assert_eq(player._time_until_next_shot, 1.0)
