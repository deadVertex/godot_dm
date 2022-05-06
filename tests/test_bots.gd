extends "res://addons/gut/test.gd"

const BotSpawner = preload("res://scenes/bot_spawner.gd")
const PlayerSpawner = preload("res://scenes/player_spawner.gd")
const PlayerScene = preload("res://scenes/prefabs/player.tscn")

# Reqs
# - Bots use same entity as players (same mechanism for driving player controller)
# - 
# Questions:
# - Do bots have state that persists across deaths? (Nice to have)

func test_bot_spawner():
	var player_spawner = double(PlayerSpawner).new()
	var player_scene = PlayerScene.instance()
	stub(player_spawner, "spawn_player").to_return(player_scene)

	# Given a bot spawner
	var bot_spawner = BotSpawner.new()
	bot_spawner.player_spawner = player_spawner

	# When I specify how many bots to spawn
	bot_spawner.spawn_bots(2)

	# Then that number of bot entities are created?
	assert_call_count(player_spawner, 'spawn_player', 2)

	# TODO: Check that bots have test brain enabled?
