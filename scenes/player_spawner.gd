extends Node

export var replication_server_path: NodePath  # FIXME: Remove this!
export var world_path: NodePath
export var player_scene: PackedScene

var _world: Node
var _replication_server: Node  # FIXME: Remove this


func _ready():
	if world_path:
		_world = get_node(world_path)
	if replication_server_path:
		_replication_server = get_node(replication_server_path)


func spawn_player():
	print("spawn_player called")
	# Find all player spawns in world
	var spawns = get_tree().get_nodes_in_group("player_spawn")

	# Choose suitable spawn
	var selected_spawn = spawns.front()
	if selected_spawn:
		print("player spawn found")
		# Create player entity at spawn location
		var new_player = player_scene.instance()
		new_player.global_transform.origin = selected_spawn.global_transform.origin
		# TODO: Set player orientation
		_world.add_child(new_player)
		# Register player entity with replication system?
		_replication_server.register_entity(new_player)  # FIXME: Remove this!
