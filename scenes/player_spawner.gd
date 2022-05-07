extends Node

const Player = preload("res://scenes/prefabs/player.gd")
const PlayerSpawn = preload("res://scenes/prefabs/player_spawn.gd")

export var world_path: NodePath
export var player_scene: PackedScene

var _world: Node

func _ready():
	if world_path:
		_world = get_node(world_path)


func spawn_player() -> Player:
	var player: Player = null

	print("spawn_player called")
	# Find all player spawns in world
	var spawns = get_tree().get_nodes_in_group("player_spawn")

	# Choose suitable spawn
	var selected_spawn = find_free_spawn(spawns)
	if selected_spawn:
		print("player spawn found")

		# Mark spawn as occupied to prevent it being picked in future calls if
		# the Area hasn't been processed yet detecting the new player entity in
		# it
		selected_spawn.occupy() 

		# Create player entity at spawn location
		player = _create_player_entity(selected_spawn.global_transform.origin)
	
	return player


func _create_player_entity(position: Vector3) -> Player:
	var player = player_scene.instance()
	player.global_transform.origin = position
	# TODO: Set player orientation
	_world.add_child(player)
	return player


func find_free_spawn(spawns: Array) -> PlayerSpawn:
	var result: PlayerSpawn = null
	for spawn in spawns:
		if not spawn.is_occupied():
			result = spawn
			break
	
	return result
