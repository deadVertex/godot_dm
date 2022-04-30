extends "res://addons/gut/test.gd"

const PlayerCommandReceiver = preload("res://scenes/prefabs/player_command_receiver.gd")
const PlayerCommandRouter = preload("res://scenes/player_command_router.gd")
const PlayerInputCollector = preload("res://scenes/player_input_collector.gd")
const Player = preload("res://scenes/prefabs/player.gd")

func test_player_command():
	# Server
	var player_command_router = PlayerCommandRouter.new()
	var player_command_receiver = PlayerCommandReceiver.new()
	add_child_autofree(player_command_router)
	add_child_autofree(player_command_receiver)

	var server_player = double(Player).new()
	player_command_receiver._player = server_player

	var client_id = 1
	player_command_router.register_receiver(player_command_receiver, client_id)

	# Client
	var player_input_collector = PlayerInputCollector.new()
	add_child_autofree(player_input_collector)

	var client_player = double(Player).new()
	player_input_collector.set_player_entity(client_player)
	stub(client_player, "get_view_angles").to_return(Vector3(1, 2, 3))
	var cmd = player_input_collector.build_player_command()

	# Send cmd over network

	# Server
	player_command_router.route_cmd(cmd, client_id)
	assert_eq(player_command_receiver._last_received_player_cmd["view_angles"], Vector3(1, 2, 3))
	player_command_receiver._physics_process(0.0)
	assert_called(server_player, "apply_player_cmd")
