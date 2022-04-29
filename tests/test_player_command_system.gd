extends "res://addons/gut/test.gd"

const PlayerCommandGenerator = preload("res://scenes/prefabs/player_command_generator.gd")
const PlayerCommandReceiver = preload("res://scenes/prefabs/player_command_receiver.gd")
const PlayerCommandCollector = preload("res://scenes/player_command_collector.gd")
const PlayerCommandRouter = preload("res://scenes/player_command_router.gd")

func test_player_command():
	# Server
	var player_command_router = PlayerCommandRouter.new()
	var player_command_receiver = PlayerCommandReceiver.new()
	add_child_autofree(player_command_router)
	add_child_autofree(player_command_receiver)

	# Client
	var player_command_collector = PlayerCommandCollector.new()
	var player_command_generator = PlayerCommandGenerator.new()
	add_child_autofree(player_command_collector)
	add_child_autofree(player_command_generator)
