extends Node

export var world_path: NodePath
export var player_scene: PackedScene
export var player_command_router_path: NodePath

var _world: Node

onready var _player_cmd_router = get_node(player_command_router_path)


func _ready():
	if world_path:
		_world = get_node(world_path)


func spawn_player(client_id: int):
	print("spawn_player called")
	# Find all player spawns in world
	var spawns = get_tree().get_nodes_in_group("player_spawn")

	# Choose suitable spawn
	var selected_spawn = spawns.front()
	if selected_spawn:
		print("player spawn found")
		# Create player entity at spawn location
		_create_player_entity(selected_spawn.global_transform.origin, client_id)


func _create_player_entity(position: Vector3, client_id: int):
	var new_player = player_scene.instance()
	new_player.global_transform.origin = position
	# TODO: Set player orientation
	_world.add_child(new_player)
	# FIXME: Player spawner should not be registering player command receivers
	var cmd_receiver = new_player.get_node("PlayerCommandReceiver")
	_player_cmd_router.register_receiver(cmd_receiver, client_id)
