extends Node

const PlayerSpawner = preload("res://scenes/player_spawner.gd")

var player_spawner: PlayerSpawner

func spawn_bots(count: int) -> void:
	print("spawn_bots")
	for index in count:
		# Spawn player entity
		var player = player_spawner.spawn_player()

		# Disable player command receiver
		var cmd_receiver = player.get_node("PlayerCommandReceiver")
		assert(cmd_receiver)
		cmd_receiver.enabled = false

		# Enable test brain
		var test_brain = player.get_node("TestBrain")
		assert(test_brain)
		test_brain.enable()
