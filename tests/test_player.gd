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


func test_player_not_local():
	# Given a player scene instance
	var player = PlayerScene.instance()
	add_child_autofree(player)

	# When we configure it to not be for the local camera
	player.set_locally_controlled(false)

	# Then the camera node on it is not current
	var camera = player.get_node("Head/Camera")
	assert_not_null(camera)
	assert_eq(camera.current, false)
