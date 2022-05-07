extends "res://addons/gut/test.gd"

const BotSpawner = preload("res://scenes/bot_spawner.gd")
const PlayerSpawner = preload("res://scenes/player_spawner.gd")
const PlayerScene = preload("res://scenes/prefabs/player.tscn")
const PlayerSpawnScene = preload("res://scenes/prefabs/player_spawn.tscn")
const PlayerSpawn = preload("res://scenes/prefabs/player_spawn.gd")

# Reqs
# - Bots use same entity as players (same mechanism for driving player controller)
# - 
# Questions:
# - Do bots have state that persists across deaths? (Nice to have)

func test_bot_spawner():
	var player_spawner = double(PlayerSpawner).new()
	var player_scene = add_child_autofree(PlayerScene.instance())
	stub(player_spawner, "spawn_player").to_return(player_scene)

	# Given a bot spawner
	var bot_spawner = autofree(BotSpawner.new())
	bot_spawner.player_spawner = player_spawner

	# When I specify how many bots to spawn
	bot_spawner.spawn_bots(2)

	# Then that number of bot entities are created?
	assert_call_count(player_spawner, 'spawn_player', 2)

	# TODO: Check that bots have test brain enabled?


func test_player_spawn_occupied() -> void:
	# Given a player spawn
	var player_spawn = add_child_autofree(PlayerSpawnScene.instance())
	player_spawn.global_transform.origin = Vector3(100, 0, 0)

	# When a player entity is present in the spawn
	var player = add_child_autofree(PlayerScene.instance())
	player.global_transform.origin = Vector3(100, 0, 0)
	yield(yield_to(player_spawn.get_node("Area"), "body_entered", 1), YIELD)

	# Then the player spawn reports itself as occupied
	assert_true(player_spawn.is_occupied(), "player_spawn is occupied")

	# When a player entity leaves the spawn
	player.global_transform.origin = Vector3(0, 0, 0)
	yield(yield_to(player_spawn.get_node("Area"), "body_exited", 1), YIELD)

	# Then the player spawn is no longer occupied
	assert_false(player_spawn.is_occupied(), "player_spawn is not longer occupied")


func test_player_spawner_find_free_spawn() -> void:
	# Given a player spawner
	var player_spawner = add_child_autofree(PlayerSpawner.new())
	var spawns = []
	spawns.append(double(PlayerSpawn).new())
	spawns.append(double(PlayerSpawn).new())
	stub(spawns[0], "is_occupied").to_return(true)
	stub(spawns[1], "is_occupied").to_return(false)

	# When we select a spawn point
	var free_spawn = player_spawner.find_free_spawn(spawns)

	# Then the spawn is not occupied
	assert_eq(free_spawn, spawns[1])


func test_player_spawner_occupied() -> void:
	# Given a player spawner, with 2 player spawns
	var player_spawner = add_child_autofree(PlayerSpawner.new())
	player_spawner.player_scene = PlayerScene
	player_spawner._world = add_child_autofree(Spatial.new())

	var player_spawns = []
	player_spawns.append(add_child_autofree(PlayerSpawnScene.instance()))
	player_spawns.append(add_child_autofree(PlayerSpawnScene.instance()))

	player_spawns[0].global_transform.origin = Vector3(100, 0, 0)
	player_spawns[1].global_transform.origin = Vector3(200, 0, 0)

	# When we occupy one of the spawns with a player entity
	var occupying_player = add_child_autofree(PlayerScene.instance())
	occupying_player.global_transform.origin = Vector3(100, 0, 0)
	yield(yield_to(player_spawns[0].get_node("Area"), "body_entered", 1), YIELD)
	assert_true(player_spawns[0].is_occupied(), "player_spawn is occupied")

	# Then we spawn a player entity at the unoccupied spawn
	var player = autofree(player_spawner.spawn_player())
	assert_eq(player.global_transform.origin, Vector3(200, 0, 0))

# TODO: Test that spawn system marks spawn point as occupied when it is used
